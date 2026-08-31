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
