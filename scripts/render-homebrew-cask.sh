#!/bin/bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  echo "Usage: $0 <version> <sha256> [output-file]" >&2
  exit 2
fi

version="$1"
sha256="$2"
output="${3:-/dev/stdout}"

if [[ ! "$version" =~ ^[0-9]+([.][0-9]+)*([.-][0-9A-Za-z.-]+)?$ ]]; then
  echo "Invalid version: $version" >&2
  exit 2
fi

if [[ ! "$sha256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Invalid SHA-256: $sha256" >&2
  exit 2
fi

if [ "$output" != "/dev/stdout" ]; then
  mkdir -p "$(dirname "$output")"
fi

cat > "$output" <<CASK
cask "open-in-code" do
  version "$version"
  sha256 "$sha256"

  url "https://github.com/sozercan/OpenInCode/releases/download/v#{version}/OpenInCode-v#{version}.zip"
  name "Open in Code"
  desc "Open the current Finder folder in Visual Studio Code"
  homepage "https://github.com/sozercan/OpenInCode"

  depends_on macos: :monterey

  app "Open in Code.app"

  zap trash: [
    "~/Library/Preferences/com.sertacozercan.openincode.plist",
    "~/Library/Saved Application State/com.sertacozercan.openincode.savedState",
  ]
end
CASK
