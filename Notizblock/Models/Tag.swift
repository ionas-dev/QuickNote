//
//  Tag.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 28.06.26.
//

import Foundation

enum TagImage: Codable, Sendable, Hashable {
    case emoji(String)
    case color(String) // hex "#RRGGBB"
}

struct Tag: Identifiable, Hashable, Sendable, Codable {
    var id: UUID = UUID()
    var name: String
    var style: TagImage
}
