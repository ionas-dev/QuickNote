//
//  Block.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 28.06.26.
//

import SwiftUI

nonisolated struct Block: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    /// Raw Markdown. Styling is applied at display time and never persisted,
    /// so what is stored is exactly what the user typed.
    var text: String = ""
    var tagIds: [UUID] = []
    var content: Content = .none

    enum Content: Equatable {
        case none
        case todo(TodoBlockContent)
    }
}

/// Encoded with an explicit `type` discriminator rather than the synthesized
/// `{"todo":{"_0":{…}}}` form, so Swift case names stop being wire format and
/// the JSON is readable by non-Swift tools.
extension Block.Content: Codable {
    private enum CodingKeys: String, CodingKey { case type, todo }
    /// `empty` spells `"none"` on the wire; the Swift name avoids colliding
    /// with `Optional.none` at use sites.
    private enum Kind: String, Codable { case empty = "none", todo }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .type) {
        case .empty:
            self = .none
        case .todo:
            self = .todo(try container.decode(TodoBlockContent.self, forKey: .todo))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode(Kind.empty, forKey: .type)
        case .todo(let todo):
            try container.encode(Kind.todo, forKey: .type)
            try container.encode(todo, forKey: .todo)
        }
    }
}

struct TodoBlockContent: Codable, Equatable {
    var isCompleted: Bool = false
    var remindersId: String
    var dueDate: Date?
    var hasTime: Bool = false
    var location: String?
    var priorityText: String?
    var list: String?
}

extension Binding {
    func caseBinding<Case>(
        get: @escaping (Value) -> Case?,
        set: @escaping (inout Value, Case) -> Void
    ) -> Binding<Case>? {
        guard let caseValue = get(wrappedValue) else { return nil }
        return Binding<Case>(
            get: { get(self.wrappedValue) ?? caseValue },
            set: { newCase in
                var newValue = self.wrappedValue
                set(&newValue, newCase)
                self.wrappedValue = newValue
            }
        )
    }
}

extension Binding where Value == Block.Content {
    var todo: Binding<TodoBlockContent>? {
        caseBinding(
            get: { if case .todo(let p) = $0 { return p } else { return nil } },
            set: { $0 = .todo($1) }
        )
    }
}

extension Block {
    var isCompletedTodo: Bool {
        if case .todo(let content) = content {
            return content.isCompleted
        }
        return false
    }
}

