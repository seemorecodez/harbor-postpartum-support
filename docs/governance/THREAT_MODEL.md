# Harbor threat model

**Version:** 0.1 engineering alpha

**Updated:** 2026-08-31

**Scope:** Harbor alpha 16 private vault and offline web/PWA boundary. This is an engineering threat model, not an independent security assessment or security guarantee.

## System boundary

Harbor has no account, application backend, analytics service, remote AI, advertising SDK, content API, or cloud synchronization. Personal content is created in the Flutter application, encrypted with AES-256-GCM, and stored in the current browser profile or installed application. The encrypted record and encryption key use separate storage adapters, but both remain on the same device.

The web build crosses the network only to retrieve Harbor's static application files from its chosen host and to refresh its same-origin offline cache. Explicit call, text, and clipboard actions cross into operating-system-controlled surfaces only after a woman activates them. A future multi-user board is outside this model and remains prohibited until its separate network boundary is explicitly approved.

## Protected assets

| Asset | Required property |
|---|---|
| Journal entries, check-ins, questions, plans, care tasks, drafts, and private story responses | Confidentiality, integrity, local-only retention, deliberate erasure |
| Vault encryption key | Confidentiality, separation from the encrypted record, no logging or export |
| Encrypted vault and migration staging record | Authentication, version integrity, fail-closed recovery, no silent replacement |
| Clinical, crisis, and provenance content | Source integrity, freshness, review evidence, safe correction |
| Woman's safety and agency | No delayed-care implication, coercive sharing, hidden publication, or simulated community |
| Release source, dependencies, service worker, and build artifacts | Reviewability, reproducibility, provenance, resistance to unauthorized modification |

## Trust boundaries and data flows

| Boundary | Data crossing | Current control | Residual limitation |
|---|---|---|---|
| Static host → browser | HTML, JavaScript, Wasm, fonts, icons, manifest | Same-origin runtime assets, restrictive meta CSP, no third-party runtime URL, versioned service worker | Host and transport can observe request metadata; deployment headers and public-host verification remain |
| Flutter UI → local vault | Personal content | AES-256-GCM envelope, authenticated data, write/read/decrypt verification | A compromised same-origin runtime or unlocked device can access the live key and plaintext |
| Encrypted record store ↔ key store | Ciphertext and separate key | Separate adapter keys, missing-key lockout, authenticated decryption | Browser storage is not equivalent to hardware-backed native key custody |
| Current schema → new schema | Decrypted in-memory model and encrypted staging | Deterministic migrations, double verification, locked recovery | Storage pressure, process-kill, rollback, and multi-platform matrices remain |
| Harbor → clipboard | User-previewed clinician questions or care request | Explicit confirmation and editable preview | Other apps and clipboard history may retain copied text |
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
| TM-005 | Sensitive content leaks through clipboard or an external handoff | High disclosure | Preview and confirmation before clipboard copy; explicit call/text buttons; no automatic handoff | Test installed targets and clipboard histories; document that Harbor cannot erase copies held by the OS or recipient |
| TM-006 | Clearing site data, backup policy, or profile eviction destroys records | High availability loss | Pre-entry browser-loss disclosure and confirmed erasure path | No approved encrypted export/import; add storage-pressure and backup/restore evidence before durability claims |
| TM-007 | A stale service worker retains corrected clinical or privacy code | Critical integrity harm | Release cache identity, forced reload/fetch/validate/put, real alpha 15→16 defect reproduction and corrected update/offline path | Add rollback, partial/corrupt response, proxy, quota, and multi-browser tests |
| TM-008 | Another site frames Harbor and tricks a woman into activating controls | High privacy/safety harm | `frame-src 'none'` blocks Harbor-created frames; the local probe served and verified HTTP `frame-ancestors 'none'` plus `X-Frame-Options: DENY` | Browsers ignore `frame-ancestors` in a meta policy. Public-host header verification and a cross-origin clickjacking test remain mandatory |
| TM-009 | Build or action dependency is replaced | Critical supply-chain compromise | Locked Dart dependencies; GitHub actions pinned to immutable commits; public clean-checkout CI | No SBOM, signed provenance, dependency review cadence, or artifact signature yet |
| TM-010 | Storage quota, offline cache damage, or resource exhaustion prevents access | High denial of service | Visible startup state, bounded retry, prior-cache fallback, locked data recovery | Define performance/storage thresholds and execute quota, eviction, and corrupted-cache scenarios |
| TM-011 | A fake or unsafe “anonymous” board exposes identity or misinformation | Critical privacy/safety harm | No implemented board and no simulated member activity | Explicit remote-publishing approval, metadata limits, human moderation, retention, report/block, legal, clinical, and security gates are required before code |

## Security requirements and negative tests

| Requirement | Evidence now | Required remaining evidence |
|---|---|---|
| No personal content is sent by Harbor | No backend/network dependency, five web privacy-contract tests, and an instrumented compiled-Chromium save/reload/delete capture with zero personal-content requests | Repeat on supported browsers, public hosting, and signed native builds |
| Runtime assets do not depend on third-party hosts | Bundled fonts/assets, local HTML attributes, CSP/source contract | Public-host network capture and dependency/SBOM review |
| Unopenable data fails closed | Vault/controller/widget tests and locked recovery UI | Native interruption and forensic matrices |
| External sharing is deliberate | Clipboard preview/cancel tests and explicit `tel:`/`sms:` source contract | Physical-device clipboard, call, SMS, accessibility, and cancel-path tests |
| Web app cannot be embedded by another origin | Local production-style response verified `frame-ancestors 'none'` and `X-Frame-Options: DENY` | Repeat the header check and a cross-origin iframe test on the public host |
| Release changes remain reviewable | Clean public Git history and immutable-action CI | Protected branch/review policy, provenance, signatures, and incident drills |

## Explicit exclusions

This model does not claim protection from a fully compromised operating system, browser, device administrator, malicious accessibility service, screen camera, physical coercion, or a woman deliberately exporting/copying information. It does not cover a community backend because none is authorized or implemented. It does not approve clinical content, public deployment, signed native applications, or store release.

## Review triggers

Re-run this model before adding any account, server, board, remote configuration, export/import, diagnostic bundle, biometric lock, notification, background task, new OS permission, new dependency capable of networking, hosting provider, signing system, or analytics/crash-reporting tool. Named security and privacy owners and an independent assessment remain release gates.
