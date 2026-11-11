//
//  MarkdownStyler.swift
//  Notizblock
//

import SwiftUI
import MarkdownKit

/// Turns raw Markdown into styled text for display. The returned
/// `AttributedString` has *exactly* the characters of the input — markers
/// included — so a `String(result.characters)` round trip is lossless and
/// editor offsets map 1:1 onto the stored string.
enum MarkdownStyler {

    /// `design` is the user's Note Font Design. It matters because italic has
    /// to be applied as a real font, and that font must keep the design the
    /// rest of the text uses.
    static func attributed(
        _ markdown: String,
        enabled: Bool = true,
        design: Font.Design = .default
    ) -> AttributedString {
        var result = AttributedString(markdown)
        guard enabled else { return result }

        for span in MarkdownScanner.scan(markdown) {
            let range = attributedRange(of: span.range, in: markdown, within: result)
            apply(span, design: design, to: &result[range])
        }
        return result
    }

    private static func apply(
        _ span: Span,
        design: Font.Design,
        to text: inout AttributedSubstring
    ) {
        switch span.style {
        case .bold: text.inlinePresentationIntent = .stronglyEmphasized
        case .italic:
            text.inlinePresentationIntent = .emphasized
            text.font = italicFont(for: design)
        case .strikethrough: text.inlinePresentationIntent = .strikethrough
        case .code:
            // Unlike bold/italic/strikethrough, SwiftUI renders no visible
            // change for `.code` — it is a semantic intent with no font
            // substitution behind it (verified on iOS 26.2, in both `Text`
            // and `TextEditor`). The monospaced font has to be set here, or
            // code spans look identical to plain text. Display-only: this
            // font never reaches storage.
            text.inlinePresentationIntent = .code
            text.font = .system(.body, design: .monospaced)
        case .link(let url):
            if !span.isMarker, let url { text.link = url }
        }
        if span.isMarker {
            text.foregroundColor = MARKDOWN_MARKER_COLOR
        }
    }

    /// Italic has to be a real font, not just `.emphasized`.
    ///
    /// SF Rounded has no italic face: asking the SDK for `.italic` on
    /// `.rounded` resolves back to `AppleSystemUIFontRounded-Regular` with the
    /// italic trait dropped, so the text stays upright. Bold was unaffected
    /// because Rounded does have weight variants — which is why the failure
    /// looked like "only italics are broken". `.default`, `.serif` and
    /// `.monospaced` all resolve to a genuine italic face.
    ///
    /// So italic spans fall back to the default design when the chosen one
    /// cannot slant. Those words render in SF rather than SF Rounded — a
    /// slight letterform mismatch, taken deliberately over italic silently
    /// doing nothing.
    private static func italicFont(for design: Font.Design) -> Font {
        let slantable: Font.Design = design == .rounded ? .default : design
        return .system(.body, design: slantable).italic()
    }

    /// Bridges a `String` range onto the same characters in an
    /// `AttributedString`, via character offsets. Non-optional: `attributed`
    /// is built from `source`, so any offset derived from `source` is in
    /// bounds by construction.
    ///
    /// `AttributedString.index(_:offsetByCharacters:)` has no `limitedBy:`
    /// overload — verified against the iOS 26.2 SDK.
    private static func attributedRange(
        of range: Range<String.Index>,
        in source: String,
        within attributed: AttributedString
    ) -> Range<AttributedString.Index> {
        let lower = source.distance(from: source.startIndex, to: range.lowerBound)
        let length = source.distance(from: range.lowerBound, to: range.upperBound)
        let start = attributed.index(attributed.startIndex, offsetByCharacters: lower)
        let end = attributed.index(start, offsetByCharacters: length)
        return start..<end
    }
}
