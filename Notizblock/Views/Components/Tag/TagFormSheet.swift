//
//  TagFormSheet.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

import SwiftUI

struct TagFormSheet: View {
    let existingTag: Tag?
    let onSave: (Tag) -> Void

    enum StyleChoice: String, CaseIterable {
        case emoji = "Emoji"
        case color = "Colour"
    }

    @State private var name: String
    @State private var styleChoice: StyleChoice
    @State private var emoji: String
    @State private var color: Color
    @Environment(\.dismiss) private var dismiss

    init(existingTag: Tag? = nil, onSave: @escaping (Tag) -> Void) {
        self.existingTag = existingTag
        self.onSave = onSave
        if let tag = existingTag {
            _name = State(initialValue: tag.name)
            switch tag.style {
            case .emoji(let e):
                _styleChoice = State(initialValue: .emoji)
                _emoji = State(initialValue: e)
                _color = State(initialValue: .blue)
            case .color(let hex):
                _styleChoice = State(initialValue: .color)
                _emoji = State(initialValue: "")
                _color = State(initialValue: Color(hex: hex))
            }
        } else {
            _name = State(initialValue: "")
            _styleChoice = State(initialValue: .emoji)
            _emoji = State(initialValue: "")
            _color = State(initialValue: .blue)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Tag name", text: $name)
                }

                styleSection
            }
            .navigationTitle(existingTag == nil ? "New Tag" : "Edit Tag")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { formToolbar }
        }
    }

    private var styleSection: some View {
        Section {
            Picker("Style", selection: $styleChoice) {
                ForEach(StyleChoice.allCases, id: \.self) { choice in
                    Text(choice.rawValue).tag(choice)
                }
            }
            .pickerStyle(.segmented)

            if styleChoice == .emoji {
                #if canImport(UIKit)
                EmojiTextField(text: $emoji)
                    .frame(height: 36)
                #else
                TextField("Emoji", text: $emoji)
                    .onChange(of: emoji) { _, new in
                        guard new.count > 1, let first = new.first else { return }
                        emoji = String(first)
                    }
                #endif
            } else {
                ColorPicker("Tag colour", selection: $color, supportsOpacity: false)
            }
        } header: {
            Text("Style")
        } footer: {
            if styleChoice == .emoji {
                Text("Tap the field and use the emoji keyboard (🌐) to pick one.")
            }
        }
    }

    private var formToolbar: some ToolbarContent {
        Group {
            ToolbarItem(placement: .confirmationAction) {
                Button(existingTag == nil ? "Add" : "Save") {
                    saveTag()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func saveTag() {
        let style: TagImage = styleChoice == .emoji
            ? .emoji(emoji)
            : .color(color.hexString)
        var tag = existingTag ?? Tag(name: name, style: style)
        tag.name = name
        tag.style = style
        onSave(tag)
        dismiss()
    }
}
