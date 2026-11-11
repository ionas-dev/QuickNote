//
//  LargeTitleToolbar.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 23.07.26.
//

import SwiftUI

private struct TitleModifier<TitleContent: View>: ViewModifier {
    @AppStorage(AppSettings.titleFontDesign) private var titleFontDesign: FontDesign
    
    let title: String
    @ViewBuilder let titleContent: () -> TitleContent

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: principalToolbarContent)
            #endif
    }

    #if os(iOS)
    @ToolbarContentBuilder
    private func principalToolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            titleContent()
                .font(.system(.headline, design: titleFontDesign.fontDesign))
        }
    }
    #endif
}

extension View {
    func adaptiveNavigationTitle(_ title: String) -> some View {
        modifier(TitleModifier(title: title) { Text(title) })
    }

    func adaptiveNavigationTitle<Content: View>(_ title: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(TitleModifier(title: title, titleContent: content))
    }
}
