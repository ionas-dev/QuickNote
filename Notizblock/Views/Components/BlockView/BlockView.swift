//
//  BlockView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 17.07.26.
//

import EventKit
import SwiftUI

struct BlockView: View {

    @State private var isTagsSheetPresented = false
    @State private var isMoveSheetPresented = false
    @Environment(TagStore.self) private var tagStore
    @State private var pendingReminder: PendingReminder? = nil
    @Environment(EventKitManager.self) private var eventKit

    @Binding var block: Block
    var expandToHeight: CGFloat?
    var isSelecting: Bool = false
    /// The day this block currently lives on, so the move sheet can
    /// highlight it.
    var currentDate: Date

    var onDelete: () -> Void
    var onMove: (Date) -> Void

    private var blockTags: [Tag] {
        tagStore.tags(for: block.tagIds)
    }

    var body: some View {
        Group {
            switch block.content {
            case .none:
                TextBlockView(text: $block.text, tags: blockTags, isExpanded: expandToHeight != nil, isSelecting: isSelecting, onDelete: onDelete, onOpenTagsSheet: openTagsSheet, onConvertToTodo: convertToTodo, onOpenMoveSheet: openMoveSheet)
                    .frame(minHeight: expandToHeight)
            case .todo:
                if let content = $block.content.todo {
                    TodoBlockView(text: $block.text, tags: blockTags, content: content, isSelecting: isSelecting, onDelete: onDelete, onOpenTagsSheet: openTagsSheet, onConvertToText: convertToText, onOpenMoveSheet: openMoveSheet)
                }
            }
        }
        .alignmentGuide(.listRowSeparatorLeading) { dimensions in dimensions[.leading] }
        .sheet(isPresented: $isTagsSheetPresented, content: tagPickerSheet)
        .sheet(isPresented: $isMoveSheetPresented, content: moveToDateSheet)
        .sheet(item: $pendingReminder, content: ReminderEditView.init)
    }

    private func openTagsSheet() {
        // Defer presentation to the next run-loop tick so the context menu's
        // dismissal transaction finishes first. Flipping the flag inside the
        // menu button's action collides with that transaction and cancels the
        // in-flight sheet presentation, so the sheet flashes open then closes
        // on the first invocation.
        Task { @MainActor in
            isTagsSheetPresented = true
        }
    }

    private func tagPickerSheet() -> some View {
        TagPickerSheet(previouslySelectedTagIds: block.tagIds) { selectedTagIds in
            block.tagIds = selectedTagIds
        }
    }

    private func openMoveSheet() {
        // Same deferred-presentation trick as `openTagsSheet`.
        Task { @MainActor in
            isMoveSheetPresented = true
        }
    }

    private func moveToDateSheet() -> some View {
        MoveToDateSheet(sourceDates: [currentDate], onMove: onMove)
    }

    private func convertToTodo() {
        pendingReminder = PendingReminder(
            initialTitle: block.text,
            initialDate: currentDate,
            onSave: linkReminder
        )
    }

    private func linkReminder(_ remindersId: String) {
        var content = TodoBlockContent(isCompleted: false, remindersId: remindersId)
        if let reminder = eventKit.store.calendarItem(withIdentifier: remindersId) as? EKReminder {
            content.dueDate = reminder.dueDateComponents?.date
            content.list = reminder.calendar?.title
            if let priority = ReminderPriority(rawValue: reminder.priority), priority != .none {
                content.priorityText = priority.label
            }
        }
        block.content = .todo(content)
    }

    private func convertToText() {
        if case .todo(let content) = block.content {
            try? eventKit.deleteLinkedRemindersEntry(id: content.remindersId)
        }
        block.content = .none
    }
}
