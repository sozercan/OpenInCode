# Repository instructions

## Project at a glance

OpenInCode is a small macOS Finder toolbar utility written in Swift. It reads the selected Finder item, or the front Finder window when nothing is selected, and opens the corresponding folder in Visual Studio Code.

- Deployment target: macOS 12 or newer.
- Build system: `Open in Code.xcodeproj`; Xcode 26 or newer is required for the current Icon Composer asset.
- Swift language mode: Swift 6.
- Dependencies: Apple frameworks only; there is no package manager or dependency-install step.

## Repository map

- `main.swift`: Finder automation, user-facing errors, application lookup, and launch flow.
- `OpenInCodeCore.swift`: testable editor-priority and Finder-path logic.
- `Tests/OpenInCodeCoreTests.swift`: standalone Foundation test executable used by the test script.
- `scripts/test.sh`: canonical focused test command; also validates Homebrew cask rendering.
- `scripts/render-homebrew-cask.sh`: release cask template generator.
- `Info.plist` and `Open in Code.entitlements`: app metadata and Finder Apple Events permission.
- `Open in Code.xcodeproj`: target membership, Swift build settings, and signing.
- `.github/workflows/release.yml`: tag-driven universal build, signing, notarization, GitHub release, and Homebrew cask update.

## Working rules

1. Check `git status --short` before editing and preserve unrelated user changes.
2. Inspect only the files relevant to the task; do not search generated `build/` or `DerivedData/` content.
3. Keep changes focused. Avoid adding dependencies, new abstractions, or project files unless the task requires them.
4. Put deterministic, UI-independent behavior in `OpenInCodeCore.swift` and cover it in `Tests/OpenInCodeCoreTests.swift`.
5. When adding or removing source or resource files, keep the Xcode project references and target membership in sync.

## Behavioral invariants

Preserve these unless the requested change explicitly replaces them:

- Prefer stable VS Code (`com.microsoft.VSCode`), then VS Code Insiders (`com.microsoft.VSCodeInsiders`).
- Use the first selected Finder item; fall back to the front Finder window's target.
- Open directories directly. Open a regular file or Finder package by opening its parent directory.
- Resolve Finder aliases without UI, reject broken aliases and inaccessible or non-file URLs, and preserve directory-symlink behavior.
- Present actionable errors for Finder permission failures and missing or failed VS Code launches.
- Keep compatibility with macOS 12; guard any newer API before use.

## Swift conventions

- Match the existing Swift style and naming (`OIC` prefix for shared symbols).
- Keep the application compatible with Swift 6 language mode and macOS 12.
- Treat compiler warnings as errors in testable core code.
- Prefer small functions with explicit failure handling over silent fallback behavior.

## Validation

Run the smallest relevant checks:

- Documentation-only changes: inspect the diff; no build is required.
- Core logic, tests, or scripts:

  ```sh
  ./scripts/test.sh
  ```

- Application code, plist, entitlements, icon, or Xcode project changes: run the focused tests, then an unsigned Release build:

  ```sh
  xcodebuild \
    -project "Open in Code.xcodeproj" \
    -scheme "Open in Code" \
    -configuration Release \
    CODE_SIGNING_ALLOWED=NO \
    clean build
  ```

Do not create tags, publish releases, notarize artifacts, update the Homebrew tap, or alter signing identities, team IDs, bundle identifiers, or release secrets unless explicitly requested.

## Git and GitHub

- Do not add `[codex]` to pull request titles.
- Use Conventional Commit format for pull request titles, for example `feat: add task timeline` or `fix(api): handle empty filters`.
- Do not open pull requests as drafts unless explicitly requested.
- Sign commits with `git commit -s`.
