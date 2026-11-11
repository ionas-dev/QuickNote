//
//  BatchTagPickerSheet.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 24.07.26.
//

import SwiftUI

private enum TagSelectionState: Equatable {
    case off, partial, on
}

struct BatchTagPickerSheet: View {
    let selectedBlocks: [Block]
    let onSave: ([Block]) -> Void

    @Environment(TagStore.self) private var tagStore
    @Environment(\.dismiss) private var dismiss
    @State private var initialStates: [UUID: TagSelectionState] = [:]
    @State private var states: [UUID: TagSelectionState] = [:]

    var body: some View {
        NavigationStack {
            Form {
                ForEach(tagStore.tags) { tag in
                    tagRow(tag)
                }
            }
            .navigationTitle("Tag \(selectedBlocks.count) Blocks")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveAndDismiss() }
                }
            }
            .onAppear(perform: loadInitialStates)
        }
    }

    private func tagRow(_ tag: Tag) -> some View {
        let state = states[tag.id] ?? .off
        return Button {
            states[tag.id] = state == .on ? .off : .on
        } label: {
            TagRow(tag: tag) {
                switch state {
                case .on:
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                case .partial:
                    Image(systemName: "minus")
                        .foregroundStyle(.secondary)
                case .off:
                    EmptyView()
                }
            }
        }
        .foregroundStyle(.primary)
    }

    private func loadInitialStates() {
        for tag in tagStore.tags {
            let count = selectedBlocks.filter { $0.tagIds.contains(tag.id) }.count
            let state: TagSelectionState
            if count == 0 { state = .off }
            else if count == selectedBlocks.count { state = .on }
            else { state = .partial }
            initialStates[tag.id] = state
            states[tag.id] = state
        }
    }

    private func saveAndDismiss() {
        var updated = selectedBlocks
        for i in updated.indices {
            for tag in tagStore.tags {
                guard let state = states[tag.id], state != initialStates[tag.id] else { continue }
                switch state {
                case .on:
                    if !updated[i].tagIds.contains(tag.id) {
                        updated[i].tagIds.append(tag.id)
                    }
                case .off:
                    updated[i].tagIds.removeAll { $0 == tag.id }
                case .partial:
                    break
                }
            }
        }
        onSave(updated)
        dismiss()
    }
}

#Preview {
    @Previewable @State var blocks: [Block] = [
        Block(text: "One"),
        Block(text: "Two")
    ]

    BatchTagPickerSheet(selectedBlocks: blocks) { _ in }
        .environment(TagStore())
}
