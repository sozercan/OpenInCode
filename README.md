# OpenInCode

Finder toolbar app that opens the current Finder folder—or the folder containing the selected file—in Visual Studio Code.

OpenInCode prefers stable Visual Studio Code and falls back to Visual Studio Code Insiders when stable is not installed.

## Requirements

- macOS 12 or newer
- Visual Studio Code or Visual Studio Code Insiders
- Swift 6.2 or newer
- Xcode 26 or newer for the `actool` step that compiles the current Icon Composer asset

## Install

Install the latest release from the Homebrew tap:

```sh
brew install --cask sozercan/repo/open-in-code
```

Release archives are also available from the [GitHub Releases](https://github.com/sozercan/OpenInCode/releases) page.

To build from source:

1. Clone this repository.
2. Run `./scripts/build-app.sh release`. The script uses SwiftPM and creates `.build/app/Open in Code.app`.
3. Copy `Open in Code.app` to `/Applications`.
4. Hold Command and drag the app from `/Applications` to a Finder toolbar.
5. Click the toolbar icon while viewing a folder or selecting a file.

The first use asks for permission to control Finder. If permission was denied, enable **Open in Code → Finder** here:

- macOS 13 or newer: **System Settings → Privacy & Security → Automation**
- macOS 12: **System Preferences → Security & Privacy → Privacy → Automation**

The local packaging script applies an ad-hoc signature by default so Finder automation entitlements are available during development. Public release artifacts should be signed with a Developer ID Application certificate and notarized before distribution.

## Development

Build the SwiftPM executable and run the focused path and editor-selection tests:

```sh
swift build
./scripts/test.sh
```

Assemble an unsigned Release app bundle for verification:

```sh
OPEN_IN_CODE_SIGNING=unsigned ./scripts/build-app.sh release
```

Set `ARCHES="arm64 x86_64"` when a universal app is required.

## Publishing a release

Pushing a `v*` tag runs `.github/workflows/release.yml`. The workflow builds a universal app, signs it, creates a GitHub release, and updates `Casks/open-in-code.rb` in [`sozercan/homebrew-repo`](https://github.com/sozercan/homebrew-repo).

Public releases require all of these Actions secrets:

- `HOMEBREW_REPO_SSH_KEY`: the private half of a write-enabled deploy key for `sozercan/homebrew-repo`
- `MACOS_CERTIFICATE`, `MACOS_CERTIFICATE_PWD`, `MACOS_KEYCHAIN_PWD`: a Developer ID Application PKCS#12 and its temporary keychain credentials
- `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`: notarization credentials

Tag pushes and manual runs with `publish=true` fail unless Developer ID signing and notarization succeed. A manual run with `publish=false` may use ad-hoc signing for validation, but it never creates a GitHub release or updates Homebrew. Prerelease tags create GitHub prereleases but do not replace the stable Homebrew cask.
