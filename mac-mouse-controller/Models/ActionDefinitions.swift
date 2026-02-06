//
//  ActionDefinitions.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import Foundation

// The various categories of possible actions
enum ActionType: Codable, Hashable {
    case keyboardShortcut(keyCode: Int, modifiers: ModifierSet) // Es. simulate CMD+C
    case systemFunction(SystemFeature) // Es. Mission Control
    case navigation(NavigationAction)  // Es. Swipe between pages/spaces
    case sensivity(factor: Double) // Wheel sensiivty
    case zoom
    case none // pass-through
}

enum SystemFeature: String, Codable, CaseIterable {
    case missionControl
    case appExpose
    case launchpad
    case showDesktop
    case lookUp // "Search"
}

enum NavigationAction: String, Codable, CaseIterable {
    case spaceLeft    // Ctrl + Left arrow
    case spaceRight   // Ctrl + Right arrow
    case back         // Cmd + [
    case forward      // Cmd + ]
    case smartZoom    // double touch zoom
}
