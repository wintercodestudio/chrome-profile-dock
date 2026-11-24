#!/bin/bash
# Chrome Profile Dock: one Dock icon per Google Chrome profile.
# Clicking an icon brings that profile's window to the front, or opens the profile if it has no window.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  --list             Show the Chrome profiles found and exit.
  --yes              Do not ask for confirmation.
  --dest DIR         Where to put the apps (default: ~/Applications).
  --rebuild-helper   Rebuild the helper app. You will need to grant its permissions again.
  -h, --help         Show this help.
EOF
}

DEST="$HOME/Applications"
YES=0
LIST=0
REBUILD_HELPER=0
while [ $# -gt 0 ]; do
  case "$1" in
    --list) LIST=1 ;;
    --yes) YES=1 ;;
    --dest) DEST="$2"; shift ;;
    --rebuild-helper) REBUILD_HELPER=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

HERE="$(cd "$(dirname "$0")" && pwd)"
CHROME_APP="/Applications/Google Chrome.app"
CHROME_DATA="$HOME/Library/Application Support/Google/Chrome"
SUPPORT="$HOME/Library/Application Support/ChromeProfileDock"
HELPER="$DEST/Chrome Profile Dock.app"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
ID_PREFIX="local.chromeprofiledock"

[ -d "$CHROME_APP" ] || { echo "Google Chrome is not in /Applications." >&2; exit 1; }
[ -f "$CHROME_DATA/Local State" ] || { echo "No Chrome profiles found (missing $CHROME_DATA/Local State)." >&2; exit 1; }

PROFILES="$(osascript -l JavaScript "$HERE/lib/profiles.js" "$CHROME_DATA")"

# Dock name for a profile: the profile name without an email domain, with no characters macOS dislikes in file names.
short_name() { printf '%s' "$1" | sed -E 's/@[^ ]+$//; s#[/:]#-#g'; }
# URL-safe key: "Profile 1" -> "profile-1".
key_of() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g'; }
# osacompile re-signs its output and says so on stderr; keep real errors only.
compile() { osacompile "$@" 2> >(grep -v 'replacing existing signature' >&2); }

# AppleScript string literal body.
as_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

echo "Chrome profiles:"
while IFS=$'\t' read -r dir name pic; do
  printf '  %-12s %-32s -> %s\n' "$dir" "$name" "Chrome - $(short_name "$name").app"
done <<< "$PROFILES"
[ "$LIST" = 1 ] && exit 0

if [ "$YES" != 1 ]; then
  printf '\nCreate these apps in %s? [y/N] ' "$DEST"
  read -r answer < /dev/tty
  case "$answer" in y|Y|yes|YES) ;; *) echo "Nothing changed."; exit 0 ;; esac
fi

mkdir -p "$DEST" "$SUPPORT"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 1. Switch logic, with the profile table filled in.
table=""
while IFS=$'\t' read -r dir name pic; do
  [ -n "$table" ] && table="$table, "
  table="$table{\"$(key_of "$dir")\", \"$(as_escape "$dir")\", \"$(as_escape "$name")\"}"
done <<< "$PROFILES"
TABLE="$table" perl -pe 's/%%TABLE%%/$ENV{TABLE}/' "$HERE/lib/switch.applescript.in" > "$SUPPORT/switch.applescript"
compile -o "$SUPPORT/switch.scpt" "$SUPPORT/switch.applescript"
echo "Switch logic: $SUPPORT/switch.scpt"

# Turn a 1024 PNG into an .icns file.
make_icns() {
  local png="$1" out="$2" set="$WORK/icon.iconset" s
  rm -rf "$set"; mkdir "$set"
  for s in 16 32 128 256 512; do
    sips -z "$s" "$s" "$png" --out "$set/icon_${s}x${s}.png" >/dev/null
    sips -z $((s * 2)) $((s * 2)) "$png" --out "$set/icon_${s}x${s}@2x.png" >/dev/null
  done
  iconutil -c icns "$set" -o "$out"
}

# Give an osacompile'd app our icon and identity, then sign it (ad hoc).
finish_app() {
  local app="$1" id="$2" icns="$3" plist="$1/Contents/Info.plist"
  # Script apps ship an Assets.car icon that wins over applet.icns.
  rm -f "$app/Contents/Resources/Assets.car"
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIdentifier" "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $id" "$plist"
  cp "$icns" "$app/Contents/Resources/applet.icns"
  codesign --force --deep -s - --identifier "$id" "$app" 2>/dev/null
  touch "$app"
  "$LSREGISTER" -f "$app"
}

# Refuse to overwrite an app this tool did not make.
ours() { [ ! -e "$1" ] || /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$1/Contents/Info.plist" 2>/dev/null | grep -q "^$ID_PREFIX\."; }

# 2. Helper app: the only app that needs permissions. Kept as is on re-runs so those permissions stay.
if [ ! -d "$HELPER" ] || [ "$REBUILD_HELPER" = 1 ]; then
  ours "$HELPER" || { echo "$HELPER exists and was not made by this tool." >&2; exit 1; }
  rm -rf "$HELPER"
  compile -o "$HELPER" "$HERE/lib/helper.applescript"
  plist="$HELPER/Contents/Info.plist"
  # Name the executable so the Privacy settings list shows "Chrome Profile Dock", not "applet".
  mv "$HELPER/Contents/MacOS/applet" "$HELPER/Contents/MacOS/Chrome Profile Dock"
  /usr/libexec/PlistBuddy \
    -c "Set :CFBundleExecutable 'Chrome Profile Dock'" \
    -c "Set :CFBundleName 'Chrome Profile Dock'" \
    -c "Add :LSUIElement bool true" \
    -c "Add :CFBundleURLTypes array" \
    -c "Add :CFBundleURLTypes:0 dict" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLName string $ID_PREFIX" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" \
    -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string chromeprofile" \
    "$plist"
  finish_app "$HELPER" "$ID_PREFIX.helper" "$CHROME_APP/Contents/Resources/app.icns"
  tccutil reset Accessibility "$ID_PREFIX.helper" >/dev/null 2>&1 || true
  tccutil reset AppleEvents "$ID_PREFIX.helper" >/dev/null 2>&1 || true
  NEW_HELPER=1
  echo "Helper app: $HELPER"
else
  NEW_HELPER=0
  echo "Helper app: kept $HELPER"
fi

# 3. One Dock launcher per profile. It only opens chromeprofile://<key>, so it needs no permissions.
i=0
while IFS=$'\t' read -r dir name pic; do
  key="$(key_of "$dir")"
  app="$DEST/Chrome - $(short_name "$name").app"
  if ! ours "$app"; then echo "  skipped $app (exists, not made by this tool)"; continue; fi
  rm -rf "$app"
  compile -o "$app" -e "do shell script \"open 'chromeprofile://$key'\""
  hue="$(awk -v i="$i" 'BEGIN { printf "%.2f", (i * 0.17) - int(i * 0.17) }')"
  osascript -l JavaScript "$HERE/lib/badge.js" "$CHROME_APP/Contents/Resources/app.icns" "$pic" "$name" "$hue" "$WORK/badge.png"
  make_icns "$WORK/badge.png" "$WORK/badge.icns"
  finish_app "$app" "$ID_PREFIX.$key" "$WORK/badge.icns"
  echo "  made $app"
  i=$((i + 1))
done <<< "$PROFILES"

cat <<EOF

Done. Drag the "Chrome - ..." apps from $DEST to your Dock.
EOF
if [ "$NEW_HELPER" = 1 ]; then
  cat <<'EOF'

One-time setup, so the helper can find Chrome's windows:
  1. System Settings > Privacy & Security > Accessibility: press +, pick
     "Chrome Profile Dock" in the apps folder above, and turn it on.
  2. Click one of the Dock icons. When macOS asks whether "Chrome Profile Dock"
     may control "System Events" and "Google Chrome", choose Allow.
EOF
fi
open "$DEST"
