# Harbor threat model

**Version:** 0.1 engineering alpha

**Updated:** 2026-08-31

**Scope:** Harbor alpha 24 private vault, passphrase-wrapped local app lock, typed reviewed clipboard boundary, bounded diagnostics, and integrity-pinned offline web/PWA update boundary. This is an engineering threat model, not an independent security assessment or security guarantee.

## System boundary

Harbor has no account, application backend, analytics service, remote AI, advertising SDK, content API, or cloud synchronization. Personal content is created in the Flutter application, encrypted with AES-256-GCM, and stored in the current browser profile or installed application. The encrypted record and encryption key use separate storage adapters, but both remain on the same device.

The web build crosses the network only to retrieve Harbor's static application files from its chosen host and to refresh its same-origin offline cache. Alpha.24 pins each non-worker release payload by SHA-256 and byte length, verifies core files in an isolated staging cache, promotes only a complete release, and limits fallback to completed Harbor caches. The browser-installed service worker is the manifest trust root and cannot contain a digest of itself. These embedded hashes detect accidental transport, storage, and partial-update corruption; because the worker and its hash manifest arrive from the same host, they do not make a compromised same-origin release trustworthy. Alpha.20 can wrap the existing vault key with a passphrase-derived key and destroy the usable in-memory key on a guaranteed manual/reload boundary; it also requests automatic locking when the browser or platform reports visibility, focus, or lifecycle loss. Explicit call, text, and clipboard actions cross into operating-system-controlled surfaces only after a woman activates them. A future multi-user board is outside this model and remains prohibited until its separate network boundary is explicitly approved.

## Protected assets

| Asset | Required property |
|---|---|
| Journal entries, check-ins, questions, plans, care tasks, drafts, and private story responses | Confidentiality, integrity, local-only retention, deliberate erasure |
| Vault encryption key | Confidentiality, separation from the encrypted record, no logging or export |
| App-lock passphrase and wrapped-key metadata | Passphrase never persisted or logged; authenticated, versioned wrapping; fail-closed unlock; bounded guessing cost |
| Encrypted vault and migration staging record | Authentication, version integrity, fail-closed recovery, no silent replacement |
| Clinical, crisis, and provenance content | Source integrity, freshness, review evidence, safe correction |
| Woman's safety and agency | No delayed-care implication, coercive sharing, hidden publication, or simulated community |
| Release source, dependencies, service worker, and build artifacts | Reviewability, reproducibility, provenance, resistance to unauthorized modification |

## Trust boundaries and data flows

| Boundary | Data crossing | Current control | Residual limitation |
|---|---|---|---|
| Static host → browser | HTML, JavaScript, Wasm, fonts, icons, manifest | Same-origin runtime assets, restrictive meta CSP, no third-party runtime URL, finalized SHA-256/length manifest, staging-cache verification, completed-release promotion and rollback fallback | The manifest and worker share the host's trust boundary and cannot detect a malicious release from that host; request metadata, deployment headers, public-host verification, cache pruning, and multi-browser behavior remain |
| Flutter UI → local vault | Personal content | AES-256-GCM envelope, authenticated data, write/read/decrypt verification | A compromised same-origin runtime or unlocked device can access the live key and plaintext |
| Encrypted record store ↔ key store | Ciphertext and separate key | Separate adapter keys, missing-key lockout, authenticated decryption | Browser storage is not equivalent to hardware-backed native key custody |
| Passphrase entry → wrapped vault key | Passphrase in memory and versioned KDF/AEAD metadata | PBKDF2-HMAC-SHA256 with a random salt and 600,000 iterations; AES-256-GCM wrapping; no passphrase/verifier/raw key persisted after enable; failed unlock delay | A weak passphrase can be guessed offline from copied metadata; JavaScript/Wasm memory and an unlocked runtime are not hardware-isolated |
| Browser/OS lifecycle → app lock | Visibility, focus, or lifecycle event only | Web visibility/focus listener, Flutter lifecycle observer, immediate UI replacement and in-memory data/key destruction | Some embedded browsers may withhold transitions; manual lock and reload are the only guaranteed web boundaries currently claimed |
| Current schema → new schema | Decrypted in-memory model and encrypted staging | Deterministic migrations, double verification, locked recovery | Storage pressure, process-kill, rollback, and multi-platform matrices remain |
| Harbor → clipboard | User-previewed clinician questions, care request, or five-field diagnostic payload | One typed production sink; the exact payload object is previewed before explicit confirmation; diagnostics are generated from a five-field allowlist and bounded error taxonomy | Other apps and clipboard history may retain deliberately copied text; installed-target clipboard forensics remain |
| Harbor → phone/SMS handler | Phone number or crisis short code | Explicit button activation; only `tel:` and `sms:` schemes | OS, carrier, and recipient receive metadata/content outside Harbor's control |
| Harbor → future community | None in current product | No board client, service, account, post, or simulated activity | A real board requires a separate approved threat model and moderation operation |

## Actors and capabilities

- A person with access to an unlocked device or browser profile.
- Malicious or compromised same-origin hosting, dependency, build action, browser extension, or application update.
- A network or hosting operator able to observe static-request metadata.
- Another local application able to inspect clipboard, backups, screenshots, recents, or accessible files.
- An attacker able to corrupt or replace local storage but not necessarily recover the key.
- A future abusive community participant or moderator; currently outside the implemented boundary.

## Prioritized abuse cases

| ID | Scenario and precondition | Impact | Current prevention/evidence | Residual risk and next test |
|---|---|---|---|---|
| TM-001 | Compromised script or dependency reads plaintext and transmits it | Critical disclosure | No general-purpose network client; same-origin runtime assets; CSP restricts connections; dependency lock; source/CI audits; one compiled-Chromium synthetic journal capture added zero requests and exposed zero sentinel values | A compromised same-origin host is still trusted by CSP. Require deployment integrity review, host hardening, dependency/SBOM audit, multi-browser capture, and signed-native personal-content captures |
| TM-002 | Host logs or network observers link a woman to Harbor use | High privacy harm | No personal-content request, referrer policy `no-referrer`, no analytics or third-party runtime host | Static request IP/time metadata remains observable. Minimize host logs, document retention, and verify public hosting configuration |
| TM-003 | Local attacker copies browser storage or native files | Critical disclosure | Encrypted envelope, plaintext-absence and wrong-key tests, separate storage adapters | Browser key and ciphertext remain within one profile; prove native key custody and perform browser/native forensics |
| TM-004 | Corruption, future schema, or missing key is treated as an empty vault | Critical data loss | Authenticated decryption, future-version rejection, locked recovery, separate confirmed erase, migration fixtures and real upgrade tests | Add process-kill, disk-full/quota, backup/restore, and rollback matrices |
| TM-005 | Sensitive content leaks through clipboard, logging, crash text, or an external handoff | High disclosure | One typed clipboard sink; exact-payload preview and confirmation; diagnostic output is restricted to version/build/platform/schema/error code and unknown exception text collapses to `vault_unavailable`; no application log sink or crash SDK; explicit call/text buttons; no automatic handoff | Test installed targets, clipboard histories, OS crash files, recents, thumbnails, and residual storage; Harbor cannot erase deliberate copies held by the OS or recipient |
| TM-006 | Clearing site data, backup policy, or profile eviction destroys records | High availability loss | Pre-entry browser-loss disclosure and confirmed erasure path | No approved encrypted export/import; add storage-pressure and backup/restore evidence before durability claims |
| TM-007 | A stale or partial service-worker update retains or mixes corrected clinical/privacy code | Critical integrity harm | Alpha.24 finalizer pins every non-worker release payload by SHA-256 and byte length; the worker verifies a staging cache before promotion, deletes failed staging/final caches, excludes staging caches from fallback, and retains completed prior releases. Deterministic truncated-precache/corrupt-lazy-Wasm tests and a real alpha.23→corrupt-alpha.24 rejection→offline-alpha.23→valid-alpha.24→offline-alpha.24 Chromium drill pass | The browser-installed worker is the manifest trust root; embedded hashes do not protect against a malicious same-origin release because its worker supplies the hashes. Add hostile-proxy/host, quota, cache-pruning, public-deployment, and multi-browser tests |
| TM-008 | Another site frames Harbor and tricks a woman into activating controls | High privacy/safety harm | `frame-src 'none'` blocks Harbor-created frames; the local probe served and verified HTTP `frame-ancestors 'none'` plus `X-Frame-Options: DENY` | Browsers ignore `frame-ancestors` in a meta policy. Public-host header verification and a cross-origin clickjacking test remain mandatory |
| TM-009 | Build or action dependency is replaced | Critical supply-chain compromise | Locked Dart dependencies; GitHub actions pinned to immutable commits; public clean-checkout CI | No SBOM, signed provenance, dependency review cadence, or artifact signature yet |
| TM-010 | Storage quota, offline cache damage, or resource exhaustion prevents access | High denial of service | Visible startup state, bounded retry, completed-prior-cache fallback, locked data recovery, deterministic corrupt/truncated asset rejection, and a real server-stopped recovery drill | Quota exhaustion/eviction and process pressure are not simulated; retained completed caches have no pruning policy. Define thresholds and execute quota, eviction, cache-pruning, and browser/device matrices |
| TM-011 | A fake or unsafe “anonymous” board exposes identity or misinformation | Critical privacy/safety harm | No implemented board and no simulated member activity | Explicit remote-publishing approval, metadata limits, human moderation, retention, report/block, legal, clinical, and security gates are required before code |
| TM-012 | An attacker guesses the app-lock passphrase offline or a browser withholds a background event | High disclosure | Versioned PBKDF2-HMAC-SHA256 at 600,000 iterations, random salt, authenticated key wrapping, no separate verifier, in-memory online retry delays, guaranteed manual/reload lock, and honest web-limit copy | Offline guessing is not throttled; an unlocked page stays open when a host withholds visibility/focus signals. Require strong user-chosen phrases, multi-browser tests, native hardware-backed credentials, app-switcher/screenshot controls, and independent review |

## Security requirements and negative tests

| Requirement | Evidence now | Required remaining evidence |
|---|---|---|
| No personal content is sent by Harbor | No backend/network dependency, five web privacy-contract tests, and an instrumented compiled-Chromium save/reload/delete capture with zero personal-content requests | Repeat on supported browsers, public hosting, and signed native builds |
| Runtime assets do not depend on third-party hosts | Bundled fonts/assets, local HTML attributes, CSP/source contract | Public-host network capture and dependency/SBOM review |
| Unopenable data fails closed | Vault/controller/widget tests and locked recovery UI | Native interruption and forensic matrices |
| App lock does not replace or expose the vault key | Production KDF/envelope tests, wrong/tampered/future rejection, raw-key removal checks, enable/change/disable/erase and lock-during-save tests, real-browser manual/reload wrong/correct unlock path | Native device-credential custody, multi-browser background reporting, memory/recents/screenshot forensics, physical-device lockout and recovery testing |
| External sharing is deliberate | Typed single-sink clipboard contract, exact payload tests, three preview/cancel widget paths, diagnostic five-field allowlist/error-redaction tests, a compiled-browser zero-request diagnostic preview/cancel, and explicit `tel:`/`sms:` source contract | Physical-device clipboard, call, SMS, accessibility, and residual-data tests |
| Personal content does not enter application logs or crash telemetry | Static production-source rule rejects logging APIs; dependency rule rejects crash/analytics SDKs; diagnostics use bounded codes instead of exception text | Native OS/framework crash files, recents, thumbnails, installer residue, debug-build behavior, and independent forensic assessment |
| Web app cannot be embedded by another origin | Local production-style response verified `frame-ancestors 'none'` and `X-Frame-Options: DENY` | Repeat the header check and a cross-origin iframe test on the public host |
| Release changes remain reviewable | Clean public Git history and immutable-action CI | Protected branch/review policy, provenance, signatures, and incident drills |

## Explicit exclusions

This model does not claim protection from a fully compromised operating system, browser, device administrator, malicious accessibility service, screen camera, physical coercion, offline guessing of a weak passphrase, an embedded browser that withholds lifecycle/focus signals, or a woman deliberately exporting/copying information. It does not cover a community backend because none is authorized or implemented. It does not approve clinical content, public deployment, signed native applications, or store release.

## Review triggers

Re-run this model before adding any account, server, board, remote configuration, export/import, diagnostic bundle, biometric lock, notification, background task, new OS permission, new dependency capable of networking, hosting provider, signing system, or analytics/crash-reporting tool. Named security and privacy owners and an independent assessment remain release gates.
