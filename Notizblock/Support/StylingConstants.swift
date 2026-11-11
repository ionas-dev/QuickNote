//
//  StylingConstants.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 28.06.26.
//

import SwiftUI

/// Colour for raw Markdown syntax characters (`**`, `` ` ``, `](url)`).
/// Deliberately a semantic colour, never a fixed grey or an opacity
/// multiplier: the row background varies with `listStylePlain` and by
/// platform, and a hardcoded value goes illegible against one of them.
let MARKDOWN_MARKER_COLOR = Color.secondary