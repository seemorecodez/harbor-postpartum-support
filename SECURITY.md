# Security policy

Harbor handles unusually sensitive personal writing. Please do not open a public issue containing personal postpartum information, medical details, security credentials, decrypted vault contents, or an exploitable vulnerability.

## Reporting a vulnerability

Use GitHub's private vulnerability-reporting or Security Advisory flow for this repository. Include:

- The affected version and platform
- Reproduction steps using synthetic data only
- Expected and observed behavior
- The security or privacy impact
- Any suggested mitigation

Do not test against another person's device or data, publish an exploit before a fix is available, or upload a real Harbor vault.

## Current support boundary

Alpha 16 is an engineering build. It has automated encryption, migration, privacy-boundary, accessibility, and web-update coverage, but has not completed independent security review, native signed-build forensics, public deployment review, or clinical release approval. See `docs/governance/RELEASE_GATES.md` for the evidence ledger.
