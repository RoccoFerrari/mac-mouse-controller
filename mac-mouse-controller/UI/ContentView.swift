//
//  ContentView.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import SwiftUI

struct ContentView: View {
    // Access the global state
    @EnvironmentObject var appState: AppState
    
    // State to manage the "Add Rule" sheet presentation
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if appState.hasPermissions {
                    // state 1: Permissions Granted -> Show Rule List
                    if appState.userProfile.rules.isEmpty {
                        // Empty state placeholder
                        VStack(spacing: 20) {
                            Image(systemName: "mouse.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.gray.opacity(0.3))
                            Text("No Rules Configured")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Click + to add your first custom mapping.")
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        // The actual list of configured rules
                        List {
                            Section {
                                Toggle("Natural Scrolling (Invert)", isOn: $appState.userProfile.invertScrolling)
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                                Toggle("Smooth Scrolling", isOn: $appState.userProfile.smoothScrolling)
                                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                            } header: {
                                Text("Global Settings")
                            }
                            Section {
                                ForEach(appState.userProfile.rules) { rule in
                                    NavigationLink {
                                        // Navigate to Detail View in "Edit Mode"
                                        RuleDetailView(userProfile: appState.userProfile, rule: rule, isNew: false)
                                    } label: {
                                        // Custom row view for the rule
                                        RuleRowView(rule: rule, onDelete: {
                                            deleteRule(id: rule.id)
                                        })
                                    }
                                }
                                .onDelete(perform: deleteRule)
                            } header: {
                                Text("Custom Rules")
                            }
                        }
                        .listStyle(.inset)
                    }
                    
                } else {
                    // state 2: Permissions Missing -> Show Request UI
                    VStack(spacing: 20) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                        
                        Text("Permissions Needed")
                            .font(.title)
                        
                        Text("Please, allow mouse control in System Settings -> Privacy & Security -> Accessibility.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .foregroundStyle(.secondary)
                        HStack {
                            // Open settings
                            Button("Open Settings") {
                                appState.openSettings()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Check / Prompt") {
                                appState.requestPermissionsExplicitly()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .controlSize(.large)
                        
                        // Quit button is useful if the user gets stuck here
                        Button("Exit App") {
                            appState.quitApp()
                        }
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Mouse Controller")
            // Toolbar is only relevant if we have permissions to configure things
            .toolbar {
                if appState.hasPermissions {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showAddSheet = true }) {
                            Label("Add Rule", systemImage: "plus")
                        }
                    }
                }
            }
            // The popup sheet for adding a new rule
            .sheet(isPresented: $showAddSheet) {
                NavigationStack {
                    // Initialize Detail View with a fresh, empty rule
                    RuleDetailView(
                        userProfile: appState.userProfile,
                        rule: MappingRule(mouseButton: .other, requiredModifiers: [], action: .none),
                        isNew: true
                    )
                }
                .frame(minWidth: 500, minHeight: 450) // Set a reasonable size for the popup
            }
        }
        // Base window size constraint
        .frame(minWidth: 600, minHeight: 400)
    }
    
    // Helper to delete rules via swipe or delete key
    func deleteRule(at offsets: IndexSet) {
        appState.userProfile.rules.remove(atOffsets: offsets)
    }
    func deleteRule(id: UUID) {
            if let index = appState.userProfile.rules.firstIndex(where: { $0.id == id }) {
                appState.userProfile.rules.remove(at: index)
            }
        }
}
