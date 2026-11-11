//
//  DayCell.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

import SwiftUI

struct DayCell: View {
    let day: Int
    let date: Date
    let hasNote: Bool

    @Environment(NavigationModel.self) private var navigation

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        Button {
            if isToday {
                navigation.path = []
            } else {
                navigation.path.append(.note(date))
            }
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    if isToday {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 32, height: 32)
                    }
                    Text("\(day)")
                        .foregroundStyle(isToday ? .white : .primary)
                        .fontWeight(isToday ? .bold : .medium)
                }
                
                Circle()
                    .frame(width: 5, height: 5)
                    .opacity(hasNote && !isToday ? 1 : 0)
                    .foregroundStyle(.blue)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .buttonStyle(.plain)
    }
}
