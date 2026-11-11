//
//  GroupedBlockList.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 18.07.26.
//

import SwiftUI

struct GroupedBlockList: View {

    @Environment(EventKitManager.self) private var eventKit
    @FocusState private var focusedBlock: UUID?
    /// Formatting actions published by whichever block editor has focus, so
    /// Bold/Italic can live in this list's keyboard capsule instead of a
    /// second one owned by the editor. Nil when no block is being edited.
    @FocusedValue(\.markdownCommands) private var markdownCommands
    @Binding var blocks: [DatedBlock]
    @Binding var isEditing: Bool
    @AppStorage(AppSettings.newBlocksFirst) private var newBlocksFirst: Bool
    @AppStorage(AppSettings.listStylePlain) private var listStylePlain: Bool
    @AppStorage(AppSettings.hideCompletedTodos) private var hideCompletedTodos: Bool
    @State private var selectedBlockIds: Set<UUID> = []
    @State private var isBatchTagging = false
    @State private var isBatchMoving = false

    /// Applied to a freshly created block before it is appended (e.g. to stamp
    /// the current tag in the tag view). Defaults to leaving the block as-is.
    var prepareNewBlock: (inout DatedBlock) -> Void = { _ in }

    /// Block indices bucketed by calendar day, newest day first.
    private var blocksGroupedByDay: [(day: Date, indices: [Int])] {
        let calendar = Calendar.current
        var groups: [Date: [Int]] = [:]

        for (i, dated) in blocks.enumerated()
        where !(hideCompletedTodos && dated.block.isCompletedTodo) {
            groups[calendar.startOfDay(for: dated.day), default: []].append(i)
        }

        return groups.keys.sorted(by: >).map { day in (day, groups[day]!) }
    }

    /// Scroll anchor id of the trailing spacer at the end of the block list.
    private static let bottomID = "bottom"

    var body: some View {
        ScrollViewReader { proxy in
            /// Lists and ScrollViews reduce the height of the text editor. The GeometryReader gets the full height and the BlockView is set to it and gets expanded
            GeometryReader { geo in
                if listStylePlain {
                    blockList(height: geo.size.height)
#if os(macOS)
                        .listStyle(.inset)
#else
                        .listStyle(.grouped)
#endif
                } else {
                    blockList(height: geo.size.height)
#if os(macOS)
                        .listStyle(.inset)
#else
                        .listStyle(.insetGrouped)
#endif
                }
            }
            .scrollDismissesKeyboard(.interactively)
#if os(iOS)
.environment(\.editMode, .constant(isEditing ? .active : .inactive))
.toolbar {
    if focusedBlock == nil {
        ToolbarItemGroup(placement: .bottomBar) {
            toolbarContent(scrollProxy: proxy)
        }
    }
}
.toolbar {
    ToolbarItemGroup(placement: .keyboard) {
        Spacer()

        HStack {
            if let markdownCommands {
                Button("Bold", systemImage: "bold", action: markdownCommands.toggleBold)
                    .padding(5)

                Button("Italic", systemImage: "italic", action: markdownCommands.toggleItalic)
                    .padding(5)
            }

            Button("Dismiss Keyboard", systemImage: "keyboard.chevron.compact.down") {
                focusedBlock = nil
            }
            .padding(5)

            Button("New Block", systemImage: "plus") {
                focusOrAppendNewBlock(scrollProxy: proxy)
            }
            .padding(5)
            .buttonSizing(.flexible)
        }
        .background(.bar.opacity(0.5), in: .capsule)
        .glassEffect()
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .padding(.bottom, 20)
    }
    .sharedBackgroundVisibility(.hidden)
}
#elseif os(macOS)
.toolbar {
    ToolbarItemGroup(placement: .primaryAction) {
        toolbarContent(scrollProxy: proxy)
    }
}
#endif
        }
        .sheet(isPresented: $isBatchTagging, content: batchTagSheet)
        .sheet(isPresented: $isBatchMoving, content: batchMoveSheet)
        .onChange(of: eventKit.externalChangeCount, pullReminderUpdates)
        .onChange(of: blocks, pruneHiddenSelection)
        .onChange(of: hideCompletedTodos, pruneHiddenSelection)
    }

    private var hasEmptyBlock: Bool {
        blocks.contains { $0.block.text.isEmpty }
    }

    private var visibleBlockCount: Int {
        blocks.filter { !(hideCompletedTodos && $0.block.isCompletedTodo) }.count
    }

    @ViewBuilder
    private func blockList(height: CGFloat?) -> some View {
        #if os(iOS)
        List(selection: $selectedBlockIds) {
            listContent(height: height)
        }
        #else
        List {
            listContent(height: height)
        }
        #endif
    }

    private func listContent(height: CGFloat?) -> some View {
        ForEach(blocksGroupedByDay, id: \.day) { group in
            Section(group.day.formatted(.dateTime.day().month(.wide).year())) {
                ForEach(group.indices, id: \.self) { blockIndex in
                    BlockView(block: $blocks[blockIndex].block, expandToHeight: visibleBlockCount <= 1 ? height : nil, isSelecting: isEditing, currentDate: blocks[blockIndex].day, onDelete: { deleteBlock(blocks[blockIndex]) }, onMove: { target in moveBlock(blocks[blockIndex], to: target) })
                        .focused($focusedBlock, equals: blocks[blockIndex].id)
                        .listRowBackground(rowBackground)
                        .listRowSeparator(blockIndex == group.indices.last ? .hidden : .automatic, edges: .bottom)
                        .tag(blocks[blockIndex].id)
                        #if os(iOS)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                deleteBlock(blocks[blockIndex])
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Select", systemImage: "scope") {
                                selectBlock(blocks[blockIndex])
                            }
                        }
                        #endif
                }
            }
        }
    }

    private func selectBlock(_ dated: DatedBlock) {
        isEditing = true
        selectedBlockIds = [dated.id]
    }

    private func pruneHiddenSelection() {
        guard hideCompletedTodos else { return }
        selectedBlockIds = selectedBlockIds.filter { id in
            blocks.first { $0.id == id }?.block.isCompletedTodo != true
        }
    }

    private var rowBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.secondarySystemGroupedBackground)
        #endif
    }

    @ViewBuilder
    private func toolbarContent(scrollProxy: ScrollViewProxy) -> some View {
        Spacer()

        if isEditing {
            editingToolbarContent
        } else {
            Button("New Block", systemImage: hasEmptyBlock ? "pencil" : "plus") {
                focusOrAppendNewBlock(scrollProxy: scrollProxy)
            }
            .buttonStyle(.borderedProminent)
            .buttonSizing(.flexible)
            .padding()
        }
    }

    @ViewBuilder
    private var editingToolbarContent: some View {
        Button("Delete", systemImage: "trash") {
            deleteSelectedBlocks()
        }
        .disabled(selectedBlockIds.isEmpty)
        .tint(.red)

        Button("Tag", systemImage: "tag") {
            isBatchTagging = true
        }
        .disabled(selectedBlockIds.isEmpty)

        Button("Move", systemImage: "calendar") {
            isBatchMoving = true
        }
        .disabled(selectedBlockIds.isEmpty)

        Button("Done") {
            isEditing = false
            selectedBlockIds = []
        }
    }

    private func batchTagSheet() -> some View {
        BatchTagPickerSheet(
            selectedBlocks: blocks.filter { selectedBlockIds.contains($0.id) }.map(\.block),
            onSave: handleBatchTagSave
        )
    }

    private func handleBatchTagSave(_ updatedBlocks: [Block]) {
        for updated in updatedBlocks {
            if let i = blocks.firstIndex(where: { $0.id == updated.id }) {
                blocks[i].block = updated
            }
        }
    }

    private func deleteSelectedBlocks() {
        for dated in blocks where selectedBlockIds.contains(dated.id) {
            if case .todo(let content) = dated.block.content {
                try? eventKit.deleteLinkedRemindersEntry(id: content.remindersId)
            }
        }
        blocks.removeAll { selectedBlockIds.contains($0.id) }
        selectedBlockIds = []
    }

    private func batchMoveSheet() -> some View {
        let sourceDates = Set(blocks.filter { selectedBlockIds.contains($0.id) }.map(\.day))
        return MoveToDateSheet(blockCount: selectedBlockIds.count, sourceDates: sourceDates, onMove: moveSelectedBlocks)
    }

    /// Reassigning `day` is enough: the parent view's `scheduleSave` diffs this
    /// array back into day files via `setTaggedBlocks`/`setUntaggedBlocks`,
    /// which drops the block from its old day and writes it into the new one.
    /// A direct `NotesStore` write here would race that reconciliation — it
    /// only knows about days represented in this array, so a block it wrote
    /// behind this view's back gets reconciled away as soon as the debounced
    /// save for this array fires.
    private func moveSelectedBlocks(to target: Date) {
        for i in blocks.indices where selectedBlockIds.contains(blocks[i].id) {
            blocks[i].day = target
        }
        selectedBlockIds = []
    }

    private func moveBlock(_ dated: DatedBlock, to target: Date) {
        guard let i = blocks.firstIndex(where: { $0.id == dated.id }) else { return }
        blocks[i].day = target
    }

    private func focusOrAppendNewBlock(scrollProxy: ScrollViewProxy) {
        Task {
            if let emptyBlock = blocks.first(where: { $0.block.text.isEmpty }) {
                withAnimation {
                    scrollProxy.scrollTo(emptyBlock.id, anchor: .top)
                } completion: {
                    focusedBlock = emptyBlock.id
                }
            } else {
                var newDatedBlock = DatedBlock(day: Calendar.current.startOfDay(for: .now), block: Block())
                prepareNewBlock(&newDatedBlock)
                if newBlocksFirst {
                    blocks.insert(newDatedBlock, at: 0)
                } else {
                    blocks.append(newDatedBlock)
                }

                /// BUG: Scrolling only works if the items isn't to far away but somehow for the emty block case it works most often
                withAnimation {
                    scrollProxy.scrollTo(newDatedBlock.id, anchor: .top)
                } completion: {
                    focusedBlock = newDatedBlock.id
                }

            }
        }
    }

    private func deleteBlock(_ dated: DatedBlock) {
        if case .todo(let content) = dated.block.content {
            try? eventKit.deleteLinkedRemindersEntry(id: content.remindersId)
        }
        blocks.removeAll {
            $0.id == dated.id
        }
    }

    private func pullReminderUpdates() {
        var plainBlocks = blocks.map(\.block)
        eventKit.refreshLinkedReminders(in: &plainBlocks)
        for i in blocks.indices {
            blocks[i].block = plainBlocks[i]
        }
    }
}

#Preview {
    @Previewable @State var blocks: [DatedBlock] = [
        DatedBlock(day: .now, block: Block(text: "Today")),
        DatedBlock(day: .now.addingTimeInterval(-86400), block: Block(text: "Yesterday")),
        DatedBlock(day: .now.addingTimeInterval(-86400), block: Block(text: "Yesterday2"))
    ]
    @Previewable @State var isEditing = false

    GroupedBlockList(blocks: $blocks, isEditing: $isEditing)
        .environment(EventKitManager())
        .environment(TagStore())
}
