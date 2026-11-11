//
//  MarkdownScannerTests.swift
//  MarkdownKitTests
//

import Testing
import Foundation
@testable import MarkdownKit

/// Renders spans as (substring, style, isMarker) so assertions read without
/// String.Index noise.
private func described(_ text: String) -> [(String, InlineStyle, Bool)] {
    MarkdownScanner.scan(text).map { (String(text[$0.range]), $0.style, $0.isMarker) }
}

@Test func scansBold() {
    let result = described("a **b** c")
    #expect(result.count == 3)
    #expect(result[0] == ("**", .bold, true))
    #expect(result[1] == ("b", .bold, false))
    #expect(result[2] == ("**", .bold, true))
}

@Test func scansItalicWithBothMarkers() {
    #expect(described("*x*").map(\.0) == ["*", "x", "*"])
    #expect(described("_x_").map(\.0) == ["_", "x", "_"])
    #expect(described("*x*").allSatisfy { $0.1 == .italic })
    #expect(described("_x_").allSatisfy { $0.1 == .italic })
}

@Test func scansCodeAndStrikethrough() {
    #expect(described("`c`").map(\.1) == [.code, .code, .code])
    #expect(described("~~s~~").map(\.1) == [.strikethrough, .strikethrough, .strikethrough])
    #expect(described("~~s~~").map(\.0) == ["~~", "s", "~~"])
}

@Test func scansLink() {
    let result = described("see [text](https://example.com) end")
    #expect(result.map(\.0) == ["[", "text", "](https://example.com)"])
    #expect(result[1].1 == .link(URL(string: "https://example.com")))
    #expect(result[1].2 == false)
    #expect(result[0].2 == true)
    #expect(result[2].2 == true)
}

@Test func boldWinsOverItalicAtSamePosition() {
    #expect(described("**b**").map(\.0) == ["**", "b", "**"])
}

@Test func unclosedMarkerProducesNoSpans() {
    #expect(MarkdownScanner.scan("**bold").isEmpty)
    #expect(MarkdownScanner.scan("a * b").isEmpty)
    #expect(MarkdownScanner.scan("[text](unclosed").isEmpty)
}

@Test func emptyContentProducesNoSpans() {
    #expect(MarkdownScanner.scan("****").isEmpty)
    #expect(MarkdownScanner.scan("``").isEmpty)
}

@Test func emptyStringProducesNoSpans() {
    #expect(MarkdownScanner.scan("").isEmpty)
}

@Test func plainTextProducesNoSpans() {
    #expect(MarkdownScanner.scan("just some plain words").isEmpty)
}

@Test func adjacentSpansBothScanned() {
    #expect(described("**a**`b`").map(\.0) == ["**", "a", "**", "`", "b", "`"])
}

@Test func nestedMarkersStyleOuterOnly() {
    // No nesting in v1: the inner asterisks are content, not a second span.
    let result = described("**bold *inner* here**")
    #expect(result.map(\.2) == [true, false, true])
    #expect(result[1].0 == "bold *inner* here")
}

@Test func spansAreOrderedNonOverlappingAndInBounds() {
    let text = "**a** plain *b* `c` ~~d~~ [e](https://x.y)"
    let spans = MarkdownScanner.scan(text)
    #expect(!spans.isEmpty)
    for span in spans {
        #expect(span.range.lowerBound >= text.startIndex)
        #expect(span.range.upperBound <= text.endIndex)
    }
    for (a, b) in zip(spans, spans.dropFirst()) {
        #expect(a.range.upperBound <= b.range.lowerBound)
    }
}

/// The invariant the whole design rests on: applying spans as attributes
/// never adds or removes a character.
@Test func applyingSpansPreservesCharacters() {
    let corpus = [
        "", "plain text", "**bold**", "*i* and _j_", "`code`", "~~s~~",
        "[link](https://example.com)", "**a**`b`~~c~~",
        "**unclosed", "emoji 🎉 **bold** 🎉", "multi\nline **b**"
    ]
    for text in corpus {
        var attributed = AttributedString(text)
        for span in MarkdownScanner.scan(text) {
            let lower = text.distance(from: text.startIndex, to: span.range.lowerBound)
            let length = text.distance(from: span.range.lowerBound, to: span.range.upperBound)
            let start = attributed.index(attributed.startIndex, offsetByCharacters: lower)
            let end = attributed.index(start, offsetByCharacters: length)
            attributed[start..<end].inlinePresentationIntent = .stronglyEmphasized
        }
        #expect(String(attributed.characters) == text)
    }
}
