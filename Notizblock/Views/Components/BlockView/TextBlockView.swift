//
//  TextBlockView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 16.07.26.
//

import SwiftUI

struct TextBlockView: View {
    @Binding var text: String
    var tags: [Tag]
    var isExpanded: Bool
    var isSelecting: Bool = false
    @AppStorage(AppSettings.markdownEnabled) private var markdownEnabled: Bool
    @AppStorage(AppSettings.noteFontDesign) private var noteFontDesign: FontDesign

    let onDelete: () -> Void
    let onOpenTagsSheet: () -> Void
    let onConvertToTodo: () -> Void
    let onOpenMoveSheet: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !tags.isEmpty {
                metaInformation
            }

            GrowingTextEditor(text: $text, isExpanded: isExpanded, menuActions: menuActions, isSelecting: isSelecting)
        }
        .contextMenu(menuItems: contextMenuItems, preview: contextMenuPreview)
    }

    private var menuActions: [BlockMenuAction] {
        guard !text.isEmpty else { return [] }
        return [
            BlockMenuAction("Tag...", systemImage: "tag", action: onOpenTagsSheet),
            BlockMenuAction("Remind Me", systemImage: "checkmark.circle", action: onConvertToTodo),
            BlockMenuAction("Move to Date...", systemImage: "calendar", action: onOpenMoveSheet),
            BlockMenuAction("Delete block", systemImage: "trash", isDestructive: true, action: onDelete),
        ]
    }

    private var metaInformation: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tags) { tag in
                    TagMetaInformation(style: tag.style)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .glassEffect()
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private func contextMenuItems() -> some View {
        if !text.isEmpty {
            ShareLink(item: text)
            Button("Tag...", systemImage: "tag", action: onOpenTagsSheet)
            Button("Remind Me", systemImage: "checkmark.circle", action: onConvertToTodo)
            Button("Move to Date...", systemImage: "calendar", action: onOpenMoveSheet)

            Divider()

            Button("Delete block", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }

    private func contextMenuPreview () -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !tags.isEmpty {
                metaInformation
            }

            Text(MarkdownStyler.attributed(text, enabled: markdownEnabled, design: noteFontDesign.fontDesign))
        }
        .padding()
    }
}

#Preview {
    @Previewable @State var text: String = """
        test1nn mmmmmmmmmmm


        df
        """

    var isExpanded = false

    TextBlockView(
        text: $text,
        tags: [Tag(name: "Work", style: .emoji("💼")), Tag(name: "Urgent", style: .color("#FF3B30"))],
        isExpanded: isExpanded,
        onDelete: {},
        onOpenTagsSheet: {},
        onConvertToTodo: {},
        onOpenMoveSheet: {}
    )
    .padding()
}
