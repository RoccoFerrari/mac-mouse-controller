//
//  AppState.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import SwiftUI
internal import Combine

// Global ViewModel
// Handles app's state and manages services
@MainActor
class AppState: ObservableObject {
    @Published var hasPermissions: Bool = false
    @Published var isEngineRunning: Bool = false
    @Published var userProfile = UserProfile()
    
    // Replaced Timer with Task for Swift 6 Concurrency compliance
    private var permissionTask: Task<Void, Never>?
    
    // Init the interceptor
    private let mouseDriver = MouseHookService()
    
    // Needed to propagate changes from UserProfile to UI
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Reactivity setup: when UserProfile changes, notify the UI
        userProfile.objectWillChange
                    .sink { [weak self] _ in
                        self?.objectWillChange.send()
                    }
                    .store(in: &cancellables)
        
        // Initial check WITHOUT PROMPT (silent check)
        // This avoids the system popup loop when launching from Xcode
        self.hasPermissions = PermissionManager.checkAccessibilityPermissions(shouldPrompt: false)
        
        // Start continuous monitoring
        startPermissionMonitoring()
    }
    
    // Continuous permission monitoring using Swift Concurrency
    // If permissions are revoked -> stops the app engine
    // If permissions are granted -> starts the app engine
    private func startPermissionMonitoring() {
        // Cancel any existing task to avoid duplicates
        permissionTask?.cancel()
        
        permissionTask = Task { [weak self] in
            // Loop until the task is cancelled
            while !Task.isCancelled {
                // Wait for 1 second (1 billion nanoseconds)
                // This replaces the Timer and is safe in concurrent contexts
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                guard let self = self else { return }
                
                // Perform the check (MainActor isolated)
                await self.checkPermissionsAndSyncState()
            }
        }
    }
    
    private func checkPermissionsAndSyncState() {
        // Silent check (we don't want popups appearing repeatedly while the user works)
        let currentlyHasPermissions = PermissionManager.checkAccessibilityPermissions(shouldPrompt: false)
        
        if currentlyHasPermissions != self.hasPermissions {
            // STATE CHANGE DETECTED
            self.hasPermissions = currentlyHasPermissions
            
            if currentlyHasPermissions {
                print("Permissions detected. Starting engine automatically.")
                startAppEngine()
            } else {
                print("Permissions LOST. Stopping engine immediately.")
                stopAppEngine()
            }
        } else {
            // Stable State
            // Safety check: if permissions are enabled but engine is down (e.g. startup error), retry
            if currentlyHasPermissions && !isEngineRunning {
                startAppEngine()
            }
        }
    }
    
    private func startAppEngine() {
        // Prevent multiple executions
        guard !isEngineRunning else { return }
        
        print("Configuring Mouse Engine...")
        
        // Re-create the handler to ensure it has the latest profile
        let configHandler = ConfigurableHandler(profile: userProfile)
        mouseDriver.add(handler: configHandler)
                
        mouseDriver.start()
        isEngineRunning = true
    }
    
    private func stopAppEngine() {
        mouseDriver.stop()
        isEngineRunning = false
    }
    
    // Called by the UI button to force the system popup if needed
    func requestPermissionsExplicitly() {
        _ = PermissionManager.checkAccessibilityPermissions(shouldPrompt: true)
    }
    
    func openSettings() {
        PermissionManager.openAccessibilitySettings()
    }
    
    func quitApp() {
        // Stop the task and the engine before quitting
        permissionTask?.cancel()
        stopAppEngine()
        NSApplication.shared.terminate(nil)
    }
}
