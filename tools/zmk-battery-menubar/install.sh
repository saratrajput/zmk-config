#!/usr/bin/env bash
# Build and install the app for Spotlight and the macOS app launcher.
# Usage: ./install.sh [destination folder] (default: ~/Applications)
set -euo pipefail

cd "$(dirname "$0")"
DEST_DIR="${1:-$HOME/Applications}"
APP="$DEST_DIR/ZMK Battery.app"

if [[ -e "$APP" ]]; then
    BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' \
        "$APP/Contents/Info.plist" 2>/dev/null || true)
    if [[ "$BUNDLE_ID" != "dev.local.zmk-battery-menubar" ]]; then
        echo "Refusing to overwrite an unrelated app: $APP" >&2
        exit 1
    fi
fi

bash ./build.sh
mkdir -p "$DEST_DIR"
ditto ZMKBattery.app "$APP"
"/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister" -f "$APP"

echo "Installed: $APP"
echo 'Search for "ZMK Battery" in Spotlight or the app launcher to open it.'
echo 'Quit any running copy before opening the installed app.'
