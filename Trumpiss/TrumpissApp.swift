//
//  TrumpissApp.swift
//  Trumpiss
//
//  A Liberty Lens Studios production.
//

import SwiftUI

@main
struct TrumpissApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
        }
    }
}
