//
//  EventKitManager.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 28.06.26.
//

import EventKit
import Observation

@Observable final class EventKitManager {
    let store = EKEventStore()

    // Incremented on the main thread whenever the EK store changes externally.
    // BlockList/GroupedBlockList observe this to pull updated reminders back into blocks.
    private(set) var externalChangeCount: Int = 0

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChange),
            name: .EKEventStoreChanged,
            object: store
        )
    }

    @objc private func storeDidChange() {
        DispatchQueue.main.async { self.externalChangeCount += 1 }
    }

    func requestCalendarAccess() async -> Bool {
        (try? await store.requestFullAccessToEvents()) ?? false
    }

    func requestRemindersAccess() async -> Bool {
        (try? await store.requestFullAccessToReminders()) ?? false
    }

    func makeEvent(title: String, date: Date) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = Calendar.current.startOfDay(for: date)
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: event.startDate)!
        event.isAllDay = true
        event.calendar = store.defaultCalendarForNewEvents
        return event
    }

    @discardableResult
    func saveReminder(
        title: String,
        notes: String,
        urlString: String,
        date: Date,
        includeTime: Bool,
        time: Date,
        priority: Int,
        calendarId: String?
    ) async throws -> String {
        guard await requestRemindersAccess() else { return "" }
        let reminder = EKReminder(eventStore: store)
        reminder.title = title
        reminder.notes = notes.isEmpty ? nil : notes
        reminder.url = urlString.isEmpty ? nil : URL(string: urlString)
        reminder.priority = priority

        let cal = Calendar.current
        if includeTime {
            var components = cal.dateComponents([.year, .month, .day], from: date)
            let timeComponents = cal.dateComponents([.hour, .minute], from: time)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            reminder.dueDateComponents = components
            reminder.addAlarm(EKAlarm(relativeOffset: 0))
        } else {
            reminder.dueDateComponents = cal.dateComponents([.year, .month, .day], from: date)
        }

        if let id = calendarId,
           let calendar = store.calendars(for: .reminder).first(where: { $0.calendarIdentifier == id }) {
            reminder.calendar = calendar
        } else {
            reminder.calendar = store.defaultCalendarForNewReminders()
        }

        try store.save(reminder, commit: true)
        return reminder.calendarItemIdentifier
    }

    func deleteLinkedRemindersEntry(id: String) throws {
        guard let item = store.calendarItem(withIdentifier: id) else { return }
        
        if let reminder = item as? EKReminder {
            try store.remove(reminder, commit: true)
        }
    }
    
    func deleteLinkedCalendarEntry(id: String) throws {
        guard let item = store.calendarItem(withIdentifier: id) else { return }
       
        if let event = item as? EKEvent {
            try store.remove(event, span: .thisEvent)
        }
    }

    func updateLinkedRemindersEntry(id: String, title: String) throws {
        guard let item = store.calendarItem(withIdentifier: id) else { return }

        if let reminder = item as? EKReminder {
            reminder.title = title
            try store.save(reminder, commit: true)
        }
    }
    
    func updateLinkedCalendarEntry(id: String, title: String) throws {
        guard let item = store.calendarItem(withIdentifier: id) else { return }
        
        if let event = item as? EKEvent {
            try store.save(event, span: .thisEvent)
        }
    }

    func setReminderCompleted(id: String, completed: Bool) throws {
        guard let item = store.calendarItem(withIdentifier: id), let reminder = item as? EKReminder
        else { return }

        reminder.isCompleted = completed
        try store.save(reminder, commit: true)
    }

//    func metaForLinkedEntry(id: String) -> BlockMeta? {
//        guard type != .none,
//              let item = store.calendarItem(withIdentifier: id) else { return nil }
//
//        var meta = BlockMeta()
//        meta.calendarOrList = item.calendar?.title
//        meta.location = (item.location?.isEmpty == false) ? item.location : nil
//
//        let cal = Calendar.current
//        let dateFmt: DateFormatter = {
//            let f = DateFormatter()
//            f.dateStyle = .medium
//            f.timeStyle = .none
//            return f
//        }()
//        let timeFmt: DateFormatter = {
//            let f = DateFormatter()
//            f.dateStyle = .none
//            f.timeStyle = .short
//            return f
//        }()
//
//        if let reminder = item as? EKReminder {
//            meta.isCompleted = reminder.isCompleted
//            if let components = reminder.dueDateComponents,
//               let date = cal.date(from: components) {
//                meta.dateText = dateFmt.string(from: date)
//                if components.hour != nil {
//                    meta.timeText = timeFmt.string(from: date)
//                }
//            }
//            switch reminder.priority {
//            case 1: meta.priorityText = "High"
//            case 5: meta.priorityText = "Medium"
//            case 9: meta.priorityText = "Low"
//            default: break
//            }
//        } else if let event = item as? EKEvent {
//            meta.dateText = dateFmt.string(from: event.startDate)
//            if !event.isAllDay {
//                meta.timeText = timeFmt.string(from: event.startDate)
//            }
//        }
//
//        return meta
//    }

    /// Returns the current title/completion of a linked reminder, or nil if not found.
    func reminderState(id: String) -> (title: String, isCompleted: Bool)? {
        guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else { return nil }
        return (reminder.title, reminder.isCompleted)
    }

    /// Pulls title/completion into todo blocks whose linked reminder changed externally.
    func refreshLinkedReminders(in blocks: inout [Block]) {
        for i in blocks.indices {
            guard case .todo(var content) = blocks[i].content,
                  let state = reminderState(id: content.remindersId) else { continue }

            if content.isCompleted != state.isCompleted {
                content.isCompleted = state.isCompleted
                blocks[i].content = .todo(content)
            }
            if blocks[i].text != state.title {
                blocks[i].text = state.title
            }
        }
    }
}
