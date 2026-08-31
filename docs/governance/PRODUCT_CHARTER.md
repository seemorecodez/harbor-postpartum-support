# Harbor product charter

**Authority:** `HARBOR_END_TO_END_ROADMAP.md`

**Lifecycle state:** Pre-production architecture and evidence phase

**Release claim currently permitted:** Prototype source only

## Outcome

Build, verify, and distribute Harbor as a women-centered postpartum support application for the web, Android, iOS, Windows, and macOS. The web application launches first, while all five targets are developed from one governed product specification and shared Flutter codebase. The product must function locally on each device or browser profile, provide only intended and clinically governed behavior, and never substitute mocked, disabled, placeholder, or compilation-only work for a functioning feature.

## Non-negotiable requirements

1. Personal content stays on the device or browser profile where it is created and is never transmitted by Harbor.
2. No account, backend, cloud sync, analytics, advertising, fingerprinting, remote AI, engagement tracking, or silent network request.
3. Every advertised feature is implemented, testable, documented, and verified in the real target-platform path.
4. Harbor is designed explicitly for adult women in the postpartum year.
5. Health content is educational orientation, never diagnosis, treatment, monitoring, or emergency response.
6. Medical and crisis content requires named clinical ownership, source provenance, approval, review date, and expiry date.
7. Personal content is encrypted locally in production and protected by platform-appropriate device security.
8. Accessibility is a release requirement on every platform.
9. A source tree, passing compiler, screenshot, simulator-only demo, unsigned binary, or store submission is not a release.
10. Installed-app completion requires signed installers that pass clean-device install, upgrade, use, deletion, rollback, and uninstall tests. Web completion requires a production deployment that passes first-load, offline-reload, update, storage-loss, deletion, browser-compatibility, content-security-policy, and zero-content-egress tests.
11. The web build must disclose that first load contacts a static host, that the hosting provider may process ordinary request metadata, and that clearing browser/site data removes Harbor records. It must never imply the stronger durability or OS-keystore guarantees of an installed app.

## Release platforms and artifacts

| Platform | Required release artifact | Required verification |
|---|---|---|
| Web | Versioned static PWA bundle with pinned hashes and rollback artifact | Chromium, Firefox, and Safari; first load; offline reload; installability where supported; storage loss; deletion; CSP; no third-party resources; zero personal-content egress |
| Android | Signed AAB for Play plus approved signed APK if direct distribution is supported | Physical Android matrix, install/upgrade/uninstall, permissions, offline traffic audit |
| iOS | Signed App Store/TestFlight archive | Physical iPhone matrix, install/upgrade/uninstall, privacy manifest, offline traffic audit |
| Windows | Signed MSIX for x64 and ARM64 where supported | Clean Windows machines, signing, install/upgrade/uninstall, keyboard/Narrator, offline traffic audit |
| macOS | Developer ID–signed and notarized app in DMG/PKG | Clean Intel/Apple Silicon matrix as supported, Gatekeeper, install/upgrade/uninstall, VoiceOver, offline traffic audit |

## Authority and approval

The following named owners are required before public release. They are deliberately not invented in this charter.

| Authority | Named owner | Status |
|---|---|---|
| Product scope and final Go/No-Go | Not assigned | Missing |
| Technical architecture | Codex working implementation; human owner not assigned | Missing human owner |
| Clinical content | Not assigned | Missing |
| Privacy and regulatory approval | Not assigned | Missing |
| Security approval | Not assigned | Missing |
| Accessibility approval | Not assigned | Missing |
| Signing keys and store accounts | Not assigned | Missing |

Codex may implement, test, and document technical work. Codex cannot replace lived-experience approval, licensed clinical judgment, legal advice, independent security review, platform accounts, signing credentials, or physical Apple hardware.

## Change control

- Every scope or architecture change receives a decision-log entry.
- Every requirement change updates the traceability matrix and affected tests.
- Every clinical content change records source, author, reviewer, date, jurisdiction, and reason.
- Privacy-reducing changes require explicit product-owner, privacy, and security approval.
- A feature that fails an acceptance gate remains incomplete and cannot appear in release marketing.

## Stop-release conditions

- Unexpected network request or undeclared data flow
- Web request containing personal content, third-party executable resource, analytics identifier, or fingerprinting signal introduced by Harbor
- Unencrypted personal-content database
- Data loss or migration corruption
- Lock bypass or personal content exposed in logs, crash files, screenshots, recent-items lists, or clipboard history
- Incorrect or expired emergency information
- Diagnostic or treatment claim without regulatory and clinical approval
- Critical/high security, safety, privacy, or accessibility defect
- Missing signature, invalid notarization, or unverified clean-device installer
