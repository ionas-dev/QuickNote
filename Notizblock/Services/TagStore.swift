//
//  TagStore.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 18.07.26.
//

import Foundation
import Observation

/// Single source of truth for tag definitions. Loaded once at app start;
/// all reads and writes go through this store, which owns `tags.json`.
@MainActor
@Observable
final class TagStore {
    private(set) var tags: [Tag] = []

    private let disk = Disk()
    private var persistTask: Task<Void, Never>?

    func tag(id: UUID) -> Tag? {
        tags.first { $0.id == id }
    }

    /// Resolves ids to tags in `ids` order; unknown ids are dropped.
    func tags(for ids: [UUID]) -> [Tag] {
        ids.compactMap(tag(id:))
    }

    func load() async {
        tags = (try? await disk.loadTags()) ?? []
    }

    func create(_ tag: Tag) {
        tags.append(tag)
        persist()
    }

    func update(_ tag: Tag) {
        guard let idx = tags.firstIndex(where: { $0.id == tag.id }) else { return }
        tags[idx] = tag
        persist()
    }

    func delete(_ tagId: UUID) {
        tags.removeAll { $0.id == tagId }
        persist()
        Task { await NotesStore.shared.deleteTagIndex(tagId) }
    }

    private func persist() {
        let snapshot = tags
        let previous = persistTask
        persistTask = Task {
            await previous?.value
            try? await disk.saveTags(snapshot)
        }
    }

    /// Owns `tags.json` (file I/O off the main actor).
    private actor Disk {
        private var fileURL: URL {
            StorageRoot.tagsFile
        }

        func loadTags() throws -> [Tag] {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Tag].self, from: data)
        }

        func saveTags(_ tags: [Tag]) throws {
            let data = try JSONEncoder().encode(tags)
            try data.write(to: fileURL, options: .atomic)
        }
    }
}
