//
//  MarkdownScanner.swift
//  MarkdownKit
//

import Foundation

public enum MarkdownScanner {

    /// Delimiters in match order — longer markers first, so `**` wins over `*`
    /// and `~~` is never mistaken for two unmatched tildes.
    private static let delimiters: [(marker: String, style: InlineStyle)] = [
        ("**", .bold),
        ("~~", .strikethrough),
        ("*", .italic),
        ("_", .italic),
        ("`", .code),
    ]

    /// Finds every styled region in `text`. Returns only styled spans — plain
    /// text produces no span — ordered, non-overlapping, and never nested:
    /// once a span is matched the scan resumes after its closing marker.
    public static func scan(_ text: String) -> [Span] {
        var spans: [Span] = []
        var i = text.startIndex

        while i < text.endIndex {
            if let match = matchDelimited(text, at: i) ?? matchLink(text, at: i) {
                spans.append(contentsOf: match.spans)
                i = match.end
            } else {
                i = text.index(after: i)
            }
        }
        return spans
    }

    private static func matchDelimited(
        _ text: String, at i: String.Index
    ) -> (spans: [Span], end: String.Index)? {
        for (marker, style) in delimiters {
            guard text[i...].hasPrefix(marker) else { continue }
            let contentStart = text.index(i, offsetBy: marker.count)
            guard contentStart < text.endIndex,
                  let closer = text.range(of: marker, range: contentStart..<text.endIndex),
                  closer.lowerBound > contentStart          // reject empty content
            else { continue }

            return (
                spans: [
                    Span(range: i..<contentStart, style: style, isMarker: true),
                    Span(range: contentStart..<closer.lowerBound, style: style, isMarker: false),
                    Span(range: closer, style: style, isMarker: true),
                ],
                end: closer.upperBound
            )
        }
        return nil
    }

    /// Wraps `range` in `style`'s marker, or strips the marker if the
    /// selection is already wrapped in exactly that marker. Returns the new
    /// selection alongside the new text, because wrapping shifts the
    /// selection by the marker width and the caret has to follow.
    ///
    /// Works in offsets rather than indices: `String.Index` values taken from
    /// the input are invalid against the mutated result.
    public static func toggle(
        _ style: ToggleableStyle,
        in text: String,
        range: Range<String.Index>
    ) -> (text: String, selection: Range<String.Index>) {
        let marker = style.marker
        let width = marker.count

        let lowerOffset = text.distance(from: text.startIndex, to: range.lowerBound)
        let upperOffset = text.distance(from: text.startIndex, to: range.upperBound)

        let before = String(text.prefix(lowerOffset))
        let selected = String(text[range])
        let after = String(text.dropFirst(upperOffset))

        let newText: String
        let newLowerOffset: Int
        if before.hasSuffix(marker) && after.hasPrefix(marker) {
            newText = String(before.dropLast(width)) + selected + String(after.dropFirst(width))
            newLowerOffset = lowerOffset - width
        } else {
            newText = before + marker + selected + marker + after
            newLowerOffset = lowerOffset + width
        }

        let start = newText.index(newText.startIndex, offsetBy: newLowerOffset)
        let end = newText.index(start, offsetBy: selected.count)
        return (newText, start..<end)
    }

    /// Matches `[text](url)`. The closing `](url)` is emitted as a single
    /// marker span so the display layer dims it in one piece.
    private static func matchLink(
        _ text: String, at i: String.Index
    ) -> (spans: [Span], end: String.Index)? {
        guard text[i] == "[" else { return nil }
        let labelStart = text.index(after: i)
        guard let labelEnd = text.range(of: "]", range: labelStart..<text.endIndex),
              labelEnd.lowerBound > labelStart,
              labelEnd.upperBound < text.endIndex,
              text[labelEnd.upperBound] == "(",
              let close = text.range(of: ")", range: labelEnd.upperBound..<text.endIndex)
        else { return nil }

        let urlStart = text.index(after: labelEnd.upperBound)
        let style = InlineStyle.link(URL(string: String(text[urlStart..<close.lowerBound])))

        return (
            spans: [
                Span(range: i..<labelStart, style: style, isMarker: true),
                Span(range: labelStart..<labelEnd.lowerBound, style: style, isMarker: false),
                Span(range: labelEnd.lowerBound..<close.upperBound, style: style, isMarker: true),
            ],
            end: close.upperBound
        )
    }
}
