//
//  StorageError.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 09.08.26.
//

import Foundation

enum StorageError: LocalizedError {
    /// A day file exists but could not be decoded. Deliberately *not*
    /// recoverable in place: the previous implementation treated any decode
    /// failure as "this must be legacy plain text" and overwrote the file,
    /// which destroyed the only copy of the data.
    case unreadable(url: URL, underlying: any Error)

    /// A day file decoded fine but its `schema` doesn't match what this
    /// build writes. Treated the same as unreadable: never silently
    /// rewritten as the current schema, which would destroy the version
    /// signal the envelope exists to carry.
    case unsupportedSchema(url: URL, found: Int, expected: Int)

    var errorDescription: String? {
        switch self {
        case .unreadable(let url, let underlying):
            "Could not read \(url.lastPathComponent): \(underlying.localizedDescription)"
        case .unsupportedSchema(let url, let found, let expected):
            "\(url.lastPathComponent) has schema \(found), expected \(expected)"
        }
    }
}
