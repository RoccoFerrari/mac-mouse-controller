//
//  PermissionManager.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import Foundation
import ApplicationServices
import Cocoa

class PermissionManager {
    
    /// Check for permissions.
    /// If not present, application shows default popup
    /// - Parameter shouldPrompt: if True, shows system popup
    static func checkAccessibilityPermissions(shouldPrompt: Bool) -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: [String: Any] = [
                    promptKey: shouldPrompt
                ]
        let isTrusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
            return isTrusted
        }
        
    /// Open the pannel: Privacy & Sicurity -> Accessibility
        static func openAccessibilitySettings() {
            let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        }
}
