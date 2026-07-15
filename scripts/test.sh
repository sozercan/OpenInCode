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

"$build_dir/OpenInCodeCoreTests"
