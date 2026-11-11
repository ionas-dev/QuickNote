//
//  MacMiniCalendarView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 22.07.26.
//

import SwiftUI

#if os(macOS)
/// Compact single-month calendar for the macOS sidebar. Unlike `MonthView`/`DayCell`
/// (which push onto the iOS `NavigationModel` stack), tapping a day here sets
/// `selection` directly for the split-view detail pane.
struct MacMiniCalendarView: View {
    @Binding var selection: MacSelection

    @State private var displayedMonth: Date = {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month], from: .now)
        return cal.date(from: components) ?? .now
    }()
    @State private var noteDates: Set<String> = []

    private var cal: Calendar { Calendar.current }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var firstWeekdayOffset: Int {
        let weekday = cal.component(.weekday, from: displayedMonth)
        return (weekday - cal.firstWeekday + 7) % 7
    }

    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
    }

    private func date(for day: Int) -> Date {
        cal.date(byAdding: .day, value: day - 1, to: displayedMonth) ?? displayedMonth
    }

    private func hasNote(for day: Int) -> Bool {
        noteDates.contains(NoteDate.string(from: date(for: day)))
    }

    private func isToday(_ day: Int) -> Bool {
        cal.isDateInToday(date(for: day))
    }

    private func isSelected(_ day: Int) -> Bool {
        if case .date(let selectedDay) = selection {
            return cal.isDate(selectedDay, inSameDayAs: date(for: day))
        }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            monthHeader
            dayGrid
        }
        .padding(.vertical, 4)
        .task(loadNoteDates)
    }

    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Spacer()

            Text(monthTitle)
                .font(.caption)
                .bold()

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            ForEach(0..<firstWeekdayOffset, id: \.self) { i in
                Color.clear
                    .frame(height: 20)
                    .id(-(i + 1))
            }

            ForEach(1...daysInMonth, id: \.self) { day in
                dayButton(day)
            }
        }
    }

    private func dayButton(_ day: Int) -> some View {
        Button {
            selection = .date(date(for: day))
        } label: {
            VStack(spacing: 0) {
                Text("\(day)")
                    .font(.caption)
                    .frame(width: 20, height: 20)
                    .background {
                        if isToday(day) {
                            Circle().fill(Color.red)
                        } else if isSelected(day) {
                            Circle().fill(Color.accentColor.opacity(0.3))
                        }
                    }
                    .foregroundStyle(isToday(day) ? .white : .primary)
                
                Circle()
                    .frame(width: 3, height: 3)
                    .foregroundStyle(.blue)
                    .opacity(hasNote(for: day) && !isToday(day) && !isSelected(day) ? 1 : 0)
            }
        }
        .buttonStyle(.plain)
    }

    private func previousMonth() {
        displayedMonth = cal.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    private func nextMonth() {
        displayedMonth = cal.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }

    private func loadNoteDates() {
        Task {
            noteDates = await NotesStore.shared.allNoteDateStrings()
        }
    }
}

#Preview {
    @Previewable @State var selection: MacSelection = .date(Calendar.current.startOfDay(for: .now))
    MacMiniCalendarView(selection: $selection)
        .padding()
        .frame(width: 220)
}
#endif
