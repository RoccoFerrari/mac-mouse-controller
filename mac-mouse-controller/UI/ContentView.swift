//
//  ContentView.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import SwiftUI

/// **Main User Interface**
///
/// This is the root view of the application. It acts as a dashboard that reacts to the global `AppState`.
/// - If permissions are missing -> It shows an onboarding/warning screen.
/// - If permissions are present -> It shows the list of active rules and global settings.
struct ContentView: View {
    // Access the global state
    /// **Dependency Injection**
    /// Retrieves the shared `AppState` instance passed down from `MacMouseControllerApp`.
    /// This allows the view to react instantly to changes in permissions or the user profile.
    @EnvironmentObject var appState: AppState
    
    // State to manage the "Add Rule" sheet presentation
    /// Controls the visibility of the "New Rule" modal window.
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // **Main Logic Switch**
                // The UI splits here based on system security status.
                if appState.hasPermissions {
                    // state 1: Permissions Granted -> Show Rule List
                    
                    if appState.userProfile.rules.isEmpty {
                        // **Empty State**
                        // Shown when the user hasn't configured any mappings yet.
                        // Provides a clear call to action.
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
                        // **Dashboard State**
                        // Displays the actual list of configured rules and global toggles.
                        List {
                            // Section 1: Global Configuration
                            Section {
                                Toggle("Natural Scrolling (Invert)", isOn: $appState.userProfile.invertScrolling)
                                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                                Toggle("Smooth Scrolling", isOn: $appState.userProfile.smoothScrolling)
                                    .toggleStyle(SwitchToggleStyle(tint: .purple))
                            } header: {
                                Text("Global Settings")
                            }
                            
                            // Section 2: User Rules
                            Section {
                                ForEach(appState.userProfile.rules) { rule in
                                    // Navigate to Detail View in "Edit Mode" (isNew: false)
                                    NavigationLink {
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
                    // This block blocks the main functionality until the user grants access.
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
                        
                        // Action Buttons
                        HStack {
                            // Deep link to System Settings
                            Button("Open Settings") {
                                appState.openSettings()
                            }
                            .buttonStyle(.bordered)
                            
                            // Trigger the system popup manually
                            Button("Check / Prompt") {
                                appState.requestPermissionsExplicitly()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .controlSize(.large)
                        
                        // Quit button is useful if the user gets stuck here or wants to restart
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
                    // We pass a dummy rule with default values to start.
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
    
    // MARK: - Helper Methods
    
    /// Helper to delete rules via swipe or delete key (List standard behavior).
    func deleteRule(at offsets: IndexSet) {
        appState.userProfile.rules.remove(atOffsets: offsets)
    }
    
    /// Helper to delete rules via the trash icon button.
    func deleteRule(id: UUID) {
            if let index = appState.userProfile.rules.firstIndex(where: { $0.id == id }) {
                appState.userProfile.rules.remove(at: index)
            }
        }
}
