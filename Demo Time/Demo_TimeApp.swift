//
//  Demo_TimeApp.swift
//  Demo Time
//
//  Created by Yavik on 3/1/26.
//

import SwiftUI

@main
struct Demo_TimeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 300)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 960, height: 540)
    }
}
