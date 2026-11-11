//
//  LegacyDailyNoteView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 24.06.26.
//

import SwiftUI
import EventKit

//enum Focusable: Hashable {
//    case block(id: UUID)
//}
//
//struct LegacyDailyNoteView: View {
//    var date: Date = .now
//
//    @Environment(\.fontResolutionContext) var fontResolutionContext
//    @Environment(EventKitManager.self) private var eventKit
//
//    @State private var blocks: [Block] = [Block()]
//    @FocusState private var blockFocus: Focusable?
//    @State private var saveTask: Task<Void, Never>? = nil
//    @State private var textSelection = AttributedTextSelection()
//    @State private var pendingEvent: PendingEvent? = nil
//    @State private var pendingReminder: PendingReminder? = nil
//    @State private var pendingLinkAction: (() -> Void)? = nil
//    @State private var showRelinkWarning = false
//    @State private var showFormattingWarning = false
//    @AppStorage("neverShowFormattingWarning") private var neverShowFormattingWarning = false
//    @State private var isEditing = false
//    @State private var selectedBlockIds: Set<UUID> = []
//    @State private var pendingBatchReminder: PendingBatchReminder? = nil
//    @State private var isBatchTagging: Bool = false
//    @State private var showDeleteConfirmation = false
//    @State private var allTags: [Tag] = []
//    @State private var pendingTagBlock: Block? = nil
//    @State private var pendingEditTag: Tag? = nil
//
//    private var focusedBlockIndex: Int? {
//        if case .block(let id) = blockFocus {
//            return blocks.firstIndex(where: { $0.id == id })
//        }
//        return nil
//    }
//
//    /// Scroll anchor id of the trailing spacer at the end of the block list.
//    private static let bottomID = "bottom"
//
//    // MARK: - Body
//
//    var body: some View {
//        ScrollViewReader { proxy in
//            textBlockList(scrollProxy: proxy)
//                .task(loadDailyNote)
//                .onChange(of: blocks, scheduleSave)
//                .toolbar {
//                    navigationToolbar
//                    textEditorToolbar(scrollProxy: proxy)
//                    if blockFocus == nil {
//                        bottomBarToolbar(scrollProxy: proxy)
//                    }
//                }
//                .onChange(of: blockFocus, { handleTextBlockFocusChange($0, $1, scrollProxy: proxy) })
//                .onChange(of: eventKit.externalChangeCount) { _, _ in syncFromSystem() }
//        }
//        .navigationTitle(date.formatted(.dateTime.day().month(.wide).locale(.current)))
//        .sheet(item: $pendingEvent) { pending in
//            EventEditView(pending: pending, store: eventKit.store)
//        }
//        .sheet(item: $pendingReminder) { pending in
//            ReminderEditView(pending: pending)
//        }
//        .sheet(item: $pendingBatchReminder) { pending in
//            BatchReminderEditView(pending: pending)
//        }
//        .sheet(isPresented: $isBatchTagging, onDismiss: refreshTags) {
//            batchTagSheet
//        }
//        .sheet(item: $pendingEditTag) { tag in
//            TagFormSheet(existingTag: tag, onSave: handleTagEdited)
//        }
//        .sheet(item: $pendingTagBlock, onDismiss: refreshTags) { block in
//            TagPickerSheet(block: block, onSave: handleSingleTagSave)
//        }
//        .confirmationDialog(
//            "Delete \(selectedBlockIds.count) Blocks",
//            isPresented: $showDeleteConfirmation,
//            titleVisibility: .visible
//        ) {
//            deleteConfirmationButtons
//        } message: {
//            Text("Some blocks are linked to Calendar or Reminder entries. Deleting them will also remove those entries.")
//        }
//        .confirmationDialog(
//            "Entry already linked",
//            isPresented: $showRelinkWarning,
//            titleVisibility: .visible
//        ) {
//            relinkWarningButtons
//        } message: {
//            Text("This block is already linked to a Calendar or Reminder entry. Relinking will remove the existing connection.")
//        }
//        .confirmationDialog(
//            "Formatting may be lost",
//            isPresented: $showFormattingWarning,
//            titleVisibility: .visible
//        ) {
//            formattingWarningButtons
//        } message: {
//            Text("If you later edit this entry's title in Calendar or Reminders, any rich formatting in this note block will be replaced with plain text when syncing back.")
//        }
//    }
//
//    // MARK: - Block List
//
//    private func textBlockList(scrollProxy: ScrollViewProxy) -> some View {
//        List(selection: $selectedBlockIds) {
//            ForEach($blocks) { $block in
//                TextBlockRow(
//                    block: $block,
//                    textSelection: $textSelection,
//                    blockFocus: $blockFocus,
//                    allTags: allTags,
//                    isEditing: isEditing,
//                    isSelected: selectedBlockIds.contains(block.id),
//                    isOnlyBlock: blocks.count <= 1,
//                    onEditTag: { pendingEditTag = $0 },
//                    onAddToCalendar: { addToCalendar(block) },
//                    onAddToReminder: { addToReminder(block) },
//                    onOpenInCalendar: openInCalendar,
//                    onOpenInReminders: openInReminders,
//                    onTag: { pendingTagBlock = block },
//                    onDelete: { deleteBlock(block) }
//                )
//            }
//            .onMove { from, to in
//                blocks.move(fromOffsets: from, toOffset: to)
//            }
//
//            Spacer()
//                .listSectionSeparator(.hidden, edges: .bottom)
//                .id(Self.bottomID)
//        }
//        #if os(iOS)
//        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
//        #endif
//        .scrollDismissesKeyboard(.interactively)
//        .listStyle(.plain)
//    }
//
//    // MARK: - Toolbars
//
//    @ToolbarContentBuilder
//    private var navigationToolbar: some ToolbarContent {
//        ToolbarItem(placement: .topBarTrailing) {
//            NavigationLink(value: AppRoute.calendar) {
//                Label("Calendar", systemImage: "calendar")
//            }
//        }
//        ToolbarItem(placement: .topBarTrailing) {
//            NavigationLink(value: AppRoute.tags) {
//                Label("Tags", systemImage: "tag")
//            }
//        }
//    }
//
//    private func textEditorToolbar(scrollProxy: ScrollViewProxy) -> ToolbarItemGroup<some View> {
//        ToolbarItemGroup(placement: .keyboard) {
//            Button("Bold", systemImage: "bold") {
//                toggleBold()
//            }
//            Button("Italic", systemImage: "italic") {
//                toggleItalic()
//            }
//            Button("Bullet List", systemImage: "list.bullet") {
//                toggleBulletList()
//            }
//
//            Spacer()
//
//            Button("Close Keyboard", systemImage: "keyboard.chevron.compact.down") {
//                blockFocus = nil
//            }
//            Button("New Section", systemImage: "plus") {
//                appendNewBlock(scrollProxy: scrollProxy)
//            }
//        }
//    }
//
//    private func bottomBarToolbar(scrollProxy: ScrollViewProxy) -> ToolbarItemGroup<some View> {
//        ToolbarItemGroup(placement: .bottomBar) {
//            Spacer()
//
//            Button {
//                toggleEditMode()
//            } label: {
//                Label("Select", systemImage: "ellipsis")
//            }
//            .tint(isEditing ? .accentColor : nil)
//
//            if isEditing {
//                Button("Delete", systemImage: "trash") {
//                    confirmDeleteSelectedBlocks()
//                }
//                .disabled(selectedBlockIds.isEmpty)
//                .tint(.red)
//
//                Button("Tag", systemImage: "tag") {
//                    openBatchTagSheet()
//                }
//                .disabled(selectedBlockIds.isEmpty)
//
//                Button("Reminder", systemImage: "checklist") {
//                    openBatchReminderSheet()
//                }
//                .disabled(selectedBlockIds.isEmpty)
//                .padding()
//            } else {
//                Button("New Section", systemImage: "plus") {
//                    focusOrAppendNewBlock(scrollProxy: scrollProxy)
//                }
//                .buttonStyle(.borderedProminent)
//                .buttonSizing(.flexible)
//                .padding()
//            }
//        }
//    }
//
//    // MARK: - Sheets & Dialogs
//
//    private var batchTagSheet: some View {
//        let selected = blocks.filter { selectedBlockIds.contains($0.id) }
//        return BatchTagPickerSheet(selectedBlocks: selected, onSave: handleBatchTagSave)
//    }
//
//    @ViewBuilder
//    private var deleteConfirmationButtons: some View {
//        Button("Delete", role: .destructive) { deleteSelectedBlocks() }
//        Button("Cancel", role: .cancel) {}
//    }
//
//    @ViewBuilder
//    private var relinkWarningButtons: some View {
//        Button("Relink") {
//            let action = pendingLinkAction
//            pendingLinkAction = nil
//            confirmFormattingOrProceed(action)
//        }
//        Button("Cancel", role: .cancel) {
//            pendingLinkAction = nil
//        }
//    }
//
//    @ViewBuilder
//    private var formattingWarningButtons: some View {
//        Button("Continue") {
//            pendingLinkAction?()
//            pendingLinkAction = nil
//        }
//        Button("Continue & Don't show again") {
//            neverShowFormattingWarning = true
//            pendingLinkAction?()
//            pendingLinkAction = nil
//        }
//        Button("Cancel", role: .cancel) {
//            pendingLinkAction = nil
//        }
//    }
//
//    private func handleBatchTagSave(_ updatedBlocks: [Block]) {
//        for updated in updatedBlocks {
//            if let i = blocks.firstIndex(where: { $0.id == updated.id }) {
//                blocks[i] = updated
//            }
//        }
//        selectedBlockIds = []
//    }
//
//    private func handleSingleTagSave(_ updatedBlock: Block) {
//        if let i = blocks.firstIndex(where: { $0.id == updatedBlock.id }) {
//            blocks[i] = updatedBlock
//        }
//    }
//
//    private func handleTagEdited(_ updatedTag: Tag) {
//        if let idx = allTags.firstIndex(where: { $0.id == updatedTag.id }) {
//            allTags[idx] = updatedTag
//        }
//        Task { try? await NotesStorage.shared.updateTag(updatedTag) }
//    }
//
//    private func refreshTags() {
//        Task { allTags = (try? await NotesStorage.shared.loadTags()) ?? [] }
//    }
//
//    // MARK: - Text Editing
//
//    private func toggleBold() {
//        guard let focusedBlockIndex else { return }
//        blocks[focusedBlockIndex].value.transformAttributes(in: &textSelection) { container in
//            let currentFont = container.font ?? .default
//            let resolved = currentFont.resolve(in: fontResolutionContext)
//            container.font = currentFont.bold(!resolved.isBold)
//        }
//    }
//
//    private func toggleItalic() {
//        guard let focusedBlockIndex else { return }
//        blocks[focusedBlockIndex].value.transformAttributes(in: &textSelection) { container in
//            let currentFont = container.font ?? .default
//            let resolved = currentFont.resolve(in: fontResolutionContext)
//            container.font = currentFont.italic(!resolved.isItalic)
//        }
//    }
//
//    private func toggleBulletList() {
//        guard let i = focusedBlockIndex else { return }
//        var text = String(blocks[i].value.characters)
//        let lines = text.components(separatedBy: "\n")
//        let alreadyBulleted = lines.allSatisfy { $0.hasPrefix("• ") || $0.isEmpty }
//        if alreadyBulleted {
//            text = lines.map { $0.hasPrefix("• ") ? String($0.dropFirst(2)) : $0 }.joined(separator: "\n")
//        } else {
//            text = lines.map { $0.isEmpty ? $0 : "• " + $0 }.joined(separator: "\n")
//        }
//        blocks[i].value = AttributedString(text)
//    }
//
//    // MARK: - Block Actions
//
//    /// Appends an empty block and focuses it (keyboard toolbar).
//    private func appendNewBlock(scrollProxy: ScrollViewProxy) {
//        if (blocks.contains { $0.value.characters.isEmpty }) { return }
//        withAnimation {
//            scrollProxy.scrollTo(Self.bottomID, anchor: .top)
//        }
//        let newTextBlock = Block()
//        blocks.append(newTextBlock)
//        blockFocus = .block(id: newTextBlock.id)
//    }
//
//    /// Focuses the first empty block, or appends a new one (bottom bar).
//    private func focusOrAppendNewBlock(scrollProxy: ScrollViewProxy) {
//        Task {
//            if let emptyBlock = blocks.first(where: { $0.value.characters.isEmpty }) {
//                withAnimation {
//                    scrollProxy.scrollTo(emptyBlock.id, anchor: .top)
//                    blockFocus = .block(id: emptyBlock.id)
//                }
//            } else {
//                withAnimation {
//                    scrollProxy.scrollTo(Self.bottomID, anchor: .bottom)
//                }
//                let newTextBlock = Block()
//                blocks.append(newTextBlock)
//                blockFocus = .block(id: newTextBlock.id)
//            }
//        }
//    }
//
//    private func toggleEditMode() {
//        isEditing.toggle()
//        if isEditing { blockFocus = nil }
//        else { selectedBlockIds = [] }
//    }
//
//    private func deleteBlock(_ block: Block) {
//        blocks.removeAll { $0.id == block.id }
//    }
//
//    private func confirmDeleteSelectedBlocks() {
//        let hasLinked = blocks
//            .filter { selectedBlockIds.contains($0.id) }
//            .contains { $0.linkedType != .none }
//        if hasLinked {
//            showDeleteConfirmation = true
//        } else {
//            deleteSelectedBlocks()
//        }
//    }
//
//    private func deleteSelectedBlocks() {
//        for block in blocks where selectedBlockIds.contains(block.id) {
//            if block.linkedType != .none, let entryId = block.linkedEntryId {
//                try? eventKit.deleteLinkedEntry(id: entryId, type: block.linkedType)
//            }
//        }
//        blocks.removeAll { selectedBlockIds.contains($0.id) }
//        selectedBlockIds = []
//    }
//
//    private func handleTextBlockFocusChange(_ oldValue: Focusable?, _ newValue: Focusable?, scrollProxy: ScrollViewProxy) {
//        Task {
//            if case .block(let oldID) = oldValue {
//                blocks.removeAll { blocks.count > 1 && $0.id == oldID && $0.value.characters.isEmpty }
//            }
//
//            if case .block(let newID) = newValue {
//                withAnimation {
//                    scrollProxy.scrollTo(newID, anchor: .top)
//                }
//            }
//        }
//    }
//
//    // MARK: - Calendar & Reminder Linking
//
//    private func addToCalendar(_ block: Block) {
//        let action = {
//            let blockId = block.id
//            let title = String(block.text.characters)
//            Task {
//                guard await eventKit.requestCalendarAccess() else { return }
//                let event = eventKit.makeEvent(title: title, date: date)
//                pendingEvent = PendingEvent(event: event) { entryId in
//                    if let i = blocks.firstIndex(where: { $0.id == blockId }) {
//                        blocks[i].linkedType = .calendar
//                        blocks[i].linkedEntryId = entryId
//                    }
//                }
//            }
//        }
//        initiateLink(block: block, action: action)
//    }
//
//    private func addToReminder(_ block: Block) {
//        let action = {
//            pendingReminder = PendingReminder(
//                initialTitle: String(block.text.characters),
//                initialDate: date
//            ) { entryId in
//                if let i = blocks.firstIndex(where: { $0.id == block.id }) {
//                    blocks[i].linkedType = .reminder
//                    blocks[i].linkedEntryId = entryId
//                }
//            }
//        }
//        initiateLink(block: block, action: action)
//    }
//
//    private func initiateLink(block: Block, action: @escaping () -> Void) {
//        if block.content != .none {
//            pendingLinkAction = action
//            showRelinkWarning = true
//        } else {
//            confirmFormattingOrProceed(action)
//        }
//    }
//
//    private func confirmFormattingOrProceed(_ action: (() -> Void)?) {
//        guard let action else { return }
//        if neverShowFormattingWarning {
//            action()
//        } else {
//            pendingLinkAction = action
//            showFormattingWarning = true
//        }
//    }
//
//    private func openBatchReminderSheet() {
//        let selected = blocks.filter { selectedBlockIds.contains($0.id) }
//        guard !selected.isEmpty else { return }
//        Task {
//            guard await eventKit.requestRemindersAccess() else { return }
//            pendingBatchReminder = PendingBatchReminder(
//                titles: selected.map { String($0.value.characters) },
//                blockIds: selected.map(\.id),
//                initialDate: date
//            ) { results in
//                for (blockId, entryId) in results {
//                    if let i = blocks.firstIndex(where: { $0.id == blockId }) {
//                        blocks[i].linkedType    = .reminder
//                        blocks[i].linkedEntryId = entryId
//                    }
//                }
//                selectedBlockIds = []
//            }
//        }
//    }
//
//    private func openBatchTagSheet() {
//        guard !selectedBlockIds.isEmpty else { return }
//        isBatchTagging = true
//    }
//
//    private func openInReminders() {
//        guard let url = URL(string: "x-apple-reminderkit://") else { return }
//        UIApplication.shared.open(url)
//    }
//
//    private func openInCalendar() {
//        let interval = date.timeIntervalSinceReferenceDate
//        guard let url = URL(string: "calshow://\(interval)") else { return }
//        UIApplication.shared.open(url)
//    }
//
//    // MARK: - Persistence & Sync
//
//    private func loadDailyNote() async {
//        allTags = (try? await NotesStorage.shared.loadTags()) ?? []
//        do {
//            blocks = try await NotesStorage.shared.load(date: date)
//        } catch {
//            // Keep default [TextBlock(value: "")]
//        }
//    }
//
//    private func scheduleSave(_ oldTextBlocks: [Block], _ newTextBlocks: [Block]) {
//        saveTask?.cancel()
//        saveTask = Task {
//            do {
//                try await Task.sleep(for: .milliseconds(500))
//                let toSave = newTextBlocks.filter { !$0.text.characters.isEmpty }
//                if toSave.isEmpty {
//                    try await NotesStorage.shared.delete(date: date)
//                } else {
//                    try await NotesStorage.shared.save(toSave, date: date)
//                }
//
//                // Sync tag folder files
//                let allTagIds = Set(
//                    newTextBlocks.flatMap(\.tagIds) + oldTextBlocks.flatMap(\.tagIds)
//                )
//                for tagId in allTagIds {
//                    try await NotesStorage.shared.syncTagBlocks(toSave, forTag: tagId, date: date)
//                }
//
//                // Sync title of linked system entries when block text changes
//                let oldById = Dictionary(uniqueKeysWithValues: oldTextBlocks.map { ($0.id, $0) })
//                for block in newTextBlocks {
//                    guard block.content != .none,
//                          let entryId = block.linkedEntryId,
//                          let old = oldById[block.id],
//                          old.value != block.text else { continue }
//                    try? eventKit.updateLinkedEntry(
//                        id: entryId,
//                        type: block.linkedType,
//                        title: String(block.text.characters)
//                    )
//                }
//            } catch is CancellationError {
//                // debounce cancelled — next edit will reschedule
//            } catch {
//                print("Save error: \(error)")
//            }
//        }
//    }
//
//    private func syncFromSystem() {
//        for i in blocks.indices {
//            guard blocks[i].content != .none,
//                  let entryId = blocks[i].linkedEntryId else { continue }
//            if let newTitle = eventKit.titleForLinkedEntry(id: entryId) {
//                // Entry exists — sync title if it changed
//                if newTitle != String(blocks[i].value.characters) {
//                    blocks[i].value = AttributedString(newTitle)
//                }
//            } else {
//                // Entry was deleted in Calendar/Reminders — unlink the block
//                blocks[i].linkedType = .none
//                blocks[i].linkedEntryId = nil
//            }
//        }
//    }
//}
//
//#Preview {
//    NavigationStack {
//        LegacyDailyNoteView()
//    }
//    .environment(EventKitManager())
//}
