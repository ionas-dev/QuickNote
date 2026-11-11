//
//  Navigation.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 15.07.26.
//

import SwiftUI

enum AppRoute: Hashable {
    case calendar
    case note(Date)
    case tags
    case tagDetail(Tag)
    case untagged
    case settings
}

@Observable final class NavigationModel {
    var path: [AppRoute] = []
}
