//
//  RuleRowView.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 27/01/26.
//

import SwiftUI

/// **List Row Component**
///
/// Displays a concise summary of a single `MappingRule` within a list.
/// Visual layout: `[Icon + Modifiers] -> [Action Description]`.
struct RuleRowView: View {
    /// The specific mapping rule data to display in this row.
    let rule: MappingRule
    
    /// Optional callback triggered when the delete button is pressed.
    /// If `nil`, the delete icon is hidden.
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            // Left: TRIGGER
            // Displays the physical input (Mouse Button + Keyboard Modifiers)
            HStack(spacing: 4) {
                // Mouse icon
                Image(systemName: iconName(for: rule.mouseButton))
                    .font(.title2)
                
                // If modifiers are required (e.g. Cmd+Click), display them next to the icon
                if !rule.requiredModifiers.isEmpty {
                    Text("+")
                        .foregroundStyle(.secondary)
                    Text(modifiersString(rule.requiredModifiers))
                        .font(.system(.caption, design: .monospaced))
                        .padding(4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .frame(width: 120, alignment: .leading)
            
            // Visual separator
            Image(systemName: "arrow.right")
                .foregroundStyle(.secondary)
            
            // Right: ACTION
            // Text description of what happens when triggered
            Text(actionDescription(rule.action))
                .font(.headline)
                .foregroundStyle(.blue)
            
            Spacer()
            
            // Delete button
            // Only appears if the parent view provided a delete action
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.borderless)
                .padding(.leading, 8)
                .help("Delete rule")
            }
        }
        .padding(.vertical, 4)
    }
    
    // Visible helper
    /// Maps a `MouseButton` enum case to a corresponding SF Symbol name.
    func iconName(for btn: MouseButton) -> String {
        switch btn {
        case .left: return "cursorarrow.click"
        case .right: return "cursorarrow.click.2"
        case .middle: return "capsule.portrait"
        case .back: return "arrow.uturn.backward.square"
        case .forward: return "arrow.uturn.forward.square"
        default: return "computermouse"
        }
    }
    
    /// Converts a `ModifierSet` into a string of standard macOS symbols (e.g., "⌘⇧").
    func modifiersString(_ mods: ModifierSet) -> String {
        var symbols = ""
        if mods.contains(.control) { symbols += "⌃" }
        if mods.contains(.option) { symbols += "⌥" }
        if mods.contains(.shift) { symbols += "⇧" }
        if mods.contains(.command) { symbols += "⌘" }
        return symbols
    }
    
    /// Generates a human-readable text summary of the configured `ActionType`.
    func actionDescription(_ action: ActionType) -> String {
        switch action {
        case .zoom: return "Zoom (Scroll)"
            
        case.sensivity(let f):
            return "Speed: \(String(format: "%.1fx", f))"
            
        case .none: return "None"
            
        case .keyboardShortcut(let code, _): return "Button \(code)" // Could map code in names
            
        case .systemFunction(let feat): return feat.rawValue.capitalized
            
        case .navigation(let nav): return "Navigation: \(nav.rawValue)"
        }
    }
}
