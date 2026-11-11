import XCTest

/// Drives the installed QuickNote Release build to each App Store screen and
/// saves a full-resolution screenshot. Not part of the app project.
///
/// Env (pass as TEST_RUNNER_SHOT_DIR / TEST_RUNNER_SHOT_LANG to xcodebuild):
///   SHOT_DIR   absolute output directory, e.g. AppStore/raw/en
///   SHOT_LANG  en | de
/// Demo data and appearance are prepared beforehand by capture.sh.
final class Driver: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.openappfabric.notizblock")
    var lang: String { ProcessInfo.processInfo.environment["SHOT_LANG"] ?? "en" }
    var dir: String { ProcessInfo.processInfo.environment["SHOT_DIR"] ?? NSTemporaryDirectory() }

    /// UI strings and demo-note prefixes per language.
    func t(_ key: String) -> String {
        let en: [String: String] = [
            "tag": "Tag...", "remind": "Remind Me", "move": "Move to Date...",
            "calendar": "Calendar", "tags": "Tags", "newBlock": "New Block", "untagged": "Untagged",
            "typed": "Ask Sam for the", "weekend": "Weekend at the coast", "flat": "Flat viewing",
            "podcast": "Podcast tip", "homeTag": "Home", "travelTag": "Travel",
        ]
        let de: [String: String] = [
            "tag": "Taggen …", "remind": "Erinnere mich", "move": "An Datum verschieben …",
            "calendar": "Kalender", "tags": "Tags", "newBlock": "Neuer Block", "untagged": "Ohne Tag",
            "typed": "Sam nach dem", "weekend": "Wochenende an der Ostsee", "flat": "Wohnungsbesichtigung",
            "podcast": "Podcast-Tipp", "homeTag": "Zuhause", "travelTag": "Reisen",
        ]
        return (lang == "de" ? de : en)[key]!
    }

    override func setUp() {
        continueAfterFailure = false
        app.terminate()
        app.launchArguments = lang == "de"
            ? ["-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
            : ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 10))
        sleep(1)
    }

    // MARK: helpers

    func snap(_ name: String, settle: UInt32 = 2) {
        sleep(settle)
        let png = XCUIScreen.main.screenshot().pngRepresentation
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        XCTAssertNoThrow(try png.write(to: url))
        try? app.debugDescription.write(to: url.deletingPathExtension().appendingPathExtension("txt"),
                                        atomically: true, encoding: .utf8)
    }

    func cell(startingWith prefix: String) -> XCUIElement {
        let tv = app.textViews.matching(NSPredicate(format: "value BEGINSWITH %@", prefix)).firstMatch
        XCTAssertTrue(tv.waitForExistence(timeout: 5), "no block starting with \(prefix)")
        return tv
    }

    func openMenu(on prefix: String, item: String) {
        cell(startingWith: prefix).press(forDuration: 1.2)
        let button = app.buttons[t(item)]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "no menu item \(t(item))")
        button.tap()
    }

    func tap(_ label: String) {
        let b = app.buttons[label].firstMatch
        XCTAssertTrue(b.waitForExistence(timeout: 5), "no button \(label)")
        b.tap()
    }

    /// Taps `day` inside the current month's grid (the calendar also shows
    /// neighbouring months, so the first "9" may belong to the previous one).
    func tapCalendarDay(_ date: Date) {
        let f = DateFormatter()
        f.locale = Locale(identifier: lang == "de" ? "de_DE" : "en_US")
        f.dateFormat = "LLLL"
        let month = f.string(from: date)   // DE shows the short form ("Nov") when space is tight
        let header = app.staticTexts.matching(NSPredicate(format: "label == %@ OR label == %@",
                                                          month, String(month.prefix(3)))).firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 5), "no month header")
        let day = "\(Calendar.current.component(.day, from: date))"
        let candidates = app.buttons.matching(NSPredicate(format: "label == %@", day)).allElementsBoundByIndex
            .filter { $0.frame.minY > header.frame.maxY }
            .sorted { $0.frame.minY < $1.frame.minY }
        XCTAssertFalse(candidates.isEmpty, "no day \(day) in current month")
        candidates[0].tap()
    }

    /// The simulator reopens its last-used keyboard; cycle with the globe key
    /// until the German layout (umlaut keys) is up.
    func switchToGermanKeyboard() {
        for _ in 0..<4 {
            if app.keys["ü"].exists || app.keys["Ü"].exists { return }
            let globe = app.buttons.matching(NSPredicate(
                format: "label IN %@", ["Nächste Tastatur", "Next keyboard"])).firstMatch
            guard globe.waitForExistence(timeout: 2) else { break }
            globe.tap()
            sleep(1)
        }
        XCTAssertTrue(app.keys["ü"].exists || app.keys["Ü"].exists, "German keyboard not reachable")
    }

    // MARK: screens (spec lineup)

    func test01Capture() {
        tap(t("newBlock"))
        sleep(1)
        // One-time keyboard tip ("Type English and German …") covers the keyboard.
        let tip = app.buttons["Continue"].firstMatch
        if tip.waitForExistence(timeout: 2) { tip.tap(); sleep(1) }
        let tipDE = app.buttons["Fortfahren"].firstMatch
        if tipDE.exists { tipDE.tap(); sleep(1) }
        if lang == "de" { switchToGermanKeyboard() }
        app.typeText(t("typed"))
        snap("01-capture")
    }

    func test02Tags() {
        openMenu(on: t("weekend"), item: "tag")
        let travel = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", t("travelTag"))).firstMatch
        XCTAssertTrue(travel.waitForExistence(timeout: 5))
        travel.tap()
        snap("02-tags")
    }

    func test03Calendar() {
        tap(t("calendar"))
        snap("03-calendar")
    }

    func test04Todos() {
        tap(t("calendar"))
        sleep(1)
        tapCalendarDay(Date().addingTimeInterval(-86_400))
        snap("04-todos")
    }

    func test05Reminders() {
        // The open block menu with "Remind Me" — the reminder sheet itself would show
        // the simulator's system-language list name ("Erinnerungen") in EN.
        cell(startingWith: t("flat")).press(forDuration: 1.2)
        XCTAssertTrue(app.buttons[t("remind")].waitForExistence(timeout: 5))
        snap("05-reminders")
    }

    func test06Move() {
        openMenu(on: t("podcast"), item: "move")
        snap("06-move")
    }

    func test07Untagged() {
        tap(t("tags"))
        sleep(1)
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", t("untagged"))).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        snap("07-untagged")
    }

    func test08aLight() {
        tap(t("tags"))
        sleep(1)
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", t("homeTag"))).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        snap("08a-light")
    }

    /// Run after `capture.sh <lang> dark custom`.
    func test08bDark() {
        snap("08b-dark")
    }
}
