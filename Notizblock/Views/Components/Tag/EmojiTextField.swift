//
//  EmojiTextField.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

#if canImport(UIKit)
import SwiftUI
import UIKit

/// A text field that opens with the emoji keyboard and keeps at most one character.
struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UIEmojiTextField {
        let field = UIEmojiTextField()
        field.delegate = context.coordinator
        field.text = text
        field.font = UIFont.preferredFont(forTextStyle: .body)
        return field
    }

    func updateUIView(_ uiView: UIEmojiTextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        init(text: Binding<String>) { _text = text }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            let s = textField.text ?? ""
            let trimmed = s.isEmpty ? s : String(s.prefix(1))
            if trimmed != s { textField.text = trimmed }
            text = trimmed
        }
    }
}

final class UIEmojiTextField: UITextField {
    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
    }
}
#endif
