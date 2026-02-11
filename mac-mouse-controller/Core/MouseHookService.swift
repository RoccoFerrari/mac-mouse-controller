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

/// **Global Event Callback**
///
/// This is the C-compatible function pointer required by `CGEvent.tapCreate`.
/// Since Core Graphics is a C API, it cannot call a Swift class method directly.
///
/// - Parameters:
///   - proxy: The tap proxy (allows posting new events).
///   - type: The type of event (Click, Scroll, etc.).
///   - event: The actual `CGEvent` object.
///   - refcon: A "Reference Context" (void pointer). We pass `self` (the Service instance) here.
/// - Returns: The event to pass to the system, or `nil` if we want to block it.
func globalEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    
    // Safety check: if refcon is nil, we can't access our service, so let the event pass.
    guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
    
    // Recover the MouseHookService instance from the void pointer
    // Converts the raw opaque pointer back into a strong Swift reference.
    let service = Unmanaged<MouseHookService>.fromOpaque(refcon).takeUnretainedValue()
    
    // Delegate the logic to the service instance method
    return service.processEvent(proxy: proxy, type: type, event: event)
}

// -----------------------------------------------------------------------------
// SERVICE CLASS
// -----------------------------------------------------------------------------

/// **Low-Level Event Interceptor**
///
/// This class manages the lifecycle of the `CGEventTap`.
/// It is responsible for bridging the low-level Core Graphics system events
/// into the high-level Swift logic of the application.
class MouseHookService {
    
    /// The reference to the system Mach port used for the event tap.
    private var eventTap: CFMachPort?
    
    /// The run loop source that keeps the event tap active in the background.
    private var runLoopSource: CFRunLoopSource?
    
    /// A chain of processors that modify or consume events.
    private var handlers: [MouseEventHandler] = []
    
    // Internal method called by the global callback
    /// **Event Processing Logic**
    ///
    /// Receives the raw event from the global callback and passes it through the handler chain.
    func processEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        
        // --- TIMEOUT / DISABLE HANDLING ---
        // macOS automatically disables Event Taps if they take too long to respond
        // or if the system is under heavy load. We must auto-reenable them here.
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
        // Iterate through registered handlers (e.g., Modifiers, Loggers).
        // Each handler can modify the event or return nil to consume/block it.
        var currentEvent: CGEvent? = event
        
        for handler in handlers {
            guard let evt = currentEvent else { break }
            currentEvent = handler.handle(type: type, event: evt)
        }
        
        if let finalEvent = currentEvent {
            // Pass the (potentially modified) event back to the system.
            return Unmanaged.passUnretained(finalEvent)
        } else {
            // Event consumed (e.g. Smooth Scroll or Zoom)
            // Returning nil tells the system to drop this event completely.
            return nil
        }
    }
    
    /// Registers a new logic handler to the processing chain.
    func add(handler: MouseEventHandler) {
        handlers.append(handler)
    }
    
    /// **Start Interception**
    ///
    /// Creates the Event Tap and attaches it to the main RunLoop.
    /// - Note: This requires Accessibility Permissions to function.
    func start() {
        if eventTap != nil { return } // Already running
        
        print("Starting Mouse Hook Service...")
        
        // Define events to intercept
        // We act on mouse clicks, scrolling, and modifier keys.
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.rightMouseDown.rawValue) |
                        (1 << CGEventType.otherMouseDown.rawValue) |
                        (1 << CGEventType.scrollWheel.rawValue) |
                        (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue)
        
        // Pass 'self' as a void pointer to the callback
        // This allows the global static C function to call instance methods on this object.
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        // Create the Event Tap
        // .cghidEventTap: Listens at the HID level (hardware input).
        // .headInsertEventTap: We want to be the first to see the event to modify it.
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
        // Required for the tap to receive events asynchronously.
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("Mouse Hook Service Started Successfully.")
    }
    
    /// **Stop Interception**
    ///
    /// Safely detaches the Event Tap and cleans up resources.
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
