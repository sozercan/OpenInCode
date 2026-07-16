# Repository instructions

## Project at a glance

OpenInCode is a small macOS Finder toolbar utility written in Swift. It reads the selected Finder item, or the front Finder window when nothing is selected, and opens the corresponding folder in Visual Studio Code.

- Deployment target: macOS 12 or newer.
- Build system: Swift Package Manager via `Package.swift`; Xcode 26 or newer is required only for `actool` to compile the current Icon Composer asset when packaging the app.
- Swift language mode: Swift 6.
- Dependencies: Apple frameworks only; SwiftPM resolves no external packages.

## Repository map

- `Package.swift`: SwiftPM executable and test target definitions.
- `Sources/OpenInCode/OpenInCodeApplication.swift`: Finder automation, user-facing errors, application lookup, and launch flow.
- `Sources/OpenInCode/OpenInCodeCore.swift`: testable editor-priority and Finder-path logic.
- `Tests/OpenInCodeTests/OpenInCodeCoreTests.swift`: XCTest coverage for editor priority and Finder paths.
- `scripts/test.sh`: canonical focused test command; runs `swift test` and validates Homebrew cask rendering.
- `scripts/build-app.sh`: builds thin SwiftPM executables, creates a universal binary when requested, compiles the icon, assembles the app bundle, and optionally ad-hoc signs it.
- `scripts/render-homebrew-cask.sh`: release cask template generator.
- `Info.plist` and `Open in Code.entitlements`: app metadata and Finder Apple Events permission.
- `.github/workflows/release.yml`: tag-driven universal build, signing, notarization, GitHub release, and Homebrew cask update.

## Working rules

1. Check `git status --short` before editing and preserve unrelated user changes.
2. Inspect only the files relevant to the task; do not search generated `.build/`, `build/`, or `DerivedData/` content.
3. Keep changes focused. Avoid adding dependencies, new abstractions, or project files unless the task requires them.
4. Put deterministic, UI-independent behavior in `Sources/OpenInCode/OpenInCodeCore.swift` and cover it in `Tests/OpenInCodeTests/OpenInCodeCoreTests.swift`.
5. Keep SwiftPM target definitions, source layout, and packaging inputs in sync when adding or removing source or resource files.

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

- Application code, package manifest, plist, entitlements, icon, or packaging changes: run the focused tests, then assemble an unsigned Release app:

  ```sh
  OPEN_IN_CODE_SIGNING=unsigned ./scripts/build-app.sh release
  ```

Do not create tags, publish releases, notarize artifacts, update the Homebrew tap, or alter signing identities, team IDs, bundle identifiers, or release secrets unless explicitly requested.

## Git and GitHub

- Do not add `[codex]` to pull request titles.
- Use Conventional Commit format for pull request titles, for example `feat: add task timeline` or `fix(api): handle empty filters`.
- Do not open pull requests as drafts unless explicitly requested.
- Sign commits with `git commit -s`.
