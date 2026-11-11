//
//  MacSidebarView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 22.07.26.
//

import SwiftUI

#if os(macOS)
struct MacSidebarView: View {
    @Environment(TagStore.self) private var tagStore
    @Binding var selection: MacSelection

    @State private var editingTag: Tag? = nil
    @State private var showingCreateSheet = false

    var body: some View {
        List(selection: $selection) {
            Section("Calendar") {
                MacMiniCalendarView(selection: $selection)
            }

            tagsSection
        }
        .safeAreaInset(edge: .bottom) {
            if selection != .date(Calendar.current.startOfDay(for: .now)) {
                todayButton
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            TagFormSheet { newTag in
                tagStore.create(newTag)
            }
        }
        .sheet(item: $editingTag, content: editTagSheet)
    }

    /// A plain `Spacer()` inside `List` doesn't expand to fill remaining space the
    /// way it would in a VStack (List lays out actual rows, not flexible box
    /// content), so pinning this to the true bottom of the sidebar needs
    /// `.safeAreaInset` instead of an in-list spacer.
    private var todayButton: some View {
        Button {
            selection = .date(Calendar.current.startOfDay(for: .now))
        } label: {
            Label("Today", systemImage: "star.fill")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var tagsSection: some View {
        Section {
            ForEach(tagStore.tags) { tag in
                TagRow(tag: tag) { EmptyView() }
                    .tag(MacSelection.tag(tag))
                    .contextMenu {
                        Button("Edit Tag", systemImage: "pencil") {
                            editingTag = tag
                        }
                        Button("Delete Tag", systemImage: "trash", role: .destructive) {
                            deleteTag(tag)
                        }
                    }
            }

            Label("Untagged", systemImage: "tag.slash")
                .tag(MacSelection.untagged)
        } header: {
            HStack {
                Text("Tags")
                Spacer()
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func editTagSheet(_ tag: Tag) -> some View {
        TagFormSheet(existingTag: tag) { updatedTag in
            tagStore.update(updatedTag)
        }
    }

    private func deleteTag(_ tag: Tag) {
        if case .tag(let selectedTag) = selection, selectedTag.id == tag.id {
            selection = .date(Calendar.current.startOfDay(for: .now))
        }
        tagStore.delete(tag.id)
    }
}

#Preview {
    @Previewable @State var selection: MacSelection = .date(Calendar.current.startOfDay(for: .now))
    NavigationSplitView {
        MacSidebarView(selection: $selection)
    } detail: {
        Text("Detail")
    }
    .environment(TagStore())
}
#endif
