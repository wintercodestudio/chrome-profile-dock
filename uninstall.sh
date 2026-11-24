#!/bin/bash
# Removes every app Chrome Profile Dock made, its switch logic and its permissions. Chrome itself is untouched.
set -euo pipefail

DEST="${1:-$HOME/Applications}"
ID_PREFIX="local.chromeprofiledock"

shopt -s nullglob
for app in "$DEST"/*.app; do
  id="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app/Contents/Info.plist" 2>/dev/null || true)"
  case "$id" in
    "$ID_PREFIX".*)
      tccutil reset Accessibility "$id" >/dev/null 2>&1 || true
      tccutil reset AppleEvents "$id" >/dev/null 2>&1 || true
      rm -rf "$app"
      echo "removed $app"
      ;;
  esac
done
rm -rf "$HOME/Library/Application Support/ChromeProfileDock"
echo "Done. Remove the icons from your Dock if they are still there."
