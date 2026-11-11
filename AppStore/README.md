# README

Everything for the App Store Connect listing (v1.0, iPhone, English + German).

## What's here

| Path                               | What                                                                                 |
| ---------------------------------- | ------------------------------------------------------------------------------------ |
| `texts/en-US.md`, `texts/de-DE.md` | Name, subtitle, promotional text, keywords, description, categories — paste verbatim |
| `final/en-US/`, `final/de-DE/`     | The 8 upload-ready screenshots per language (1320 × 2868, 6.9" display)              |
| `raw/en/`, `raw/de/`               | Plain simulator captures the finals are made from (+ `.txt` accessibility dumps)     |
| `template/shots.json`              | Headlines, accent word/colour and tilt per screenshot                                |
| `tools/`                           | The pipeline below                                                                   |

## Upload

App Store Connect → your app → version 1.0 → **iPhone 6.9" Display**:
1. English (U.S.): drag `final/en-US/01…08` in order.
2. Switch the language to German and drag `final/de-DE/01…08`.
3. Paste the text fields from `texts/`.

Smaller iPhone sizes are scaled from the 6.9" set automatically.

## Rerunning

Everything runs from the repo root with Xcode 26 and the **iPhone 17 Pro Max** simulator booted.

```bash
# 1. Check texts against Apple's limits
python3 -I AppStore/tools/check_texts.py AppStore/texts/*.md

# 2. Build the tools (seed tool compiles the app's own model/storage files)
AppStore/tools/seed/build.sh
AppStore/tools/compose/build.sh

# 3. Build the Release app for the simulator
xcodebuild -project Notizblock.xcodeproj -scheme Notizblock -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -derivedDataPath /tmp/qn-dd build
APP=/tmp/qn-dd/Build/Products/Release-iphonesimulator/Notizblock.app

# 4. Per language: set simulator language/keyboard (reboots it), then capture all screens
AppStore/tools/simlang.sh en "$APP" && AppStore/tools/shoot.sh en
AppStore/tools/simlang.sh de "$APP" && AppStore/tools/shoot.sh de

# 5. Compose the finals (takes a few minutes)
AppStore/tools/compose/.build/compose AppStore/template/shots.json AppStore/final
```

- **Change a headline:** edit `template/shots.json`, rerun step 5. The composer fails if a headline needs more than two lines.
- **Change demo notes:** edit `tools/seed/content-{en,de}.swift`, rerun steps 2, 4, 5.
- **Redo one screen:** `AppStore/tools/shoot.sh de test06Move` (test names in `tools/driver/DriverUITests/Driver.swift`).
- Demo dates are relative to the day you run it, always inside the current month.

### How the tools fit together

- `tools/seed/` writes demo notes/tags in the app's real storage format (it compiles `Notizblock/Models` + `NotesStore` unmodified).
- `tools/capture.sh` reseeds the app container, sets light/dark and the font/list settings, status bar 9:41.
- `tools/driver/` is a standalone UI-test project that drives the installed app by bundle ID (`com.openappfabric.notizblock`) and saves screenshots. It is **not** part of the app project.
- `tools/compose/` renders paper background, a New York (system serif) headline and the framed, tilted phone, and writes opaque sRGB PNGs.
