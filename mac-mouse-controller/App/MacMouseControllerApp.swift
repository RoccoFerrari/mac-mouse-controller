//
//  MacMouseControllerApp.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import SwiftUI
internal import Combine

/// **Application Entry Point**
///
/// This struct bootstraps the macOS application. It is responsible for:
/// 1. Initializing the global source of truth (`AppState`).
/// 2. Creating the main window structure.
/// 3. Injecting the state into the view hierarchy.
@main
struct MacMouseControllerApp: App {
    // Inject state as StateObject
    /// The single source of truth for the entire application.
    ///
    /// Using `@StateObject` ensures this instance is created once and persists
    /// for the entire lifetime of the app. It initializes the mouse driver
    /// and permission monitoring immediately upon app launch.
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Passes the state to child view
                // Makes `appState` available to ContentView and all its descendants
                // automatically via the @EnvironmentObject wrapper.
                .environmentObject(appState)
                .frame(minWidth: 400, minHeight: 300)
        }
        // No title from window
        // Hides the standard macOS window title bar to allow for a custom UI design.
        .windowStyle(.hiddenTitleBar)
    }
}
