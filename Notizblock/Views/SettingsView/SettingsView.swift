//
//  SettingsView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 23.07.26.
//

import SwiftUI

enum FontDesign: String, CaseIterable {
    case sans
    case serif
    case rounded
    case monospaced

    var fontDesign: Font.Design {
        switch self {
        case .sans: return .default
        case .serif: return .serif
        case .rounded: return .rounded
        case .monospaced: return .monospaced
        }
    }
}

enum AppColorScheme: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @AppStorage(AppSettings.titleFontDesign) private var titleFontDesign: FontDesign
    @AppStorage(AppSettings.noteFontDesign) private var noteFontDesign: FontDesign
    @AppStorage(AppSettings.newBlocksFirst) private var newBlocksFirst: Bool
    @AppStorage("tagAsDefaultList") private var tagAsDefaultList: Bool = false
    @AppStorage(AppSettings.listStylePlain) private var listStylePlain: Bool
    @AppStorage(AppSettings.markdownEnabled) private var markdownEnabled: Bool
    @AppStorage(AppSettings.colorScheme) private var colorScheme: AppColorScheme


    var body: some View {
        List {
            Section("Styling") {
                Picker("Color Scheme", selection: $colorScheme) {
                    Text("System")
                        .tag(AppColorScheme.system)

                    Text("Light")
                        .tag(AppColorScheme.light)

                    Text("Dark")
                        .tag(AppColorScheme.dark)
                }

                Picker("Note List Style", selection: $listStylePlain) {
                    Text("Default")
                        .tag(false)
                    
                    Text("Plain")
                        .tag(true)
                }
                
                Picker("Title Font Design", selection: $titleFontDesign) {
                    Text("Sans")
                        .tag(FontDesign.sans)
                    
                    Text("Serif")
                        .tag(FontDesign.serif)
                    
                    Text("Rounded")
                        .tag(FontDesign.rounded)
                    
                    Text("Monospaced")
                        .tag(FontDesign.monospaced)
                }
                
                Picker("Note Font Design", selection: $noteFontDesign) {
                    Text("Sans")
                        .tag(FontDesign.sans)
                    
                    Text("Serif")
                        .tag(FontDesign.serif)
                    
                    Text("Rounded")
                        .tag(FontDesign.rounded)
                    
                    Text("Monospaced")
                        .tag(FontDesign.monospaced)
                }
            }

            Section("Notes") {
                VStack {
                    HStack {
                        Text("New Blocks Order")
                        Spacer()
                    }
                    Picker("New Blocks Order", selection: $newBlocksFirst) {
                        Text("First")
                            .tag(true)
                        Text("Last")
                            .tag(false)
                    }
                    .pickerStyle(.palette)
                }
            }
            
            Section("Reminders") {
                Toggle("Use Tag As Default List", isOn: $tagAsDefaultList)
                    .disabled(true)
            }
            
            Section("Experimental") {
                Toggle("Markdown Formatting", isOn: $markdownEnabled)
            }
        }
        .adaptiveNavigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
