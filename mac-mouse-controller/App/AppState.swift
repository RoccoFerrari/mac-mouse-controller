//
//  AppState.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import SwiftUI
internal import Combine

/// **Global ViewModel / Source of Truth**
///
/// This class is responsible for:
/// 1. Managing the global state of the application (Permissions, Engine Status, User Profile).
/// 2. Bridging the UI with the low-level `MouseHookService`.
/// 3. Monitoring system accessibility permissions in real-time.
///
/// Marked as `@MainActor` to ensure all UI updates occur on the main thread.
@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties (UI State)
        
    /// Tracks whether the user has granted Accessibility Permissions in System Settings.
    /// The UI observes this to decide whether to show the "Setup" screen or the "Dashboard".
    @Published var hasPermissions: Bool = false
    
    /// Indicates if the mouse interception engine is currently active and modifying input.
    @Published var isEngineRunning: Bool = false
    
    /// Stores user configuration (e.g., sensitivity, scrolling speed, acceleration curves).
    /// Changes here are observed to update the engine dynamically.
    @Published var userProfile = UserProfile()
    
    // MARK: - Private Properties
        
    /// A handle for the background permission monitoring loop.
    /// Using `Task` instead of `Timer` ensures compliance with Swift 6 structured concurrency.
    private var permissionTask: Task<Void, Never>?
    
    /// The low-level service responsible for hooking into the CGEventTap to intercept mouse events.
    private let mouseDriver = MouseHookService()
    
    /// Storage for Combine subscriptions, specifically to watch for nested changes in `UserProfile`.
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    
    init() {
        // Reactive Binding:
        // Since `userProfile` is a nested ObservableObject, we need to explicitly listen
        // for its changes and trigger an update on `AppState` so the View redraws.
        userProfile.objectWillChange
                    .sink { [weak self] _ in
                        self?.objectWillChange.send()
                    }
                    .store(in: &cancellables)
        
        // Initial Permission Check:
        // We perform a "silent" check (shouldPrompt: false) to avoid annoying the user
        // with system popups immediately upon app launch or during development.
        self.hasPermissions = PermissionManager.checkAccessibilityPermissions(shouldPrompt: false)
        
        // Begin the polling loop to watch for permission changes.
        startPermissionMonitoring()
    }
    
    // MARK: - Permission Monitoring
        
    /// Starts a continuous background task that checks for accessibility permissions every second.
    ///
    /// - Note: If permissions are revoked externally (System Settings), this loop detects it
    /// and stops the engine to prevent crashes or undefined behavior.
    private func startPermissionMonitoring() {
        // Cancel any existing task to avoid duplicates
        permissionTask?.cancel()
        
        permissionTask = Task { [weak self] in
            // Cancel any existing task to prevent duplicate polling loops.
            while !Task.isCancelled {
                // Wait for 1 second (1 billion nanoseconds)
                // This replaces the Timer and is safe in concurrent contexts
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                guard let self = self else { return }
                
                // Perform the logic check on the MainActor.
                await self.checkPermissionsAndSyncState()
            }
        }
    }
    
    /// Synchronizes the app's internal state with the actual system permission status.
    ///
    /// Logic:
    /// 1. If permissions were **gained**: Automatically start the engine.
    /// 2. If permissions were **lost**: Immediately stop the engine.
    /// 3. If stable: Retry starting the engine if it should be running but isn't.
    private func checkPermissionsAndSyncState() {
        // Silent check again to avoid spamming the user with dialogs while they work.
        let currentlyHasPermissions = PermissionManager.checkAccessibilityPermissions(shouldPrompt: false)
        
        if currentlyHasPermissions != self.hasPermissions {
            // State transition detected
            self.hasPermissions = currentlyHasPermissions
            
            if currentlyHasPermissions {
                print("Permissions detected. Starting engine automatically.")
                startAppEngine()
            } else {
                print("Permissions LOST. Stopping engine immediately.")
                stopAppEngine()
            }
        } else {
            // Stable State Maintenance
            // If we have permissions, but the engine isn't running (e.g., due to a previous startup failure),
            // we attempt to restart it here.
            if currentlyHasPermissions && !isEngineRunning {
                startAppEngine()
            }
        }
    }
    
    // MARK: - Engine Control
        
    /// Configures the mouse driver with the current profile and activates the event tap.
    private func startAppEngine() {
        // Safety check to prevent double-activation.
        guard !isEngineRunning else { return }
        
        print("Configuring Mouse Engine...")
        
        // Inject the current `UserProfile` into the handler logic.
        // This ensures the driver uses the latest settings for sensitivity/scrolling.
        let configHandler = ConfigurableHandler(profile: userProfile)
        mouseDriver.add(handler: configHandler)
                
        mouseDriver.start()
        isEngineRunning = true
    }
    
    /// Disables the event tap and stops processing mouse events.
    private func stopAppEngine() {
        mouseDriver.stop()
        isEngineRunning = false
    }
    
    // MARK: - User Actions
        
    /// Called by the UI (e.g., "Grant Permissions" button) to explicitly trigger
    /// the macOS system popup requesting Accessibility access.
    func requestPermissionsExplicitly() {
        _ = PermissionManager.checkAccessibilityPermissions(shouldPrompt: true)
    }
    
    /// Opens the macOS System Settings directly to the Accessibility/Privacy page.
    func openSettings() {
        PermissionManager.openAccessibilitySettings()
    }
    
    /// Cleanly terminates the application.
    /// Ensures background tasks and the mouse driver are stopped before exiting.
    func quitApp() {
        // Stop the task and the engine before quitting
        permissionTask?.cancel()
        stopAppEngine()
        NSApplication.shared.terminate(nil)
    }
}
