//
//  ReminderFormSections.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

import SwiftUI
import EventKit

enum ReminderPriority: Int, CaseIterable, Identifiable {
    case none = 0, high = 1, medium = 5, low = 9
    var id: Int { rawValue }
    var label: String {
        switch self {
        case .none:   String(localized: "None")
        case .high:   String(localized: "High")
        case .medium: String(localized: "Medium")
        case .low:    String(localized: "Low")
        }
    }
}

/// Form state shared by the single and batch reminder editors.
struct ReminderFormValues {
    var notes: String = ""
    var urlString: String = ""
    var dueDate: Date = .now
    var includeTime: Bool = false
    var dueTime: Date = .now
    var priority: ReminderPriority = .none
    var lists: [EKCalendar] = []
    var selectedListId: String? = nil
}

/// Notes and URL text fields — embedded in each editor's own leading section.
struct ReminderNotesFields: View {
    @Binding var form: ReminderFormValues

    var body: some View {
        TextField("Notes", text: $form.notes, axis: .vertical)
            .lineLimit(3...)
        TextField("URL", text: $form.urlString)
            #if os(iOS)
            .keyboardType(.URL)
            #endif
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
    }
}

/// Due date/time and priority/list sections shared by both reminder editors.
/// Loads the available reminder lists on appear.
struct ReminderFormSections: View {
    @Binding var form: ReminderFormValues
    @Environment(EventKitManager.self) private var eventKit

    var body: some View {
        Section {
            DatePicker("Date", selection: $form.dueDate, displayedComponents: .date)
            Toggle("Include Time", isOn: $form.includeTime)
            if form.includeTime {
                DatePicker("Time", selection: $form.dueTime, displayedComponents: .hourAndMinute)
            }
        }

        Section {
            Picker("Priority", selection: $form.priority) {
                ForEach(ReminderPriority.allCases) { p in
                    Text(p.label).tag(p)
                }
            }

            if !form.lists.isEmpty {
                Picker("List", selection: $form.selectedListId) {
                    ForEach(form.lists, id: \.calendarIdentifier) { list in
                        Text(list.title).tag(list.calendarIdentifier as String?)
                    }
                }
            }
        }
        .task {
            if await eventKit.requestRemindersAccess() {
                form.lists = eventKit.store.calendars(for: .reminder)
                form.selectedListId = eventKit.store.defaultCalendarForNewReminders()?.calendarIdentifier
            }
        }
    }
}
