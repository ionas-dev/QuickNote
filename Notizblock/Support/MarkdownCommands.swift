//
//  MarkdownCommands.swift
//  Notizblock
//

import SwiftUI

/// The focused block editor's formatting actions, published up to whichever
/// list owns the keyboard bar.
///
/// `GrowingTextEditor` cannot host the Bold/Italic buttons itself: every block
/// is its own editor, and a second `.keyboard`-placement toolbar group renders
/// as a second floating capsule beside the one `BlockList`/`GroupedBlockList`
/// already provide. Publishing the actions instead lets those lists put the
/// buttons inside their existing capsule, next to Dismiss Keyboard.
///
/// A reference type, held in the editor's `@State`, deliberately: a struct of
/// closures is never equal to itself, so republishing one on every body pass
/// invalidated the reading list, which re-rendered the editor, which published
/// again — a spin at 100% CPU. Identity here is stable for the editor's
/// lifetime, and `==` is identity, so the value only "changes" when focus
/// actually moves to a different editor.
final class MarkdownCommands: Equatable {
    var toggleBold: () -> Void = {}
    var toggleItalic: () -> Void = {}

    static func == (lhs: MarkdownCommands, rhs: MarkdownCommands) -> Bool {
        lhs === rhs
    }
}

extension FocusedValues {
    @Entry var markdownCommands: MarkdownCommands?
}
