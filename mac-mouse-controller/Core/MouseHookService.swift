//
//  MouseHookService.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import Foundation
import CoreGraphics

class MouseHookService {
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // Scalable list of handlers (Chain of Responsibility)
    private var handlers: [MouseEventHandler] = []
    
    /// Adds a new handler to the processing chain
    func add(handler: MouseEventHandler) {
        handlers.append(handler)
    }
    
    /// Starts the mouse interception
    func start() {
        print("MouseHookService: Starting...")
        
        // Define which events we want to intercept
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.leftMouseUp.rawValue) |
                        (1 << CGEventType.rightMouseDown.rawValue) |
                        (1 << CGEventType.rightMouseUp.rawValue) |
                        (1 << CGEventType.otherMouseDown.rawValue) |
                        (1 << CGEventType.otherMouseUp.rawValue) |
                        (1 << CGEventType.scrollWheel.rawValue)
        
        // Pass 'self' as an UnsafeMutableRawPointer to access it inside the static callback
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        // Create the Event Tap
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,       // Intercept at session level
            place: .headInsertEventTap,    // Insert at the "head" (before other apps)
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: mouseEventCallback,
            userInfo: observer
        ) else {
            print("ERROR: Could not create Event Tap. Check Accessibility permissions.")
            return
        }
        
        self.eventTap = eventTap
        
        // Add the tap to the main RunLoop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        print("MouseHookService: Started successfully.")
    }
    
    /// Stops the interception
    func stop() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
            print("MouseHookService: Stopped.")
        }
    }
    
    // Internal method called by the C callback to process the chain
    fileprivate func processEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        
        var currentEvent: CGEvent? = event
        
        // Iterate over all registered handlers
        for handler in handlers {
            guard let evt = currentEvent else { break }
            
            // Pass the event to the current handler.
            // If it returns nil, the event is consumed.
            // If it returns a modified event, that becomes the input for the next handler.
            currentEvent = handler.handle(type: type, event: evt)
            
            if currentEvent == nil {
                // A handler decided to block the event. Stop the chain.
                return nil
            }
        }
        
        // If the event survived all handlers, pass it back to the system
        if let finalEvent = currentEvent {
            return Unmanaged.passRetained(finalEvent)
        } else {
            return nil
        }
    }
}

// -----------------------------------------------------------------------------
// GLOBAL C-STYLE CALLBACK
// This function is called by macOS for every mouse event. It must be FAST.
// -----------------------------------------------------------------------------
func mouseEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
    
    // Recover the MouseHookService instance from the void pointer
    let service = Unmanaged<MouseHookService>.fromOpaque(refcon).takeUnretainedValue()
    
    // Delegate logic to the Swift class instance
    return service.processEvent(proxy: proxy, type: type, event: event)
}
