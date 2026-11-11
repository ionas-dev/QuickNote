//
//  NotesStore.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 27.06.26.
//

import Foundation

/// The v3 day file. An object rather than a bare array so the schema version
/// has somewhere to live; `date` duplicates the filename deliberately, so an
/// exported or renamed file still knows its day.
private struct DayNote: Codable {
    static let currentSchema = 3

    let schema: Int
    let date: String
    var blocks: [Block]
}

actor NotesStore {
    static let shared = NotesStore()

    private let root: URL

    /// `root` is injectable so tests can run against a temp directory.
    init(root: URL = StorageRoot.url) {
        self.root = root
    }

    private var notesDirectory: URL { StorageRoot.notesDirectory(in: root) }
    private var tagsDirectoryURL: URL { StorageRoot.tagIndexDirectory(in: root) }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private func fileURL(for date: Date) -> URL {
        notesDirectory.appendingPathComponent(NoteDate.string(from: date) + ".json")
    }

    // MARK: - Day notes (source of truth)

    func load(date: Date) throws -> [Block] {
        guard let note = try readDayNote(at: fileURL(for: date)) else {
            return [Block()]
        }
        return note.blocks
    }

    /// Decodes and schema-validates the day file at `url`. Never rewrites a
    /// file it could not read: nil means the file is simply absent; a thrown
    /// `StorageError` means it exists but failed to decode or carries a
    /// schema this build doesn't understand.
    private func readDayNote(at url: URL) throws -> DayNote? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let note = try Self.decoder.decode(DayNote.self, from: data)
            guard note.schema == DayNote.currentSchema else {
                throw StorageError.unsupportedSchema(
                    url: url, found: note.schema, expected: DayNote.currentSchema
                )
            }
            return note
        } catch let error as StorageError {
            throw error
        } catch {
            throw StorageError.unreadable(url: url, underlying: error)
        }
    }

    /// Writes the day file, then updates the affected per-tag date lists.
    /// The day file is written first so a failing index write can never
    /// lose note data; the index self-heals on the next save or reindex.
    func save(_ blocks: [Block], date: Date) throws {
        let oldTagIds = tagIds(in: storedBlocks(date: date))
        let note = DayNote(
            schema: DayNote.currentSchema,
            date: NoteDate.string(from: date),
            blocks: blocks
        )
        try FileManager.default.createDirectory(at: notesDirectory, withIntermediateDirectories: true)
        let data = try Self.encoder.encode(note)
        try data.write(to: fileURL(for: date), options: .atomic)
        updateTagIndexes(date: date, old: oldTagIds, new: tagIds(in: blocks))
    }

    /// Appends `blocks` onto the day file at `date`, used when moving blocks
    /// in from another day. Siblings already stored on `date` are preserved.
    func appendBlocks(_ blocks: [Block], to date: Date) throws {
        guard !blocks.isEmpty else { return }
        var existing = try storedNote(date: date) ?? []
        existing.append(contentsOf: blocks)
        try save(existing, date: date)
    }

    func delete(date: Date) throws {
        let oldTagIds = tagIds(in: storedBlocks(date: date))
        let url = fileURL(for: date)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        updateTagIndexes(date: date, old: oldTagIds, new: [])
    }

    func allNoteDateStrings() -> Set<String> {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: notesDirectory.path)) ?? []
        return Set(files.compactMap { name -> String? in
            guard name.hasSuffix(".json") else { return nil }
            let stem = String(name.dropLast(5))
            guard NoteDate.date(from: stem) != nil else { return nil }
            return stem
        })
    }

    /// The day file as currently stored, or [] if absent or unreadable.
    /// Deliberately swallows errors — safe ONLY for the index-maintenance
    /// callers `save`'s `oldTagIds`, `notes(with:)`, and `reindexTags()`,
    /// where a missed read degrades to a stale index that `reindexTags()`
    /// can rebuild, never to lost data. `mergeTaggedBlocks` must not use
    /// this: there, an unreadable file has to throw rather than read as
    /// empty. Use `storedNote(date:)` there instead.
    private func storedBlocks(date: Date) -> [Block] {
        guard let data = try? Data(contentsOf: fileURL(for: date)),
              let note = try? Self.decoder.decode(DayNote.self, from: data) else { return [] }
        return note.blocks
    }

    /// Throwing counterpart to `storedBlocks`, used only by
    /// `mergeTaggedBlocks`: nil when the day file is absent, its blocks when
    /// it decodes, and a thrown `StorageError` when the file exists but is
    /// unreadable or carries an unsupported schema — so a corrupt day is
    /// skipped by `setTaggedBlocks` rather than deleted or overwritten.
    private func storedNote(date: Date) throws -> [Block]? {
        try readDayNote(at: fileURL(for: date))?.blocks
    }

    // MARK: - Tag index (derived cache: tags/<uuid>.json holds the dates containing that tag)

    private func tagIndexURL(for tagId: UUID) -> URL {
        tagsDirectoryURL.appendingPathComponent("\(tagId.uuidString).json")
    }

    private func tagIds(in blocks: [Block]) -> Set<UUID> {
        Set(blocks.flatMap(\.tagIds))
    }

    private func indexedDates(for tagId: UUID) -> Set<String> {
        guard let data = try? Data(contentsOf: tagIndexURL(for: tagId)),
              let dates = try? Self.decoder.decode([String].self, from: data) else { return [] }
        return Set(dates)
    }

    /// Writes a tag's date list; an empty list deletes the file.
    private func writeTagIndex(_ dates: Set<String>, for tagId: UUID) throws {
        let url = tagIndexURL(for: tagId)
        if dates.isEmpty {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } else {
            try FileManager.default.createDirectory(at: tagsDirectoryURL, withIntermediateDirectories: true)
            let data = try Self.encoder.encode(dates.sorted())
            try data.write(to: url, options: .atomic)
        }
    }

    /// Index errors are swallowed (`try?`): the source of truth is already
    /// written, and the index is rebuildable via `reindexTags`.
    private func updateTagIndexes(date: Date, old: Set<UUID>, new: Set<UUID>) {
        let dateString = NoteDate.string(from: date)
        for tagId in new {
            var dates = indexedDates(for: tagId)
            if dates.insert(dateString).inserted {
                try? writeTagIndex(dates, for: tagId)
            }
        }
        for tagId in old.subtracting(new) {
            var dates = indexedDates(for: tagId)
            if dates.remove(dateString) != nil {
                try? writeTagIndex(dates, for: tagId)
            }
        }
    }

    /// The blocks carrying the tag, grouped by day, newest first. Only the
    /// tagged blocks are returned — untagged siblings on the same day stay in
    /// the day file and are never handed out here. Index entries whose day file
    /// is missing, unreadable, or no longer carries the tag are skipped.
    func notes(with tagId: UUID) -> [(date: Date, blocks: [Block])] {
        var groups: [(date: Date, blocks: [Block])] = []
        for dateString in indexedDates(for: tagId) {
            guard let date = NoteDate.date(from: dateString) else { continue }
            let tagged = storedBlocks(date: date).filter { $0.tagIds.contains(tagId) }
            guard !tagged.isEmpty else { continue }
            groups.append((date: date, blocks: tagged))
        }
        return groups.sorted { $0.date > $1.date }
    }

    /// The blocks carrying no tag at all, grouped by day, newest first.
    /// Unlike `notes(with:)` there's no index to consult — untagged is the
    /// complement of every tag index — so this scans every day file, the
    /// same full scan `reindexTags()` already performs.
    func untaggedNotes() -> [(date: Date, blocks: [Block])] {
        var groups: [(date: Date, blocks: [Block])] = []
        for dateString in allNoteDateStrings() {
            guard let date = NoteDate.date(from: dateString) else { continue }
            let untagged = storedBlocks(date: date).filter { $0.tagIds.isEmpty }
            guard !untagged.isEmpty else { continue }
            groups.append((date: date, blocks: untagged))
        }
        return groups.sorted { $0.date > $1.date }
    }

    /// Reconciles a tag's blocks back into their day files. The affected days
    /// are the days the index currently records for the tag, unioned with the
    /// days of the incoming blocks — so a day the caller emptied still gets the
    /// tag cleared. Untagged siblings on each day are preserved.
    func setTaggedBlocks(_ blocks: [DatedBlock], tagId: UUID) throws {
        let calendar = Calendar.current
        let byDay = Dictionary(grouping: blocks) { calendar.startOfDay(for: $0.day) }

        var days = Set(byDay.keys)
        for dateString in indexedDates(for: tagId) {
            if let date = NoteDate.date(from: dateString) {
                days.insert(calendar.startOfDay(for: date))
            }
        }

        for day in days {
            try mergeTaggedBlocks((byDay[day] ?? []).map(\.block), tagId: tagId, on: day)
        }
    }

    /// Reconciles the untagged view's blocks back into their day files. The
    /// affected days are the days of the incoming blocks, unioned with every
    /// day `untaggedNotes()` currently reports — so a day the caller emptied
    /// (e.g. by tagging its last untagged block) still gets reconciled.
    /// Tagged siblings on each day are preserved.
    func setUntaggedBlocks(_ blocks: [DatedBlock]) throws {
        let calendar = Calendar.current
        let byDay = Dictionary(grouping: blocks) { calendar.startOfDay(for: $0.day) }

        var days = Set(byDay.keys)
        for group in untaggedNotes() {
            days.insert(calendar.startOfDay(for: group.date))
        }

        for day in days {
            try mergeUntaggedBlocks((byDay[day] ?? []).map(\.block), on: day)
        }
    }

    /// Merges `edited` (one day's blocks from a tag view or the untagged
    /// view) into that day's stored file, matched by block id:
    /// - stored block present in `edited` → replaced (dropped if now empty)
    /// - stored block belonging to this view but absent from `edited` → deleted, dropped
    /// - stored block not belonging to this view → untouched sibling, kept in place
    /// - `edited` block not in the file → new, appended (dropped if empty)
    private func mergeBlocks(_ edited: [Block], belongsToView: (Block) -> Bool, on date: Date) throws {
        let editedById = Dictionary(edited.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let stored = try storedNote(date: date) ?? []
        let storedIds = Set(stored.map(\.id))

        var result: [Block] = []
        for block in stored {
            if let replacement = editedById[block.id] {
                if !replacement.text.isEmpty { result.append(replacement) }
            } else if belongsToView(block) {
                // Belonged to this view but was removed there — drop it.
            } else {
                result.append(block)
            }
        }
        for block in edited where !storedIds.contains(block.id) && !block.text.isEmpty {
            result.append(block)
        }

        if result.isEmpty {
            try delete(date: date)
        } else {
            try save(result, date: date)
        }
    }

    private func mergeTaggedBlocks(_ edited: [Block], tagId: UUID, on date: Date) throws {
        try mergeBlocks(edited, belongsToView: { $0.tagIds.contains(tagId) }, on: date)
    }

    private func mergeUntaggedBlocks(_ edited: [Block], on date: Date) throws {
        try mergeBlocks(edited, belongsToView: { $0.tagIds.isEmpty }, on: date)
    }

    /// Called by TagStore when a tag definition is deleted.
    func deleteTagIndex(_ tagId: UUID) {
        let url = tagIndexURL(for: tagId)
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Rebuilds every index file by scanning all day notes, then removes
    /// stale index files. Recovery tool: the index is derived state and this
    /// regenerates all of it.
    func reindexTags() throws {
        var index: [UUID: Set<String>] = [:]
        for dateString in allNoteDateStrings() {
            guard let date = NoteDate.date(from: dateString) else { continue }
            for tagId in tagIds(in: storedBlocks(date: date)) {
                index[tagId, default: []].insert(dateString)
            }
        }
        for (tagId, dates) in index {
            try writeTagIndex(dates, for: tagId)
        }

        let contents = (try? FileManager.default.contentsOfDirectory(
            at: tagsDirectoryURL, includingPropertiesForKeys: nil
        )) ?? []
        for item in contents {
            if item.pathExtension == "json",
               let tagId = UUID(uuidString: item.deletingPathExtension().lastPathComponent),
               index[tagId] == nil {
                try FileManager.default.removeItem(at: item)
            }
        }
    }

}
