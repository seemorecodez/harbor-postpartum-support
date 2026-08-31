# ADR-001: shared Flutter product with platform privacy adapters

**Date:** August 30, 2026
**Status:** Accept with conditions for continued production implementation; not a release approval

## Decision

Use Flutter as Harbor's shared product framework for web/PWA, Android, iOS, Windows, and macOS. Share domain models, feature logic, content structures, design tokens, navigation, and acceptance tests. Keep key custody, encrypted record storage, biometric/device lock, app-switcher protection, sharing, backup exclusion, and packaging behind platform-specific adapters where their guarantees differ.

The web/PWA is the first release train. This does not reduce or replace Android, iOS, Windows, or macOS acceptance.

## Evidence supporting this conditional acceptance

- Flutter 3.47.2 and Dart 3.13.2 run on the current Windows host.
- Flutter generated one source tree with web, Android, iOS, Windows, and macOS targets.
- The Windows sqlite3mc proof passes three behavioral encryption tests: raw plaintext absence, correct-key reopen, and wrong-key rejection.
- The production shared vault uses AES-256-GCM authenticated encryption, a versioned envelope, separately abstracted key storage, and fail-closed decryption.
- Static analysis of the current shared product slice reports no issues; five unit/controller/widget tests pass.
- A release-mode WebAssembly PWA bundle compiles and renders in the real in-app browser.
- An initial default renderer request to `gstatic.com` was detected and rejected. Harbor now explicitly loads bundled same-origin engine and font assets under a restrictive CSP.
- A clean browser-origin run produced only same-origin asset requests; every request returned HTTP 200 and browser error/warning logs were empty.
- With the local HTTP server stopped, the Harbor-owned service worker reloaded the application successfully with no browser errors or warnings.
- The real browser path completed privacy acknowledgment, safety acknowledgment, encrypted initialization, synthetic check-in save, and persistence across reload without errors.

## Conditions still required

1. Enable Windows Developer Mode and produce/run the Windows release executable with secure-storage plugins.
2. Install the Android SDK, compile an Android artifact, and run on a physical device or approved device lab.
3. Acquire a Mac with supported Xcode plus Apple signing access; compile and run iOS and macOS targets on physical/clean systems.
4. Replace conditional technical approval with independent security and accessibility review.
5. Prove OS key custody, app lifecycle lock, backup exclusion, forensic deletion, and zero-network behavior on every installed platform.
6. Run Chromium, Firefox, and Safari browser matrices, including assistive technology, quota/storage loss, PWA update, rollback, and clinical-content expiry.
7. Complete full release-scope features, clinical governance, lived-experience approval, legal review, signing, packaging, and clean-device distribution.

## Rejected alternatives

- Treat the React Native prototype as production: rejected because it lacks desktop targets, encrypted production storage, and release evidence.
- Wrap the web build as desktop/mobile applications: rejected because installed apps require native platform security and packaging behavior.
- Maintain unrelated web, mobile, and desktop implementations: rejected because duplicated clinical content and privacy logic create unacceptable drift risk.

## Reversal trigger

Reverse or split the architecture if any remaining platform cannot meet Harbor's accepted encryption, accessibility, lifecycle privacy, offline, packaging, or performance gates without weakening the requirement.
