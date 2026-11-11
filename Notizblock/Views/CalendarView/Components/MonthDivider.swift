//
//  MonthDivider.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 18.07.26.
//

import SwiftUI

struct MonthDivider: View {
    let month: Date

    @State private var contentHeight: CGFloat = 26

    private var cal: Calendar { Calendar.current }

    private var firstWeekdayOffset: Int {
        let weekday = cal.component(.weekday, from: month)
        return (weekday - cal.firstWeekday + 7) % 7
    }

    var body: some View {
        /// only way to learn the row's actual width so the label/rule can be indented to align under the upcoming month's first-day column
        GeometryReader { proxy in
            let startX = proxy.size.width / 7 * CGFloat(firstWeekdayOffset)

            VStack(alignment: .leading, spacing: 2) {
                ViewThatFits(in: .horizontal) {
                    Text(month, format: .dateTime.month(.wide))
                    Text(month, format: .dateTime.month(.abbreviated))
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(1)

                Rectangle()
                    #if os(macOS)
                    .fill(Color(nsColor: .separatorColor))
                    #else
                    .fill(Color(.separator))
                    #endif
                    .frame(height: 1)
            }
            .padding(.leading, startX)
            /// feeds the measured content height back into the frame below so GeometryReader doesn't leave leftover empty space under the rule
            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }) { contentHeight = $0 }
        }
        .frame(height: contentHeight)
        .padding(.top, 12)
    }
}
