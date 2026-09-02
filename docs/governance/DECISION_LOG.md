# Harbor decision and assumption log

## Accepted decisions

### HBR-DEC-001 — Personal content is device-local

- **Decision:** Check-ins, journal entries, questions, plans, and preferences remain on the device where created.
- **Reason:** Explicit user privacy requirement.
- **Consequences:** No account, automatic sync, server moderation, remote AI, or remote recovery.
- **Verification:** Zero-network signed-build tests; encrypted local storage; declaration audit.
- **Revisit trigger:** Only an explicit user-approved scope change with a new privacy/security review.

### HBR-DEC-002 — Harbor is explicitly for adult women

- **Decision:** Product research, language, features, and acceptance are women-centered.
- **Reason:** Explicit audience requirement.
- **Consequences:** Recruit and compensate women with diverse postpartum experiences; do not claim research validation before it occurs.
- **Verification:** Research and lived-experience acceptance reports.

### HBR-DEC-003 — No simulated live community

- **Decision:** Until the separately governed board is approved and real, Stories are bundled editorial drafts, offline, provenance-labeled, and visibly awaiting review; there is no simulated activity or member posting.
- **Reason:** Live conversation requires remote data and moderation, conflicting with the device-local boundary.
- **Verification:** Runtime traffic audit, content provenance, UI wording review.

### HBR-DEC-004 — Desktop is a first-class product target

- **Decision:** Windows and macOS signed installers are required alongside iOS and Android.
- **Reason:** Explicit correction that Harbor must be downloadable on computers.
- **Consequences:** Mobile-only Expo implementation cannot define completion.
- **Verification:** Signed, clean-device-tested artifacts on all four platforms.

### HBR-DEC-009 — Web is a first-class, first-launch target

- **Decision:** Harbor launches as a production web application first while Android, iOS, Windows, and macOS continue simultaneously from the same governed product contract and shared Flutter codebase.
- **Reason:** Explicit user direction on August 30, 2026.
- **Consequences:** Web receives its own encrypted browser-storage adapter, accessibility/browser matrix, PWA/offline behavior, CSP, privacy disclosure, and deployment/rollback gate. The web build is not a throwaway preview and cannot replace installed-app completion.
- **Privacy boundary:** Harbor sends no personal content, uses no account, analytics, tracking, fingerprinting, remote AI, third-party runtime asset, or background content service. Initial/static asset requests necessarily reach the chosen host; this limitation must be disclosed and hosting logs minimized by policy/configuration.
- **Verification:** Production build, dependency and asset audit, browser network capture, Web Crypto/IndexedDB behavior tests, offline E2E, storage-loss/deletion tests, and three-browser accessibility pass.

### HBR-DEC-010 — One product contract, platform-specific privacy adapters

- **Decision:** Share domain models, content, design system, navigation, validation, and feature logic; isolate storage, key custody, lifecycle lock, sharing, and packaging behind platform adapters.
- **Reason:** Cross-platform consistency must not force weaker browser security assumptions onto installed applications.
- **Verification:** Contract tests run against each adapter; no platform-specific exception may reduce an accepted safety or data-flow requirement without an explicit decision entry.

### HBR-DEC-011 — Anonymous message board privacy boundary

- **Request:** Add an anonymous message board.
- **Status:** Pending explicit product-owner/user choice; implementation not authorized across the existing local-only boundary.
- **Conflict:** A real cross-user board requires intentional network transmission and remote message storage, while HBR-DEC-001 and the charter currently prohibit a backend and require content to stay local.
- **Recommended resolution:** Keep the private vault strictly local and add a separately consented, text-only, accountless, human-moderated community service with honest metadata limits. See `ANONYMOUS_MESSAGE_BOARD_OPTIONS.md`.
- **Rejected shortcut:** Fake member activity or bundled stories presented as live posts.
- **Decision needed:** Confirm whether deliberately published board posts may leave the device and be stored by the separately governed Harbor Community service.

### HBR-DEC-005 — Current React Native work is a prototype

- **Decision:** Preserve current source as requirements, interaction, tone, and content evidence; do not call it the complete app or release candidate.
- **Reason:** It lacks desktop applications, encrypted content storage, clinical approval, independent QA, signing, and physical-device evidence.
- **Verification:** Traceability status and release gates.

### HBR-DEC-006 — No feature exists until its real behavior passes

- **Decision:** Placeholder, mock, disabled, simulated, compilation-only, or undocumented behavior cannot be marketed or counted as complete.
- **Reason:** Explicit acceptance requirement.
- **Verification:** Claim-to-runtime-test mapping for every release feature.

### HBR-DEC-012 — Web startup state follows the real Flutter first frame

- **Decision:** Keep the startup surface in the document above Flutter's initial layer and remove it only when the runtime emits `flutter-first-frame`; expose an honest retry state on fatal loading failure.
- **Reason:** A timer or hidden overlay can claim progress while a woman still sees a blank or broken screen. The real runtime event preserves the acceptance boundary.
- **Verification:** Alpha.13 clean-origin, controlled fatal-load, pointer/Enter/Space recovery, and server-stopped offline browser observations plus three startup contract tests in the 20-test suite.
- **Remaining gate:** Define and pass a supported browser/device performance and assistive-technology matrix.

### HBR-DEC-013 — Unopenable local data is locked, never treated as empty

- **Decision:** Preserve the existing envelope, record key, encryption-key name, and authenticated-data value; migrate inner schema 1 to 2 through an encrypted staging write, decrypt-and-compare verification, primary commit, second verification, and staging deletion. A missing key, future version, authentication failure, corrupt document, or failed migration routes to a locked recovery screen and blocks all normal writes.
- **Reason:** Showing onboarding after a load failure can falsely imply that private records disappeared and can allow a new empty vault to overwrite recoverable ciphertext.
- **Recovery boundary:** Retry leaves the vault untouched. Erasure is available only through a separate, explicit, irreversible confirmation.
- **Verification:** Eleven vault tests, two controller recovery tests, two widget recovery tests, the 32-test regression suite, and the real alpha.13-to-alpha.14 browser upgrade/restart/erase/offline path.
- **Remaining gate:** Native/multi-browser interruption, storage-pressure, backup/restore, rollback, and independent forensic testing.
- **Alpha.16 extension:** The same locked, encrypted staging protocol now migrates both schema 1 and schema 2 into schema 3, whose only added field is the set of privately resonated story IDs. Focused fixtures and a real alpha.15→alpha.16 Chromium restart/offline path preserve earlier journal data.

### HBR-DEC-014 — Phone navigation must scale without hiding destinations

- **Decision:** Use the desktop navigation rail at widths of 920 pixels and above. Below that breakpoint, use a labeled menu button and a full-width, scrollable navigation drawer containing every destination and an explicit close control; keep urgent support visible in the phone header.
- **Reason:** The six-item Material bottom bar overflowed by 735 pixels at a 390×844 viewport with 200% text, and the stock fixed-width drawer still overflowed. Hiding labels, clipping destinations, or shrinking text would violate the accessibility and crisis-routing requirements.
- **Verification:** Alpha.15 regression tests cover all six destinations at 390×844/200% text plus names, target sizes, and contrast. Compiled Chromium keyboard and visual checks cover the desktop rail, phone header, complete menu, semantic selected state, and dense Plan screen.
- **Remaining gate:** Accessibility-user testing and VoiceOver, TalkBack, Narrator, macOS VoiceOver, browser zoom, high-contrast, reduced-motion, and physical touch-device matrices.

### HBR-DEC-015 — Each web release cache must fetch a fresh runtime snapshot

- **Decision:** During installation of a new versioned Harbor service-worker cache, fetch every release asset using cache-reload semantics and store the verified response explicitly. Do not use an unqualified bulk `cache.addAll` for unversioned Flutter runtime paths.
- **Reason:** A real alpha.15→alpha.16 same-origin test installed the alpha.16 shell but rendered the old six-destination alpha.15 runtime because the browser reused unversioned cached responses.
- **Verification:** A startup contract rejects `cache.addAll` and requires reload/fetch/response validation/cache-put behavior. After the fix, the same migration path rendered all seven alpha.16 destinations, preserved the schema-2 journal through schema 3, persisted encrypted story resonance across restart, and reloaded with the server stopped.
- **Remaining gate:** Multi-browser update/rollback, partial-response, hostile proxy, cache-corruption, quota-eviction, and public-deployment tests.

### HBR-DEC-016 — Release and content status must be visible in the product

- **Decision:** Harbor exposes the exact application/build, local-data schema, body-and-baby guide catalog, and Stories catalog identities in an accessible About path, together with their current review and release status.
- **Reason:** A hidden or documentation-only version cannot help a woman, reviewer, or support worker determine which offline content is actually on her device. Showing only a marketing version could also conceal that clinical, lived-experience, security, or five-platform approval is still missing.
- **Privacy boundary:** The About path reads compile-time public metadata only. It does not inspect, summarize, export, or count personal vault content and contains no remote URL or update check.
- **Verification:** Alpha.17 metadata-drift tests bind the in-app values to `pubspec.yaml`, bootstrap, service-worker, schema, and governed catalogs. Widget and 200%-text tests cover the Privacy → About route, private-value exclusion, semantics, and urgent support. A corrected compiled Chromium pass exposes every label/value and returns safely to Privacy.
- **Remaining gate:** Public CI, non-Chromium and native assistive-technology verification, independent wording review, and signed-target release evidence.

### HBR-DEC-017 — Diagnostics are manual, preview-first, and structurally bounded

- **Decision:** Harbor may generate only `applicationVersion`, `buildNumber`, `platform`, `dataSchemaVersion`, and a bounded `errorCode`. The complete payload must be visible before an explicit clipboard action. There is no automatic submission or remote support endpoint.
- **Reason:** The no-telemetry boundary makes support harder, but exporting logs, exception text, device identifiers, timestamps, record counts, OS versions, or vault-derived values would create a new surveillance and disclosure path.
- **Failure boundary:** Known vault failures map to fixed codes; every unknown exception becomes `vault_unavailable`. Raw exception text cannot enter either the visible or semantic payload.
- **Verification:** Alpha.18 has four allowlist/redaction tests, About and locked-recovery widget paths, cancel/copy clipboard assertions, 200%-text accessibility coverage, and a compiled Chromium preview/cancel run that showed the exact five fields while adding zero requests.
- **Remaining gate:** Public-host and multi-browser checks, installed-target platform/clipboard forensics, assistive-technology testing, support-process review, and independent privacy/security assessment.

### HBR-DEC-018 — Release safety scenarios are explicit catalog data

- **Decision:** Every roadmap-mandated maternal or newborn safety scenario must map to exactly one controlled guide entry through `GuideSafetyScenario`; keyword coincidence is not accepted as coverage.
- **Reason:** Free-text searches and broad emergency cards can appear to cover a condition while omitting its source, stage, severity, action, or UI route. Explicit tags make gaps and accidental duplication test failures.
- **Safety boundary:** Scenario tags support coverage and testing only. They do not diagnose, score risk, infer a condition from user data, or replace independent clinical judgment. The entries remain visibly labeled clinical drafts.
- **Verification:** Alpha.19 maps hemorrhage, preeclampsia, infection, psychosis, suicidality, newborn fever, breathing difficulty, poor feeding, and jaundice to 12 source-backed entries. Unit, registry, urgent-language, real-guide UI, 200%-text, release-identity, and compiled Chromium infection/psychosis/support-path checks pass.
- **Remaining gate:** Named obstetric, pediatric, perinatal mental-health, crisis, and compensated women-led lived-experience review; source expiry; public-host and five-platform assistive-technology verification.

### HBR-DEC-019 — Web app lock wraps the existing vault key and states its event boundary

- **Decision:** The web/shared fallback derives a key from a 12–128 character local passphrase using versioned PBKDF2-HMAC-SHA256 metadata at 600,000 iterations, then wraps the existing random vault key with AES-256-GCM. It stores neither the passphrase, a separate verifier, nor the raw vault key after enable. Native biometric or operating-system credentials remain a separate release requirement rather than being simulated by this fallback.
- **Reason:** Re-encrypting or recreating personal records during setup would increase data-loss risk, while persisting a verifier would add another offline guessing oracle. A web passphrase can improve closed/reloaded-vault protection but cannot honestly claim native hardware custody.
- **Lifecycle boundary:** Manual lock and reload are the guaranteed web boundaries. Harbor also locks when standard browser visibility/focus or Flutter lifecycle events are delivered, but product copy warns that an embedded host may withhold them. The tested in-app browser did withhold its own tab transition, so automatic tab-switch locking is not claimed there.
- **Verification:** Alpha.20 adds KDF/envelope, vault transaction, controller state/throttle, lock-during-save, widget-flow, privacy-contract, and 200%-text tests; analysis is clean and all 83 tests plus release Wasm compilation pass. A fresh-origin compiled path enabled lock over encrypted synthetic data, hid private UI on manual lock/reload, rejected the wrong phrase, restored only with the correct phrase, kept urgent support accessible, and produced 29 GET-only requests with no bodies, failures, non-GETs, or sentinel exposure.
- **Remaining gate:** Independent cryptographic/security review, multi-browser background-event testing, native hardware-backed device credentials, app-switcher/screenshot protection, physical-device fallback/lockout/accessibility testing, and public CI/package evidence.

### HBR-DEC-020 — Platform accessibility preferences are authoritative

- **Decision:** Harbor follows the platform's high-contrast and reduced-motion signals without creating a separate stored accessibility profile. High contrast selects a distinct women-centered plum theme with stronger contrast and boundaries. Reduced motion makes Harbor-owned onboarding, route, dialog, snackbar, and theme transitions immediate while preserving urgent support and navigation.
- **Reason:** Platform preferences are already user-controlled, minimize repeated setup, and avoid storing another potentially personal profile. Accessibility must change actual behavior, not only startup decoration.
- **Privacy boundary:** The preference is read from the local platform at runtime. Alpha.21 adds no identifier, storage field, dependency, permission, analytics event, or network path.
- **Verification:** Four focused preference tests validate palette ratios/boundaries, platform theme selection, direct route/dialog behavior, and immediate onboarding changes. Static analysis is clean, all 87 tests and release Wasm compilation pass, and the compiled default-preference smoke preserves urgent support, release identity, reload, empty console, and GET-only/no-body/no-sentinel traffic.
- **Remaining gate:** Active reduced-motion, high-contrast, forced-colors, browser zoom, touch, screen-reader, accessibility-user, and all-target device matrices plus independent accessibility review.

### HBR-DEC-021 — Golden references require human visual acceptance

- **Decision:** Harbor keeps deterministic core-phone golden references for privacy onboarding, Today, high-contrast Today, and urgent support. References use the actual app tree and bundled fonts at 390×844 with Harbor-owned motion disabled. Windows and Linux select separately reviewed canonical pixels because their Flutter engines rasterize glyphs differently; an unsupported OS fails closed. CI compares the selected references byte-for-byte but never updates them.
- **Reason:** Screenshot existence is not evidence of visual correctness. The first two generated sets contained placeholder glyphs and were rejected by direct inspection; the accepted set then exposed and drove fixes for production button typography and custom-panel high-contrast boundaries.
- **Update boundary:** A reference may change only with an intentional product change, direct inspection of every affected image, a written evidence update, immutable non-update comparison, full regression/build gates, and a reviewable commit. `--update-goldens` is forbidden in CI.
- **Privacy boundary:** References contain only fixed product copy and empty/local default state—no journal, check-in, diagnostic, identifier, device, or community data.
- **Remaining gate:** Add separately reviewed references before running on another test OS, expand only to high-risk screens, and obtain accessibility-user/design review. Goldens do not replace real browser, device, screen-reader, or clinical acceptance.

### HBR-DEC-022 — Clipboard and diagnostic disclosure is explicit and typed

- **Decision:** Harbor has one production clipboard sink. It accepts only a typed clinician-question, care-request, or bounded-diagnostic payload. The exact payload object must be shown before an affirmative copy action; canceling performs no write. Harbor has no application log sink or crash-reporting SDK.
- **Reason:** The product intentionally lets a woman carry selected words into a clinician conversation or care request, so an absolute promise that personal text can never enter clipboard history would be false. The safety requirement is no silent or incidental disclosure, exact review, and a narrow code boundary.
- **Privacy boundary:** Clipboard copies are deliberate exports. Once copied, the operating system, other applications, a recipient, or clipboard history may retain the text, and Harbor cannot revoke those copies. Private vault fields cannot be silently attached. Diagnostics remain limited to the five-field allowlist and collapse unknown exceptions to a bounded code.
- **Verification:** Alpha.23 centralizes all production `Clipboard.setData` access in one gateway; static tests fail on any second sink or application logging API, payload tests preserve exact preview/copy identity and reject empty payloads, and existing widget paths prove cancel/no-copy plus private-field exclusion.
- **Remaining gate:** Real Windows, macOS, Android, and iOS clipboard-history/residual-data forensics; browser and assistive-technology matrices; native crash/recents/thumbnail/backup inspection; and independent privacy/security assessment.

### HBR-DEC-023 — Web releases promote only verified staged caches

- **Decision:** A deployable Harbor web build must be finalized with a manifest that pins every non-worker release payload by SHA-256 and byte length. The service worker downloads core assets into a release-specific staging cache, verifies them before promotion, deletes failed partial state, serves fallback only from completed Harbor release caches, and retains prior completed releases for recovery. An unfinalized source-template worker fails installation closed.
- **Reason:** A failed `Promise.all` install can leave a partial named cache, and an HTTP 200 response can still contain truncated or corrupt bytes. Cache naming and `response.ok` alone cannot prove that a coherent release is available offline.
- **Trust boundary:** The pins detect accidental transport, storage, and partial-update corruption. The browser-installed worker is the manifest trust root and cannot hash itself; this is not a signature, so a compromised same-origin release host can replace both the worker and its manifest. Retaining old completed caches also consumes storage and needs a governed pruning policy.
- **Verification:** Alpha.24 finalizes and re-verifies 49 manifest entries—48 non-worker payload files plus the versioned bootstrap alias—with 9 core precache entries. Tests reject a truncated core asset and corrupt lazy Wasm, enforce staged promotion/fallback boundaries, and fail an unfinalized worker closed. A fresh-origin Chromium drill rejected four-byte alpha.24 Wasm, retained alpha.23 online/offline, then promoted valid alpha.24 and retained it offline. The three served phases recorded 73 GETs with no bodies, non-GETs, failures, or sentinel hits; the only warning was `harbor_offline_update_failed`.
- **Remaining gate:** Public-host, supported-browser, hostile-proxy/host, quota/eviction, cache-pruning, content-correction, and operational rollback exercises; signed provenance is still required to address release-origin compromise.

### HBR-DEC-024 — Native compiler output is an engineering proof, and Android data is excluded from backup and transfer

- **Decision:** Manual CI compiles the shared source on hosted Android, Windows, macOS, and iOS toolchains and preserves short-lived outputs named `engineering-proof`; these outputs are never described as installers or releases. Android production source disables backup and cleartext traffic, omits the INTERNET permission, and excludes all supported credential/device storage domains from both legacy cloud-backup and Android 12+ cloud/device-transfer rules.
- **Reason:** Native source folders and successful compilation are useful architecture evidence but do not establish signing, installation, launch, privacy, accessibility, upgrade, or store readiness. `allowBackup=false` alone does not express the complete Android 12+ device-transfer boundary.
- **Verification:** First public run `33447199764` compiled Windows, macOS, and no-codesign iOS and exposed a real Android API-37 mismatch plus a Windows verifier defect. Alpha.25 pins the smallest compatible AGP/API pair and adds four source-contract tests. Final run `33449252145` passes all Android, Windows, and Apple jobs, including compiled Android manifest, Windows product/signature, Apple product-name, clean-tree, and artifact checks.
- **Remaining gate:** Real signed/notarized packaging; clean-device install/launch/upgrade/uninstall; Android cloud-backup and device-transfer attempts; zero-egress, key-custody, deletion, screenshot/recents, accessibility, and physical-device evidence on every target.

### HBR-DEC-025 — GitHub Pages may host the public engineering alpha, not define the production privacy boundary

- **Decision:** Harbor's first public browser deployment uses a separately compiled, finalized GitHub Pages artifact under the repository subpath. Deployment is downstream of the complete clean-checkout gate, limited to pushes on `main`, uses immutable official action commits, and isolates `pages:write`/OIDC to the deploy job. The canonical root-host artifact remains independently built and preserved.
- **Reason:** A real public origin is required to test first-load, offline, update, header, and ordinary-request behavior. GitHub Pages supplies a reversible static-hosting path without adding Harbor accounts, application telemetry, a backend, cookies, or content APIs.
- **Privacy boundary:** GitHub and network intermediaries can observe ordinary IP/time/path request metadata. Harbor does not control or inspect the platform's underlying log retention. Pages also cannot be assumed to supply Harbor's desired response headers until the deployed responses and cross-origin framing behavior are measured.
- **Verification:** Alpha.26 public run `33451662643` passed its 108-test clean-checkout/build/deploy gate at `bc28a75`; the live HTTPS app exposed the correct subpath/version, rendered online and offline, and loaded no third-party application resources. Response inspection found HSTS but no CSP, X-Frame-Options, or nosniff header, and a separate-origin iframe loaded the complete alpha.26 app. Alpha.27 therefore adds a fail-closed pre-Flutter framing boundary; 109 tests, both finalized builds, top-level rendering, cross-origin frame refusal, and server-stopped restart pass locally.
- **Verification:** Public alpha.27 run `33554479209` passes at `cbde264`; live top-level rendering and the hostile-frame boundary pass after the prior alpha.26 worker promotes alpha.27. The first cached iframe navigation still exposed the completed alpha.26 UI before promotion, making convergence time a measured residual risk rather than an instant security-update claim.
- **Remaining gate:** Repeat live-origin offline/update timing across supported browsers; document hosting retention limits; establish monitoring/rollback; and move any production claim to a host that can enforce `frame-ancestors`, nosniff, and the accepted response-header policy.

### HBR-DEC-026 — Large-history evidence must exercise production vault, search, and widget paths

- **Decision:** Harbor's 1,000-record/20-migration roadmap workload uses the production `HarborVault`, model codecs, migration logic, journal-search helper, navigation shell, and Journal widget. It may use deterministic synthetic content and in-memory storage adapters inside Flutter's test engine, but it may not replace production algorithms with benchmark-only copies. Journal results render through a lazy sliver list, while cached feature destinations rebuild from explicit controller notifications rather than every navigation change.
- **Reason:** A fast standalone loop or domain-only search can conceal data loss, plaintext staging, eager construction of hundreds of cards, or stale UI after a save. The workload must validate exact persisted state and the real rendering behavior it is meant to improve.
- **Verification:** The first standalone-Dart attempt failed because the production vault legitimately depends on Flutter platform libraries; the same workload was then run intact in Flutter's engine. Alpha.28 exactly reloads 1,000 encrypted records, verifies 20 schema-1 migration/restart cycles (20,000 record instances), rejects plaintext sentinel exposure and staging residue, measures 25 searches, and drives the production Journal widget. An initial screen-cache optimization failed the existing care-task UI regression and was corrected with controller-bound cached screens. The final 112-test suite and both governed workloads pass; local root and Pages WebAssembly artifacts finalize and verify.
- **Remaining gate:** Repeat under release/profile instrumentation with plugin-backed storage on accepted physical baseline devices and supported browsers; measure cold launch, disk/quota/fault behavior, and signed-app navigation before changing G-09 or G-10 to pass.

### HBR-DEC-027 — The public privacy notice is a verified release asset, not an external runtime dependency

- **Decision:** Harbor carries the complete privacy notice inside the shared application and as a self-contained static `privacy.html`. The two surfaces must contain the same governed version, status, summary, section titles, and section bodies. The in-app screen performs no network navigation or vault read; it displays the public address as non-executable text. The static page has no scripts, forms, images, remote fonts, trackers, or subresource connections.
- **Reason:** App-store and public review need a stable URL, while a woman must be able to read the same disclosure without leaving Harbor or transmitting an entry. A link-only in-app implementation would add an avoidable network handoff, and an ungoverned duplicate could drift from measured behavior.
- **Release boundary:** `privacy.html` is SHA-256/length pinned with every other web payload and is a required precache entry. The worker gives that exact navigation its own verified cache key instead of treating it as the Flutter shell. Unknown application routes still fall back to `index.html`.
- **Verification:** Alpha.29 adds six tests covering exact cross-surface claims, a no-tracking/CSP contract, structural accessibility, exact worker routing, in-app vault exclusion, and 200%-text accessibility. The 132-test local gate, both 50-asset/10-precache WebAssembly finalizations, a real direct-page inspection, worker-controlled online navigation, and server-stopped reload pass with an empty browser warning/error log.
- **Remaining gate:** Deploy and re-exercise the exact public URL; obtain qualified privacy/legal review; select a host with accepted response headers and logging/retention; publish accountable contact/controller details if counsel requires them; and repeat on supported browsers and signed native packages. This engineering disclosure is not a legal approval or privacy certification.

## Decisions pending evidence

### HBR-DEC-007 — Production cross-platform framework

- **Proposal:** Flutter for web, Android, iOS, Windows, and macOS.
- **Status:** Experiment first.
- **Required evidence:** Five-platform build/deployment; encrypted local DB or browser store with key separation; accessibility; lifecycle lock where supported; responsive UI; zero-personal-content-egress tests.
- **Fallback:** React Native mobile plus separately owned native desktop clients.
- **Deadline:** Before production feature implementation.

### HBR-DEC-008 — Encrypted export/import

- **Proposal:** Optional, explicit, passphrase-encrypted file export/import with no sync.
- **Status:** Pending security threat model and user research.
- **Risk:** Weak passphrases, lost keys, exposed temporary files, user confusion about copies.
- **Default if unapproved:** Exclude from version 1.

## Assumptions requiring confirmation

| ID | Assumption | Impact if wrong | Status |
|---|---|---|---|
| HBR-ASM-001 | Initial release is U.S. English | Crisis and clinical content jurisdiction changes | Unverified |
| HBR-ASM-002 | Minimum audience age is 18 | Store rating, consent, and content controls change | Unverified |
| HBR-ASM-003 | Windows x64/ARM64 and current supported macOS are required | Build matrix and hardware cost change | Unverified |
| HBR-ASM-004 | No paid features are needed in version 1 | Store billing/legal scope changes | Unverified |
| HBR-ASM-005 | A small professional team will own the release | Timeline and governance change | Unverified |
