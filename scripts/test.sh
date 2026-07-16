#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$(mktemp -d "${TMPDIR:-/tmp}/OpenInCodeTests.XXXXXX")"
trap 'rm -rf "$build_dir"' EXIT

swift test \
  --package-path "$repo_root" \
  --scratch-path "$build_dir/swiftpm" \
  -Xswiftc -warnings-as-errors

cask_path="$build_dir/open-in-code.rb"
"$repo_root/scripts/render-homebrew-cask.sh" \
  "1.2.3" \
  "$(printf '0%.0s' {1..64})" \
  "$cask_path"
ruby -c "$cask_path" >/dev/null
grep -q 'version "1.2.3"' "$cask_path"
grep -q 'app "Open in Code.app"' "$cask_path"
