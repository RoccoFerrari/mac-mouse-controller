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
    static func checkAccessibilityPermissions() -> Bool {
        // options for show the popup
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        
        // C-based function that controlls effectively
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        return accessEnabled
    }
    
    /// Open the pannel: Privacy & Sicurity -> Accessibility
    static func openAccessibilitySettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
