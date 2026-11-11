//
//  DatedBlock.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 31.07.26.
//

import Foundation

/// A block paired with the day whose file it belongs to.
///
/// Only the tag view needs this: it shows blocks drawn from many days at
/// once, so it must carry each block's day alongside it to group them and to
/// route edits back to the right file. The daily note has no use for it —
/// there the filename already says which day every block belongs to.
struct DatedBlock: Identifiable, Equatable {
    var day: Date
    var block: Block

    var id: UUID { block.id }
}
