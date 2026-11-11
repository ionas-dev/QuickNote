//
//  NotizblockApp.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 24.06.26.
//

import SwiftUI

@main
struct NotizblockApp: App {
    @State private var navigation = NavigationModel()
    @State private var eventKit = EventKitManager()
    @State private var tagStore = TagStore()
    @AppStorage(AppSettings.colorScheme) private var colorScheme: AppColorScheme

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            MacRootView()
                .environment(navigation)
                .environment(eventKit)
                .environment(tagStore)
                .preferredColorScheme(colorScheme.colorScheme)
                .task(startup)
            #else
            @Bindable var nav = navigation
            NavigationStack(path: $nav.path) {
                DailyNoteView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .calendar:
                            CalendarView()
                        case .note(let date):
                            DailyNoteView(date: date)
                        case .tags:
                            TagsView()
                        case .tagDetail(let tag):
                            TagNoteView(tag: tag)
                        case .untagged:
                            UntaggedNoteView()
                        case .settings:
                            SettingsView()
                        }
                    }
            }
            .environment(navigation)
            .environment(eventKit)
            .environment(tagStore)
            .preferredColorScheme(colorScheme.colorScheme)
            .task(startup)
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 600)
        #endif
    }

    private func startup() async {
        await tagStore.load()
    }
}
