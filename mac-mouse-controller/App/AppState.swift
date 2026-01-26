//
//  AppState.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import SwiftUI
internal import Combine

// Global ViewModel
// Handles app' state and handles services
@MainActor
class AppState: ObservableObject {
    @Published var hasPermissions: Bool = false
    @Published var isEngineRunning: Bool = false
    
    private var permissionTimer: AnyCancellable?
    
    // Init the interceptor
    private let mouseDriver = MouseHookService()
    
    init() {
        // Initial check with PROMPT (showing popup)
        self.hasPermissions = PermissionManager.checkAccessibilityPermissions(shouldPrompt: true)
        
        // If no permissions, starts TIMER (no prompt)
        if !hasPermissions {
            startPermissionMonitoring()
        } else {
            startAppEngine()
        }
    }
    
    private func startPermissionMonitoring() {
        permissionTimer = Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // PROMPT = False -> for avoiding freeze
                let granted = PermissionManager.checkAccessibilityPermissions(shouldPrompt: false)
                
                if granted {
                    self.hasPermissions = true
                    self.permissionTimer?.cancel() // Stop timer
                    self.startAppEngine()
                }
            }
    }
    
    private func startAppEngine() {
        print("Permissions OK. Configuring Mouse Engine...")
        
        // Handler config. (Chain of Responsibility)
        // Here we decide which features to activate and in what order.
        // For example, let's add the back button handler:
        mouseDriver.add(handler: BackButtonHandler())
        
        // Starting logic
        mouseDriver.start()
        
        isEngineRunning = true
    }
    
    func openSettings() {
        PermissionManager.openAccessibilitySettings()
    }
    
    func quitApp() {
        // Stop the driver
        mouseDriver.stop()
        NSApplication.shared.terminate(nil)
    }
}
