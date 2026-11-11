//
//  MacRootView.swift
//  Notizblock
//
//  Created by Jonas Kaiser on 22.07.26.
//

import SwiftUI

#if os(macOS)
struct MacRootView: View {
    @State private var selection: MacSelection = .date(Calendar.current.startOfDay(for: .now))
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .detailOnly

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            MacSidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 220, ideal: 220)
        } detail: {
            detailView
                .padding(.top, sidebarVisibility == .detailOnly ? 40 : 0)
                .ignoresSafeArea(edges: .top)
        }
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .toolbar(removing: .title)
        .frame(minWidth: 600, minHeight: 400)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .date(let date):
            DailyNoteView(date: date)
        case .tag(let tag):
            TagNoteView(tag: tag)
        case .untagged:
            UntaggedNoteView()
        }
    }
}

#Preview {
    MacRootView()
        .environment(EventKitManager())
        .environment(TagStore())
}
#endif
