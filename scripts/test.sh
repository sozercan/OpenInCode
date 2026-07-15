#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$(mktemp -d "${TMPDIR:-/tmp}/OpenInCodeTests.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT

xcrun clang \
  -fno-objc-arc \
  -Wall \
  -Wextra \
  -Werror \
  -framework Foundation \
  -I"$repo_root" \
  "$repo_root/OpenInCodeCore.m" \
  "$repo_root/Tests/OpenInCodeCoreTests.m" \
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
