//
//  InlineStyle.swift
//  MarkdownKit
//

import Foundation

/// An inline Markdown style the scanner recognises.
public enum InlineStyle: Equatable, Sendable {
    case bold
    case italic
    case code
    case strikethrough
    case link(URL?)
}

/// The subset of styles with a toolbar button behind them, and therefore a
/// wrap/unwrap operation. Code, strikethrough and links are typed by hand.
public enum ToggleableStyle: Equatable, Sendable {
    case bold
    case italic

    public var marker: String {
        switch self {
        case .bold: "**"
        case .italic: "*"
        }
    }
}

/// A styled region of the source string. `isMarker` distinguishes the literal
/// syntax characters (`**`) from the content they wrap, so the display layer
/// can dim the former while styling the latter.
public struct Span: Equatable, Sendable {
    public let range: Range<String.Index>
    public let style: InlineStyle
    public let isMarker: Bool

    public init(range: Range<String.Index>, style: InlineStyle, isMarker: Bool) {
        self.range = range
        self.style = style
        self.isMarker = isMarker
    }
}
