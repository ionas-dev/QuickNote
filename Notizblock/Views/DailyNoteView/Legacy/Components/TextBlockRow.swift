//
//  TextBlockRow.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

import SwiftUI

///// A single block row in the daily note list: accent bar, tag indicators,
///// linked-entry metadata, the text editor, and the block context menu.
//struct TextBlockRow: View {
//    @Binding var block: TextBlock
//    @Binding var textSelection: AttributedTextSelection
//    var blockFocus: FocusState<Focusable?>.Binding
//    let allTags: [Tag]
//    let isEditing: Bool
//    let isSelected: Bool
//    let isOnlyBlock: Bool
//    let onEditTag: (Tag) -> Void
//    let onAddToCalendar: () -> Void
//    let onAddToReminder: () -> Void
//    let onOpenInCalendar: () -> Void
//    let onOpenInReminders: () -> Void
//    let onTag: () -> Void
//    let onDelete: () -> Void
//
//    @Environment(EventKitManager.self) private var eventKit
//
//    var body: some View {
//        HStack(spacing: 0) {
//            BlockAccentBar(linkType: block.linkedType)
//            VStack(alignment: .leading, spacing: 0) {
//                if !block.tagIds.isEmpty {
//                    tagIndicators
//                }
//                if block.linkedType != .none,
//                   let entryId = block.linkedEntryId,
//                   let meta = eventKit.metaForLinkedEntry(id: entryId, type: block.linkedType) {
//                    BlockMetaText(meta: meta, type: block.linkedType)
//                        .padding(.horizontal)
//                        .padding(.top, 8)
//                }
//                editor
//            }
//        }
//        .listSectionSeparator(.hidden)
//        .listRowBackground(
//            isEditing && isSelected
//                ? Color.accentColor.opacity(0.12)
//                : nil
//        )
//        .contextMenu {
//            contextMenuItems
//        } preview: {
//            BlockPreview(block: block)
//        }
//    }
//
//    private var tagIndicators: some View {
//        HStack(spacing: 8) {
//            ForEach(block.tagIds, id: \.self) { tagId in
//                if let tag = allTags.first(where: { $0.id == tagId }) {
//                    TagStyleIndicator(
//                        style: tag.style,
//                        emojiFont: .caption2,
//                        colorSize: 8
//                    )
//                    .onLongPressGesture {
//                        onEditTag(tag)
//                    }
//                }
//            }
//            Spacer()
//        }
//        .padding(.horizontal)
//        .padding(.top, 6)
//    }
//
//    private var editor: some View {
//        TextEditor(text: $block.value, selection: $textSelection)
//            .id(block.id)
//            .frame(minHeight: isOnlyBlock ? 700 : 120)
//            .padding()
//            .focused(blockFocus, equals: .block(id: block.id))
//            .disabled(isEditing)
//            .scrollContentBackground(.hidden)
//            .background(.clear)
//    }
//
//    @ViewBuilder
//    private var contextMenuItems: some View {
//        ShareLink(item: String(block.value.characters))
//
//        Button("Add to Calendar", systemImage: "calendar.badge.plus", action: onAddToCalendar)
//
//        Button("Add to Reminder", systemImage: "checklist", action: onAddToReminder)
//
//        if block.linkedType == .reminder, let entryId = block.linkedEntryId {
//            Button("Complete Reminder", systemImage: "checkmark.circle") {
//                try? eventKit.completeReminder(id: entryId)
//            }
//            Button("Open in Reminders", systemImage: "arrow.up.right.square", action: onOpenInReminders)
//        }
//
//        if block.linkedType == .calendar {
//            Button("Open in Calendar", systemImage: "arrow.up.right.square", action: onOpenInCalendar)
//        }
//
//        Button("Tag...", systemImage: "tag", action: onTag)
//
//        Divider()
//
//        Button(role: .destructive, action: onDelete) {
//            Label("Delete", systemImage: "trash")
//        }
//    }
//}
