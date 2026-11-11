//
//  TagNoteView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 28.06.26.
//

import SwiftUI

struct TagNoteView: View {
    @Environment(TagStore.self) private var tagStore
    @State private var blocks: [DatedBlock] = []
    @State private var isEditing = false
    @State private var isSelectingBlocks = false
    @State private var saveTask: Task<Void, Never>? = nil
    @AppStorage(AppSettings.hideCompletedTodos) private var hideCompletedTodos: Bool

    private let initialTag: Tag

    init(tag: Tag) {
        initialTag = tag
    }

    /// Live view of the tag from the store; falls back to the passed-in value
    /// so the view keeps rendering if the tag was deleted while open.
    private var currentTag: Tag {
        tagStore.tag(id: initialTag.id) ?? initialTag
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            #if os(macOS)
            tagHeader

            GroupedBlockList(blocks: $blocks, isEditing: $isSelectingBlocks, prepareNewBlock: applyTag)
                .frame(minWidth: 500, maxWidth: 700)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
            #else
            GroupedBlockList(blocks: $blocks, isEditing: $isSelectingBlocks, prepareNewBlock: applyTag)
            #endif
        }
        .task(id: currentTag.id, loadBlocks)
        .onChange(of: blocks, scheduleSave)
        #if os(iOS)
        .adaptiveNavigationTitle(currentTag.name) { iosNavigationTitle }
        .toolbar(content: topToolbar)
        .toolbar(content: moreOptionsToolbar)
        #endif
        .sheet(isPresented: $isEditing, content: editTagSheet)
    }

    // MARK: - View components
    @ViewBuilder
    private var iosNavigationTitle: some View {
        switch currentTag.style {
        case .color(let hex):
            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .foregroundStyle(Color(hex: hex))
                    .font(.caption)
                Text(currentTag.name)
            }
        case .emoji(let emoji):
            Text("\(emoji) \(currentTag.name)")
        }
    }
    
    private var tagHeader: some View {
        HStack {
            TagMetaInformation(style: currentTag.style)
                .font(.largeTitle.bold())

            Text(currentTag.name)
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
            tagHeader
        }
    }

    private func moreOptionsToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu("More Options", systemImage: "ellipsis") {
                Button("Edit Tag", systemImage: "pencil") {
                    isEditing = true
                }
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

    private func editTagSheet() -> some View {
        TagFormSheet(existingTag: currentTag) { updatedTag in
            tagStore.update(updatedTag)
        }
    }

    // MARK: - Logic

    private func applyTag(_ dated: inout DatedBlock) {
        dated.block.tagIds = [currentTag.id]
    }

    private func loadBlocks() async {
        blocks = await NotesStore.shared.notes(with: currentTag.id).flatMap { group in
            group.blocks.map { DatedBlock(day: group.date, block: $0) }
        }
    }

    private func scheduleSave(_ oldBlocks: [DatedBlock], _ newBlocks: [DatedBlock]) {
        saveTask?.cancel()
        saveTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                try await NotesStore.shared.setTaggedBlocks(newBlocks, tagId: currentTag.id)
            } catch is CancellationError {
                // debounce cancelled — next edit will reschedule
            } catch {
                print("Save error: \(error)")
            }
        }
    }
}
