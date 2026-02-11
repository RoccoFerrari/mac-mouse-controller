//
//  MouseHookService.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 25/01/26.
//

import Foundation
import Cocoa

// -----------------------------------------------------------------------------
// GLOBAL C-STYLE CALLBACK
// This function must be outside the class to ensure C-compatibility without crashes.
// -----------------------------------------------------------------------------
func globalEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    // Safety check: if refcon is nil, we can't access our service, so let the event pass.
    guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
    
    // Recover the MouseHookService instance from the void pointer
    let service = Unmanaged<MouseHookService>.fromOpaque(refcon).takeUnretainedValue()
    
    // Delegate the logic to the service instance method
    return service.processEvent(proxy: proxy, type: type, event: event)
}

// -----------------------------------------------------------------------------
// SERVICE CLASS
// -----------------------------------------------------------------------------
class MouseHookService {
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var handlers: [MouseEventHandler] = []
    
    // Internal method called by the global callback
    func processEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        
        // --- TIMEOUT / DISABLE HANDLING ---
        if type == .tapDisabledByTimeout {
            print("Warning: Event Tap disabled by timeout. Re-enabling...")
            if let tap = self.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        if type == .tapDisabledByUserInput {
            print("Warning: Event Tap disabled by user input. Re-enabling...")
            if let tap = self.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        // --- HANDLER CHAIN ---
        var currentEvent: CGEvent? = event
        
        for handler in handlers {
            guard let evt = currentEvent else { break }
            currentEvent = handler.handle(type: type, event: evt)
        }
        
        if let finalEvent = currentEvent {
            return Unmanaged.passUnretained(finalEvent)
        } else {
            // Event consumed (e.g. Smooth Scroll or Zoom)
            return nil
        }
    }
    
    func add(handler: MouseEventHandler) {
        handlers.append(handler)
    }
    
    func start() {
        if eventTap != nil { return } // Already running
        
        print("Starting Mouse Hook Service...")
        
        // Define events to intercept
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.rightMouseDown.rawValue) |
                        (1 << CGEventType.otherMouseDown.rawValue) |
                        (1 << CGEventType.scrollWheel.rawValue) |
                        (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue)
        
        // Pass 'self' as a void pointer to the callback
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        // Create the Event Tap
        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: globalEventCallback, // Use the global function
            userInfo: selfPointer
        ) else {
            print("CRITICAL ERROR: Failed to create Event Tap.")
            print("HINT: Verify that 'App Sandbox' is DISABLED in Xcode Signing & Capabilities.")
            return
        }
        
        self.eventTap = tap
        
        // Add to RunLoop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("Mouse Hook Service Started Successfully.")
    }
    
    func stop() {
        print("Stopping Mouse Hook Service...")
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap) // Crucial to prevent freeze
        }
        
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        handlers.removeAll()
        
        print("Mouse Hook Service Stopped.")
    }
}
