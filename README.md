# OpenInCode

Finder toolbar app that opens the current Finder folder—or the folder containing the selected file—in Visual Studio Code.

OpenInCode prefers stable Visual Studio Code and falls back to Visual Studio Code Insiders when stable is not installed.

## Requirements

- macOS 12 or newer
- Visual Studio Code or Visual Studio Code Insiders
- Xcode 26 or newer to build the current Icon Composer asset

## Build and install

The legacy v1.0 binaries and Homebrew cask are no longer maintained. Build the current version from source:

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
