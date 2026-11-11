//
//  MonthView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

import SwiftUI

struct MonthView: View {
    let month: Date
    let noteDates: Set<String>

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    private var cal: Calendar { Calendar.current }

    private var firstWeekdayOffset: Int {
        let weekday = cal.component(.weekday, from: month)
        return (weekday - cal.firstWeekday + 7) % 7
    }

    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: month)?.count ?? 30
    }

    private func date(for day: Int) -> Date {
        cal.date(byAdding: .day, value: day - 1, to: month) ?? month
    }

    private func hasNote(for day: Int) -> Bool {
        noteDates.contains(NoteDate.string(from: date(for: day)))
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<firstWeekdayOffset, id: \.self) { i in
                Color.clear
                    .id(-(i + 1))
            }

            ForEach(1...daysInMonth, id: \.self) { day in
                DayCell(day: day, date: date(for: day), hasNote: hasNote(for: day))
            }
        }
    }
}
