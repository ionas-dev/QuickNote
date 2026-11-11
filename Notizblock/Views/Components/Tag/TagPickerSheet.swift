//
//  TagPickerSheet.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 28.06.26.
//

import SwiftUI

struct TagPickerSheet: View {
    let previouslySelectedTagIds: [UUID]
    let onSave: (_ selectedTagIds: [UUID]) -> Void

    @Environment(TagStore.self) private var tagStore
    @State private var selectedTagIds: Set<UUID>
    @State private var showingCreateSheet = false
    @Environment(\.dismiss) private var dismiss

    init(previouslySelectedTagIds: [UUID], onSave: @escaping (_ selectedTagIds: [UUID]) -> Void) {
        self.previouslySelectedTagIds = previouslySelectedTagIds
        self.onSave = onSave
        _selectedTagIds = State(initialValue: Set(previouslySelectedTagIds))
    }

    var body: some View {
        NavigationStack {
            Form {
                ForEach(tagStore.tags) { tag in
                    tagRow(tag)
                }
            }
            .navigationTitle("Tag...")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    Button("New Tag", systemImage: "plus") {
                        showingCreateSheet = true
                    }
                }
                #else
                ToolbarItem(placement: .navigation) {
                    Button("New Tag", systemImage: "plus") {
                        showingCreateSheet = true
                    }
                }
                #endif
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveAndDismiss() }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                TagFormSheet { newTag in
                    tagStore.create(newTag)
                    selectedTagIds.insert(newTag.id)
                }
            }
        }
    }

    private func tagRow(_ tag: Tag) -> some View {
        let isSelected = selectedTagIds.contains(tag.id)
        return Button {
            if isSelected {
                selectedTagIds.remove(tag.id)
            } else {
                selectedTagIds.insert(tag.id)
            }
        } label: {
            TagRow(tag: tag) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                }
            }
        }
        .foregroundStyle(.primary)
    }

    private func saveAndDismiss() {
        onSave(Array(selectedTagIds))
        dismiss()
    }
}
