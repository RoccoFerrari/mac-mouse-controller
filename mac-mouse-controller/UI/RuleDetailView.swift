//
//  RuleDetailView.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 27/01/26.
//

import SwiftUI

/// **Rule Editor Interface**
///
/// This view provides a form to create or modify a specific `MappingRule`.
/// It handles the complexity of mapping physical inputs (Mouse Button + Modifiers)
/// to various output actions (System functions, Navigation, Sensitivity changes).
struct RuleDetailView: View {
    /// Handler to close this sheet when finished.
    @Environment(\.dismiss) var dismiss
    
    /// Reference to the global profile.
    /// Changes made here are saved back to this object.
    @ObservedObject var userProfile: UserProfile
    
    // Local state for editing
    /// The rule object currently being edited.
    /// This is a temporary copy until "Save" is pressed.
    @State var rule: MappingRule
    
    /// Flag to determine if we are creating a new rule or editing an existing one.
    var isNew: Bool
    
    // MARK: - Temporary UI State
    // SwiftUI Pickers and Sliders work best with simple types (Int, Double, Enum cases).
    // Since our `ActionType` model is a complex Enum with associated values,
    // we use these temporary state variables to hold the form data before saving.
    
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
            // MARK: - Input Trigger Section
            Section("When pressing...") {
                // Select which mouse button triggers the rule
                Picker("Mouse button", selection: $rule.mouseButton) {
                    ForEach(MouseButton.allCases, id: \.self) { btn in
                        Text(btn.displayName).tag(btn)
                    }
                }
                
                // Select which keyboard modifiers must be held down (e.g., Cmd + Click)
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
            
            // MARK: - Output Action Section
            Section("Do this...") {
                // Horizontal scrollable picker for the Action Category
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
                // Displays different controls based on what the user wants the mouse to do.
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
    
    // MARK: - Logic Helpers
    
    /// **Data Binding (Model -> UI)**
    ///
    /// Checks the existing `rule.action` (Complex Enum) and populates the
    /// temporary state variables so the UI reflects the current configuration.
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
    
    /// **Persist Changes (UI -> Model)**
    ///
    /// Takes the values from the temporary UI state variables, constructs a new
    /// `ActionType` enum, assigns it to the rule, and saves the rule to the UserProfile.
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
