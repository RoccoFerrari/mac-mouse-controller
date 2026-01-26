//
//  BackButtonHandler.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import CoreGraphics
import Cocoa

/// Example handler
class BackButtonHandler: MouseEventHandler {
    
    func handle(type: CGEventType, event: CGEvent) -> CGEvent? {
        // We only care about "Other" mouse buttons (side buttons, wheel click)
        guard type == .otherMouseDown else {
            return event // Pass the event untouched to the next handler
        }
        
        let buttonNumber = event.getIntegerValueField(.mouseEventButtonNumber)
        
        // Assuming button #3 is the "Back" button on your mouse
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
