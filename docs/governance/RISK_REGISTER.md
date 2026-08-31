# Harbor risk register

| ID | Risk | Probability | Impact | Current status | Mitigation and evidence | Owner |
|---|---|---:|---:|---|---|---|
| R-001 | Current local content storage is not independently encrypted | High | Critical | Open | Do not promote prototype; prove SQLCipher/equivalent and separate secure key storage | Security owner missing |
| R-002 | “Is this normal?” is interpreted as diagnosis or delays care | Medium | Critical | Open | Claims review, wording research, independent clinical scenarios, persistent call boundary | Clinical/legal owners missing |
| R-003 | Incorrect/expired obstetric, pediatric, mental-health, or crisis content | Medium | Critical | Open | Content registry, two-person urgent review, expiry and pre-release verification | Clinical owner missing |
| R-004 | Flutter cannot meet one platform’s security/accessibility requirement | Medium | High | Open | Architecture proof before production commitment; platform adapters and documented fallback | Technical owner missing |
| R-005 | No Mac/Xcode/Apple account blocks iOS and macOS proof and release | High | Critical | Open | Acquire early; no valid Apple fallback exists | Product/release owner missing |
| R-006 | No Android SDK/Windows build tools/device lab blocks real testing | High | High | Open | Install toolchains and obtain physical/device-lab access | Release owner missing |
| R-007 | No Windows/macOS signing identity blocks trusted downloads | High | Critical | Open | Choose Store/direct channels and establish key custody early | Release owner missing |
| R-008 | Hidden dependency or framework traffic violates privacy promise | Medium | Critical | Open | Dependency denylist, OS permission denial, proxy/firewall tests on signed builds | Security owner missing |
| R-009 | Personal content leaks through logs, screenshots, recents, clipboard, backups, or temp files | Medium | Critical | Open | Threat model, platform protections, forensic test, independent assessment | Security owner missing |
| R-010 | Schema migration corrupts or loses sensitive records | Medium | Critical | Mitigated for schema 1/2→3 in alpha.16; open for release | Encrypted staged migration, double verification, interrupted-write retry, locked recovery UX, deterministic fixtures, and real alpha.13→14 and alpha.15→16 browser upgrade/restart passes; next add native/multi-browser process-kill, disk-full/quota, backup/restore, and rollback matrices | Technical/QA owners missing |
| R-011 | Biometric lock creates inaccessible or unrecoverable state | Medium | High | Open | Device-credential fallback, accessibility testing, explicit limitations | Accessibility/security owners missing |
| R-012 | Feminist/women-centered claim is performative or exclusionary in practice | Medium | High | Open | Diverse compensated women’s advisory panel and research-based acceptance | Research owner missing |
| R-013 | Lack of telemetry makes defects hard to diagnose | High | Medium | Accepted constraint | Opt-in user-previewed diagnostic export with no content; manual support workflow | Support owner missing |
| R-014 | Store health-app policy or regulatory classification causes rejection | Medium | High | Open | Early counsel, claims matrix, Health declaration, static privacy page | Legal owner missing |
| R-015 | Signing key compromise allows malicious distribution | Low | Critical | Open | Hardware-backed custody, least privilege, rotation/revocation drill | Release/security owners missing |
| R-016 | Unsupported OS/device expands failures and QA cost | Medium | High | Open | Lock minimum versions after research and Flutter proof; publish compatibility | Product/QA owners missing |
| R-017 | Schedule pressure promotes mock or unverified work | High | Critical | Controlled by charter | Gate every claim; release authority cannot waive critical safety/privacy gates | Product owner missing |
| R-018 | Users assume browser storage is as durable or OS-protected as an installed app | High | High | Open | Pre-entry disclosure, encrypted browser store, deletion/storage-loss UX, recommend installed app for durable use | Product/privacy owners missing |
| R-019 | Static web hosting request logs conflict with an absolute “no data collection” claim | High | High | Open | No personal-content requests, no analytics/CDN third-party code, minimize/disable logs where possible, accurate privacy notice, self-hostable build | Privacy/release owners missing |
| R-020 | Service worker serves stale clinical or crisis content | Medium | Critical | Alpha.16 stale-runtime defect reproduced and mitigated; open for release | Each new cache now force-fetches and validates runtime responses; contract test and corrected real alpha.15→16 update/offline path pass. Next add content expiry/invalidation, rollback, partial/corrupt-response, quota, multi-browser, and public-deployment E2E | Clinical/technical owners missing |
| R-021 | “Anonymous” board exposes women to metadata linkage, harassment, doxxing, medical misinformation, or false expectations of emergency monitoring | High | Critical | Pending boundary decision | Separate opt-in service, no profiles/DMs/images/tracking, honest metadata disclosure, trained human moderation, report/block, retention limits, legal/safety/security review | Community safety/privacy owners missing |
| R-022 | Offline web startup can leave a woman looking at a blank screen long enough to appear broken | High | High | Mitigated in alpha.13; open for release | First-frame-bound startup, honest fatal state, pointer/Enter/Space recovery, and server-stopped offline completion are visibly verified; next set an accepted threshold and test the supported browser/device and assistive-technology matrix | Product/performance/accessibility owners missing |
| R-023 | Large text, narrow layouts, or inaccessible navigation can hide support and care controls | Medium | Critical | Mitigated in alpha.15 automated/Chromium paths; open for release | Full-width scrollable phone navigation, scalable brand/dropdowns, persistent labeled urgent support, four accessibility regressions, and compiled desktop/phone keyboard/semantic inspection; next run accessibility-user and five-platform assistive-technology/high-contrast/reduced-motion matrices | Accessibility/QA owners missing |

## Highest-leverage unblock actions

1. Assign a product/release owner with authority and budget.
2. Acquire Mac/Xcode, Apple and Google developer accounts, Windows signing path, and physical/device-lab access.
3. Recruit lived-experience, clinical, legal, security, and accessibility reviewers.
4. Complete the Flutter web/Windows proof, install remaining platform toolchains, and execute the five-target architecture proof.
5. Approve encrypted local-data architecture before implementing production features.
