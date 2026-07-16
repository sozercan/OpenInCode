#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${1:-release}"
case "$configuration" in
  debug|release) ;;
  *)
    echo "Usage: $0 [debug|release]" >&2
    exit 2
    ;;
esac

app_name="Open in Code"
product_name="OpenInCode"
bundle_id="com.sertacozercan.openincode"
build_root="$repo_root/.build/app"
app_bundle="$build_root/$app_name.app"
signing_mode="${OPEN_IN_CODE_SIGNING:-adhoc}"
marketing_version="${MARKETING_VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$repo_root/Info.plist")}"
build_number="${BUILD_NUMBER:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$repo_root/Info.plist")}"

architectures=()
if [[ -n "${ARCHES:-}" ]]; then
  IFS=' ' read -r -a architectures <<< "$ARCHES"
else
  architectures=("$(uname -m)")
fi

verify_architectures() {
  local binary="$1"
  local actual
  actual="$(lipo -archs "$binary")"

  for architecture in "${architectures[@]}"; do
    if [[ "$actual" != *"$architecture"* ]]; then
      echo "ERROR: $binary is missing $architecture (contains: $actual)" >&2
      exit 1
    fi
  done
}

build_architecture() {
  local architecture="$1"
  local scratch_path="$build_root/swiftpm/$architecture"
  local binary_directory
  local source_binary
  local staged_directory="$build_root/arch-products/$architecture"

  echo "  → Building $product_name for $architecture"
  swift build \
    --package-path "$repo_root" \
    --scratch-path "$scratch_path" \
    --configuration "$configuration" \
    --arch "$architecture" \
    --product "$product_name"

  binary_directory="$(swift build \
    --package-path "$repo_root" \
    --scratch-path "$scratch_path" \
    --configuration "$configuration" \
    --arch "$architecture" \
    --show-bin-path)"
  source_binary="$binary_directory/$product_name"

  if [[ ! -f "$source_binary" ]]; then
    echo "ERROR: SwiftPM did not produce $source_binary" >&2
    exit 1
  fi

  mkdir -p "$staged_directory"
  cp "$source_binary" "$staged_directory/$product_name"
  chmod +x "$staged_directory/$product_name"
}

install_executable() {
  local destination="$1"
  local binaries=()
  local architecture

  for architecture in "${architectures[@]}"; do
    binaries+=("$build_root/arch-products/$architecture/$product_name")
  done

  if [[ ${#binaries[@]} -eq 1 ]]; then
    cp "${binaries[0]}" "$destination"
  else
    lipo -create "${binaries[@]}" -output "$destination"
  fi
  chmod +x "$destination"
  verify_architectures "$destination"
}

compile_app_icon() {
  local resources_directory="$1"
  local partial_info_plist="$build_root/AppIconPartialInfo.plist"

  xcrun actool "$repo_root/vscode.icon" \
    --compile "$resources_directory" \
    --notices --warnings --errors \
    --output-partial-info-plist "$partial_info_plist" \
    --app-icon vscode \
    --enable-on-demand-resources NO \
    --development-region English \
    --target-device mac \
    --minimum-deployment-target 12.0 \
    --platform macosx

  [[ -f "$resources_directory/Assets.car" ]] || {
    echo "ERROR: actool did not produce Assets.car" >&2
    exit 1
  }
  [[ -f "$resources_directory/vscode.icns" ]] || {
    echo "ERROR: actool did not produce vscode.icns" >&2
    exit 1
  }
}

echo "Building $app_name ($configuration) for ${architectures[*]}"
rm -rf "$build_root"
mkdir -p "$build_root"

for architecture in "${architectures[@]}"; do
  build_architecture "$architecture"
done

mkdir -p \
  "$app_bundle/Contents/MacOS" \
  "$app_bundle/Contents/Resources/English.lproj"

install_executable "$app_bundle/Contents/MacOS/$app_name"
compile_app_icon "$app_bundle/Contents/Resources"
cp "$repo_root/English.lproj/InfoPlist.strings" \
  "$app_bundle/Contents/Resources/English.lproj/InfoPlist.strings"
cp "$repo_root/Info.plist" "$app_bundle/Contents/Info.plist"
echo -n "APPL????" > "$app_bundle/Contents/PkgInfo"

/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $bundle_id" "$app_bundle/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $marketing_version" "$app_bundle/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $build_number" "$app_bundle/Contents/Info.plist"
plutil -lint "$app_bundle/Contents/Info.plist" >/dev/null

xattr -cr "$app_bundle" 2>/dev/null || true
find "$app_bundle" -name '._*' -delete 2>/dev/null || true

case "$signing_mode" in
  unsigned|none)
    echo "Leaving app unsigned"
    ;;
  adhoc)
    echo "Applying ad-hoc signature"
    codesign --force --options runtime --timestamp=none \
      --entitlements "$repo_root/Open in Code.entitlements" \
      --sign - "$app_bundle"
    codesign --verify --deep --strict --verbose=2 "$app_bundle"
    ;;
  *)
    echo "ERROR: OPEN_IN_CODE_SIGNING must be 'adhoc' or 'unsigned'" >&2
    exit 2
    ;;
esac

echo "Built $app_bundle"
echo "Architectures: $(lipo -archs "$app_bundle/Contents/MacOS/$app_name")"
echo "Version: $marketing_version ($build_number)"
