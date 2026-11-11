//
//  TodoBlockView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 17.07.26.
//
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct TodoBlockView: View {
    @Environment(EventKitManager.self) private var eventKit
    @State private var titleSyncTask: Task<Void, Never>?

    @Binding var text: String
    var tags: [Tag]
    @Binding var content: TodoBlockContent
    var isSelecting: Bool = false
    @AppStorage(AppSettings.markdownEnabled) private var markdownEnabled: Bool
    @AppStorage(AppSettings.noteFontDesign) private var noteFontDesign: FontDesign

    let onDelete: () -> Void
    let onOpenTagsSheet: () -> Void
    let onConvertToText: () -> Void
    let onOpenMoveSheet: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            checkbox

            VStack(alignment: .leading, spacing: 0) {
                metaInformation

                GrowingTextEditor(text: $text, isExpanded: false, menuActions: menuActions, isSelecting: isSelecting)
                    .foregroundStyle(content.isCompleted ? .secondary : .primary)
            }
        }
        .contextMenu(menuItems: contextMenuItems, preview: contextMenuPreview)
        .onChange(of: text, scheduleTitleSync)
    }

    private var menuActions: [BlockMenuAction] {
        guard !text.isEmpty else { return [] }
        return [
            BlockMenuAction("Open in Reminders", systemImage: "arrow.up.right.square", action: openInRemindersApp),
            BlockMenuAction("Tag...", systemImage: "tag", action: onOpenTagsSheet),
            BlockMenuAction("Unlink Reminder", systemImage: "text.alignleft", action: onConvertToText),
            BlockMenuAction("Move to Date...", systemImage: "calendar", action: onOpenMoveSheet),
            BlockMenuAction("Delete block and reminder", systemImage: "trash", isDestructive: true, action: onDelete),
        ]
    }

    // MARK: Component Views
    private var checkbox: some View {
        Button("", systemImage: content.isCompleted ? "inset.filled.circle" : "circle", action: toggleCompletion)
            .foregroundStyle(content.isCompleted ? Color.accentColor : Color.primary)
    }
    
    private var metaInformation: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags) { tag in
                            TagMetaInformation(style: tag.style)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .glassEffect()
                }
                
                HStack(spacing: 4) {
                    if let list = content.list {
                        Text("\(Image(systemName: "folder")) \(list)")
                    }
                    
                    if let date = content.dueDate {
                        let dateText = content.hasTime ? date.formatted(.dateTime.day().month(.wide).year().hour().minute()) : date.formatted(.dateTime.day().month(.wide).year())
                        
                        Text("\(Image(systemName: "calendar")) \(dateText)")
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .glassEffect()
                
                //            if let location = content.location {
                //                Text("\(Image(systemName: "location")) \(location)")
                //            }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .scrollClipDisabled()
    }
    
    @ViewBuilder
    private func contextMenuItems() -> some View {
        if !text.isEmpty {
            ShareLink(item: text)
            Button("Open in Reminders", systemImage: "arrow.up.right.square", action: openInRemindersApp)
            Button("Tag...", systemImage: "tag", action: onOpenTagsSheet)
            Button("Unlink Reminder", systemImage: "text.alignleft", action: onConvertToText)
            Button("Move to Date...", systemImage: "calendar", action: onOpenMoveSheet)

            Divider()

            Button("Delete block and reminder", systemImage: "trash", role: .destructive, action: onDelete)
        }
    }
    
    private func contextMenuPreview() ->  some View {
        HStack {
            checkbox
            
            VStack(alignment: .leading, spacing: 0) {
                metaInformation
                   
                Text(MarkdownStyler.attributed(text, enabled: markdownEnabled, design: noteFontDesign.fontDesign))
                    .foregroundStyle(content.isCompleted ? .secondary : .primary)
            }
        }
        .padding()
    }
    
    // MARK: Logic
    
    private func openInRemindersApp() {
        guard let url = URL(string: "x-apple-reminderkit://REMCDReminder/\(content.remindersId)") else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }

    private func toggleCompletion() {
        content.isCompleted.toggle()
        let id = content.remindersId
        let completed = content.isCompleted
        Task {
            try? eventKit.setReminderCompleted(id: id, completed: completed)
        }
    }

    private func scheduleTitleSync(_ oldText: String, _ newText: String) {
        titleSyncTask?.cancel()
        let id = content.remindersId
        let title = newText
        titleSyncTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                try eventKit.updateLinkedRemindersEntry(id: id, title: title)
            } catch is CancellationError {
            } catch {
                print("Reminder title sync error: \(error)")
            }
        }
    }
}

#Preview {
    @Previewable @State var content = TodoBlockContent(
        isCompleted: false,
        remindersId: "",
        dueDate: Date.now,
        location: "Da und Da",
        list: "Aufgaben"
    )

    @Previewable @State var text: String = """
        test1nn mmmmmmmmmmm
        
        
        df
        """

    TodoBlockView(
        text: $text,
        tags: [Tag(name: "Work", style: .emoji("💼")), Tag(name: "Urgent", style: .color("#FF3B30"))],
        content: $content,
        onDelete: {},
        onOpenTagsSheet: {},
        onConvertToText: {},
        onOpenMoveSheet: {}
    )
    .padding()
}
