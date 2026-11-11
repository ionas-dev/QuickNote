//
//  EventEditView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 28.06.26.
//

#if canImport(EventKitUI)
import SwiftUI
import EventKit
import EventKitUI


struct PendingEvent: Identifiable {
    let id = UUID()
    let event: EKEvent
    let onSave: (String) -> Void  // called with calendarItemIdentifier on save
}

struct EventEditView: UIViewControllerRepresentable {
    let pending: PendingEvent
    let store: EKEventStore
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let vc = EKEventEditViewController()
        vc.event = pending.event
        vc.eventStore = store
        vc.editViewDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onSave: pending.onSave)
    }

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let dismiss: DismissAction
        let onSave: (String) -> Void

        init(dismiss: DismissAction, onSave: @escaping (String) -> Void) {
            self.dismiss = dismiss
            self.onSave = onSave
        }

        func eventEditViewController(_ controller: EKEventEditViewController,
                                     didCompleteWith action: EKEventEditViewAction) {
            if action == .saved {
                onSave(controller.event?.calendarItemIdentifier ?? "")
            }
            dismiss()
        }
    }
}
#endif
