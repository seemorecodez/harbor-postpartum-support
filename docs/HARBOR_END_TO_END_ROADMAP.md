# Harbor: end-to-end product and release roadmap

**Version:** 1.1

**Date:** August 30, 2026

**Status:** Governing roadmap; no phase may be called complete without its exit evidence

**Products:** Web/PWA, iOS app, Android app, Windows desktop app, macOS desktop app

**Audience:** Adult women navigating the postpartum year

## 1. Outcome and non-negotiable acceptance target

Harbor will be a complete, women-centered postpartum support product in browsers, on phones, and on computers. The production web/PWA launches first; Android, iOS, Windows, and macOS are built simultaneously from the same governed requirements, content, design system, domain logic, and acceptance tests. It will provide an emotionally safe private space, educational orientation about postpartum body and baby changes, guided reflection, care planning, clinician-question preparation, and emergency routes.

The following requirements govern every phase:

1. Personal content remains local to the device or browser profile where it was created and is never transmitted by Harbor.
2. No accounts, cloud sync, analytics, advertising, fingerprinting, engagement tracking, remote AI, data brokerage, or hidden network traffic.
3. Web, mobile, and desktop are first-class products. The web/PWA is not a disposable prototype, and the installed apps are not wrappers around the website.
4. The product is explicitly designed for women and informed by compensated women with postpartum lived experience.
5. Harbor never claims to diagnose, treat, monitor, or replace a clinician or emergency service.
6. Clinical content must be source-traceable, reviewed, dated, owned, and re-reviewed.
7. Crisis resources are never paywalled and remain reachable within two actions from every major screen.
8. “Complete” means a verified production web deployment plus signed installable artifacts tested on their target operating systems—not source files, screenshots, or successful compilation alone.

## 2. Product boundary

### Version 1 includes

- Privacy and safety onboarding
- Optional biometric/device-credential app lock
- Private check-ins, history, and non-diagnostic pattern reflections
- Private journal
- Searchable postpartum body-and-baby field guide by stage and urgency
- Clinician-question organizer
- Personal hard-day and support plan
- Invisible-care-load and boundary-script tools
- Bundled offline library of clearly labeled composite women’s stories
- Local data export, import, deletion, migration, and recovery controls after security approval
- Region-appropriate crisis and emergency routes
- Keyboard, screen-reader, large-text, reduced-motion, and high-contrast support
- Production web/PWA plus installers for iOS, Android, Windows, and macOS

### Version 1 excludes

- Live community, messaging, member profiles, or user-generated public content
- Cloud backup or cross-device synchronization
- Remote AI or automated interpretation of journal/check-in text
- Diagnosis, individualized treatment recommendations, medication instructions, or clinical monitoring
- HealthKit, Health Connect, contacts, location, camera, microphone, or body-sensor access
- Partner, employer, insurer, clinician, or family dashboards
- Advertising and engagement optimization

### Pending scope decision: anonymous message board

A real cross-user board was requested on August 30, 2026. It is not silently added to the accepted local-only scope because publishing requires a network service and remote message storage. `docs/governance/ANONYMOUS_MESSAGE_BOARD_OPTIONS.md` defines the recommended separate opt-in, accountless, text-only, human-moderated service and the honest anonymity limits. Implementation begins only after explicit approval that deliberately published posts may leave the device. Fake posts or bundled stories presented as live activity remain prohibited.

Each installation or browser profile is independent. A browser does not silently synchronize Harbor content to a phone or computer. Any future device transfer must be a deliberate, end-to-end encrypted export/import flow and must pass a separate threat-model gate. The web onboarding must explain that clearing browser/site data erases Harbor data and that the initial static download contacts the chosen host even though Harbor never sends personal content.

## 3. Architecture decision

### Options reviewed

| Option | Web | Mobile | Windows/macOS | Privacy surface | Maintenance | Verdict |
|---|---|---|---|---|---|---|
| Extend Expo/React Native and add React Native Windows/macOS | React Native Web adds another compatibility layer | Existing mobile work is reusable | Separate platform ecosystems and uneven Expo compatibility | Duplicated storage/security behavior | Highest long-term platform burden | Rework |
| Maintain separate web, mobile, and desktop implementations | Independent native choices | Independent native choices | Independent native choices | Three diverging privacy/security surfaces | Highest duplication and clinical-content drift risk | Reject |
| Migrate to Flutter after a proof spike | Official web deployment and PWA support | Official Android/iOS support | Official Windows/macOS support | Shared audited product layer with platform-specific secure-storage adapters | Lowest cross-platform divergence | **Experiment first; expected choice** |

Flutter officially lists web, Android, iOS, Windows, and macOS as supported deployment platforms: [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms).

### Architecture verdict

**Experiment first, then accept Flutter if all proof conditions pass.** Rewriting now is cheaper and safer than maintaining separate desktop implementations later. The current React Native app is preserved as a requirements, interaction, tone, and content prototype—not promoted as the production release.

### Architecture proof conditions

Before migration is approved, a two-week spike must demonstrate:

- Production-mode web build plus signed debug installation on one Android phone, one iPhone, one Windows computer, and one Mac
- One shared screen and navigation model with native keyboard, mouse, touch, and screen-reader behavior
- Encrypted local database using SQLCipher or an equivalently reviewed store; web uses a separately reviewed Web Crypto/IndexedDB adapter
- Encryption key held in Keychain/Keystore/Windows Credential Locker/macOS Keychain; web uses a non-extractable origin-bound key where browser support permits and accurately discloses weaker browser guarantees
- Biometric/device-credential unlock where supported, with accessible fallback
- Installed-app network-denial test showing zero application requests during all local flows; web capture showing no personal-content egress and no runtime third-party request
- Correct app lifecycle lock and app-switcher privacy behavior
- Responsive browser/desktop window resizing and mobile one-handed layouts from one design system
- A documented fallback if any platform fails

**Fallback:** keep a dedicated privacy-first web client, retain React Native for iOS/Android, and build native Windows/macOS clients sharing content schemas and test fixtures. This costs more, increases drift risk, and requires separate release owners; it is not the default.

## 4. Required team and decision owners

| Role | Responsibility | Required before |
|---|---|---|
| Product owner | Scope, acceptance, funding, release decision | Phase 0 |
| Lead cross-platform engineer | Architecture, application implementation, packaging | Phase 0 |
| Product designer/researcher | Women-centered research, interaction and visual system | Phase 1 |
| QA/accessibility engineer | Test automation, device matrix, assistive-technology verification | Phase 3 |
| Security/privacy engineer | Threat model, encrypted storage, supply chain, privacy verification | Phase 2 |
| Clinical content lead | Content governance and review coordination | Phase 1 |
| OB-GYN advisor | Postpartum body and obstetric warning content | Phase 1 |
| Pediatric advisor | Newborn/baby content and escalation thresholds | Phase 1 |
| Perinatal mental-health advisor | Depression, anxiety, psychosis, crisis language | Phase 1 |
| Women with lived experience | Compensated research and acceptance testing | Phase 1 onward |
| Regulatory/privacy counsel | Claims, FDA posture, privacy, terms, store declarations | Phase 1 |
| Release engineer | Signing, stores, installers, provenance, rollback | Phase 7 |

One person may hold multiple engineering roles on a small team, but clinical, lived-experience, legal, and independent security review cannot be replaced by developer judgment.

## 5. Full phased roadmap

Planning estimate for a focused 4–6 person core team: **22–30 weeks to a controlled web-first release and 28–38 weeks for the complete five-platform release family**. The trains overlap: shared product work proceeds once, web-specific verification leads, and installed-platform packaging/device work continues simultaneously. These are planning ranges, not promises; clinical, security, signing, hardware, and store-review lead times control the critical path.

### Phase 0 — Charter, ownership, and evidence system (Week 1)

**Work**

- Name the legal/product owner and release authority.
- Lock the non-negotiable requirements in Section 1.
- Decide initial countries, languages, minimum OS versions, and adult-only positioning.
- Define issue severity, document ownership, decision log, risk register, and change-control process.
- Create traceability from requirement → design → code → test → release evidence.
- Inventory the current React Native prototype and quarantine unsupported completion claims.

**Deliverables**

- Signed product charter
- Requirements traceability matrix
- Decision and assumption log
- Risk register
- Repository governance, branch protection, code review rules, and backup policy

**Exit gate**

- One accountable owner for every release gate
- No unresolved contradiction about audience, platforms, locality, or medical claims

### Phase 1 — Women-centered research and clinical/regulatory framing (Weeks 2–5)

**Work**

- Recruit a diverse, compensated group of postpartum women across birth experiences, disability, race, age, income, feeding choices, family structures, rural/urban location, and postpartum stages.
- Use trauma-informed interviews; never require disclosure of medical trauma.
- Study one-handed use, sleep deprivation, cognitive overload, shame triggers, privacy on shared devices, and moments when women hesitate to call clinicians.
- Form the clinical advisory group and define review authority.
- Create the intended-use and prohibited-claims statements.
- Obtain regulatory counsel’s written classification analysis. The FDA’s 2026 general-wellness guidance distinguishes low-risk wellness from diagnosis/treatment functions: [FDA general wellness guidance](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/general-wellness-policy-low-risk-devices).
- Review Apple and Google health-app requirements. Google requires a Health apps declaration, public privacy policy, clear disclaimer, and clinician-consultation language for applicable apps: [Google Play Health Content and Services](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en). Apple applies heightened scrutiny to health accuracy and sensitive-data privacy: [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

**Deliverables**

- Research plan, consent language, interview findings, and evidence-backed personas
- Jobs-to-be-done and harm scenarios
- Intended-use, non-device, and claims matrix
- Clinical governance charter
- Initial content inventory and source register

**Exit gate**

- At least 12–20 completed participant sessions with major themes saturated
- Clinical and legal reviewers approve the product boundary
- Any diagnostic-sounding flow is removed or sent back for regulatory analysis

### Phase 2 — Cross-platform architecture and security proof (Weeks 3–6, overlaps Phase 1)

**Work**

- Execute the Flutter architecture spike defined in Section 3.
- Define a platform-neutral encrypted local-data schema.
- Threat-model shared devices, stolen devices, screenshots, app switcher, logs, clipboard, backups, malware, database copying, tampered content, signing-key compromise, and unsafe migrations.
- Prove database encryption, secure key storage, deletion behavior, backup exclusion, and lock behavior.
- Establish dependency allowlist, software bill of materials, lockfile verification, and license scan.
- Design versioned migrations with backup, rollback, and corruption recovery.

**Deliverables**

- Architecture Decision Record
- Working five-platform proof artifacts
- Threat model and mitigations
- Data schema and migration contract
- Dependency and license inventory
- Measured network-denial report

**Exit gate**

- Architecture verdict is Accept or Accept with conditions
- Zero unexpected network requests in instrumented tests
- Security reviewer approves the local-storage design
- Failed proof causes a written fallback decision before feature development

### Phase 3 — Full product specification and design system (Weeks 5–9)

**Work**

- Convert research into numbered functional and non-functional requirements.
- Map every user journey, empty state, error, interruption, deletion, and recovery state.
- Design responsive web/PWA, phone, tablet, resizable Windows, and resizable macOS layouts.
- Design for one hand, low attention, large text, keyboard-only use, screen readers, color-blindness, reduced motion, and panic conditions.
- Establish language rules: women-centered, nonjudgmental, feeding-neutral, non-diagnostic, never implying surveillance.
- Prototype onboarding, home, body/baby guide, check-in, journal, questions, hard-day plan, Stories, privacy, lock, export/import, deletion, and urgent support.
- Test prototypes with the lived-experience group and accessibility users.
- Target WCAG 2.2 AA principles plus native platform accessibility requirements. W3C recommends WCAG 2.2 as the current target: [WCAG 2.2](https://www.w3.org/TR/WCAG22/).

**Deliverables**

- Build-ready product requirements document
- Information architecture and complete flow map
- Component, typography, color, icon, motion, and content systems
- Responsive specifications for all five platforms
- Prototype usability and accessibility findings
- Approved release design baseline

**Exit gate**

- Every requirement has an approved interaction and testable acceptance criterion
- No placeholder or “coming soon” flow remains in release scope
- Critical journeys pass moderated usability testing

### Phase 4 — Clinical content production and governance (Weeks 6–13)

**Work**

- Create a content record for every body, baby, mental-health, and crisis item: source, author, reviewer, jurisdiction, review date, expiry date, severity, and wording history.
- Review common/call/urgent boundaries independently.
- Test plain language and emotional impact with women.
- Localize crisis numbers and medical wording only after regional review.
- Include content as signed application assets; do not fetch remote content.
- Create an emergency correction procedure requiring a new signed app release.

**Deliverables**

- Clinically reviewed content database
- Source and change log
- Jurisdiction matrix
- Content-expiry dashboard used during release preparation, not inside the app
- Clinical sign-off packet

**Exit gate**

- Two-person clinical approval for every urgent item
- No expired, unsourced, or jurisdiction-ambiguous release content
- Crisis routes verified by direct authoritative sources immediately before release

### Phase 5 — Production foundation (Weeks 8–12)

**Work**

- Create production repository structure, continuous integration, reproducible toolchain, and environment pinning.
- Implement design tokens, navigation, responsive shell, keyboard commands, routing, state restoration, and error boundaries.
- Implement encrypted database, secure key management, migrations, backups disabled by default, app lock, screenshot/app-switcher protection, and complete deletion.
- Implement structured local logs that never contain journal, check-in, question, plan, or health content.
- Add offline-only build checks that fail on network packages, URLs, remote update configuration, telemetry, or prohibited permissions.
- Establish unit, widget/component, integration, golden/screenshot, and end-to-end test harnesses.

**Deliverables**

- Deployable internal web build and installable internal build on all four native platforms
- Automated build and test pipeline
- Local schema version 1 with migration tests
- Privacy-enforcement tests
- Developer setup and recovery documentation

**Exit gate**

- Clean checkout builds reproducibly
- Fresh install, upgrade, lock, deletion, and corrupt-storage recovery tests pass
- Security controls work on real target devices, not only mocks

### Phase 6 — Vertical feature implementation (Weeks 11–20)

Build and approve one complete vertical slice at a time in this order:

1. Onboarding, privacy promise, emergency boundaries, and home
2. Check-in creation, history, deletion, and non-diagnostic reflection
3. Journal creation, search, edit, deletion, and recovery
4. Body-and-baby guide with stage, search, severity, sources, and emergency routing
5. Clinician-question list with deliberate share/export
6. Hard-day plan with explicit phone/text handoff
7. Invisible-load and boundary-script tools
8. Offline Stories library with transparent composite labeling
9. Privacy center, app lock, data export/import, erase, and About/content-version screens
10. Desktop keyboard, menu, window, installer, file-association, and accessibility behavior

For each slice:

- Implement the actual user path and all error/empty states.
- Add unit, UI, integration, accessibility, privacy, migration, and platform tests.
- Conduct design, lived-experience, clinical (where relevant), and security review.
- Fix and retest before beginning dependent slices.

**Exit gate**

- No release-scope feature is simulated, disabled, or backed by mock data
- Every slice has reproducible evidence against its original acceptance criteria

### Phase 7 — Hardening and independent verification (Weeks 19–25)

**Functional QA**

- Fresh install, upgrade from every supported schema, uninstall/reinstall, lockout, interruption, low storage, corrupted database, clock/timezone change, font scaling, rotation where allowed, window resizing, sleep/wake, and crash recovery
- Phone and desktop call/text/share behavior with clear handoff boundaries
- All destructive actions require confirmation and have documented recovery limits

**Accessibility QA**

- Browser keyboard/screen-reader matrix, VoiceOver, TalkBack, Windows Narrator, and macOS VoiceOver
- Keyboard-only desktop navigation and visible focus
- 200% text scaling/reflow, contrast, target sizes, reduced motion, screen zoom, and cognitive-load review

**Privacy/security QA**

- Independent threat-model review and penetration test
- Static and dynamic dependency analysis
- Verify no network traffic through an intercepting proxy and OS firewall logs
- Verify no personal content in logs, crash files, recent-items lists, thumbnails, clipboard history, or installer artifacts
- Verify database encryption and key separation by copying the database off-device
- Verify erase, uninstall, migration rollback, and tampered-content failure behavior

**Clinical/safety QA**

- Source-to-screen comparison for every health statement
- Independent review of all urgent routes and thresholds
- Scenario tests for hemorrhage, preeclampsia warning signs, infection, postpartum psychosis/suicidality, newborn fever, breathing difficulty, poor feeding, and jaundice
- Confirm app never delays care or presents “common” as a guarantee

**Performance acceptance**

- Cold launch ≤2.5 seconds on agreed baseline devices
- Core navigation response ≤150 ms where no disk operation is required
- Search results ≤300 ms across bundled content
- No data loss across 1,000 journal/check-in records and 20 consecutive migrations
- Installer and storage budgets defined and measured per platform

**Exit gate**

- Zero open critical/high safety or security defects
- All supported-platform matrices pass
- Independent accessibility, security, clinical, and privacy sign-offs obtained

### Phase 8 — Closed alpha and compensated beta (Weeks 23–28)

**Work**

- Run an internal alpha on all five platforms, beginning with the production-mode web artifact while native builds continue in parallel.
- Recruit a compensated beta group representing the research population.
- Use no in-app analytics. Collect only deliberate, separately consented feedback that excludes personal journal/health content.
- Provide a manual diagnostic export containing app version, OS, schema version, and error codes only; show the exact payload before sharing.
- Test installation, onboarding, day-7 retention of local records, app lock, updates, and removal.
- Operate a safety incident channel with defined clinical escalation.

**Deliverables**

- Alpha and beta plans
- Signed beta builds
- Defect and safety-incident reports
- Beta acceptance report by platform and participant segment

**Exit gate**

- No unresolved data-loss, safety-routing, lock, or accessibility issue
- Target women can complete critical journeys without facilitator help
- No feedback collection violates the zero-tracking promise

### Phase 9 — Legal, policy, brand, and store preparation (Weeks 22–29)

**Work**

- Complete name/trademark search, ownership, open-source notices, contributor terms, and asset licenses.
- Finalize Terms of Use, medical disclaimer, accessibility statement, support policy, and a public, static, no-analytics privacy-policy page.
- Do not claim HIPAA compliance unless counsel confirms the product and organization qualify and controls are audited.
- Complete Apple privacy nutrition labels and review guidelines.
- Complete Google Data Safety and Health apps declarations. Google requires a publicly accessible privacy-policy URL even when data collection is absent.
- Define adult audience, age rating, countries, content rating, support contact, and store descriptions.
- Prepare screenshots, preview video, icon, splash, release notes, review notes, and reviewer test instructions without exposing real user data.

**Exit gate**

- Legal and regulatory counsel approve claims and disclosures
- Store declarations exactly match measured application behavior
- Every third-party license and attribution is satisfied

### Phase 10 — Signing, packaging, and distribution (Weeks 27–32)

**Web/PWA — first release train**

- Produce a versioned static bundle with no third-party runtime asset, strict Content Security Policy, pinned hashes, service-worker update/rollback behavior, self-hosting instructions, and hosting configuration that minimizes request logs.
- Verify first load, offline reload, browser installability where supported, browser-data deletion, storage quota/failure, upgrade, clinical-content expiry, three-browser compatibility, accessibility, and zero personal-content egress.
- Publish only after the same clinical, security, privacy, accessibility, legal, and Go/No-Go gates required for the installed applications pass for the web scope.

**iOS**

- Apple Developer account, bundle ID, certificates, provisioning, archive, TestFlight, App Store review, phased release, rollback plan

**Android**

- Play Console account, package registration, upload key/app-signing key, signed AAB, internal/closed testing, Health declaration, staged rollout; retain a signed APK only if direct distribution is explicitly supported

**Windows**

- Produce x64 and ARM64 MSIX where supported, validate install/uninstall/upgrade, sign through Microsoft Store or trusted certificate, publish Store and optional direct-download channels. Microsoft documents that signing verifies publisher identity and package integrity: [Microsoft MSIX signing](https://learn.microsoft.com/en-us/windows/msix/package/sign-app-package-using-signtool).

**macOS**

- Produce universal or architecture-specific signed app and DMG/PKG, enable hardened runtime, validate sandbox/entitlements, notarize, staple ticket, test Gatekeeper and upgrade. Apple requires Developer ID signing and notarization for direct distribution: [Apple notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

**All platforms**

- Generate software bill of materials, checksums, build provenance, version manifest, installation guide, rollback instructions, and archived source/toolchain state.

**Exit gate**

- A clean browser can load, operate offline, update, erase, and roll back the web artifact; a clean consumer device can download, install, launch, upgrade, and uninstall each signed native artifact
- Signatures, notarization, checksums, and store metadata verify successfully
- Personal data survives approved upgrades and is removed by approved deletion/uninstall behavior

### Phase 11 — Release candidate and launch decision (Weeks 31–34)

**Release gates: all must be Pass**

| Gate | Evidence |
|---|---|
| Product | Every release requirement traced to an accepted test |
| Women-centered experience | Lived-experience acceptance report |
| Clinical safety | Signed content and scenario review |
| Privacy | Zero-network report, declarations, data-flow audit |
| Security | Independent assessment; no unresolved high findings |
| Accessibility | Four-platform assistive-technology report |
| Reliability | Device/OS matrix and migration/data-loss report |
| Performance | Measured baseline report |
| Legal/policy | Counsel and store declarations approved |
| Packaging | Signed installers tested on clean machines/devices |
| Operations | Support, incident, rollback, and key-compromise drills passed |

The release authority records Go, No-Go, or Conditional Go. A compile, demo, source ZIP, unsigned installer, or store submission is not a release.

### Phase 12 — Staged launch and verification (Weeks 34–36)

- Begin with a small country and staged platform rollout.
- Monitor store-reported crashes only if they can be received without violating the disclosed privacy posture; otherwise rely on explicit user reports and store aggregate health.
- Review support and safety incidents daily during launch week.
- Verify crisis routes and public policies after publication.
- Halt or roll back for any harmful content error, data loss, unexpected network traffic, lock bypass, or severe accessibility failure.
- Record final artifact hashes, store versions, release date, and approvals.

### Phase 13 — Maintenance, governance, and eventual sunset (Ongoing)

**Every release**

- Dependency/SBOM/license scan, reproducible builds, unit/UI/E2E suite, five-platform smoke test, installed zero-network tests, web zero-content-egress/CSP tests, privacy-declaration comparison, content-diff review, and upgrade/rollback tests

**Monthly**

- Security advisories, dependency and OS compatibility, support themes, store-policy changes

**Quarterly**

- Crisis-resource verification, threat-model changes, accessibility regression sweep, signing-key drill

**At least annually**

- Full clinical content re-review, legal/regulatory review, lived-experience advisory review, independent security assessment

**Sunset plan**

- Announce end of support without exposing users.
- Keep export and deletion available.
- Do not remotely disable local records.
- Publish final signed installers only if legally and clinically supportable.
- Revoke compromised signing credentials and preserve release provenance.

## 6. Critical dependency and risk map

| Dependency | Status now | Failure impact | Required unlock | Fallback |
|---|---|---|---|---|
| Product/release owner | Missing | No accountable approval | Name owner and decision rights | Stop release work |
| Flutter five-platform proof | In progress | Architecture may not meet browser/desktop/privacy needs | Measured web/Windows spike followed by Android and Apple device proof | Split clients behind shared contracts |
| Privacy-minimizing static web host | Missing | Web cannot launch without ordinary host request metadata | Select/configure host, minimize logs, publish accurate disclosure and self-hostable artifact | Distribute self-hostable static bundle only |
| Mac + Xcode + Apple account | Missing | No iOS/macOS signed artifacts | Acquire hardware/account early | None for Apple release |
| Windows signing/Store account | Missing | Untrusted or undistributable installer | Choose Store or certificate path | Limited unsigned internal test only |
| Google Play account/signing | Missing | No Android store release | Establish organizational account and key custody | Signed direct APK with narrower reach |
| Clinical advisory group | Missing | Unsafe/unapproved medical content | Contract named reviewers | Remove unreviewed content |
| Lived-experience panel | Missing | Feminist claims remain unvalidated | Recruit and compensate panel | No public launch |
| Regulatory/privacy counsel | Missing | Claims/store/legal rejection risk | Written analysis and disclosures | Narrow claims and countries |
| Encrypted local database | Missing in current prototype | Sensitive local data exposure | Architecture proof and migration | Do not store free text |
| Independent security review | Missing | Unknown privacy/security defects | Budget and schedule assessor | No public release |
| Public static privacy-policy URL | Missing | Store rejection | Host a no-analytics static page | Store release blocked |
| Physical-device/desktop matrix | Missing | Behavior unverified | Acquire devices or lab access | Reduce supported matrix explicitly |

### Critical path

1. Name owner and lock scope.
2. Recruit clinical, lived-experience, legal, and security reviewers.
3. Prove the five-platform architecture and encrypted locality, including the separate browser security boundary.
4. Approve requirements/design/content.
5. Implement vertical slices with tests.
6. Complete independent hardening and beta.
7. Obtain platform accounts, hardware, signing, policy approval, and installers.
8. Test signed releases on clean target devices.
9. Conduct Go/No-Go and staged launch.

Apple hardware/accounts, clinical reviewers, and participant recruitment are long-lead single points of failure and must start before feature implementation is complete.

## 7. Current state against the roadmap

| Area | Status | Honest interpretation |
|---|---|---|
| Product direction | Conditional pass | Audience, locality, and broad feature intent are explicit |
| Interaction/content prototype | Pass as enabling work | React Native prototype demonstrates key flows and tone |
| Mobile source compilation | Pass as validation evidence | iOS/Android bundles compile; this is not signed-device release evidence |
| Automated prototype checks | Pass as enabling evidence | Eight source/configuration checks pass |
| Public source and CI | **Conditional** | Public `main` has an immutable-action Ubuntu 24.04 clean-checkout gate; alpha.22 commit `29fca83` passes Flutter 3.47.2 lockfile resolution, formatting, analysis, all 91 tests including strict Linux goldens, release WebAssembly build, clean-tree verification, and short-lived artifact preservation. Its web download matches all 49 CI files and its source download matches all 203 raw Git blobs. Native CI, signing/provenance, long-term retention, and cross-OS deterministic build output remain |
| Web product | **Conditional** | Versioned alpha.23 PWA source and the integrity-audited alpha.22 web/source downloads exist. Verified browser paths cover upgrades, encrypted schema migration/restart, locked recovery, visible online/offline startup, fatal-load recovery, responsive and accessible layouts, encrypted synthetic data, care tools, factual reflections, clinician-question handoff, transparent offline Stories, truthful About/content versions, bounded diagnostics, the nine-scenario clinical-safety guide, urgent-support routing, erase, the alpha.20 passphrase-wrapped app lock paths, alpha.21/22 compiled accessibility smokes, and alpha.23 exact-preview/cancel privacy paths. Alpha.23 centralizes every clipboard write behind one typed gateway and rejects application logging APIs; native clipboard/crash/recents forensics remain open. Automatic web locking remains dependent on visibility/focus events supplied by the host; native device-credential and app-switcher proofs remain open |
| Desktop product | **Fail** | Shared Windows/macOS targets exist but no native release artifact has passed its build/install/runtime path |
| Production architecture | **Conditional** | Shared Flutter web runtime and Windows encrypted-store library proof pass; Android, Windows UI, and Apple runtime proofs remain |
| Encrypted personal-content storage | **Conditional** | Production AES-256-GCM shared vault, version-1/2-to-version-3 migration/restart, interrupted-write recovery, future-version lockout, and Windows sqlite3mc proof pass; platform key-custody and forensic reviews remain |
| Women’s research validation | **Fail** | No documented compensated research panel |
| Clinical approval | **Fail** | A typed nine-scenario source-backed draft matrix, registry synchronization, non-reassurance rules, real UI searches, and emergency routing pass; named clinical and lived-experience sign-off is still absent |
| Independent security/accessibility QA | **Fail** | Automated 200%-text/label/target/contrast/platform-preference and visually inspected real-UI golden tests plus real Chromium keyboard/semantic/responsive/default-preference passes succeed; independent active-preference, accessibility-user, five-platform assistive-technology, and security reviews are not performed |
| Signed mobile/desktop installers | **Fail** | No store or code-signing credentials were supplied |
| Physical-device release testing | **Fail** | No target device matrix has run |
| Store/legal readiness | **Fail** | Declarations, policies, counsel, and accounts are incomplete |

The React Native ZIP remains **prototype source**. The working Flutter tree is alpha.23; the current integrity-audited public web/source downloads remain alpha.22 until alpha.23 public CI and package verification complete. They remain **engineering alpha**, not a “complete app” or release candidate; no native release artifact is implied by the presence of native target source.

## 8. Definition of complete

Harbor is complete only when all of the following are true:

- Five production applications exist: web/PWA, iOS, Android, Windows, and macOS.
- The web app is deployed, offline-capable, upgradable, erasable, rollback-tested, and verified in clean browser profiles; each native app is signed, installable, upgradable, removable, and verified on clean target devices.
- Every release-scope feature is real and contains no placeholders or mock community behavior.
- Personal content is encrypted locally, never silently transmitted, and can be exported or erased deliberately.
- Instrumented testing proves zero unexpected network requests.
- Women with lived experience approve the product experience.
- Named clinicians approve all health and crisis content.
- Independent security, privacy, accessibility, and legal reviews pass.
- Store declarations and public policies match measured behavior.
- Rollback, incident, key-compromise, content-correction, and sunset procedures are tested.
- The release authority signs a Go decision supported by the complete evidence packet.

Anything less must be reported by its actual stage: concept, prototype, alpha, beta, release candidate, or released product.
