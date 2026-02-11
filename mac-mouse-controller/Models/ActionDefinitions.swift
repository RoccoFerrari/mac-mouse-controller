//
//  ActionDefinitions.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import Foundation

// The various categories of possible actions
/// **Action Category**
///
/// Defines the different types of operations that can be triggered by a mouse event.
/// This enum supports associated values to carry specific parameters (e.g., key codes or sensitivity levels).
enum ActionType: Codable, Hashable {
    /// Simulates a standard keyboard shortcut (e.g., Cmd+C, Cmd+V).
    /// - Parameters:
    ///   - keyCode: The hardware key code to press.
    ///   - modifiers: The set of modifier keys (Cmd, Shift, etc.) to hold down.
    case keyboardShortcut(keyCode: Int, modifiers: ModifierSet) // Es. simulate CMD+C
    
    /// Triggers a native macOS system feature (e.g., Mission Control, Launchpad).
    case systemFunction(SystemFeature) // Es. Mission Control
    
    /// Performs a navigation command (e.g., switching spaces, browser history navigation).
    case navigation(NavigationAction)  // Es. Swipe between pages/spaces
    
    /// Modifies the speed or sensitivity of the input (typically for scroll wheels).
    /// - Parameter factor: The multiplier to apply (e.g., 1.5x speed).
    case sensivity(factor: Double) // Wheel sensiivty
    
    /// Triggers a standard system zoom or smart zoom action.
    case zoom
    
    /// **Pass-through**
    ///
    /// Indicates that no special action should be taken. The event is forwarded
    /// to the system as if the app were not running.
    case none // pass-through
}

/// **System Features**
///
/// Represents high-level macOS window management and system shortcuts.
enum SystemFeature: String, Codable, CaseIterable {
    /// Shows all open windows (Mission Control).
    case missionControl
    
    /// Shows all windows of the current application (App Exposé).
    case appExpose
    
    /// Opens the application launcher grid.
    case launchpad
    
    /// Moves all windows aside to reveal the desktop.
    case showDesktop
    
    /// Triggers the "Look Up" data detector (usually three-finger tap).
    case lookUp // "Search"
}

/// **Navigation Commands**
///
/// Represents directional or history-based navigation actions.
enum NavigationAction: String, Codable, CaseIterable {
    /// Moves to the Desktop/Space to the left (Ctrl + Left Arrow).
    case spaceLeft    // Ctrl + Left arrow
    
    /// Moves to the Desktop/Space to the right (Ctrl + Right Arrow).
    case spaceRight   // Ctrl + Right arrow
    
    /// Navigates back in history (e.g., Web Browser Back, Finder Back).
    case back         // Cmd + [
    
    /// Navigates forward in history.
    case forward      // Cmd + ]
    
    /// Performs a "Smart Zoom" (typically a double-tap to zoom in/out on content).
    case smartZoom    // double touch zoom
}
