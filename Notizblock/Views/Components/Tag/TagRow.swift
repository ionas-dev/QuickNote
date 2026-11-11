//
//  TagRow.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

import SwiftUI

/// Shared row label for tag lists: style indicator, name, and a trailing accessory.
struct TagRow<Trailing: View>: View {
    let tag: Tag
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 10) {
            TagMetaInformation(style: tag.style)
            Text(tag.name)
                .foregroundStyle(.primary)
            Spacer()
            trailing
        }
    }
}
