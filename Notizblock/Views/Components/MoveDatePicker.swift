//
//  MoveDatePicker.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 13.10.26.
//

import SwiftUI

/// A vertically scrollable list of month grids for picking a target date in
/// `MoveToDateSheet`. Unlike `CalendarView`'s `MonthView`/`DayCell` (which
/// navigate away on tap), this returns the tapped date to the caller and
/// marks the days the moved block(s) currently live on, alongside today and
/// the current selection.
struct MoveDatePicker: View {
    @Binding var selectedDate: Date
    /// Calendar days the block(s) being moved currently live on, so the
    /// picker can show the user what they'd be moving away from.
    var sourceDates: Set<Date> = []

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private var cal: Calendar { Calendar.current }

    private var normalizedSourceDates: Set<Date> {
        Set(sourceDates.map { cal.startOfDay(for: $0) })
    }

    private func firstOfMonth(for date: Date) -> Date {
        cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? cal.startOfDay(for: date)
    }

    /// The month the list opens scrolled to: the earliest source day's
    /// month, so a move from a day outside the current month doesn't start
    /// the picker scrolled away from the thing it's highlighting.
    private var anchorMonth: Date {
        firstOfMonth(for: sourceDates.min() ?? selectedDate)
    }

    /// A generous, bounded window of months around today and the anchor
    /// month, so the list has a fixed extent to scroll rather than growing
    /// unbounded in either direction.
    private var months: [Date] {
        let today = firstOfMonth(for: .now)
        let anchor = anchorMonth
        let start = cal.date(byAdding: .month, value: -12, to: min(today, anchor)) ?? today
        let end = cal.date(byAdding: .month, value: 24, to: max(today, anchor)) ?? today

        var result: [Date] = []
        var month = start
        while month <= end {
            result.append(month)
            guard let next = cal.date(byAdding: .month, value: 1, to: month) else { break }
            month = next
        }
        return result
    }

    private var weekdayHeaders: [String] {
        let symbols = cal.shortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private func firstWeekdayOffset(for month: Date) -> Int {
        let weekday = cal.component(.weekday, from: month)
        return (weekday - cal.firstWeekday + 7) % 7
    }

    private func daysInMonth(_ month: Date) -> Int {
        cal.range(of: .day, in: .month, for: month)?.count ?? 30
    }

    private func date(for day: Int, in month: Date) -> Date {
        cal.date(byAdding: .day, value: day - 1, to: month) ?? month
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(months, id: \.self) { month in
                        monthSection(month)
                            .id(month)
                    }
                }
            }
            .onAppear {
                // `LazyVStack` hasn't registered its ids by the time `onAppear`
                // fires, so an immediate `scrollTo` here is a no-op and the
                // list opens at its natural top instead of the anchor month.
                // Deferring to the next run loop tick gives it time to lay out.
                DispatchQueue.main.async {
                    proxy.scrollTo(anchorMonth, anchor: .top)
                }
            }
        }
    }

    private func monthSection(_ month: Date) -> some View {
        VStack(spacing: 8) {
            Text(month.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdayHeaders, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(0..<firstWeekdayOffset(for: month), id: \.self) { _ in
                    Color.clear
                }

                ForEach(1...daysInMonth(month), id: \.self) { day in
                    cell(for: date(for: day, in: month), day: day)
                }
            }
        }
    }

    private func cell(for date: Date, day: Int) -> some View {
        let isToday = cal.isDateInToday(date)
        let isSource = normalizedSourceDates.contains(cal.startOfDay(for: date))
        let isSelected = cal.isDate(date, inSameDayAs: selectedDate)

        return Button {
            selectedDate = date
        } label: {
            ZStack {
                if isToday {
                    Circle()
                        .fill(Color.red)
                } else if isSource {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                }

                if isSelected {
                    Circle()
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }

                Text("\(day)")
                    .foregroundStyle(isToday ? .white : .primary)
                    .fontWeight(isToday || isSource ? .bold : .medium)
            }
            .frame(width: 32, height: 32)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }
}

#Preview {
    @Previewable @State var selectedDate: Date = .now

    MoveDatePicker(selectedDate: $selectedDate, sourceDates: [.now.addingTimeInterval(-86400 * 3)])
        .padding()
}
