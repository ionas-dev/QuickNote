#!/bin/bash
# Captures every raw App Store screen for one language, reseeding before each
# screen so nothing typed in one screen leaks into the next.
#
#   shoot.sh <en|de> [test-name …]     e.g. shoot.sh en test04Todos
# Output: AppStore/raw/<lang>/NN-slug.png (+ .txt accessibility dump for debugging)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/.."
LANG_CODE="$1"; shift
TESTS=("$@")
[ ${#TESTS[@]} -gt 0 ] || TESTS=(test01Capture test02Tags test03Calendar test04Todos test05Reminders test06Move test07Untagged test08aLight test08bDark)
DEVICE_ID="$(xcrun simctl list devices booted | grep -F "${DEVICE:-iPhone 17 Pro Max} (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
DD="${DRIVER_DERIVED_DATA:-$HERE/driver/.build}"
OUT="$ROOT/raw/$LANG_CODE"
mkdir -p "$OUT"

xcodebuild build-for-testing -project "$HERE/driver/Driver.xcodeproj" -scheme DriverUITests \
  -destination "id=$DEVICE_ID" -derivedDataPath "$DD" -quiet

for t in "${TESTS[@]}"; do
  if [ "$t" = test08bDark ]; then "$HERE/capture.sh" "$LANG_CODE" dark custom >/dev/null
  else "$HERE/capture.sh" "$LANG_CODE" light >/dev/null; fi
  if TEST_RUNNER_SHOT_DIR="$OUT" TEST_RUNNER_SHOT_LANG="$LANG_CODE" xcodebuild test-without-building \
      -project "$HERE/driver/Driver.xcodeproj" -scheme DriverUITests -destination "id=$DEVICE_ID" \
      -derivedDataPath "$DD" -only-testing:"DriverUITests/Driver/$t" > "$DD/$LANG_CODE-$t.log" 2>&1; then
    echo "ok   $LANG_CODE $t"
  else
    echo "FAIL $LANG_CODE $t (log: $DD/$LANG_CODE-$t.log)"; exit 1
  fi
done
"$HERE/capture.sh" "$LANG_CODE" light >/dev/null   # leave the simulator in a clean state
sips -g pixelWidth -g pixelHeight "$OUT"/*.png | paste - - - | awk '{print $1, $3, $5}' | sed "s|$OUT/||"
