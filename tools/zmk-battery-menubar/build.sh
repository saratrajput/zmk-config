#!/usr/bin/env bash
# Builds ZMKBattery.app.
#
# Uses swiftc directly rather than SwiftPM so it works with only the Command Line Tools
# installed (SwiftPM wants a full Xcode for the macOS platform path).
#
# The .app bundle is not optional: CoreBluetooth refuses to run without an Info.plist
# carrying NSBluetoothAlwaysUsageDescription, and the ad-hoc signature is what lets macOS
# remember the Bluetooth permission across launches instead of re-prompting every time.
set -euo pipefail

cd "$(dirname "$0")"

APP="ZMKBattery.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp Resources/Info.plist "$APP/Contents/Info.plist"

swiftc -O -target "$(uname -m)-apple-macos12" \
    Sources/ZMKBattery/*.swift \
    -o "$APP/Contents/MacOS/ZMKBattery"

codesign --force --sign - "$APP"

echo "Built $(pwd)/$APP"
echo "Run it with:  open $APP"
