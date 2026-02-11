//
//  InputDefinitions.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import Foundation
import Carbon // It is used for standard keyboard codes (kVK_...)

// Map physical mouse buttons to human-readable names
/// **Mouse Input Types**
///
/// Enumerates the specific physical buttons or input types supported by the application.
/// Used to identify the "Trigger" part of a mapping rule.
enum MouseButton: Int, Codable, CaseIterable {
    /// Standard primary click (Left).
    case left = 0
    /// Standard secondary click (Right).
    case right = 1
    /// Wheel click.
    case middle = 2
    /// Side button often used for "Back" in browsers.
    case back = 3
    /// Side button often used for "Forward" in browsers.
    case forward = 4
    
    /// **Special Case: Scroll Wheel**
    /// Represents the action of scrolling (up/down) rather than a button press.
    /// Assigned a negative value to differentiate from standard HID button indices.
    case scroll = -2
    
    /// Fallback for unrecognized buttons (e.g., gaming mouse macro buttons).
    case other = -1
    
    /// **UI Label**
    /// Returns a user-friendly string for display in the Settings/Dashboard.
    var displayName: String {
        switch self {
        case .scroll: return "Scroll Wheel"
        case .left: return "Left Click"
        case .right: return "Right Click"
        case .middle: return "Middle Click (Wheel)"
        case .back: return "Back Button (Side)"
        case .forward: return "Forward Button (Side)"
        case .other: return "Other Button"
        }
    }
}

// Map keyboard modifier keys (Cmd, Ctrl, etc.) in a Codable way.
/// **Keyboard Modifiers**
///
/// A custom `OptionSet` representing keys held down during an action (e.g., Cmd, Shift).
///
/// - Why custom?
///   Apple's `CGEventFlags` are not easily `Codable` (JSON-serializable).
///   This struct maps those low-level flags to a format we can save in `UserProfile`.
struct ModifierSet: OptionSet, Codable, Hashable {
    let rawValue: Int
    
    // MARK: - Bitmasks
    
    /// Command Key (⌘)
    static let command = ModifierSet(rawValue: 1 << 0)
    /// Shift Key (⇧)
    static let shift   = ModifierSet(rawValue: 1 << 1)
    /// Option / Alt Key (⌥)
    static let option  = ModifierSet(rawValue: 1 << 2) // Alt
    /// Control Key (⌃)
    static let control = ModifierSet(rawValue: 1 << 3)
    /// Function Key (fn)
    static let function = ModifierSet(rawValue: 1 << 4) // Fn
    
    // Helper to convert CoreGraphics flags (CGEventFlags) to our flags
    /// **Conversion Helper**
    ///
    /// Transforms the low-level `CGEventFlags` received from the Event Tap
    /// into our internal `ModifierSet`.
    ///
    /// - Parameter cgFlags: The flags property from a `CGEvent`.
    /// - Returns: The corresponding `ModifierSet` with active keys set.
    static func from(cgFlags: CGEventFlags) -> ModifierSet {
        var set: ModifierSet = []
        if cgFlags.contains(.maskCommand) { set.insert(.command) }
        if cgFlags.contains(.maskShift) { set.insert(.shift) }
        if cgFlags.contains(.maskAlternate) { set.insert(.option) }
        if cgFlags.contains(.maskControl) { set.insert(.control) }
        if cgFlags.contains(.maskSecondaryFn) { set.insert(.function) }
        return set
    }
}
