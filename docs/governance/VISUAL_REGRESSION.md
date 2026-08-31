# Harbor visual-regression evidence

## Scope

Alpha.22 establishes the roadmap-required golden/screenshot harness for four high-risk phone states at 390×844 logical pixels and device-pixel ratio 1:

| Reference | User-facing boundary | SHA-256 |
|---|---|---|
| `privacy_onboarding_phone.png` | Local-only disclosure and required consent before sensitive entry | `FD28A03AF7B1BBC8D605B170376945A4AA98FEB4294654C669690EC8E1A76C32` |
| `today_phone.png` | Default women-centered Today surface and persistent urgent support | `B9788B66351604594ADE0E4D084786E897AC1AE1ECBB32E2F0F3EA5D5343EC02` |
| `today_high_contrast_phone.png` | Platform high-contrast surface with plum identity and black two-pixel boundaries | `EB4EE2D0B26EBB4E30AA2A270B88FA06F051C8920D4328DCCECAAEF13649BE9E` |
| `urgent_support_phone.png` | Unobscured 911/988 emergency handoff from Today | `8A8F2F5DC93BD4CA52417570CBD0F3F9E92313F7B877433F392E74365035A890` |

The harness constructs the production `HarborApp` with in-memory local stores, real default models, the bundled HarborSans faces, and bundled Material Icons. It disables Harbor-owned motion only to make the captured state deterministic. It adds no runtime dependency, permission, persistence, identifier, personal fixture, or network path.

## Visual acceptance record

Date: 2026-08-31. Environment: Windows host, Flutter 3.47.2 / Dart 3.13.2, software-rendered widget-test goldens.

Two preliminary reference sets were rejected. The first rendered Harbor and icon glyphs as placeholder blocks. Loading bundled HarborSans and Material Icons corrected most glyphs, but filled/outlined button labels still used the test default. Inspection traced that to production button themes that specified weight and size but did not explicitly retain HarborSans. Binding both themes to HarborSans fixed the actual product and the harness.

The next default/high-contrast comparison showed that custom soft panels bypassed `CardTheme`, leaving the high-contrast screen insufficiently distinct. Alpha.22 now gives the header, hero, information panel, and empty state explicit black two-pixel boundaries; information and empty panels use white surfaces and black icons under platform high contrast. The accepted references visibly retain the soft plum/blush default identity, provide a materially distinct high-contrast state, keep all inspected copy readable, and leave urgent support unobscured.

The exact compiled alpha.22 WebAssembly app was then inspected separately. It rendered HarborSans controls on Today, completed consent onboarding, exposed the complete 911/988 dialog, reported build 22 in About, and logged no browser warnings or errors. Goldens are validation evidence, not a substitute for that runtime path.

## Reproduction

Compare immutable references:

```text
flutter test test/visual_regression_test.dart
```

Regenerate candidates locally only after an intentional accepted design change:

```text
flutter test --update-goldens test/visual_regression_test.dart
```

Every regenerated candidate must be inspected at original resolution before commit. CI must run only the comparison command and must never use `--update-goldens`. A passing golden does not prove screen-reader, touch-device, browser-zoom, active OS high-contrast/reduced-motion, clinical, lived-experience, or cross-platform acceptance.
