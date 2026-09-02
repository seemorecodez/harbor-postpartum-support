#!/usr/bin/env python3
"""Fail-closed verification for a Harbor known-good recovery release.

The verifier reads only public release artifacts. It never reads a Harbor vault,
browser profile, clipboard, crash report, or user identifier.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any


class VerificationError(RuntimeError):
    """Raised when a release cannot be used as a recovery anchor."""


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise VerificationError(message)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _release_label(version: str) -> str:
    match = re.fullmatch(r"0\.1\.0-alpha\.(\d+)", version)
    _require(match is not None, "Release version must use 0.1.0-alpha.N.")
    return f"alpha{match.group(1)}"


def _safe_zip_entries(archive: zipfile.ZipFile) -> dict[str, zipfile.ZipInfo]:
    entries: dict[str, zipfile.ZipInfo] = {}
    total_bytes = 0
    for info in archive.infolist():
        raw_name = info.filename
        if info.is_dir():
            continue
        _require("\\" not in raw_name, f"ZIP entry uses a backslash: {raw_name}")
        path = PurePosixPath(raw_name)
        _require(not path.is_absolute(), f"ZIP entry is absolute: {raw_name}")
        _require(".." not in path.parts, f"ZIP entry traverses directories: {raw_name}")
        _require(path.parts and ":" not in path.parts[0], f"Unsafe ZIP entry: {raw_name}")
        _require(path.as_posix() == raw_name, f"ZIP entry path is not canonical: {raw_name}")
        unix_type = (info.external_attr >> 16) & 0o170000
        _require(unix_type != 0o120000, f"ZIP entry is a symbolic link: {raw_name}")
        _require(info.file_size <= 128 * 1024 * 1024, f"ZIP entry is too large: {raw_name}")
        total_bytes += info.file_size
        _require(total_bytes <= 512 * 1024 * 1024, "ZIP expands beyond the recovery-verifier limit.")
        _require(raw_name not in entries, f"Duplicate ZIP entry: {raw_name}")
        entries[raw_name] = info
        _require(len(entries) <= 4096, "ZIP contains too many files.")
    _require(entries, "ZIP contains no files.")
    return entries


def _parse_checksums(path: Path) -> dict[str, str]:
    checksums: dict[str, str] = {}
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        match = re.fullmatch(r"([0-9A-Fa-f]{64})  ([A-Za-z0-9][A-Za-z0-9._-]*)", line)
        _require(match is not None, f"Invalid checksum line {number}.")
        digest, name = match.groups()
        _require(name not in checksums, f"Duplicate checksum entry: {name}")
        checksums[name] = digest.lower()
    _require(checksums, "Checksum inventory is empty.")
    return checksums


def _verify_checksum_inventory(bundle_dir: Path, checksum_name: str, required: set[str]) -> dict[str, str]:
    checksum_path = bundle_dir / checksum_name
    _require(checksum_path.is_file(), f"Missing checksum inventory: {checksum_name}")
    checksums = _parse_checksums(checksum_path)
    _require(set(checksums) == required, "Checksum inventory does not exactly cover the governed release assets.")
    for name, expected in checksums.items():
        asset = bundle_dir / name
        _require(asset.is_file(), f"Missing release asset: {name}")
        _require(_sha256(asset) == expected, f"Checksum mismatch: {name}")
    return checksums


def _extract_release_assets(worker: str) -> list[dict[str, Any]]:
    match = re.search(
        r"/\* HARBOR_RELEASE_ASSETS_START \*/\s*(\[.*?\])\s*/\* HARBOR_RELEASE_ASSETS_END \*/",
        worker,
        re.DOTALL,
    )
    _require(match is not None, "Web worker release manifest markers are missing.")
    try:
        assets = json.loads(match.group(1))
    except json.JSONDecodeError as error:
        raise VerificationError("Web worker release manifest is invalid JSON.") from error
    _require(isinstance(assets, list) and assets, "Web worker release manifest is empty.")
    return assets


def _verify_web_zip(path: Path, version: str, build_number: int) -> dict[str, int]:
    with zipfile.ZipFile(path) as archive:
        entries = _safe_zip_entries(archive)
        required = {
            "harbor_service_worker.js",
            "index.html",
            "main.dart.wasm",
            "privacy.html",
            "version.json",
        }
        _require(required <= set(entries), "Web ZIP is missing a required runtime file.")

        worker = archive.read("harbor_service_worker.js").decode("utf-8")
        _require(
            f'const CACHE_NAME = "harbor-shell-{version}";' in worker,
            "Web worker cache identity does not match the release version.",
        )
        assets = _extract_release_assets(worker)
        manifested_files: set[str] = set()
        precached = 0
        for asset in assets:
            _require(isinstance(asset, dict), "Release manifest entry is not an object.")
            url = asset.get("url")
            digest = asset.get("sha256")
            byte_count = asset.get("bytes")
            _require(isinstance(url, str) and url.startswith("./"), "Release asset URL is invalid.")
            _require(isinstance(digest, str) and re.fullmatch(r"[0-9a-f]{64}", digest) is not None, "Release asset digest is invalid.")
            _require(isinstance(byte_count, int) and byte_count >= 0, "Release asset byte count is invalid.")
            file_name = url[2:].split("?", 1)[0]
            _require(file_name in entries, f"Manifest references a missing web file: {file_name}")
            payload = archive.read(file_name)
            _require(len(payload) == byte_count, f"Manifest byte count mismatch: {url}")
            _require(hashlib.sha256(payload).hexdigest() == digest, f"Manifest digest mismatch: {url}")
            manifested_files.add(file_name)
            if asset.get("precache") is True:
                precached += 1

        expected_manifested = set(entries) - {"harbor_service_worker.js"}
        _require(manifested_files == expected_manifested, "Release manifest does not exactly cover the web payload.")

        identity = json.loads(archive.read("version.json").decode("utf-8"))
        _require(identity.get("version") == version, "version.json release identity mismatch.")
        _require(str(identity.get("build_number")) == str(build_number), "version.json build number mismatch.")

        privacy = archive.read("privacy.html").decode("utf-8").lower()
        for forbidden in ("<script", "<form", "<img", "http-equiv=\"refresh\""):
            _require(forbidden not in privacy, f"Static privacy notice contains forbidden markup: {forbidden}")
        _require("legal review pending" in privacy, "Static privacy notice lacks its legal-review boundary.")

    return {"files": len(entries), "manifestAssets": len(assets), "precacheAssets": precached}


def _git_blob_sha1(payload: bytes) -> str:
    return hashlib.sha1(f"blob {len(payload)}\0".encode("ascii") + payload).hexdigest()


def _git_blobs(repo_dir: Path, commit: str) -> dict[str, str]:
    result = subprocess.run(
        ["git", "-C", str(repo_dir), "ls-tree", "-rz", "--full-tree", commit],
        check=False,
        capture_output=True,
    )
    _require(result.returncode == 0, "Unable to read the expected source commit.")
    blobs: dict[str, str] = {}
    for record in result.stdout.split(b"\0"):
        if not record:
            continue
        metadata, raw_path = record.split(b"\t", 1)
        parts = metadata.split()
        if len(parts) == 3 and parts[1] == b"blob":
            blobs[raw_path.decode("utf-8")] = parts[2].decode("ascii")
    _require(blobs, "Source commit contains no blobs.")
    return blobs


def _verify_source_zip(path: Path, repo_dir: Path, commit: str) -> int:
    expected = _git_blobs(repo_dir, commit)
    with zipfile.ZipFile(path) as archive:
        entries = _safe_zip_entries(archive)
        roots = {PurePosixPath(name).parts[0] for name in entries}
        _require(len(roots) == 1, "Source ZIP must contain one top-level directory.")
        root = next(iter(roots))
        actual: dict[str, str] = {}
        for name in entries:
            parts = PurePosixPath(name).parts
            _require(parts[0] == root and len(parts) > 1, "Source ZIP entry is outside its release root.")
            relative = PurePosixPath(*parts[1:]).as_posix()
            actual[relative] = _git_blob_sha1(archive.read(name))
        _require(set(actual) == set(expected), "Source ZIP does not exactly cover the source commit.")
        mismatches = [name for name in expected if actual[name] != expected[name]]
        if mismatches:
            raise VerificationError(f"Source ZIP blob mismatch: {mismatches[0]}")
    return len(expected)


def _load_json(path: Path, label: str) -> dict[str, Any]:
    _require(path.is_file(), f"{label} is missing.")
    _require(path.stat().st_size <= 16 * 1024 * 1024, f"{label} exceeds the verifier limit.")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise VerificationError(f"{label} is not valid UTF-8 JSON.") from error
    _require(isinstance(value, dict), f"{label} root must be an object.")
    return value


def _verify_inventory(sbom_path: Path, licenses_path: Path, version: str, build_number: int) -> dict[str, int]:
    sbom = _load_json(sbom_path, "SBOM")
    _require(sbom.get("bomFormat") == "CycloneDX", "SBOM format is not CycloneDX.")
    _require(sbom.get("specVersion") == "1.5", "SBOM spec version is not 1.5.")
    root = sbom.get("metadata", {}).get("component", {})
    _require(root.get("name") == "harbor_app", "SBOM root component mismatch.")
    _require(root.get("version") == f"{version}+{build_number}", "SBOM release identity mismatch.")
    components = sbom.get("components")
    _require(isinstance(components, list), "SBOM components are missing.")

    licenses = _load_json(licenses_path, "License inventory")
    _require(licenses.get("schemaVersion") == 1, "License inventory schema mismatch.")
    _require(licenses.get("rootComponent") == "harbor_app", "License inventory root mismatch.")
    license_components = licenses.get("components")
    summary = licenses.get("summary", {})
    _require(isinstance(license_components, list), "License inventory components are missing.")
    _require(summary.get("componentCount") == len(license_components), "License inventory component count mismatch.")
    _require(summary.get("runtimeComponentCount") == len(components), "SBOM/license runtime count mismatch.")
    limitations = licenses.get("limitations")
    _require(isinstance(limitations, list) and limitations, "License limitations are missing.")
    return {"sbomComponents": len(components), "licenseComponents": len(license_components)}


def _verify_attestation_subject(path: Path, expected_name: str, expected_digest: str, predicate_type: str) -> None:
    bundle = _load_json(path, "Sigstore bundle")
    envelope = bundle.get("dsseEnvelope")
    _require(isinstance(envelope, dict), "Sigstore DSSE envelope is missing.")
    signatures = envelope.get("signatures")
    _require(isinstance(signatures, list) and signatures, "Sigstore signature is missing.")
    try:
        statement = json.loads(base64.b64decode(envelope["payload"], validate=True))
    except (KeyError, ValueError, json.JSONDecodeError) as error:
        raise VerificationError("Sigstore statement payload is invalid.") from error
    _require(statement.get("predicateType") == predicate_type, "Sigstore predicate type mismatch.")
    subjects = statement.get("subject")
    _require(isinstance(subjects, list), "Sigstore subjects are missing.")
    matches = [
        item
        for item in subjects
        if item.get("name") == expected_name
        and item.get("digest", {}).get("sha256") == expected_digest
    ]
    _require(len(matches) == 1, "Sigstore subject does not bind the governed web artifact.")
    _require(isinstance(bundle.get("verificationMaterial"), dict), "Sigstore verification material is missing.")


def _verify_online_attestation(
    web_zip: Path,
    repository: str,
    signer_workflow: str,
    source_ref: str,
    source_commit: str,
) -> None:
    gh = shutil.which("gh")
    _require(gh is not None, "GitHub CLI is required for cryptographic attestation verification.")
    for predicate_type in (
        "https://slsa.dev/provenance/v1",
        "https://cyclonedx.org/bom",
    ):
        result = subprocess.run(
            [
                gh,
                "attestation",
                "verify",
                str(web_zip),
                "--repo",
                repository,
                "--signer-workflow",
                signer_workflow,
                "--source-ref",
                source_ref,
                "--source-digest",
                source_commit,
                "--predicate-type",
                predicate_type,
            ],
            check=False,
            capture_output=True,
            text=True,
            timeout=120,
        )
        _require(
            result.returncode == 0,
            f"GitHub rejected the {predicate_type} web artifact attestation.",
        )


def verify_bundle(args: argparse.Namespace) -> dict[str, Any]:
    bundle_dir = args.bundle_dir.resolve()
    repo_dir = args.repo_dir.resolve()
    _require(bundle_dir.is_dir(), "Bundle directory does not exist.")
    _require(repo_dir.is_dir(), "Repository directory does not exist.")
    _require(re.fullmatch(r"[0-9a-f]{40}", args.source_commit) is not None, "Source commit must be a full lowercase Git SHA.")
    label = _release_label(args.release_version)
    prefix = f"Harbor-web-{label}"
    web_name = f"{prefix}.zip"
    source_name = f"Harbor-flutter-{label}-source.zip"
    sbom_name = f"{prefix}.cdx.json"
    licenses_name = f"Harbor-runtime-licenses-{label}.json"
    provenance_name = f"{prefix}-provenance.sigstore.json"
    sbom_bundle_name = f"{prefix}-sbom.sigstore.json"
    roadmap_name = f"Harbor-end-to-end-roadmap-{label}.md"
    notes_name = f"Harbor-{label}-RELEASE-NOTES.md"
    checksum_name = f"Harbor-{label}-SHA256.txt"
    governed = {
        web_name,
        source_name,
        sbom_name,
        licenses_name,
        provenance_name,
        sbom_bundle_name,
        roadmap_name,
        notes_name,
    }
    checksums = _verify_checksum_inventory(bundle_dir, checksum_name, governed)
    web_summary = _verify_web_zip(bundle_dir / web_name, args.release_version, args.build_number)
    source_blobs = _verify_source_zip(bundle_dir / source_name, repo_dir, args.source_commit)
    inventory = _verify_inventory(
        bundle_dir / sbom_name,
        bundle_dir / licenses_name,
        args.release_version,
        args.build_number,
    )
    expected_subject = f"harbor-web-{args.source_commit}"
    web_digest = checksums[web_name]
    _verify_attestation_subject(
        bundle_dir / provenance_name,
        expected_subject,
        web_digest,
        "https://slsa.dev/provenance/v1",
    )
    _verify_attestation_subject(
        bundle_dir / sbom_bundle_name,
        expected_subject,
        web_digest,
        "https://cyclonedx.org/bom",
    )

    notes = (bundle_dir / notes_name).read_text(encoding="utf-8")
    _require(args.source_commit in notes, "Release notes do not name the source commit.")
    _require(args.release_version in notes, "Release notes do not name the release version.")
    _require("not a clinically approved" in notes.lower(), "Release notes lack the clinical boundary.")
    roadmap = (bundle_dir / roadmap_name).read_text(encoding="utf-8")
    _require("## 8. Definition of complete" in roadmap, "Roadmap snapshot lacks the completion contract.")

    if args.verify_attestation:
        _verify_online_attestation(
            bundle_dir / web_name,
            args.repository,
            args.signer_workflow,
            args.source_ref,
            args.source_commit,
        )

    return {
        "status": "passed",
        "drill": "known-good-release-anchor",
        "releaseVersion": args.release_version,
        "buildNumber": args.build_number,
        "sourceCommit": args.source_commit,
        "governedAssets": len(governed) + 1,
        "webZipSha256": web_digest,
        "webFiles": web_summary["files"],
        "releaseManifestAssets": web_summary["manifestAssets"],
        "precacheAssets": web_summary["precacheAssets"],
        "sourceBlobs": source_blobs,
        **inventory,
        "attestation": "cryptographically-verified" if args.verify_attestation else "subject-structure-verified",
        "personalContentRead": False,
        "rollbackMethod": "forward-corrective-release-only",
    }


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle-dir", type=Path, required=True)
    parser.add_argument("--repo-dir", type=Path, required=True)
    parser.add_argument("--release-version", required=True)
    parser.add_argument("--build-number", type=int, required=True)
    parser.add_argument("--source-commit", required=True)
    parser.add_argument("--repository", default="seemorecodez/harbor-postpartum-support")
    parser.add_argument(
        "--signer-workflow",
        default="seemorecodez/harbor-postpartum-support/.github/workflows/ci.yml",
    )
    parser.add_argument("--source-ref", default="refs/heads/main")
    parser.add_argument("--verify-attestation", action="store_true")
    parser.add_argument("--json-output", type=Path)
    return parser


def main() -> int:
    args = _parser().parse_args()
    try:
        report = verify_bundle(args)
    except VerificationError as error:
        print(json.dumps({"status": "failed", "error": str(error)}, sort_keys=True))
        return 1
    encoded = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.json_output:
        args.json_output.write_text(encoded, encoding="utf-8", newline="\n")
    print(encoded, end="")
    return 0


if __name__ == "__main__":
    sys.exit(main())
