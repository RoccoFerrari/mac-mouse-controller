//
//  BackButtonHandler.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import CoreGraphics
import Cocoa

/// A specific handler designed to intercept mouse button 3 and trigger a "Back" navigation action.
/// Example handler
class BackButtonHandler: MouseEventHandler {
    
    /// Processes the incoming event to check for the "Back" button (Button 3).
    /// - Parameters:
    ///   - type: The type of the event (e.g., left click, other click).
    ///   - event: The low-level CGEvent.
    /// - Returns: `nil` if the back button is detected (consuming the event), otherwise the original event.
    func handle(type: CGEventType, event: CGEvent) -> CGEvent? {
        // We only care about "Other" mouse buttons (side buttons, wheel click)
        // Filter: proceed only if it is a non-standard mouse button click (e.g., side buttons).
        guard type == .otherMouseDown else {
            return event // Pass the event untouched to the next handler
        }
        
        // Retrieve the integer identifying which button was pressed.
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
        
        // Assuming button #3 is the "Back" button on your mouse
        // Check if the physical button corresponds to the standard "Back" button index (3).
        if buttonNumber == 3 {
            print("🔙 BackButtonHandler: Button 3 intercepted! Executing 'Back' action.")
            
            // TODO: logic to simulate CMD+[ or swipe
            // simulateBackAction()
            
            // By returning nil, we tell the system: This event never happened
            // No other app will see the click of button 3.
            return nil
        }
        
        return event
    }
}
