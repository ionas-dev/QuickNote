//
//  GrowingTextEditor.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 13.07.26.
//

import SwiftUI
import MarkdownKit
#if os(macOS)
import AppKit
#endif

/// One custom action appended to a block's right-click menu on macOS. Unused
/// on iOS, where `TextBlockView`/`TodoBlockView`'s own `.contextMenu` already
/// supplies these directly.
struct BlockMenuAction {
    let title: String
    let systemImage: String
    let isDestructive: Bool
    let action: () -> Void

    /// Takes a `LocalizationValue` because the title ends up in an `NSMenuItem`,
    /// which — unlike SwiftUI's `Button` — does no lookup of its own.
    init(_ title: String.LocalizationValue, systemImage: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = String(localized: title)
        self.systemImage = systemImage
        self.isDestructive = isDestructive
        self.action = action
    }
}

struct GrowingTextEditor: View {

    @AppStorage(AppSettings.noteFontDesign) private var noteFontDesign: FontDesign
    @AppStorage(AppSettings.markdownEnabled) private var markdownEnabled: Bool

    @FocusState private var isFocused: Bool
    @State private var selection = AttributedTextSelection()
    /// The styled buffer the editor actually edits, kept as state rather than
    /// recomputed per render. This is load-bearing, not an optimisation:
    /// `AttributedTextSelection` is a set of indices *into a specific
    /// `AttributedString` instance*, and `TextEditor` silently discards a
    /// selection whose indices don't belong to the instance it is currently
    /// holding — it keeps its own caret instead. A computed `Binding` mints a
    /// fresh `AttributedString` on every read, so a programmatic caret move was
    /// stale the moment the next render ran and never took effect. Owning the
    /// instance is what lets `toggle` address it.
    @State private var styled = AttributedString()
    /// Stable for this editor's lifetime, so publishing it as a focused value
    /// does not invalidate the reading list on every body pass.
    @State private var commands = MarkdownCommands()

    @Binding var text: String
    var isExpanded: Bool
    /// Extra actions merged into the block's right-click menu on macOS. A SwiftUI
    /// `.contextMenu` on an ancestor view never fires when the click lands on the
    /// text content itself — macOS routes that to NSTextView's own menu instead —
    /// so on macOS these are appended directly to that native menu (see
    /// `MacBlockTextView` below). Ignored on iOS, where `.contextMenu` already
    /// covers the whole row.
    var menuActions: [BlockMenuAction] = []
    var isSelecting: Bool = false

    var body: some View {
        /// Text with padding is needed in the ZStack since TextEditor doesn't report the right size of its content
        ZStack {
            #if os(macOS)
            MacBlockTextView(text: $text, menuActions: menuActions, markdownEnabled: markdownEnabled, noteFontDesign: noteFontDesign)
            #else
            TextEditor(text: $styled, selection: $selection)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .focused($isFocused)
                .disabled(isSelecting)
                .font(.system(.body, design: noteFontDesign.fontDesign))
                .focusedValue(\.markdownCommands, markdownEnabled ? commands : nil)
                .onAppear(perform: bindCommands)
                .onAppear(perform: reloadStyled)
                .onChange(of: text, reloadStyled)
                .onChange(of: markdownEnabled, reloadStyled)
                .onChange(of: styled, commitEdit)
            #endif

            /// Without the prefix A the height would increase with the first keystroke
            Text("A\(text)")
                .padding(.top, 20)
                .padding(.bottom, 10)
                .opacity(0)
                #if os(iOS)
                .font(.system(.body, design: noteFontDesign.fontDesign))
                #endif
        }
        .fixedSize(horizontal: false, vertical: isExpanded ? false : true)
    }


    // MARK: - Text Editing

    #if os(iOS)
    /// Rebuilds the styled buffer from `text`. For changes that originate
    /// outside the editor: first appearance, a different block's text arriving
    /// in this row, or the Markdown setting being flipped.
    private func reloadStyled() {
        let restyled = MarkdownStyler.attributed(text, enabled: markdownEnabled, design: noteFontDesign.fontDesign)
        if restyled != styled { styled = restyled }
    }

    /// The other direction: the user edited in the editor. Styling never adds
    /// or removes characters, so `String(styled.characters)` is exactly what
    /// they typed; restyling it afterwards is what makes typed markers style
    /// live. Both writes are guarded against no-ops, so this and
    /// `reloadStyled` settle instead of feeding each other.
    private func commitEdit() {
        let raw = String(styled.characters)
        if raw != text { text = raw }
        let restyled = MarkdownStyler.attributed(raw, enabled: markdownEnabled, design: noteFontDesign.fontDesign)
        if restyled != styled { styled = restyled }
    }

    /// Points `commands` at this editor's toggles. Assigned once, not
    /// rebuilt per body pass: the closures capture `self`, but `text` is a
    /// `Binding` and `styled`/`selection` are `@State`, so their storage
    /// outlives any particular struct value and a captured older `self`
    /// still reads and writes the live ones.
    private func bindCommands() {
        commands.toggleBold = { toggle(.bold) }
        commands.toggleItalic = { toggle(.italic) }
    }

    private func toggleBold() { toggle(.bold) }
    private func toggleItalic() { toggle(.italic) }

    /// Formatting is now a text edit, not an attribute edit: wrap the
    /// selection in the marker, or strip it if already wrapped.
    private func toggle(_ style: ToggleableStyle) {
        guard let range = selectedStringRange() else { return }
        let result = MarkdownScanner.toggle(style, in: text, range: range)
        text = result.text
        // `styled` has to be restyled here, before the selection is built from
        // it: the caret is expressed as indices into this exact instance.
        styled = MarkdownStyler.attributed(result.text, enabled: markdownEnabled, design: noteFontDesign.fontDesign)
        selection = attributedSelection(for: result.selection, in: result.text)
    }

    /// Mirrors `selectedStringRange()` in the opposite direction: maps
    /// `toggle`'s returned `text`-relative selection back onto `styled`, so the
    /// caret follows the marker that was just inserted/removed instead of
    /// staying at its pre-toggle offset. Indexes `styled` — not a freshly built
    /// equivalent — because only indices into the instance the editor holds are
    /// honoured (see `styled`'s doc comment).
    private func attributedSelection(for range: Range<String.Index>, in newText: String) -> AttributedTextSelection {
        let lower = newText.distance(from: newText.startIndex, to: range.lowerBound)
        let upper = newText.distance(from: newText.startIndex, to: range.upperBound)
        let start = styled.index(styled.startIndex, offsetByCharacters: lower)

        guard lower != upper else {
            return AttributedTextSelection(insertionPoint: start)
        }
        let end = styled.index(styled.startIndex, offsetByCharacters: upper)
        return AttributedTextSelection(range: start..<end)
    }

    /// Maps the editor's selection onto `text` by character offset.
    ///
    /// Both cases of `AttributedTextSelection.Indices` must be handled:
    /// `.insertionPoint` is the common one — tapping Bold with no selection
    /// collapses to a zero-length range, and `toggle` inserts an empty marker
    /// pair at the caret. Handling only `.ranges` makes the buttons silently
    /// do nothing.
    private func selectedStringRange() -> Range<String.Index>? {
        let attributed = styled
        let lower: Int
        let upper: Int

        switch selection.indices(in: attributed) {
        case .insertionPoint(let point):
            let offset = attributed.characters.distance(from: attributed.startIndex, to: point)
            lower = offset
            upper = offset
        case .ranges(let set):
            guard let first = set.ranges.first, let last = set.ranges.last else { return nil }
            lower = attributed.characters.distance(from: attributed.startIndex, to: first.lowerBound)
            upper = attributed.characters.distance(from: attributed.startIndex, to: last.upperBound)
        }

        guard let start = text.index(text.startIndex, offsetBy: lower, limitedBy: text.endIndex),
              let end = text.index(text.startIndex, offsetBy: upper, limitedBy: text.endIndex)
        else { return nil }
        return start..<end
    }
    #endif
}

#if os(macOS)
/// AppKit-backed text surface for macOS, used in place of SwiftUI's `TextEditor`
/// specifically so `menuActions` can be merged into NSTextView's own right-click
/// menu (see `GrowingTextEditor.menuActions`'s doc comment for why this exists).
private struct MacBlockTextView: NSViewRepresentable {
    @Binding var text: String
    var menuActions: [BlockMenuAction]
    var markdownEnabled: Bool
    var noteFontDesign: FontDesign

    /// Matches the month/year font size in `DailyNoteView`'s day header, so
    /// block text isn't noticeably smaller than the surrounding chrome.
    private static let defaultFontSize: CGFloat = 15

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> MenuAugmentedTextView {
        let textView = MenuAugmentedTextView()
        textView.coordinator = context.coordinator
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        /// No enclosing `NSScrollView` (see this file's class doc comment), so
        /// the text container should track the view's width and the view
        /// itself just grows to fit its content rather than scrolling.
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.autoresizingMask = [.width, .height]
        textView.font = NSFont.systemFont(ofSize: Self.defaultFontSize)
        textView.typingAttributes = [.font: NSFont.systemFont(ofSize: Self.defaultFontSize)]
        context.coordinator.menuActions = menuActions
        context.coordinator.markdownEnabled = markdownEnabled
        context.coordinator.noteFontDesign = noteFontDesign
        context.coordinator.applyStyling(to: textView)
        return textView
    }

    /// The restyle-while-typing path (`Coordinator.textDidChange`) has to
    /// live on the coordinator, not here: this representable is a struct
    /// recreated on every render, so it can't hold state across the
    /// `NSTextViewDelegate` callbacks that fire between updates. `markdownEnabled`
    /// is handed to the coordinator the same way `menuActions` already is.
    func updateNSView(_ textView: MenuAugmentedTextView, context: Context) {
        context.coordinator.menuActions = menuActions
        context.coordinator.markdownEnabled = markdownEnabled
        context.coordinator.noteFontDesign = noteFontDesign
        guard !context.coordinator.isEditing || textView.string != text else { return }
        context.coordinator.applyStyling(to: textView)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var menuActions: [BlockMenuAction] = []
        var markdownEnabled = true
        var noteFontDesign: FontDesign = .sans
        var isEditing = false
        /// Re-entrancy guard: `applyStyling` mutates `textStorage`, which
        /// AppKit reports back through `textDidChange` before
        /// `setAttributedString` even returns. Without this flag that second
        /// call would call `applyStyling` again, which mutates `textStorage`
        /// again, forever.
        private var isRestyling = false

        init(text: Binding<String>) {
            _text = text
        }

        func textDidBeginEditing(_ notification: Notification) {
            isEditing = true
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
            // Restyle on every keystroke, not just when focus is lost —
            // otherwise typed `**bold**` stays as plain, unstyled asterisks
            // until the user taps away.
            applyStyling(to: textView)
        }

        func textDidEndEditing(_ notification: Notification) {
            isEditing = false
        }

        /// Re-applies attributes without disturbing the caret or, on the
        /// keystroke path, the undo stack. Dispatches on whether the styled
        /// string is the same length as what's already in `textStorage`:
        /// equal lengths mean `text` still has the exact characters
        /// `textStorage` already holds (the common case — a keystroke, or a
        /// markdownEnabled toggle with no content change), so only
        /// attributes need to move. A mismatch means `text` was swapped out
        /// from under the view entirely (e.g. switching to a different
        /// day's, shorter block), which needs a real content replace.
        func applyStyling(to textView: NSTextView) {
            guard !isRestyling, let textStorage = textView.textStorage else { return }
            isRestyling = true
            defer { isRestyling = false }

            let styled = NSAttributedString(MarkdownStyler.attributed(text, enabled: markdownEnabled, design: noteFontDesign.fontDesign))

            if styled.length == textStorage.length {
                applyAttributesOnly(styled, to: textStorage)
            } else {
                replaceContents(with: styled, on: textView)
            }
        }

        /// Restyles in place without touching characters, so Cmd+Z keeps
        /// working while the user types. `setAttributedString` performs a
        /// character-level edit (`.editedCharacters`) outside AppKit's
        /// `shouldChangeText`/`didChangeText` transaction, which is what
        /// clobbers the undo stack; `setAttributes`/`addAttributes` post
        /// only `.editedAttributes` edits, which the undo manager never
        /// tracked in the first place, so this can run on every keystroke
        /// for free. The full range is reset to the base attributes first
        /// so a marker's dimmed color/`.code` font don't linger once the
        /// user deletes the marker that produced them.
        private func applyAttributesOnly(_ styled: NSAttributedString, to textStorage: NSTextStorage) {
            let fullRange = NSRange(location: 0, length: textStorage.length)
            textStorage.beginEditing()
            textStorage.setAttributes(Self.baseAttributes, range: fullRange)
            styled.enumerateAttributes(in: NSRange(location: 0, length: styled.length)) { attributes, range, _ in
                guard !attributes.isEmpty else { return }
                textStorage.addAttributes(attributes, range: range)
            }
            textStorage.endEditing()
        }

        /// Full-content replace for when `text` didn't come from this
        /// view's own typing (its length disagrees with what's already in
        /// `textStorage`), so undo-stack clobbering here is expected and
        /// acceptable. The caret is re-derived rather than trusted as-is:
        /// an offset valid for the old, longer content can be out of
        /// bounds for the new, shorter one and crash
        /// `NSTextView.selectedRanges`'s setter, so every saved range is
        /// clamped to the new content's length before it's restored.
        private func replaceContents(with styled: NSAttributedString, on textView: NSTextView) {
            let selected = textView.selectedRanges.map {
                NSValue(range: Self.clamp($0.rangeValue, toLength: styled.length))
            }
            textView.textStorage?.setAttributedString(styled)
            textView.selectedRanges = selected
        }

        /// Matches `typingAttributes` (`.font`) plus the standard label
        /// color, so resetting to this before re-layering `styled`'s runs
        /// reproduces exactly what unstyled text already looks like.
        private static let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: MacBlockTextView.defaultFontSize),
            .foregroundColor: NSColor.textColor,
        ]

        /// Confines `range` to `0..<length`, sliding a range that starts
        /// past the end back to a zero-length selection at the end rather
        /// than leaving it out of bounds.
        private static func clamp(_ range: NSRange, toLength length: Int) -> NSRange {
            let location = min(range.location, length)
            return NSRange(location: location, length: min(range.length, length - location))
        }
    }

    /// Custom `NSTextView` subclass whose only job is appending the block's
    /// menu actions (and a Share item) to the standard editing menu that
    /// `super.menu(for:)` already builds.
    final class MenuAugmentedTextView: NSTextView {
        weak var coordinator: Coordinator?

        override func menu(for event: NSEvent) -> NSMenu? {
            guard let menu = super.menu(for: event) else { return nil }

            menu.addItem(.separator())

            let shareItem = NSMenuItem(title: String(localized: "Share..."), action: #selector(shareText), keyEquivalent: "")
            shareItem.target = self
            shareItem.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)
            menu.addItem(shareItem)

            for blockAction in coordinator?.menuActions ?? [] {
                let item = NSMenuItem(title: blockAction.title, action: #selector(runAction(_:)), keyEquivalent: "")
                item.target = self
                item.image = NSImage(systemSymbolName: blockAction.systemImage, accessibilityDescription: nil)
                item.representedObject = blockAction.action
                menu.addItem(item)
            }

            return menu
        }

        @objc private func shareText() {
            let picker = NSSharingServicePicker(items: [string])
            picker.show(relativeTo: bounds, of: self, preferredEdge: .minY)
        }

        @objc private func runAction(_ sender: NSMenuItem) {
            (sender.representedObject as? () -> Void)?()
        }
    }
}
#endif

#Preview {
    @Previewable @State var text: String = ""
    @Previewable @State var isExpanded: Bool = false

    GrowingTextEditor(text: $text, isExpanded: isExpanded)
        .border(.red)
        .padding()
}
