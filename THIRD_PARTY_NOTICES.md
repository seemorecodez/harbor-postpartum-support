# Harbor third-party font notices

Harbor bundles font files so the web application never needs a runtime font CDN request.

## Roboto

- Files: `assets/fonts/HarborSans-Regular.ttf`, `assets/fonts/HarborSans-Medium.ttf`
- Upstream: Android Open Source Project / Google Roboto
- License: Apache License 2.0
- Source used for this build: Flutter engine third-party font fixtures

## Noto fallback subsets

- Files: the `.woff2` subsets under `web/assets/fonts/`
- Upstream: Google Noto Fonts / Google Fonts
- License: SIL Open Font License 1.1
- Purpose: local symbol and international fallback for Flutter's web renderer

The generated Flutter `assets/NOTICES` file contains package and framework license notices. Release packaging must preserve both that generated file and this notice. A final independent license/SBOM audit remains a release gate.
