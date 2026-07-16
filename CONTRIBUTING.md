# Contributing to OpenInCode

## Development requirements

- macOS 12 or newer
- Swift 6.2 or newer
- Xcode 26 or newer for the `actool` step that compiles the current Icon Composer asset
- Visual Studio Code or Visual Studio Code Insiders for end-to-end testing

OpenInCode uses Swift Package Manager and Apple frameworks only; there are no external package dependencies.

## Build and test

Clone the repository, then build the SwiftPM executable and run the focused tests:

```sh
swift build
./scripts/test.sh
```

`./scripts/test.sh` is the canonical test command. It runs the Swift tests with warnings treated as errors and validates the generated Homebrew cask.

## Build the app bundle

Assemble an unsigned Release app for verification:

```sh
OPEN_IN_CODE_SIGNING=unsigned ./scripts/build-app.sh release
```

The app is written to `.build/app/Open in Code.app`.

The packaging script applies an ad-hoc signature by default so Finder automation entitlements are available during local development. Set `OPEN_IN_CODE_SIGNING=unsigned` to skip signing. Set `ARCHES="arm64 x86_64"` when a universal app is required.

To try the local build:

1. Copy `.build/app/Open in Code.app` to `/Applications`.
2. Hold Command and drag the app from `/Applications` to a Finder toolbar.
3. Click the toolbar icon while viewing a folder or selecting a file.

## Publishing a release

Pushing a `v*` tag runs `.github/workflows/release.yml`. The workflow builds a universal app, signs it, creates a GitHub release, and updates `Casks/open-in-code.rb` in [`sozercan/homebrew-repo`](https://github.com/sozercan/homebrew-repo).

Public releases require all of these GitHub Actions secrets:

- `HOMEBREW_REPO_SSH_KEY`: the private half of a write-enabled deploy key for `sozercan/homebrew-repo`
- `MACOS_CERTIFICATE`, `MACOS_CERTIFICATE_PWD`, `MACOS_KEYCHAIN_PWD`: a Developer ID Application PKCS#12 and its temporary keychain credentials
- `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`: notarization credentials

Tag pushes and manual runs with `publish=true` fail unless Developer ID signing and notarization succeed. A manual run with `publish=false` may use ad-hoc signing for validation, but it never creates a GitHub release or updates Homebrew. Prerelease tags create GitHub prereleases but do not replace the stable Homebrew cask.

Do not create tags, publish releases, notarize artifacts, update the Homebrew tap, or change signing identities, team IDs, bundle identifiers, or release secrets as part of a normal contribution.
