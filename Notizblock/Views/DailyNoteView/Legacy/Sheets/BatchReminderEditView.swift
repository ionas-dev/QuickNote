//
//  BatchReminderEditView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

import SwiftUI

struct PendingBatchReminder: Identifiable {
    let id = UUID()
    let titles: [String]
    let blockIds: [UUID]
    let initialDate: Date
    let onSave: ([UUID: String]) -> Void  // blockId → calendarItemIdentifier
}

struct BatchReminderEditView: View {
    @Environment(EventKitManager.self) private var eventKit
    @Environment(\.dismiss) private var dismiss

    let pending: PendingBatchReminder

    @State private var form = ReminderFormValues()

    var body: some View {
        NavigationStack {
            Form {
                Section("Blocks (\(pending.titles.count))") {
                    ForEach(pending.titles, id: \.self) { title in
                        Text(title)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    ReminderNotesFields(form: $form)
                }

                ReminderFormSections(form: $form)
            }
            .navigationTitle("New Reminders")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveAndDismiss() }
                }
            }
        }
        .onAppear {
            form.dueDate = pending.initialDate
            form.dueTime = pending.initialDate
        }
    }

    private func saveAndDismiss() {
        Task {
            var results: [UUID: String] = [:]
            for (blockId, title) in zip(pending.blockIds, pending.titles) {
                let entryId = try? await eventKit.saveReminder(
                    title: title,
                    notes: form.notes,
                    urlString: form.urlString,
                    date: form.dueDate,
                    includeTime: form.includeTime,
                    time: form.dueTime,
                    priority: form.priority.rawValue,
                    calendarId: form.selectedListId
                )
                results[blockId] = entryId ?? ""
            }
            pending.onSave(results)
            dismiss()
        }
    }
}
