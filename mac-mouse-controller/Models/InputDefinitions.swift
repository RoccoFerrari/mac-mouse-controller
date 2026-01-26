//
//  InputDefinitions.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import Foundation
import Carbon // It is used for standard keyboard codes (kVK_...)

// Map physical mouse buttons to human-readable names
enum MouseButton: Int, Codable, CaseIterable {
    case left = 0
    case right = 1
    case middle = 2
    case back = 3
    case forward = 4
    case other = -1
    
    var displayName: String {
        switch self {
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
struct ModifierSet: OptionSet, Codable, Hashable {
    let rawValue: Int
    
    static let command = ModifierSet(rawValue: 1 << 0)
    static let shift   = ModifierSet(rawValue: 1 << 1)
    static let option  = ModifierSet(rawValue: 1 << 2) // Alt
    static let control = ModifierSet(rawValue: 1 << 3)
    static let function = ModifierSet(rawValue: 1 << 4) // Fn
    
    // Helper to convert CoreGraphics flags (CGEventFlags) to our flags
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
