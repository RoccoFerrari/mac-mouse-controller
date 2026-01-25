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
        print("Permissions OK, starting app engine...")
        isEngineRunning = true
        // Init of the MouseController
    }
    
    func openSettings() {
        PermissionManager.openAccessibilitySettings()
    }
    
    func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
