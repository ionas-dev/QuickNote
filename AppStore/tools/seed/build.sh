#!/bin/bash
# Builds the demo-data seeder from the app's own model/storage sources (unmodified).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HERE/../../../Notizblock"
mkdir -p "$HERE/.build"
xcrun swiftc -O -parse-as-library -swift-version 5 -default-isolation MainActor \
  -enable-upcoming-feature InferIsolatedConformances -enable-upcoming-feature NonisolatedNonsendingByDefault \
  -enable-upcoming-feature InferSendableFromCaptures -enable-upcoming-feature DisableOutwardActorInference \
  -enable-upcoming-feature GlobalActorIsolatedTypesUsability -enable-upcoming-feature MemberImportVisibility \
  "$APP/Models/TextBlock.swift" \
  "$APP/Models/Tag.swift" \
  "$APP/Models/DatedBlock.swift" \
  "$APP/Services/NotesStore.swift" \
  "$APP/Services/StorageError.swift" \
  "$APP/Support/StorageRoot.swift" \
  "$APP/Support/NoteDateFormatter.swift" \
  "$HERE/Seed.swift" "$HERE/content-en.swift" "$HERE/content-de.swift" \
  -o "$HERE/.build/seed"
echo "built $HERE/.build/seed"
