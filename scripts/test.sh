#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$(mktemp -d "${TMPDIR:-/tmp}/OpenInCodeTests.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT

sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
architecture="$(uname -m)"

xcrun swiftc \
  -swift-version 6 \
  -warnings-as-errors \
  -target "${architecture}-apple-macos12.0" \
  -sdk "$sdk_path" \
  "$repo_root/OpenInCodeCore.swift" \
  "$repo_root/Tests/OpenInCodeCoreTests.swift" \
  -o "$build_dir/OpenInCodeCoreTests"

cask_path="$build_dir/open-in-code.rb"
"$repo_root/scripts/render-homebrew-cask.sh" \
  "1.2.3" \
  "$(printf '0%.0s' {1..64})" \
  "$cask_path"
ruby -c "$cask_path" >/dev/null
grep -q 'version "1.2.3"' "$cask_path"
grep -q 'app "Open in Code.app"' "$cask_path"

"$build_dir/OpenInCodeCoreTests"
