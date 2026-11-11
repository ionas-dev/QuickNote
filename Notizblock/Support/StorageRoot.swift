//
//  StorageRoot.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 18.07.26.
//

import Foundation

/// The single authority for where persisted files live. The later iCloud
/// move changes `url` to the app's ubiquity container Documents directory.
nonisolated enum StorageRoot {
    static var url: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Day notes. A subdirectory so the user's notes are not mixed with
    /// derived cache files, and so an export is one folder.
    static func notesDirectory(in root: URL) -> URL {
        root.appendingPathComponent("Notes", isDirectory: true)
    }

    /// Derived, rebuildable tag index. Dot-prefixed so it stays hidden from
    /// Files.app and Finder.
    static func tagIndexDirectory(in root: URL) -> URL {
        root.appendingPathComponent(".index", isDirectory: true)
            .appendingPathComponent("tags", isDirectory: true)
    }

    static var tagsFile: URL {
        url.appendingPathComponent("tags.json")
    }
}
