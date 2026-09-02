# Harbor release, incident, correction, rollback, and sunset runbook

**Status:** Engineering-alpha operations control. It is executable and tested for the web recovery anchor, but it is not production approval. Named release, clinical, privacy, security, legal, accessibility, community-safety, and support owners remain required.

## Non-negotiable boundaries

- Never request, copy, upload, or attach a woman's journal, check-ins, questions, care-load items, story responses, app-lock material, browser profile, or local Harbor database to an incident record.
- Never add analytics, session replay, tracking pixels, remote diagnostics, device fingerprinting, or automatic crash submission to investigate an incident.
- Public operational evidence may contain only release identifiers, public artifact hashes, bounded error codes, synthetic test records, timestamps for Harbor-controlled actions, and responder decisions.
- Do not call a prior binary a safe rollback merely because it starts. A recovery candidate must pass the same privacy, clinical-content, migration, integrity, accessibility, and distribution gates required of a forward release.
- Never silently substitute an editorial story or local mock for the anonymous message board. The board remains absent until its separate remote-data and human-moderation boundary is approved.

## Roles and authority

Before a production launch, one named person must hold each role and an alternate must be recorded:

| Role | Authority |
|---|---|
| Release owner | Opens/closes incidents, freezes deployment, authorizes tested corrective releases, and records Go/No-Go |
| Clinical owner | Classifies health-content defects and approves corrected or withdrawn clinical copy with the required second reviewer |
| Privacy/security owner | Contains exposure, preserves non-personal evidence, rotates or revokes credentials, and approves restored boundaries |
| Accessibility owner | Verifies urgent support and corrected paths remain usable with the supported assistive-technology matrix |
| Support owner | Publishes approved plain-language status and routes emergency concerns to emergency services, never to Harbor monitoring |
| Legal/operator owner | Approves public notices, accountable contact details, retention statements, store declarations, and jurisdictional response |

Until those people are named, this runbook may support engineering drills only. It cannot authorize a clinical or store release.

## Severity and stop conditions

| Severity | Examples | Immediate action |
|---|---|---|
| Critical | Personal-content egress, compromised signing/deployment identity, incorrect emergency direction, destructive migration | Freeze deployment; preserve public build evidence; remove affected distribution when safe; convene release, clinical, and security owners |
| High | Material health-content error, inaccessible urgent control, corrupt update, broken erase/lock, hostile framing | Freeze promotion; identify last verified recovery anchor; prepare a forward corrective release |
| Moderate | Non-safety workflow regression, stale non-clinical copy, supported-browser offline failure | Stop the affected rollout; document scope; correct through the normal verified release path |
| Low | Cosmetic defect with no safety, privacy, accessibility, or data effect | Record and schedule; do not bypass release gates |

Any uncertainty about personal-content egress, emergency routing, data loss, or signing identity is treated as Critical until disproved with evidence that does not collect user content.

## Establishing the known-good recovery anchor

The recovery anchor is a durable public prerelease containing the exact attested CI web ZIP, exact source commit, checksums, SBOM, license inventory, Sigstore bundles, release notes, and roadmap snapshot. Run this from a clean checkout after downloading every asset from the GitHub release into one directory:

```text
python tool/release_recovery_drill.py --bundle-dir <download-directory> --repo-dir . --release-version 0.1.0-alpha.29 --build-number 29 --source-commit 75555a498fea9183578c0927a3cd0af56f5d61fd --verify-attestation --json-output <evidence-directory>/alpha29-recovery-anchor.json
```

Acceptance requires `status: passed`, the expected source commit and web digest, exact source-blob coverage, exact web-manifest coverage, structural SLSA/CycloneDX subjects, successful online cryptographic attestation verification, consistent SBOM/license counts, and `personalContentRead: false`. Any mismatch fails closed. A manually re-zipped build, local Windows web build, expired CI link, or unverified source archive is not the anchor.

## Content correction or withdrawal

1. Open an incident record containing a bounded issue ID, public release/version, affected governed content IDs, discovery time, and owners. Do not paste a user's personal account into the record.
2. A clinical concern is independently reviewed by the clinical owner and second qualified reviewer. If review cannot finish promptly, withdraw the affected entry rather than replacing it with reassurance or an unsourced claim.
3. Change the controlled source, its registry row, source/review/expiry metadata, catalog version, application build number, and service-worker cache identity together.
4. Run source-to-screen urgent-language tests, the nine-scenario safety matrix, accessibility checks, privacy tests, migration/data workloads, finalized root and deployment-subpath builds, dependency/license/OSV gates, and clean-tree verification.
5. Exercise a real browser that already holds the preceding release. Verify promotion timing, corrected content, urgent-support availability, encrypted local-data survival, zero content-bearing requests, and server-stopped offline reload.
6. Publish only the exact attested artifact that passed. Update the static privacy/content-version paths and public incident notice when applicable.
7. Record the commit, workflow run, artifact/checksum/attestation identities, browser evidence, reviewers, residual risks, and explicit release decision.

## Rollback is a forward corrective release

Harbor does not redeploy an old package under an old identity. A stale worker, older clinical copy, or older schema could otherwise silently replace a correction or strand encrypted local data.

1. Verify the durable known-good anchor with the command above.
2. Create a new commit from current `main` that restores only the reviewed known-good behavior while retaining every later compatible migration and privacy/security fix.
3. Assign a new monotonically increasing application version, build number, catalog versions where changed, and `CACHE_NAME`. Never reuse the affected cache identity.
4. Re-run every current release gate. The old run proves provenance of the reference only; it does not approve the new recovery artifact.
5. Exercise affected-release → recovery-release update, encrypted-data survival, wrong/future/corrupt vault lockout, corrected screen behavior, offline restart, and predecessor-cache fallback in supported browsers.
6. Deploy through the normal immutable CI/OSV/attestation path. Observe only synthetic public checks; do not instrument women using Harbor.
7. Publish the new artifact and incident resolution only after the named authorities record the decision.

If a compatible forward release cannot be produced, stop distribution and direct users to urgent/professional support outside Harbor. Do not advise clearing browser storage unless the woman has explicitly chosen to erase her local Harbor content.

## Signing, repository, or deployment credential compromise

1. Freeze releases and disable the affected credential or environment immediately through the platform owner.
2. Preserve public audit identifiers, workflow runs, release/tag/commit identities, attestations, and administrative actions. Never collect a Harbor vault as evidence.
3. Determine the earliest trustworthy commit and artifact independently; do not trust tags, releases, or Pages content controlled by the suspected credential.
4. Rotate credentials with least privilege and protected custody. Review branch protection, environments, pinned actions, collaborator access, Pages configuration, and recent public releases.
5. Remove or mark compromised artifacts and publish an operator-approved notice. A new key alone does not make old artifacts trustworthy.
6. Rebuild from a clean, reviewed commit; run dependency/license/OSV gates; create new provenance and SBOM attestations; independently verify them; then execute the clean-browser and installed-target matrices.
7. Record revocation, rotation, rebuilt artifact identities, independent review, communication, and Go/No-Go.

No production signing key exists yet, so this procedure remains unexecuted for native platforms.

## Outage and offline behavior

- Harbor's completed web release should remain available offline after one successful load. Confirm this with a server-stopped browser exercise, not a network throttle alone.
- Never tell a woman the host is private or unavailable without evidence. GitHub Pages and network intermediaries retain ordinary request metadata outside Harbor's control.
- During a host outage, keep emergency call/text guidance outside the application available in the public status message. Harbor is not an emergency-monitoring service.
- Recovery checks use fresh and previously controlled profiles. Record cache names, version identity, promotion timing, response status, subpath scope, console errors, and only synthetic request metadata.

## Sunset

1. Stop accepting new distribution only after operator, clinical, privacy/security, accessibility, and legal review.
2. Publish a dated plain-language notice explaining that Harbor does not hold personal content and cannot remotely export or erase a woman's local vault.
3. Preserve a verified self-hostable release, source, SBOM, license notices, checksums, attestations, and offline instructions for the approved retention period.
4. Keep deliberate local erase available. Do not remotely revoke an offline cache in a way that destroys access to local content.
5. Remove store listings and credentials through their owners; preserve required audit evidence without user content; publish the end of support and emergency alternatives.
6. Execute and record clean-profile, existing-profile, offline, export/erase (if approved), and native uninstall tests before calling sunset complete.

## Drill record and acceptance

Every drill records the bounded incident ID, scenario, start/end times, participants, exact commits/artifacts, commands, synthetic data, expected and observed results, failures, corrective actions, approvals, and next drill date. A drill passes only when the actual recovery artifact is verified, the real update/rollback behavior path succeeds, private content is never collected, urgent support remains available, and the evidence is independently reviewable.

The alpha.29 verifier establishes the durable web recovery anchor. Public content-correction deployment, credential revocation/rotation, supported-browser rollback timing, native signing compromise, native clean-device recovery, and sunset remain separate required drills.
