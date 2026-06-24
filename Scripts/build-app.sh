#!/bin/sh
set -eu

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$PWD/.build/clang-module-cache}"

xcrun swift build \
  --build-system xcode \
  --disable-sandbox \
  --cache-path .build/swiftpm-cache \
  --config-path .build/swiftpm-config \
  --security-path .build/swiftpm-security

app=".build/Launch.app"
binary=".build/apple/Products/Debug/Launch"

test -x "$binary"

rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
cp Resources/MenuBarIcon.png "$app/Contents/Resources/MenuBarIcon.png"
cp Resources/AppIconColor.png "$app/Contents/Resources/AppIconColor.png"
cp Resources/AppIconMono.png "$app/Contents/Resources/AppIconMono.png"
cp "$binary" "$app/Contents/MacOS/Launch"
chmod +x "$app/Contents/MacOS/Launch"

echo "$app"
