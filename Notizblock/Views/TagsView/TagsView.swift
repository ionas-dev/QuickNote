//
//  TagsView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 28.06.26.
//

import SwiftUI

struct TagsView: View {
    @Environment(TagStore.self) private var tagStore
    @State private var showingCreateSheet = false
    @State private var editingTag: Tag? = nil
    @Environment(NavigationModel.self) private var navigation

    var body: some View {
        List {
            Section {
                ForEach(tagStore.tags) { tag in
                    tagRow(tag)
                }
                .onDelete(perform: deleteTag)
            }

            Section {
                untaggedRow
            }
        }
        .adaptiveNavigationTitle("Tags")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                Button("New Tag", systemImage: "plus") {
                    showingCreateSheet = true
                }
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                Button("New Tag", systemImage: "plus") {
                    showingCreateSheet = true
                }
            }
            #endif
        }
        .sheet(isPresented: $showingCreateSheet) {
            TagFormSheet { newTag in
                tagStore.create(newTag)
            }
        }
        .sheet(item: $editingTag) { tag in
            TagFormSheet(existingTag: tag) { updatedTag in
                tagStore.update(updatedTag)
            }
        }
    }

    private func tagRow(_ tag: Tag) -> some View {
        Button {
            navigation.path.append(.tagDetail(tag))
        } label: {
            TagRow(tag: tag) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
        #if os(iOS)
        .swipeActions(edge: .leading) {
            Button("Edit Tag", systemImage: "pencil") {
                editingTag = tag
            }
            .tint(.accentColor)
        }
        #endif
    }

    private var untaggedRow: some View {
        Button {
            navigation.path.append(.untagged)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "tag.slash")
                    .foregroundStyle(.secondary)
                Text("Untagged")
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
    }

    private func deleteTag(at offsets: IndexSet) {
        let idsToDelete = offsets.map { tagStore.tags[$0].id }
        idsToDelete.forEach(tagStore.delete)
    }
}

#Preview {
    @Previewable @State var navigation = NavigationModel()
    NavigationStack(path: $navigation.path) {
        TagsView()
    }
    .environment(navigation)
    .environment(TagStore())
}
