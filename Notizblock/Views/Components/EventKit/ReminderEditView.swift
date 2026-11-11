//
//  ReminderEditView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 28.06.26.
//

import SwiftUI

struct PendingReminder: Identifiable {
    let id = UUID()
    let initialTitle: String
    let initialDate: Date
    let onSave: (String) -> Void  // called with calendarItemIdentifier on save
}

struct ReminderEditView: View {
    @Environment(EventKitManager.self) private var eventKit
    @Environment(\.dismiss) private var dismiss

    let pending: PendingReminder

    @State private var title: String = ""
    @State private var form = ReminderFormValues()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    ReminderNotesFields(form: $form)
                }

                ReminderFormSections(form: $form)
            }
            .navigationTitle("New Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveAndDismiss() }
                        .disabled(title.isEmpty)
                }
            }
        }
        .onAppear {
            title = pending.initialTitle
            form.dueDate = pending.initialDate
            form.dueTime = pending.initialDate
        }
    }

    private func saveAndDismiss() {
        Task {
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
            pending.onSave(entryId ?? "")
            dismiss()
        }
    }
}
