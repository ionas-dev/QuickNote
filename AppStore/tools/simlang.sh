#!/bin/bash
# Sets the simulator's system language, region and keyboard (so the keyboard in
# screenshot 1 matches the screenshot language), reboots it, and re-applies the
# status bar / permission setup.
#   simlang.sh <en|de> <path/to/Notizblock.app>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEVICE="${DEVICE:-iPhone 17 Pro Max}"
UDID="$(xcrun simctl list devices | grep -F "$DEVICE (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
case "$1" in
  en) langs="en"; locale="en_US"; kb="en_US@sw=QWERTY;hw=Automatic" ;;
  de) langs="de"; locale="de_DE"; kb="de_DE@sw=QWERTZ-German;hw=Automatic" ;;
  *) echo "usage: simlang.sh <en|de> <app>"; exit 2 ;;
esac
g() { xcrun simctl spawn "$UDID" defaults write -g "$@"; }
xcrun simctl bootstatus "$UDID" -b >/dev/null
g AppleLanguages -array "$langs"
g AppleLocale -string "$locale"
g AppleKeyboards -array "$kb" "emoji@sw=Emoji"
g AppleKeyboardsExpanded -int 1
# The keyboard shown is the last-used one, kept separately from the enabled list.
k() { xcrun simctl spawn "$UDID" defaults write com.apple.keyboard.preferences "$@"; }
k KeyboardLastUsed -string "$kb"
k KeyboardsCurrentAndNext -array "$kb" "$kb"
xcrun simctl shutdown "$UDID"
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b >/dev/null
"$HERE/capture.sh" setup "$2"
echo "simulator language: $1"
