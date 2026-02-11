//
//  UIHelpers.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 27/01/26.
//

import SwiftUI

// Helper for modifiers (checkbox)
/// **Modifier Key Toggle**
///
/// A custom SwiftUI component that renders a specific modifier key (Cmd, Alt, etc.)
/// as a toggleable button.
///
/// - Purpose: Bridges the gap between SwiftUI's `Bool` based Toggle and the
///   `OptionSet` based `ModifierSet`. When clicked, it inserts or removes
///   the specific flag from the binding.
struct ModifierToggle: View {
    let label: String
    let flag: ModifierSet
    @Binding var selection: ModifierSet
    
    var body: some View {
        Toggle(label, isOn: Binding(
            get: { selection.contains(flag) },
            set: { isSelected in
                if isSelected { selection.insert(flag) }
                else { selection.remove(flag) }
            }
        ))
        .toggleStyle(.button)
    }
}

// Helper for categorize ActionType in the Picker
/// **Action UI Categories**
///
/// A simplified enumeration used specifically for the UI (Pickers/Segments).
///
/// - Note: The underlying `ActionType` enum has associated values (e.g., specific key codes),
///   which makes it difficult to use directly in a SwiftUI `Picker`.
///   This enum groups those actions into high-level categories to streamline the user interface.
enum ActionCategory: String, CaseIterable, Identifiable {
    case none = "None"
    case keyboard = "Keyboard Shortcut"
    case system = "System Function"
    case navigation = "Navigation"
    case modification = "Speed / Sensivity"
    case zoom = "Smart Zoom"
    
    var id: String { rawValue }
}
