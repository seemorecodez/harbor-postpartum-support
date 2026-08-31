# Harbor

[![Verify Harbor](https://github.com/seemorecodez/harbor-postpartum-support/actions/workflows/ci.yml/badge.svg)](https://github.com/seemorecodez/harbor-postpartum-support/actions/workflows/ci.yml)

Harbor is a private, women-centered postpartum support application targeting web/PWA, Android, iOS, Windows, and macOS from shared Flutter source. The current version is engineering alpha 19, not a clinically approved release or a claim that all five native applications are finished.

## Implemented production slice

- Explicit privacy and safety onboarding.
- AES-256-GCM local vault with a separately stored secure key adapter.
- Local check-ins, journal, clinician questions, hard-day plan, care-load tasks, and editable care-request drafts.
- Deterministic factual reflections with no diagnosis, cause inference, risk score, streak, or remote AI.
- Deliberate clipboard review for unanswered clinician questions and care requests.
- Searchable bundled postpartum body, mood, and baby guide with stage, severity, source metadata, urgent routing, and typed coverage for hemorrhage, preeclampsia, infection, psychosis, suicidality, newborn fever, breathing difficulty, poor feeding, and jaundice.
- Versioned offline web shell and a startup surface removed by Flutter's real first-frame event, with explicit pointer and Enter/Space retry activation after fatal loading failure.
- Full erase back to onboarding.
- Versioned encrypted-data migration with verified staging/commit, explicit future/corrupt-data lockout, Retry, and separately confirmed erasure.
- Responsive phone navigation, scalable brand/dropdown layouts, accessible control labels, and regression coverage for 200% text, contrast, target size, and keyboard activation.
- Offline editorial story drafts with explicit non-live/provenance labels, local search/topic filters, and encrypted private resonance stored through schema 3.
- An accessible About/content-version path that exposes the exact app, build, schema, guide, and Stories catalog identities together with their unapproved engineering-alpha status.
- A manual diagnostic preview containing only app version, build number, platform, data-schema version, and a bounded error code; nothing is copied until explicit confirmation.

There are no Harbor accounts, analytics, advertisements, tracking pixels, cloud synchronization, remote AI calls, or backend content APIs in this source. The anonymous message board is absent pending explicit approval of its network privacy boundary.

## Verified on this Windows host

- Flutter 3.47.2 / Dart 3.13.2 static analysis: clean.
- Sixty-three automated tests: all pass, including the nine-scenario clinical-safety matrix, clinical-registry synchronization, urgent-language rules, real-guide search and support routing, schema-1/2-to-3 migration, encrypted story resonance, catalog and release-identity provenance, diagnostic allowlisting and error redaction, non-simulated-community rules, forced fresh runtime caching during release updates, legacy migration, interrupted-write recovery, future-version lockout, tamper rejection, missing-key protection, recovery-screen interactions, web privacy contracts, phone/desktop responsiveness, 200% text, labels, contrast, target sizes, and keyboard activation.
- Release WebAssembly web build: passes.
- Clean-origin, warm-reload, server-stopped offline startup, and alpha.13-to-alpha.14 encrypted migration: visually exercised in a real browser.
- Alpha.15 browser accessibility inspection exercised onboarding and signed-in desktop/phone layouts, keyboard activation, the semantic tree, the full phone menu, and the dense care-plan screen with no runtime console errors.
- A real alpha.15-to-alpha.16 browser upgrade preserved an encrypted schema-2 journal, migrated to schema 3, loaded the seven-destination app on the first corrected update, saved encrypted story resonance, survived restart, and reloaded with the server stopped. The first attempt exposed and led to a fix for stale unversioned runtime reuse during service-worker cache installation.
- A production-style loopback traffic probe observed a compiled-browser synthetic journal save, reload, and confirmed deletion: save/delete added no requests, only same-origin asset GET/HEAD requests occurred, and the unique journal sentinel appeared in no request path, header, or body. This is narrow local evidence, not a public-host or signed-native privacy certification.
- The compiled alpha.17 Privacy → About path exposes every metadata label/value to browser semantics, retains direct urgent-support access and back navigation, and completed a clean-origin run with only same-origin HTTP 200 asset traffic.
- The compiled alpha.18 diagnostic path visibly displayed its exact five-field payload, cancelled without copying, added zero requests during preview/cancel, produced zero non-GET traffic or sentinel hits, and logged no browser warnings or errors.
- The exact compiled alpha.19 guide visibly exercised postpartum psychosis and infection searches, the corrected ACOG/NIMH/AAP draft boundary, NIMH source metadata, non-diagnostic emergency copy, and the 911/988 support dialog. Its fresh-origin pass used 24 same-origin GETs and a cached follow-up infection pass used 2; both had zero non-GETs, failed responses, sentinel hits, or browser warnings/errors.
- [Public GitHub clean-checkout verification](https://github.com/seemorecodez/harbor-postpartum-support/actions/runs/33412177333) for alpha.18 on Ubuntu 24.04 repeats locked dependency resolution, formatting, static analysis, all 57 then-current tests, the release WebAssembly build, a post-build clean-tree check, and artifact preservation using immutable action revisions. Alpha.19 public CI is pending this commit.
- The downloadable alpha.18 web ZIP matches all 49 files in that public CI artifact, and the source ZIP matches all 184 raw Git blobs at commit `26761f5`. A first Windows `git archive` candidate was rejected because text normalization changed 55 blobs; it is not distributed. Cross-OS binary reproducibility remains an explicit gap.

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
