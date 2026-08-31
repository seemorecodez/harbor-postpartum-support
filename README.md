# Harbor

[![Verify Harbor](https://github.com/seemorecodez/harbor-postpartum-support/actions/workflows/ci.yml/badge.svg)](https://github.com/seemorecodez/harbor-postpartum-support/actions/workflows/ci.yml)

Harbor is a private, women-centered postpartum support application targeting web/PWA, Android, iOS, Windows, and macOS from shared Flutter source. The current version is engineering alpha 22, not a clinically approved release or a claim that all five native applications are finished.

## Implemented production slice

- Explicit privacy and safety onboarding.
- AES-256-GCM local vault with a separately stored secure key adapter.
- Optional local app lock with a passphrase-wrapped vault key, fail-closed unlock, attempt throttling, manual/reload lock boundaries, lifecycle hooks, and a separately confirmed no-recovery erase path. Web automatic locking depends on the browser reporting visibility or focus loss; native device credentials remain a release gate.
- Local check-ins, journal, clinician questions, hard-day plan, care-load tasks, and editable care-request drafts.
- Deterministic factual reflections with no diagnosis, cause inference, risk score, streak, or remote AI.
- Deliberate clipboard review for unanswered clinician questions and care requests.
- Searchable bundled postpartum body, mood, and baby guide with stage, severity, source metadata, urgent routing, and typed coverage for hemorrhage, preeclampsia, infection, psychosis, suicidality, newborn fever, breathing difficulty, poor feeding, and jaundice.
- Versioned offline web shell and a startup surface removed by Flutter's real first-frame event, with explicit pointer and Enter/Space retry activation after fatal loading failure.
- Full erase back to onboarding.
- Versioned encrypted-data migration with verified staging/commit, explicit future/corrupt-data lockout, Retry, and separately confirmed erasure.
- Responsive phone navigation, scalable brand/dropdown layouts, accessible control labels, platform-driven high contrast and reduced motion, and regression coverage for 200% text, contrast, target size, and keyboard activation.
- Offline editorial story drafts with explicit non-live/provenance labels, local search/topic filters, and encrypted private resonance stored through schema 3.
- An accessible About/content-version path that exposes the exact app, build, schema, guide, and Stories catalog identities together with their unapproved engineering-alpha status.
- A manual diagnostic preview containing only app version, build number, platform, data-schema version, and a bounded error code; nothing is copied until explicit confirmation.

There are no Harbor accounts, analytics, advertisements, tracking pixels, cloud synchronization, remote AI calls, or backend content APIs in this source. The anonymous message board is absent pending explicit approval of its network privacy boundary.

## Verified on this Windows host

- Flutter 3.47.2 / Dart 3.13.2 static analysis: clean.
- Ninety-one automated tests: all pass, including passphrase-wrapped key metadata/tamper/future-version rejection, wrong-passphrase and throttling behavior, enable/change/disable/erase flows, lock-during-save recovery, app-lock UI and 200% text, the nine-scenario clinical-safety matrix, schema migration, encrypted story resonance, bounded diagnostics, web privacy contracts, recovery interactions, phone/desktop responsiveness, platform high contrast and reduced motion, four governed real-UI golden comparisons, labels, contrast, target sizes, and keyboard activation.
- Release WebAssembly web build: passes.
- Clean-origin, warm-reload, server-stopped offline startup, and alpha.13-to-alpha.14 encrypted migration: visually exercised in a real browser.
- Alpha.15 browser accessibility inspection exercised onboarding and signed-in desktop/phone layouts, keyboard activation, the semantic tree, the full phone menu, and the dense care-plan screen with no runtime console errors.
- A real alpha.15-to-alpha.16 browser upgrade preserved an encrypted schema-2 journal, migrated to schema 3, loaded the seven-destination app on the first corrected update, saved encrypted story resonance, survived restart, and reloaded with the server stopped. The first attempt exposed and led to a fix for stale unversioned runtime reuse during service-worker cache installation.
- A production-style loopback traffic probe observed a compiled-browser synthetic journal save, reload, and confirmed deletion: save/delete added no requests, only same-origin asset GET/HEAD requests occurred, and the unique journal sentinel appeared in no request path, header, or body. This is narrow local evidence, not a public-host or signed-native privacy certification.
- The compiled alpha.17 Privacy → About path exposes every metadata label/value to browser semantics, retains direct urgent-support access and back navigation, and completed a clean-origin run with only same-origin HTTP 200 asset traffic.
- The compiled alpha.18 diagnostic path visibly displayed its exact five-field payload, cancelled without copying, added zero requests during preview/cancel, produced zero non-GET traffic or sentinel hits, and logged no browser warnings or errors.
- The exact compiled alpha.19 guide visibly exercised postpartum psychosis and infection searches, the corrected ACOG/NIMH/AAP draft boundary, NIMH source metadata, non-diagnostic emergency copy, and the 911/988 support dialog. Its fresh-origin pass used 24 same-origin GETs and a cached follow-up infection pass used 2; both had zero non-GETs, failed responses, sentinel hits, or browser warnings/errors.
- The compiled alpha.20 web path enabled app lock over an existing encrypted vault, hid private UI on manual lock and reload, rejected a wrong passphrase, restored the vault only after the correct passphrase, retained locked-screen urgent support, and kept the passphrase out of storage. A fresh-origin probe covering onboarding, encrypted synthetic journal save, lock setup, manual lock, wrong/correct unlock, and reload recorded 29 same-origin GETs, zero request bodies, failures, non-GETs, or sentinel hits, with an empty browser console. The tested embedded host did not expose tab visibility/focus changes, so automatic tab-switch locking is not claimed for that host.
- The exact compiled alpha.21 app applies a distinct WCAG-enhanced plum high-contrast theme when the platform requests high contrast and removes Harbor-owned onboarding, route, dialog, snackbar, and theme transition durations when the platform requests reduced motion. Four focused preference tests pass alongside the full 87-test suite. A compiled default-preference browser smoke verified the alpha.21 identity, urgent-support path, reload, and empty console; its probe recorded 27 same-origin GETs, zero request bodies, failures, non-GETs, or sentinel hits. Active preference behavior still requires real OS/browser and assistive-technology matrix evidence.
- Alpha.22 adds governed phone goldens for privacy onboarding, Today, high-contrast Today, and urgent support. Visual inspection rejected two preliminary sets that exposed placeholder font/icon rendering; the corrected harness then exposed and fixed production button-font fallback and insufficient custom-card high-contrast boundaries. Immutable comparison, all 91 tests, analysis, and release Wasm compilation pass. The exact compiled app visibly renders HarborSans controls, reports build 22, preserves urgent support, and has an empty console; its probe recorded 24 same-origin GETs with zero bodies, failures, non-GETs, or sentinel hits.
- [Public GitHub clean-checkout verification](https://github.com/seemorecodez/harbor-postpartum-support/actions/runs/33432724819) for alpha.22 on Ubuntu 24.04 repeats locked dependency resolution, formatting, static analysis, all 91 tests including strict Linux goldens, the release WebAssembly build, a post-build clean-tree check, and artifact preservation using immutable action revisions.
- The downloadable alpha.22 web ZIP matches all 49 files in that public CI artifact, and the source ZIP matches all 203 raw Git blobs at commit `29fca83`. Source packaging reads raw Git blobs to avoid platform newline normalization. Cross-OS binary reproducibility remains an explicit gap.

These checks do not prove clinical approval, independent security/accessibility review, public deployment, native compilation, signing, installation, store acceptance, or physical-device behavior.

## Common commands

```text
flutter pub get
flutter analyze
flutter test
flutter build web --release --wasm
```

Android requires the Android SDK and personal acceptance of its licenses. iOS and macOS builds require macOS with Xcode. Windows currently requires Developer Mode or an equivalent symlink-capable build environment for the selected dependencies.

## Project governance

- [End-to-end roadmap](docs/HARBOR_END_TO_END_ROADMAP.md)
- [Requirements traceability](docs/governance/REQUIREMENTS_TRACEABILITY.md)
- [Release gates and verification evidence](docs/governance/RELEASE_GATES.md)
- [Threat model](docs/governance/THREAT_MODEL.md)
- [Privacy boundary for the requested anonymous board](docs/governance/ANONYMOUS_MESSAGE_BOARD_OPTIONS.md)
- [Story provenance register](docs/governance/STORY_PROVENANCE_REGISTER.md)
- [Security reporting](SECURITY.md)
- [Contribution guide](CONTRIBUTING.md)

See `THIRD_PARTY_NOTICES.md` and the generated web build's `assets/NOTICES` before redistribution.

## License

The public source is available under the MIT License, copyright SeemoreCodez. Founder governance, contribution terms, optional contributor-upside terms, and trademark policy are documented separately in [README-LICENSING.md](README-LICENSING.md).
