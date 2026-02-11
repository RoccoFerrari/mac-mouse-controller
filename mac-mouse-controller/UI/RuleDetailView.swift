//
//  RuleDetailView.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 27/01/26.
//

import SwiftUI

struct RuleDetailView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var userProfile: UserProfile
    
    // Local state for editing
    @State var rule: MappingRule
    var isNew: Bool
    
    @State private var speedFactor: Double = 1.0
    
    // Tmp state for handle the picker
    @State private var selectedCategory: ActionCategory = .none
    
    // Tmp variables for action's param
    @State private var selectedSysFeature: SystemFeature = .missionControl
    @State private var selectedNavAction: NavigationAction = .back
    @State private var keyCodeInput: Int = 0
    @State private var keyModifiers: ModifierSet = []
    
    var body: some View {
        Form {
            Section("When pressing...") {
                Picker("Mouse button", selection: $rule.mouseButton) {
                    ForEach(MouseButton.allCases, id: \.self) { btn in
                        Text(btn.displayName).tag(btn)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Keep pressed:")
                    HStack {
                        ModifierToggle(label: "⌘ Cmd", flag: .command, selection: $rule.requiredModifiers)
                        ModifierToggle(label: "⌥ Opt", flag: .option, selection: $rule.requiredModifiers)
                        ModifierToggle(label: "⌃ Ctrl", flag: .control, selection: $rule.requiredModifiers)
                        ModifierToggle(label: "⇧ Shift", flag: .shift, selection: $rule.requiredModifiers)
                    }
                }
            }
            
            Section("Do this...") {
                ScrollView(.horizontal, showsIndicators: true) {
                    Picker("Action type", selection: $selectedCategory) {
                        ForEach(ActionCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    // Impostiamo una larghezza minima ampia per forzare i bottoni a non tagliarsi
                    .frame(minWidth: 700)
                }
                
                // Conditional form dependent on category
                switch selectedCategory {
                case .zoom:
                    Text("Simulates Cmd + / Cmd - based on scroll direction.")
                        .foregroundStyle(.secondary)
                case .modification:
                    VStack(alignment: .leading) {
                        Text("Scroll Speed Multiplier: \(String(format: "%.1fx", speedFactor))")
                        Slider(value: $speedFactor, in: 0.1...15.0, step: 0.1) {
                            Text("Speed")
                        } minimumValueLabel: {
                            Text("0.1x")
                        } maximumValueLabel: {
                            Text("15.0x")
                        }
                    }
                    Text("Values > 1.0 accelerate. Values < 1.0 slow down (precision).")
                        .font(.caption).foregroundStyle(.secondary)
        
                case .system:
                    Picker("Function", selection: $selectedSysFeature) {
                        ForEach(SystemFeature.allCases, id: \.self) { feat in
                            Text(feat.rawValue.capitalized).tag(feat)
                        }
                    }
                    
                case .navigation:
                    Picker("Navigation", selection: $selectedNavAction) {
                        ForEach(NavigationAction.allCases, id: \.self) { nav in
                            Text(nav.rawValue).tag(nav)
                        }
                    }
                    
                case .keyboard:
                    Text("Keyboard shortcut recording coming soon.")
                        .foregroundStyle(.secondary)
                case .none:
                    Text("No action taken.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(isNew ? "New rule" : "Modify rule")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveRule()
                    dismiss()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .onAppear {
            // Decode the existing action in the UI state
            setupInitialState()
        }
    }
    
    func setupInitialState() {
        switch rule.action {
        case .zoom:
            selectedCategory = .zoom
            
        case .sensivity(let f):
            selectedCategory = .modification
            speedFactor = f
            
        case .systemFunction(let f):
            selectedCategory = .system
            selectedSysFeature = f
            
        case .navigation(let n):
            selectedCategory = .navigation
            selectedNavAction = n
            
        case .keyboardShortcut(let k, let m):
            selectedCategory = .keyboard
            keyCodeInput = k
            keyModifiers = m
            
        case .none:
            selectedCategory = .none
        }
    }
    
    func saveRule() {
        // Rebuilds the ActionType enum from temporary values
        switch selectedCategory {
        case .zoom:
            rule.action = .zoom
            
        case .modification:
            rule.action = .sensivity(factor: speedFactor)
            
        case .system:
            rule.action = .systemFunction(selectedSysFeature)
            
        case .navigation:
            rule.action = .navigation(selectedNavAction)
            
        case .keyboard:
            rule.action = .keyboardShortcut(keyCode: keyCodeInput, modifiers: keyModifiers)
            
        case .none:
            rule.action = .none
        }
        
        if isNew {
            userProfile.rules.append(rule)
        } else {
            if let index = userProfile.rules.firstIndex(where: { $0.id == rule.id }) {
                userProfile.rules[index] = rule
            }
        }
    }
}
