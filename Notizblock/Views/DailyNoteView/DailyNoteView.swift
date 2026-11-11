//
//  DailyNoteView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 17.07.26.
//

import SwiftUI

struct DailyNoteView: View {
    
    @AppStorage(AppSettings.titleFontDesign) private var titleFontDesign: FontDesign
    @AppStorage(AppSettings.newBlocksFirst) private var newBlocksFirst: Bool
    @AppStorage(AppSettings.hideCompletedTodos) private var hideCompletedTodos: Bool

    @State var blocks: [Block] = []
    @State var isSelectingBlocks = false
    @State private var saveTask: Task<Void, Never>? = nil

    /// Suppresses saving after a failed load, so the cleared `blocks` are
    /// never written back over a file we could not read.
    @State private var loadFailed = false

    var date: Date = Date.now

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            #if os(macOS)
            dayHeader
            
            BlockList(date: date, blocks: $blocks, isEditing: $isSelectingBlocks)
                .frame(minWidth: 500, maxWidth: 700)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
            #elseif os(iOS)
            BlockList(date: date, blocks: $blocks, isEditing: $isSelectingBlocks)
            #endif
        }
        .task(id: date, loadBlocks)
        .onChange(of: blocks, scheduleSave)
        #if os(iOS)
        .navigationTitle(date.formatted(.dateTime.weekday(.wide).day().month()))
        .toolbar(content: largeTitleToolbarContent)
        .toolbar(content: navigationToolbar)
        #endif
    }

    // MARK: - View components

    private var dayHeader: some View {
        HStack {
            if isToday {
                Image(systemName: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            
            Text(date.formatted(.dateTime.weekday(.wide)))
                .font(.system(.largeTitle, design: titleFontDesign.fontDesign).weight(.bold))
            
            Text(date.formatted(.dateTime.day()))
                .font(.system(.largeTitle, design: titleFontDesign.fontDesign).weight(.bold))
            
            VStack(alignment: .leading, spacing: 0) {
                Text(date.formatted(.dateTime.month(.wide)))
                    .font(.system(.subheadline, design: titleFontDesign.fontDesign).weight(.medium))
                    .foregroundStyle(.secondary)
                
                Text(date.formatted(.dateTime.year()))
                    .font(.system(.subheadline, design: titleFontDesign.fontDesign).weight(.medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.top, 11.5)
    }

    #if os(iOS)
    @ToolbarContentBuilder
    private func navigationToolbar() -> some ToolbarContent {
        if isToday {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.calendar) {
                    Label("Calendar", systemImage: "calendar")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.tags) {
                    Label("Tags", systemImage: "tag")
                }
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu("More Options", systemImage: "ellipsis") {
                Button("Select", systemImage: "checkmark.circle") {
                    isSelectingBlocks = true
                }
                Toggle(isOn: $hideCompletedTodos) {
                    Label("Hide Completed", systemImage: "checkmark.circle.badge.xmark")
                }
                if isToday {
                    NavigationLink(value: AppRoute.settings) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
        }
    }

    private func largeTitleToolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .largeTitle) {
            dayHeader
        }
    }
    #endif
    
    
    
    
    // MARK: - Logic
    
    private func loadBlocks() {
        Task {
            do {
                let loaded = try await NotesStore.shared.load(date: date)
                loadFailed = false
                blocks = loaded
            } catch {
                // Never leave the previous day's blocks in state. On macOS this
                // view keeps its identity when only `date` changes, so day A's
                // content would otherwise sit under day B's header and the
                // first keystroke would write A into B's file.
                //
                // `loadFailed` is set *before* `blocks`, because assigning
                // `blocks` itself trips `.onChange(of: blocks, scheduleSave)`.
                loadFailed = true
                blocks = []
                print("Load error: \(error)")
            }
        }
    }

    private func scheduleSave(_ oldBlocks: [Block], _ newBlocks: [Block]) {
        guard !loadFailed else { return }
        saveTask?.cancel()
        saveTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                let toSave = newBlocks.filter { !$0.text.isEmpty }
                if toSave.isEmpty {
                    try await NotesStore.shared.delete(date: date)
                } else {
                    try await NotesStore.shared.save(toSave, date: date)
                }
            } catch is CancellationError {
                // debounce cancelled — next edit will reschedule
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}

#Preview {
    var date: Date = Date.now

    NavigationStack {
        DailyNoteView(date: date)
    }
    .environment(EventKitManager())
    .environment(TagStore())
}
