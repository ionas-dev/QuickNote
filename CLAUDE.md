# CLAUDE

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Notizblock** is an iOS/iPadOS/visionOS note-taking app built with SwiftUI. It targets iOS 26.2+ and is written in Swift 6.

## Building & Running

Build and run via Xcode — open `Notizblock.xcodeproj`. There is no CLI build script yet.

To build from the command line:
```
xcodebuild -project Notizblock.xcodeproj -scheme Notizblock -destination 'platform=iOS Simulator,name=iPhone 16' build
```

To run tests (once tests exist):
```
xcodebuild -project Notizblock.xcodeproj -scheme Notizblock -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Architecture

A daily-notes app: one note per day, made of text blocks that can be tagged and linked to Calendar events or Reminders via EventKit. Files are organized by layer; the Xcode project uses filesystem-synchronized groups, so new files/folders on disk are picked up automatically — never edit `project.pbxproj` to add files.

- `Notizblock/App/` — `NotizblockApp.swift` (`@main`, single `NavigationStack`), `Navigation.swift` (`AppRoute` + `NavigationModel`, value-based routing)
- `Notizblock/Models/` — `TextBlock` (+ `BlockLinkType`), `Tag` (+ `TagStyle`), `BlockMeta`
- `Notizblock/Services/` — `NotesStorage` (actor; JSON files per day in Documents, plus per-tag folders and `tags.json`), `EventKitManager` (`@Observable`; EKEventStore access, linked-entry sync)
- `Notizblock/Views/DailyNote/` — `DailyNoteView` (root view; blocks list, toolbars, sheets/dialogs) and its row subviews (`TextBlockRow`, `BlockAccentBar`, `BlockMetaView`, `BlockPreview`)
- `Notizblock/Views/Calendar/`, `Views/Tags/`, `Views/EventKit/` — month calendar, tag management/pickers, event/reminder edit sheets
- `Notizblock/Support/` — shared helpers (`Color+Hex`, `NoteDate` formatter, styling constants)
- `Notizblock/Assets.xcassets` — app icon and accent color

Conventions: small single-purpose view structs, one per file; toolbars and modifier clusters as `private` functions/computed properties on the owning view; nontrivial sheet/dialog closures moved into named private methods.
