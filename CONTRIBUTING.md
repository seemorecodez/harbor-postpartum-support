# Contributing to Harbor

Thank you for helping improve Harbor. Before submitting work, read `CONTRIBUTOR_TERMS.md`, `GOVERNANCE.md`, and `README-LICENSING.md`.

## Safety and privacy boundaries

- Use synthetic test data only. Never submit a real woman's journal entry, health history, message, credential, vault, or identifying information.
- Do not add analytics, advertising, tracking, accounts, remote AI, cloud synchronization, or personal-content network transmission.
- Do not present invented people, quotations, reactions, or activity as a real community.
- Do not add or change medical, mental-health, feeding-safety, pediatric, obstetric, or crisis claims without provenance and the required independent review record.
- A real community feature must remain separate from the private vault and cannot be merged before its explicit privacy, moderation, retention, legal, and security gates are approved.

## Development checks

```text
flutter pub get
flutter analyze
flutter test
flutter build web --release --wasm
```

Keep generated build output, caches, credentials, local SDK paths, signing material, and device data out of commits. Explain the user-visible outcome and verification evidence in each pull request.
