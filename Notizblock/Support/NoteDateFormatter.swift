//
//  NoteDateFormatter.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

import Foundation

/// Formatting for the "YYYY-MM-DD" day strings used as note file names.
///
/// The formatter is built per call rather than held in a `static let`: a
/// cached one captures `TimeZone.current` at first use, so changing timezone
/// mid-session silently shifts which file a given `Date` maps to.
nonisolated enum NoteDate {
    private static func formatter() -> ISO8601DateFormatter {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        f.timeZone = .current
        return f
    }

    static func string(from date: Date) -> String {
        formatter().string(from: date)
    }

    static func date(from string: String) -> Date? {
        formatter().date(from: string)
    }
}
