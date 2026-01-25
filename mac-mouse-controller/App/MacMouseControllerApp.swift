//
//  MacMouseControllerApp.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import SwiftUI
internal import Combine

@main
struct MacMouseControllerApp: App {
    // Inject state as StateObject
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Passes the state to child view
                .environmentObject(appState)
                .frame(minWidth: 400, minHeight: 300)
        }
        // No title from window
        .windowStyle(.hiddenTitleBar)
    }
}
