//
//  MainView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 13.07.26.
//

import SwiftUI


struct BlockList: View {

    @Environment(EventKitManager.self) private var eventKit
    @FocusState private var focusedBlock: UUID?
    /// Formatting actions published by whichever block editor has focus, so
    /// Bold/Italic can live in this list's keyboard capsule instead of a
    /// second one owned by the editor. Nil when no block is being edited.
    @FocusedValue(\.markdownCommands) private var markdownCommands
    var date: Date
    @Binding var blocks: [Block]
    @Binding var isEditing: Bool
    @AppStorage(AppSettings.newBlocksFirst) private var newBlocksFirst: Bool
    @AppStorage(AppSettings.listStylePlain) private var listStylePlain: Bool
    @AppStorage(AppSettings.hideCompletedTodos) private var hideCompletedTodos: Bool
    @State private var selectedBlockIds: Set<UUID> = []
    @State private var isBatchTagging = false
    @State private var isBatchMoving = false

    /// Scroll anchor id of the trailing spacer at the end of the block list.
    private static let bottomID = "bottom"

    var body: some View {
        ScrollViewReader { proxy in
            /// Lists and ScrollViews reduce the height of the text editor. The GeometryReader gets the full height and the BlockView is set to it and gets expanded
            GeometryReader { geo in
                if listStylePlain {
                    blockList(height: geo.size.height)
                        .listStyle(.plain)
                } else {
                    blockList(height: geo.size.height)
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
        ForEach($blocks, id: \.id) { $block in
            if !(hideCompletedTodos && block.isCompletedTodo) {
                BlockView(block: $block, expandToHeight: expandToHeight(block, height: height), isSelecting: isEditing, currentDate: date, onDelete: { deleteBlock(block) }, onMove: { target in moveBlock(block, to: target) })
                    .focused($focusedBlock, equals: block.id)
                    .tag(block.id)
                    .listRowBackground(rowBackground)
                    .listRowSeparator(block.id == visibleBlocks.last?.id ? .hidden : .automatic, edges: .bottom)
                    #if os(iOS)
                    .swipeActions(edge: .trailing) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            deleteBlock(block)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button("Select", systemImage: "scope") {
                            selectBlock(block)
                        }
                    }
                    #endif
            }
        }
    }


    private func selectBlock(_ block: Block) {
        isEditing = true
        selectedBlockIds = [block.id]
    }

    private func pruneHiddenSelection() {
        guard hideCompletedTodos else { return }
        selectedBlockIds = selectedBlockIds.filter { id in
            blocks.first { $0.id == id }?.isCompletedTodo != true
        }
    }

    private var rowBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        listStylePlain ? Color(.systemBackground) : Color(.secondarySystemGroupedBackground)
        #endif
    }

    private var hasEmptyBlock: Bool {
        blocks.contains { $0.text.isEmpty }
    }

    private var visibleBlocks: [Block] {
        blocks.filter { !(hideCompletedTodos && $0.isCompletedTodo) }
    }

    private func expandToHeight(_ block: Block, height: CGFloat?) -> CGFloat? {
        if newBlocksFirst {
            return visibleBlocks.count <= 1 ? height : nil
        }
        return block.id == visibleBlocks.last?.id ? height : nil
    }

    @ViewBuilder
    private func newBlockButton(scrollProxy: ScrollViewProxy) -> some View {
        Button("New Block", systemImage: hasEmptyBlock ? "pencil" : "plus") {
            focusOrAppendNewBlock(scrollProxy: scrollProxy)
        }
    }

    @ViewBuilder
    private func toolbarContent(scrollProxy: ScrollViewProxy) -> some View {
        Spacer()

        if isEditing {
            editingToolbarContent
        } else {
            newBlockButton(scrollProxy: scrollProxy)
                .buttonStyle(.borderedProminent)
                .buttonSizing(.flexible)
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
            selectedBlocks: blocks.filter { selectedBlockIds.contains($0.id) },
            onSave: handleBatchTagSave
        )
    }

    private func handleBatchTagSave(_ updatedBlocks: [Block]) {
        for updated in updatedBlocks {
            if let i = blocks.firstIndex(where: { $0.id == updated.id }) {
                blocks[i] = updated
            }
        }
    }

    private func deleteSelectedBlocks() {
        for block in blocks where selectedBlockIds.contains(block.id) {
            if case .todo(let content) = block.content {
                try? eventKit.deleteLinkedRemindersEntry(id: content.remindersId)
            }
        }
        blocks.removeAll { selectedBlockIds.contains($0.id) }
        selectedBlockIds = []
    }

    private func batchMoveSheet() -> some View {
        MoveToDateSheet(blockCount: selectedBlockIds.count, sourceDates: [date], onMove: moveSelectedBlocks)
    }

    private func moveSelectedBlocks(to target: Date) {
        guard !Calendar.current.isDate(target, inSameDayAs: date) else { return }
        let moved = blocks.filter { selectedBlockIds.contains($0.id) }
        blocks.removeAll { selectedBlockIds.contains($0.id) }
        selectedBlockIds = []
        Task {
            try? await NotesStore.shared.appendBlocks(moved, to: target)
        }
    }

    private func moveBlock(_ block: Block, to target: Date) {
        guard !Calendar.current.isDate(target, inSameDayAs: date) else { return }
        blocks.removeAll { $0.id == block.id }
        Task {
            try? await NotesStore.shared.appendBlocks([block], to: target)
        }
    }

    private func focusOrAppendNewBlock(scrollProxy: ScrollViewProxy) {
        Task {
            if let emptyBlock = blocks.first(where: { $0.text.isEmpty }) {
                withAnimation {
                    scrollProxy.scrollTo(emptyBlock.id, anchor: .top)
                } completion: {
                    focusedBlock = emptyBlock.id
                }
            } else {
                appendNewBlock(scrollProxy: scrollProxy)
            }
        }
    }

    private func appendNewBlock(scrollProxy: ScrollViewProxy) {
        let newTextBlock = Block()
        if newBlocksFirst {
            blocks.insert(newTextBlock, at: 0)
        } else {
            blocks.append(newTextBlock)
        }
        /// BUG: Scrolling only works if the items isn't to far away but somehow for the emty block case it works most often
        withAnimation {
            scrollProxy.scrollTo(newTextBlock.id, anchor: .top)
        } completion: {
            focusedBlock = newTextBlock.id
        }
    }

    private func deleteBlock(_ block: Block) {
        if case .todo(let content) = block.content {
            try? eventKit.deleteLinkedRemindersEntry(id: content.remindersId)
        }
        blocks.removeAll {
            $0.id == block.id
        }
    }

    private func pullReminderUpdates() {
        eventKit.refreshLinkedReminders(in: &blocks)
    }
}

#Preview {
    @Previewable @State var blocks: [Block] = [Block()]
    @Previewable @State var isEditing = false

    BlockList(date: .now, blocks: $blocks, isEditing: $isEditing)
        .environment(EventKitManager())
        .environment(TagStore())
}
