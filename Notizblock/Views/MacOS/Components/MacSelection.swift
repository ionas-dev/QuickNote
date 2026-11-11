//
//  MacSelection.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 22.07.26.
//

import Foundation

#if os(macOS)
/// Sidebar selection state for the macOS split view. `.today` always
/// resolves to the current day at render time rather than being frozen
/// at launch, so it stays correct across midnight rollover.
enum MacSelection: Hashable {
    case date(Date)
    case tag(Tag)
    case untagged
}
#endif
