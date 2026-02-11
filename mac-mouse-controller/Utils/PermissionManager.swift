//
//  PermissionManager.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import Foundation
import ApplicationServices
import Cocoa

/// **Permission Manager**
///
/// A utility class responsible for interacting with the macOS Accessibility API.
///
/// Since this application uses a `CGEventTap` to intercept global mouse events,
/// it requires "Accessibility" permissions to be granted by the user in System Settings.
class PermissionManager {
    
    /// Checks the current status of Accessibility Permissions for this process.
    ///
    /// - Parameter shouldPrompt:
    ///   - `true`: If permissions are missing, macOS will display the standard "App would like to control this computer" alert.
    ///   - `false`: Checks the status silently (useful for background checks or startup loops).
    /// - Returns: `true` if the app is trusted and can intercept events; `false` otherwise.
    static func checkAccessibilityPermissions(shouldPrompt: Bool) -> Bool {
        // Prepare the options dictionary.
        // kAXTrustedCheckOptionPrompt determines if the system dialog appears.
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: [String: Any] = [
                    promptKey: shouldPrompt
                ]
        
        // Query the Accessibility API to see if this process is trusted.
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
            return isTrusted
        }
        
    /// Opens the macOS System Settings application directly to the "Privacy & Security > Accessibility" pane.
    ///
    /// This uses a deep link URL (`x-apple.systempreferences`) to guide the user to the correct setting
    /// instead of making them search for it manually.
        static func openAccessibilitySettings() {
            let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }
}
