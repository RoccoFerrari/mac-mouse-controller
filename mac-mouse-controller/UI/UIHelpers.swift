//
//  UIHelpers.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 27/01/26.
//

import SwiftUI

// Helper for modifiers (checkbox)
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
enum ActionCategory: String, CaseIterable, Identifiable {
    case none = "None"
    case keyboard = "Keyboard Shortcut"
    case system = "System Function"
    case navigation = "Navigation"
    case modification = "Speed / Sensivity"
    
    var id: String { rawValue }
}
