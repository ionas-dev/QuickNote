//
//  UntaggedNoteView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 21.08.26.
//

import SwiftUI

/// Blocks that carry no tag at all, across every day — the complement of
/// every `TagNoteView`. Shares `GroupedBlockList` with the tag views, so
/// select/delete/batch-tag/new-block behave identically; the only
/// difference is there's no backing `Tag` to header or edit.
struct UntaggedNoteView: View {
    @State private var blocks: [DatedBlock] = []
    @State private var isSelectingBlocks = false
    @State private var saveTask: Task<Void, Never>? = nil
    @AppStorage(AppSettings.hideCompletedTodos) private var hideCompletedTodos: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            #if os(macOS)
            untaggedHeader

            GroupedBlockList(blocks: $blocks, isEditing: $isSelectingBlocks)
                .frame(minWidth: 500, maxWidth: 700)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
            #else
            GroupedBlockList(blocks: $blocks, isEditing: $isSelectingBlocks)
            #endif
        }
        .task(loadBlocks)
        .onChange(of: blocks, scheduleSave)
        #if os(iOS)
        .adaptiveNavigationTitle("Untagged") { iosNavigationTitle }
        .toolbar(content: topToolbar)
        .toolbar(content: moreOptionsToolbar)
        #endif
    }

    // MARK: - View components

    private var iosNavigationTitle: some View {
        HStack(spacing: 4) {
            Image(systemName: "tag.slash")
                .foregroundStyle(.secondary)
                .font(.caption)
            
            Text("Untagged")
        }
    }

    private var untaggedHeader: some View {
        HStack {
            Image(systemName: "tag.slash")
                .foregroundStyle(.secondary)

            Text("Untagged")
                .font(.largeTitle.bold())

            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom)
        .padding(.top, 10)
    }

    #if os(iOS)
    private func topToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .largeTitle) {
            untaggedHeader
        }
    }

    private func moreOptionsToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu("More Options", systemImage: "ellipsis") {
                Button("Select", systemImage: "checkmark.circle") {
                    isSelectingBlocks = true
                }
                Toggle(isOn: $hideCompletedTodos) {
                    Label("Hide Completed", systemImage: "checkmark.circle.badge.xmark")
                }
            }
        }
    }
    #endif

    // MARK: - Logic

    private func loadBlocks() async {
        blocks = await NotesStore.shared.untaggedNotes().flatMap { group in
            group.blocks.map { DatedBlock(day: group.date, block: $0) }
        }
    }

    private func scheduleSave(_ oldBlocks: [DatedBlock], _ newBlocks: [DatedBlock]) {
        saveTask?.cancel()
        saveTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                try await NotesStore.shared.setUntaggedBlocks(newBlocks)
            } catch is CancellationError {
                // debounce cancelled — next edit will reschedule
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}

#Preview {
    @Previewable @State var navigation = NavigationModel()
    NavigationStack(path: $navigation.path) {
        UntaggedNoteView()
    }
    .environment(navigation)
    .environment(EventKitManager())
    .environment(TagStore())
}
