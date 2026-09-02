from __future__ import annotations

import argparse
import base64
import hashlib
import json
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path

from tool.release_recovery_drill import VerificationError, _safe_zip_entries, verify_bundle


VERSION = "0.1.0-alpha.29"
BUILD = 29


class ReleaseRecoveryDrillTest(unittest.TestCase):
    def _fixture(self, root: Path) -> argparse.Namespace:
        repo = root / "repo"
        bundle = root / "bundle"
        repo.mkdir()
        bundle.mkdir()
        subprocess.run(["git", "init", "-q", str(repo)], check=True)
        subprocess.run(["git", "-C", str(repo), "config", "user.name", "Harbor Test"], check=True)
        subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.invalid"], check=True)
        (repo / "README.md").write_bytes(b"Harbor recovery fixture\n")
        subprocess.run(["git", "-C", str(repo), "add", "README.md"], check=True)
        subprocess.run(["git", "-C", str(repo), "commit", "-q", "-m", "fixture"], check=True)
        commit = subprocess.check_output(["git", "-C", str(repo), "rev-parse", "HEAD"], text=True).strip()

        source_name = "Harbor-flutter-alpha29-source.zip"
        with zipfile.ZipFile(bundle / source_name, "w") as archive:
            archive.writestr("harbor-source/README.md", b"Harbor recovery fixture\n")

        payloads = {
            "index.html": b"<!doctype html><title>Harbor</title>",
            "main.dart.wasm": b"fixture-wasm",
            "privacy.html": b"<!doctype html><main>Legal review pending</main>",
            "version.json": json.dumps(
                {"version": VERSION, "build_number": str(BUILD)}, separators=(",", ":")
            ).encode(),
        }
        assets = []
        for name, payload in payloads.items():
            assets.append(
                {
                    "url": f"./{name}",
                    "sha256": hashlib.sha256(payload).hexdigest(),
                    "bytes": len(payload),
                    "precache": True,
                }
            )
        worker = (
            f'const CACHE_NAME = "harbor-shell-{VERSION}";\n'
            "/* HARBOR_RELEASE_ASSETS_START */\n"
            + json.dumps(assets, separators=(",", ":"))
            + "\n/* HARBOR_RELEASE_ASSETS_END */\n"
        ).encode()
        web_name = "Harbor-web-alpha29.zip"
        with zipfile.ZipFile(bundle / web_name, "w") as archive:
            for name, payload in payloads.items():
                archive.writestr(name, payload)
            archive.writestr("harbor_service_worker.js", worker)

        sbom_name = "Harbor-web-alpha29.cdx.json"
        (bundle / sbom_name).write_text(
            json.dumps(
                {
                    "bomFormat": "CycloneDX",
                    "specVersion": "1.5",
                    "metadata": {"component": {"name": "harbor_app", "version": f"{VERSION}+{BUILD}"}},
                    "components": [],
                }
            ),
            encoding="utf-8",
        )
        licenses_name = "Harbor-runtime-licenses-alpha29.json"
        (bundle / licenses_name).write_text(
            json.dumps(
                {
                    "schemaVersion": 1,
                    "rootComponent": "harbor_app",
                    "components": [{"name": "harbor_app"}],
                    "summary": {"componentCount": 1, "runtimeComponentCount": 0},
                    "limitations": ["Not legal approval."],
                }
            ),
            encoding="utf-8",
        )

        web_digest = hashlib.sha256((bundle / web_name).read_bytes()).hexdigest()
        subject = [{"name": f"harbor-web-{commit}", "digest": {"sha256": web_digest}}]
        for name, predicate in (
            ("Harbor-web-alpha29-provenance.sigstore.json", "https://slsa.dev/provenance/v1"),
            ("Harbor-web-alpha29-sbom.sigstore.json", "https://cyclonedx.org/bom"),
        ):
            statement = {"predicateType": predicate, "subject": subject}
            bundle_json = {
                "dsseEnvelope": {
                    "payload": base64.b64encode(json.dumps(statement).encode()).decode(),
                    "signatures": [{"sig": "fixture"}],
                },
                "verificationMaterial": {"fixture": True},
            }
            (bundle / name).write_text(json.dumps(bundle_json), encoding="utf-8")

        (bundle / "Harbor-end-to-end-roadmap-alpha29.md").write_text(
            "## 8. Definition of complete\n", encoding="utf-8"
        )
        (bundle / "Harbor-alpha29-RELEASE-NOTES.md").write_text(
            f"Harbor {VERSION} at {commit} is not a clinically approved release.\n",
            encoding="utf-8",
        )
        governed = sorted(path.name for path in bundle.iterdir())
        checksum_lines = [
            f"{hashlib.sha256((bundle / name).read_bytes()).hexdigest().upper()}  {name}"
            for name in governed
        ]
        (bundle / "Harbor-alpha29-SHA256.txt").write_text(
            "\n".join(checksum_lines) + "\n", encoding="utf-8", newline="\n"
        )
        return argparse.Namespace(
            bundle_dir=bundle,
            repo_dir=repo,
            release_version=VERSION,
            build_number=BUILD,
            source_commit=commit,
            repository="example/harbor",
            signer_workflow="example/harbor/.github/workflows/ci.yml",
            source_ref="refs/heads/main",
            verify_attestation=False,
        )

    def test_complete_known_good_fixture_passes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            report = verify_bundle(self._fixture(Path(directory)))
            self.assertEqual(report["status"], "passed")
            self.assertEqual(report["sourceBlobs"], 1)
            self.assertEqual(report["webFiles"], 5)
            self.assertFalse(report["personalContentRead"])

    def test_tampered_release_asset_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            args = self._fixture(Path(directory))
            notes = args.bundle_dir / "Harbor-alpha29-RELEASE-NOTES.md"
            notes.write_text(notes.read_text(encoding="utf-8") + "tampered\n", encoding="utf-8")
            with self.assertRaisesRegex(VerificationError, "Checksum mismatch"):
                verify_bundle(args)

    def test_zip_traversal_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "unsafe.zip"
            with zipfile.ZipFile(path, "w") as archive:
                archive.writestr("../private.txt", b"not allowed")
            with zipfile.ZipFile(path) as archive:
                with self.assertRaisesRegex(VerificationError, "traverses"):
                    _safe_zip_entries(archive)


if __name__ == "__main__":
    unittest.main()
