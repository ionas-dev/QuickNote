#!/bin/bash
# Builds the screenshot composer (macOS, SwiftUI ImageRenderer).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$HERE/.build"
xcrun swiftc -O -parse-as-library -swift-version 5 "$HERE/Compose.swift" -o "$HERE/.build/compose"
echo "built $HERE/.build/compose"
