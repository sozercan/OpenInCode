# OpenInCode

Finder toolbar app that opens the current Finder folder—or the folder containing the selected file—in Visual Studio Code.

OpenInCode prefers stable Visual Studio Code and falls back to Visual Studio Code Insiders when stable is not installed.

## Requirements

- macOS 12 or newer
- Visual Studio Code or Visual Studio Code Insiders
- Xcode 26 or newer to build the current Icon Composer asset

## Install

Install the latest release from the Homebrew tap:

```sh
brew install --cask sozercan/repo/open-in-code
```

Release archives are also available from the [GitHub Releases](https://github.com/sozercan/OpenInCode/releases) page.

To build from source:

1. Clone this repository.
2. Open `Open in Code.xcodeproj` in Xcode.
3. Build the Debug configuration for local use, or select a Developer ID Application certificate before archiving Release.
4. Copy `Open in Code.app` to `/Applications`.
5. Hold Command and drag the app from `/Applications` to a Finder toolbar.
6. Click the toolbar icon while viewing a folder or selecting a file.

The first use asks for permission to control Finder. If permission was denied, enable **Open in Code → Finder** here:

- macOS 13 or newer: **System Settings → Privacy & Security → Automation**
- macOS 12: **System Preferences → Security & Privacy → Privacy → Automation**

Release archives are configured for hardened runtime and the project publisher team. Fork maintainers should override `DEVELOPMENT_TEAM` with their own team and provide a Developer ID Application certificate. Notarize public release artifacts before distribution.

## Development

Run the focused path and editor-selection tests:

```sh
./scripts/test.sh
```

Run a clean unsigned compiler verification:

```sh
xcodebuild \
  -project "Open in Code.xcodeproj" \
  -scheme "Open in Code" \
  -configuration Release \
  CODE_SIGNING_ALLOWED=NO \
  clean build
```

## Publishing a release

Pushing a `v*` tag runs `.github/workflows/release.yml`. The workflow builds a universal app, signs it, creates a GitHub release, and updates `Casks/open-in-code.rb` in [`sozercan/homebrew-repo`](https://github.com/sozercan/homebrew-repo).

Configure this required Actions secret before publishing:

- `HOMEBREW_REPO_TOKEN`: a fine-grained token with **Contents: Read and write** access to `sozercan/homebrew-repo`

Optional signing and notarization secrets follow the same convention as Kaset:

- `MACOS_CERTIFICATE`, `MACOS_CERTIFICATE_PWD`, `MACOS_KEYCHAIN_PWD`
- `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`

Without a signing certificate, the workflow uses ad-hoc signing unless `require_developer_id` is enabled for a manual run.
