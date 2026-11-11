//
//  MarkdownToggleTests.swift
//  MarkdownKitTests
//

import Testing
import Foundation
@testable import MarkdownKit

/// Toggles over an offset range, returning the new text and the new selection
/// as offsets, so tests read without String.Index noise.
private func toggle(
    _ style: ToggleableStyle, _ text: String, _ bounds: Range<Int>
) -> (text: String, selection: Range<Int>) {
    let lower = text.index(text.startIndex, offsetBy: bounds.lowerBound)
    let upper = text.index(text.startIndex, offsetBy: bounds.upperBound)
    let result = MarkdownScanner.toggle(style, in: text, range: lower..<upper)
    let lo = result.text.distance(from: result.text.startIndex, to: result.selection.lowerBound)
    let hi = result.text.distance(from: result.text.startIndex, to: result.selection.upperBound)
    return (result.text, lo..<hi)
}

@Test func wrapsSelectionInBold() {
    let result = toggle(.bold, "hello world", 6..<11)
    #expect(result.text == "hello **world**")
    #expect(result.selection == 8..<13)
}

@Test func wrapsSelectionInItalic() {
    let result = toggle(.italic, "hello world", 0..<5)
    #expect(result.text == "*hello* world")
    #expect(result.selection == 1..<6)
}

@Test func unwrapsAlreadyBoldSelection() {
    let result = toggle(.bold, "hello **world**", 8..<13)
    #expect(result.text == "hello world")
    #expect(result.selection == 6..<11)
}

@Test func wrapThenUnwrapReturnsOriginal() {
    let original = "hello world"
    let wrapped = toggle(.bold, original, 6..<11)
    let lower = wrapped.text.index(wrapped.text.startIndex, offsetBy: wrapped.selection.lowerBound)
    let upper = wrapped.text.index(wrapped.text.startIndex, offsetBy: wrapped.selection.upperBound)
    let unwrapped = MarkdownScanner.toggle(.bold, in: wrapped.text, range: lower..<upper)
    #expect(unwrapped.text == original)
    #expect(String(unwrapped.text[unwrapped.selection]) == "world")
}

@Test func togglingEmptySelectionInsertsEmptyMarkerPair() {
    let result = toggle(.bold, "ab", 1..<1)
    #expect(result.text == "a****b")
    #expect(result.selection == 3..<3)
}

@Test func boldDoesNotUnwrapItalicMarkers() {
    let result = toggle(.bold, "*word*", 1..<5)
    #expect(result.text == "***word***")
}

@Test func wrapsAtStringBoundaries() {
    #expect(toggle(.bold, "abc", 0..<3).text == "**abc**")
    #expect(toggle(.italic, "abc", 0..<3).text == "*abc*")
}

@Test func wrapsWholeEmptyString() {
    let result = toggle(.bold, "", 0..<0)
    #expect(result.text == "****")
    #expect(result.selection == 2..<2)
}

/// The selection must keep covering the same characters after a toggle,
/// because the caret follows it in the editor.
@Test func selectionStillCoversSameContent() {
    let wrapped = MarkdownScanner.toggle(
        .italic,
        in: "one two three",
        range: "one two three".range(of: "two")!
    )
    #expect(String(wrapped.text[wrapped.selection]) == "two")
}
