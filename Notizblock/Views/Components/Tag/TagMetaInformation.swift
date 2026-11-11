//
//  TagStyleIndicator.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

import SwiftUI

struct TagMetaInformation: View {
    let style: TagImage

    var body: some View {
        switch style {
        case .emoji(let e):
            Text(e)
        case .color(let hex):
            Image(systemName: "circle.fill")
                .foregroundStyle(Color(hex: hex))
        }
    }
}
