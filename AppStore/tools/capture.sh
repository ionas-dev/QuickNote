#!/bin/bash
# Prepares the simulator for App Store raw captures.
#
#   capture.sh setup <path/to/Notizblock.app>   install the Release build, status bar, permissions
#   capture.sh <en|de> [light|dark] [custom]    reseed demo data for a language and relaunch
#   capture.sh shot <en|de> <NN-slug>           save the current screen to AppStore/raw/<lang>/NN-slug.png
#
# "custom" = the screenshot-8 look: serif fonts + plain list rows.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
DEVICE="${DEVICE:-iPhone 17 Pro Max}"
BUNDLE="com.openappfabric.notizblock"
SEED="$HERE/seed/.build/seed"

udid() { xcrun simctl list devices booted | grep -F "$DEVICE (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'; }
UDID="$(udid)"
[ -n "$UDID" ] || { echo "boot '$DEVICE' first: xcrun simctl boot '$DEVICE'" >&2; exit 1; }

case "${1:-}" in
  setup)
    xcrun simctl install "$UDID" "$2"
    xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
      --cellularMode active --cellularBars 4 --operatorName "" --batteryState discharging --batteryLevel 100
    xcrun simctl privacy "$UDID" grant reminders "$BUNDLE" || true
    xcrun simctl privacy "$UDID" grant calendar "$BUNDLE" || true
    echo "setup done on $UDID"
    ;;
  shot)
    lang="$2"; name="$3"
    mkdir -p "$ROOT/raw/$lang"
    xcrun simctl io "$UDID" screenshot --type=png "$ROOT/raw/$lang/$name.png" >/dev/null
    sips -g pixelWidth -g pixelHeight "$ROOT/raw/$lang/$name.png" | tail -2 | tr -s ' ' | tr '\n' ' '; echo "$lang/$name"
    ;;
  en|de)
    lang="$1"; appearance="${2:-light}"; custom="${3:-}"
    xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
    data="$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)"
    rm -rf "$data/Documents/Notes" "$data/Documents/.index" "$data/Documents/tags.json"
    "$SEED" "$lang" "$data/Documents"
    xcrun simctl ui "$UDID" appearance "$appearance"
    d() { xcrun simctl spawn "$UDID" defaults write "$BUNDLE" "$@"; }
    if [ "$custom" = "custom" ]; then
      d titleFontDesign serif; d noteFontDesign serif; d listStylePlain -bool YES; d colorScheme "$appearance"
    else
      d titleFontDesign sans; d noteFontDesign sans; d listStylePlain -bool NO; d colorScheme system
    fi
    d markdownEnabled -bool NO; d hideCompletedTodos -bool NO; d newBlocksFirst -bool YES
    if [ "$lang" = de ]; then args=(-AppleLanguages "(de)" -AppleLocale de_DE)
    else args=(-AppleLanguages "(en)" -AppleLocale en_US); fi
    xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE" "${args[@]}" >/dev/null; sleep 2
    echo "launched $lang ($appearance${custom:+, custom})"
    ;;
  *) sed -n 2,8p "$0"; exit 2 ;;
esac
