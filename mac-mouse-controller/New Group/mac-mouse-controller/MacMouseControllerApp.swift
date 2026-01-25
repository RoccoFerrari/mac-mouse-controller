//
//  mac_mouse_controllerApp.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import SwiftUI
internal import Combine

@main
struct MacMouseControllerApp: App {
    // @State: trace if permissions are enabled
    @State private var hasPermissions: Bool = false
    
    // Timer for checking permissions again
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Initial check on starting
                    hasPermissions = PermissionManager.checkAccessibilityPermissions()
                }
                .onReceive(timer) { _ in
                    // Re-check every 2 secs while we don't get permissions
                    if !hasPermissions {
                        hasPermissions = PermissionManager.checkAccessibilityPermissions()
                        if hasPermissions {
                            print("Permissions are now enabled!")
                            
                            // Potential EventTap place
                        }
                    }
                }
                .alert("Permissions required", isPresented: Binding(get: { !hasPermissions }, set: { _ in })) {
                    Button("Open Settings") {
                        PermissionManager.openAccessibilitySettings()
                    }
                    Button("Exit") {
                        NSApplication.shared.terminate(nil)
                    }
                } message: {
                    Text("For this app to work, please enable 'Allow access in background' in the System Preferences -> Privacy -> Accessibility section.")
                }
        }
    }
}
