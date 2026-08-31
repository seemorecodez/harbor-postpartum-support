# Harbor architecture proof report

**Date:** August 30, 2026

**Scope:** Web/PWA release-mode vertical slice and Windows encrypted-storage library proof
**Overall result:** Conditional pass for continued implementation; five-platform proof remains incomplete

## Host and toolchain

| Item | Result |
|---|---|
| Flutter | 3.47.2 stable, revision `d3b14c8769` |
| Dart | 3.13.2 |
| Windows compiler | Visual Studio Build Tools 2022 17.14.33 and Windows SDK 10.0.26100.0 detected |
| Android | SDK missing on this host |
| Apple | iOS/macOS build and runtime proof require a Mac/Xcode host |
| Windows packaging prerequisite | Developer Mode remains required for Flutter plugin symlinks |

## Implemented shared product slice

- Three-step privacy, postpartum-stage, and emergency-boundary onboarding with explicit acknowledgments
- Responsive phone/browser/desktop navigation
- Persistent urgent-support entry point
- Encrypted check-ins with history and deletion control
- Encrypted journal create/edit/search/delete
- Encrypted clinician-question add/toggle/delete
- Encrypted hard-day plan with deliberate call handoff
- Source-attributed educational draft library with explicit clinical-approval boundary
- Privacy center and erase-all control
- AES-256-GCM versioned vault with separate key-store adapter, tamper/wrong-key failure, and complete key/data erase
- No account, backend, analytics, ads, remote AI, third-party runtime asset, or personal-content request

## Automated verification

| Check | Result |
|---|---|
| `flutter analyze` | Pass, no issues |
| Vault plaintext absence and round trip | Pass |
| Copied record with wrong key | Rejected, pass |
| Vault record/key erase | Pass |
| Full data slice across controller restart | Pass |
| Privacy onboarding acknowledgment required | Pass |
| Total Flutter tests | 5/5 pass |
| Release WebAssembly/PWA compilation | Pass |

## Real-browser verification

1. The first build failed at runtime because Flutter attempted a renderer download from `gstatic.com`; Harbor's CSP blocked it. This failure was not waived.
2. The renderer and fallback fonts were bundled locally and the bootstrap was configured for same-origin assets.
3. The final clean-origin server log contained only `127.0.0.1:8770` requests and every request returned HTTP 200.
4. Browser error/warning log after load: empty.
5. Privacy and safety acknowledgments enabled entry into Harbor.
6. A synthetic check-in was encrypted, saved, displayed, and preserved across a browser reload.
7. After the HTTP server was stopped, a full page reload succeeded from the Harbor-owned offline cache with an empty browser error/warning log.

## What this report does not prove

- Public deployment, hosting log policy, production TLS/headers, multi-browser compatibility, or public availability
- Plaintext absence in the actual browser profile through forensic extraction; current proof combines behavioral browser persistence with adapter-level ciphertext tests
- Windows executable runtime, Android package/device behavior, or any iOS/macOS build
- Complete feature scope, clinical approval, accessibility conformance, independent penetration testing, performance targets, store policy, signatures, installers, or clean-device release readiness

No broader completion claim is permitted from this report.
