# Harbor visual-regression evidence

## Scope

Alpha.22 establishes the roadmap-required golden/screenshot harness for four high-risk phone states at 390×844 logical pixels and device-pixel ratio 1. Windows and Linux keep separate, visually reviewed, byte-exact references because the same bundled glyphs rasterize differently across their Flutter test engines:

| Reference | User-facing boundary | Windows SHA-256 | Linux SHA-256 |
|---|---|---|---|
| `privacy_onboarding_phone.png` | Local-only disclosure and required consent before sensitive entry | `FD28A03AF7B1BBC8D605B170376945A4AA98FEB4294654C669690EC8E1A76C32` | `5183F5756BF9802D35A49C676A0E6C51DB0BFCE5C5669E6A997ECB3A96CCF920` |
| `today_phone.png` | Default women-centered Today surface and persistent urgent support | `B9788B66351604594ADE0E4D084786E897AC1AE1ECBB32E2F0F3EA5D5343EC02` | `44153CD89584504E3E4802FD07F2C4282AAFC23EEA3D74795BDE77DEFA8ABC7E` |
| `today_high_contrast_phone.png` | Platform high-contrast surface with plum identity and black two-pixel boundaries | `EB4EE2D0B26EBB4E30AA2A270B88FA06F051C8920D4328DCCECAAEF13649BE9E` | `46465BCC6EE7EAA7817ED876BB528E0AC3ADC67C3A922815718816ABB4964D91` |
| `urgent_support_phone.png` | Unobscured 911/988 emergency handoff from Today | `8A8F2F5DC93BD4CA52417570CBD0F3F9E92313F7B877433F392E74365035A890` | `2303F4C19DA51E742B6CCB123B915E957CB5D618E650208D7C1597C357FD1071` |

The harness constructs the production `HarborApp` with in-memory local stores, real default models, the bundled HarborSans faces, and bundled Material Icons. It disables Harbor-owned motion only to make the captured state deterministic. It adds no runtime dependency, permission, persistence, identifier, personal fixture, or network path.

## Visual acceptance record

Date: 2026-08-31. Environment: Windows host, Flutter 3.47.2 / Dart 3.13.2, software-rendered widget-test goldens.

Two preliminary reference sets were rejected. The first rendered Harbor and icon glyphs as placeholder blocks. Loading bundled HarborSans and Material Icons corrected most glyphs, but filled/outlined button labels still used the test default. Inspection traced that to production button themes that specified weight and size but did not explicitly retain HarborSans. Binding both themes to HarborSans fixed the actual product and the harness.

The next default/high-contrast comparison showed that custom soft panels bypassed `CardTheme`, leaving the high-contrast screen insufficiently distinct. Alpha.22 now gives the header, hero, information panel, and empty state explicit black two-pixel boundaries; information and empty panels use white surfaces and black icons under platform high contrast. The accepted references visibly retain the soft plum/blush default identity, provide a materially distinct high-contrast state, keep all inspected copy readable, and leave urgent support unobscured.

The first Ubuntu clean-checkout run then failed all four Windows references by 3.95–4.99% while the other 87 tests passed. A failure-only CI artifact preserved Linux actual/master/isolated-diff images. Direct inspection found the same layout, copy, color, support access, and boundaries; isolated differences traced glyph edges rather than geometry. Harbor therefore keeps strict per-platform references instead of introducing a tolerance. Windows and Linux compare byte-for-byte to their own reviewed set. Any unsupported test OS fails closed until its own references are reviewed.

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

Every regenerated candidate must be inspected at original resolution before commit. CI must run only the comparison command and must never use `--update-goldens`. A passing golden does not prove screen-reader, touch-device, browser-zoom, active OS high-contrast/reduced-motion, clinical, lived-experience, or unreviewed-platform acceptance.
