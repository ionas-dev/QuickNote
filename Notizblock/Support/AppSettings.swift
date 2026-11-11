import SwiftUI

/// A user setting's storage key paired with its default, so the default is
/// written once instead of at every `@AppStorage` call site. Before this,
/// `newBlocksFirst` defaulted to `true` in DailyNoteView/SettingsView and
/// `false` in BlockList/GroupedBlockList, so the UI disagreed with itself
/// until the user visited Settings.
struct Setting<Value> {
    let key: String
    let defaultValue: Value
}

enum AppSettings {
    static let markdownEnabled = Setting(key: "markdownEnabled", defaultValue: false)
    static let newBlocksFirst = Setting(key: "newBlocksFirst", defaultValue: true)
    static let listStylePlain = Setting(key: "listStylePlain", defaultValue: false)
    static let hideCompletedTodos = Setting(key: "hideCompletedTodos", defaultValue: false)
    static let titleFontDesign = Setting(key: "titleFontDesign", defaultValue: FontDesign.sans)
    static let noteFontDesign = Setting(key: "noteFontDesign", defaultValue: FontDesign.sans)
    static let colorScheme = Setting(key: "colorScheme", defaultValue: AppColorScheme.system)
}

extension AppStorage where Value == Bool {
    init(_ setting: Setting<Bool>) {
        self.init(wrappedValue: setting.defaultValue, setting.key)
    }
}

extension AppStorage where Value: RawRepresentable, Value.RawValue == String {
    init(_ setting: Setting<Value>) {
        self.init(wrappedValue: setting.defaultValue, setting.key)
    }
}
