//
//  MoveToDateSheet.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 13.10.26.
//

import SwiftUI

struct MoveToDateSheet: View {
    var blockCount: Int = 1
    /// Calendar days the block(s) being moved currently live on, highlighted
    /// in the picker alongside today.
    var sourceDates: Set<Date> = []
    let onMove: (Date) -> Void

    @State private var targetDate: Date = .now
    @Environment(\.dismiss) private var dismiss

    private var title: LocalizedStringKey {
        blockCount > 1 ? "Move \(blockCount) Blocks" : "Move Block"
    }

    var body: some View {
        NavigationStack {
            MoveDatePicker(selectedDate: $targetDate, sourceDates: sourceDates)
                .padding(.horizontal)
                .navigationTitle(title)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Move") {
                            onMove(targetDate)
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    MoveToDateSheet(blockCount: 3, onMove: { _ in })
}
