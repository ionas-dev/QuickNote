//
//  CalendarView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 28.06.26.
//

import SwiftUI

struct CalendarView: View {
    @State private var noteDates: Set<String> = []
    @State private var visibleMonth: Date?
    @State private var headerHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    
    
    @AppStorage(AppSettings.titleFontDesign) private var titleFontDesign: FontDesign

    private var cal: Calendar { Calendar.current }

    private var toolbarMonth: Date {
        visibleMonth ?? currentMonth
    }

    private var toolbarMonthTitle: String {
        toolbarMonth.formatted(.dateTime.month(.wide).year())
    }

    private var weekdayHeaders: [String] {
        let symbols = cal.shortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var headerBackgroundColor: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }

    private let weekdayColumns = Array(repeating: GridItem(.flexible()), count: 7)

    private var earliestNoteYear: Int {
        guard let earliest = noteDates.min(),
              let date = NoteDate.date(from: earliest) else {
            return cal.component(.year, from: .now)
        }
        return cal.component(.year, from: date)
    }

    private var currentMonth: Date {
        let components = cal.dateComponents([.year, .month], from: .now)
        return cal.date(from: components) ?? .now
    }

    private var months: [Date] {
        let currentYear = cal.component(.year, from: .now)
        guard let start = cal.date(from: DateComponents(year: earliestNoteYear, month: 1)) else { return [] }
        let totalMonths = (currentYear + 1 - earliestNoteYear + 1) * 12
        return (0..<totalMonths).compactMap { offset in
            cal.date(byAdding: .month, value: offset, to: start)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(Array(months.enumerated()), id: \.element) { index, month in
                    MonthView(month: month, noteDates: noteDates)
                        .id(month)
                        .opacity(month == toolbarMonth ? 1 : 0.4)

                    if index < months.count - 1 {
                        MonthDivider(month: months[index + 1])
                    }
                }

                /// without this trailing spacer the last month has no room to scroll past the anchor point, so it can never become `visibleMonth`
                Color.clear
                    .frame(height: scrollViewHeight * 0.3)
            }
            .padding()
            .scrollTargetLayout()
        }
        /// measures the scroll view's own visible height so the trailing spacer above can be sized relative to it
        .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { scrollViewHeight = $0 }
        .contentMargins(.top, headerHeight, for: .scrollContent)
        .scrollPosition(id: $visibleMonth, anchor: UnitPoint(x: 0, y: 0.25))
        .task(loadNoteDates)
        .overlay(alignment: .top, content: header)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func loadNoteDates() {
        Task {
            noteDates = await NotesStore.shared.allNoteDateStrings()
            visibleMonth = currentMonth
        }
    }

    private func header() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if toolbarMonth == currentMonth {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }

                Text(toolbarMonthTitle)
                    .font(.system(.largeTitle, design: titleFontDesign.fontDesign))
                    .bold()
            }

            LazyVGrid(columns: weekdayColumns, spacing: 8) {
                ForEach(weekdayHeaders, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.bottom)
        .background {
            headerBackgroundColor
                .opacity(0.7)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
        /// measures the rendered header height so `.contentMargins(.top:)` above can reserve exactly enough scroll inset for it
        .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { headerHeight = $0 }
    }
}

#Preview {
    @Previewable @State var navigation = NavigationModel()
    NavigationStack(path: $navigation.path) {
        CalendarView()
    }
    .environment(navigation)
}
