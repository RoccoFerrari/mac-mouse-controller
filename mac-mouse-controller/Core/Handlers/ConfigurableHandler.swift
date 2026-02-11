//
//  ConfigurableHandler.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import Foundation
import CoreGraphics
import Cocoa

class ConfigurableHandler: MouseEventHandler {
    
    // Reference to the source of truth for user settings
    private var userProfile: UserProfile
    
    // Variables for SMOOTH SCROLLING
    private var velocityY: Double = 0
    private var velocityX: Double = 0
    private var scrollTimer: Timer?
    private let friction: Double = 0.92 // Deceleration (0.92 = fluid, 0.8 = instant)
    private let stopThreshold: Double = 0.2 // Speed ​​below which we stop
    private let magicNumber: Int64 = 555 // ID for recognize these events
    
    init(profile: UserProfile) {
        self.userProfile = profile
    }
    
    func handle(type: CGEventType, event: CGEvent) -> CGEvent? {
        
        // check infinte loop
        if event.getIntegerValueField(.eventSourceUserData) == magicNumber {
            return event
        }
        
        // Smooth scrolling logic
        if type == .scrollWheel && userProfile.smoothScrolling {
            // if zoomming -> smooth disabled
            let flags = event.flags
            if !flags.contains(.maskCommand) {
                let deltaY = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
                let deltaX = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
                // if there is movement -> we accumulate speed
                if deltaY != 0 || deltaX != 0 {
                    velocityY += Double(deltaY) * 3.0
                    velocityX += Double(deltaX) * 3.0
                    
                    startSmoothTimer()
                    
                    // No more jerky event
                    return nil
                }
                
            }
        }
        
        // Handle global scroll inversion
        if type == .scrollWheel && userProfile.invertScrolling {
            let currentY = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
            let currentX = event.getIntegerValueField(.scrollWheelEventDeltaAxis2)
                    
            // Sign invert
            event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -currentY)
            event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: -currentX)
        }
        
        // Identify the input
        var currentButton: MouseButton = .other
        
        if type == .scrollWheel {
            currentButton = .scroll
        } else if type == .leftMouseDown || type == .rightMouseDown || type == .otherMouseDown {
            let num = event.getIntegerValueField(.mouseEventButtonNumber)
            currentButton = MouseButton(rawValue: Int(num)) ?? .other
        } else {
            return event // ignore movement events or keyUp
        }
        
        // Identify modifiers (Cmd, Ctrl, etc.) currently held down
        let currentModifiers = ModifierSet.from(cgFlags: event.flags)
        
        // LOOKUP: Find a matching rule
        // We look for an enabled rule that matches both the button and the modifiers
        if let rule = userProfile.rules.first(where: { rule in
            return rule.isEnabled &&
                   rule.mouseButton == currentButton &&
                   rule.requiredModifiers == currentModifiers
        }) {
            print("Match found! Rule ID: \(rule.id). Executing action...")
            
            // EXECUTE the action
            return execute(action: rule.action, on: event)
        }
        
        // No rule found -> Pass the event through
        return event
    }
    
    // MARK: - Action Execution Logic
    
    private func execute(action: ActionType, on event: CGEvent) -> CGEvent? {
        switch action {
        case .zoom:
            // Direction of the scroll
            let deltaY = event.getIntegerValueField(.scrollWheelEventDeltaAxis1)
            
            if deltaY > 0 {
                // Scroll Up -> Zoom In
                // Keypad num: 69 = +
                simulateKeystroke(keyCode: 69, modifiers: .command)
            } else if deltaY < 0 {
                // Scroll Down -> Zoom out
                // Keypad num: 78 = -
                simulateKeystroke(keyCode: 78, modifiers: .command)
            }
            return nil
            
        case .sensivity(factor: let factor):
            // Multiply deltaY by factor
            let axis1 = event.getIntegerValueField(.scrollWheelEventDeltaAxis1) // Y axis
            let axis2 = event.getIntegerValueField(.scrollWheelEventDeltaAxis2) // X axis
            event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: Int64(Double(axis1) * factor))
            event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: Int64(Double(axis2) * factor))
            return event // not nil
            
        case .keyboardShortcut(let keyCode, let modifiers):
            simulateKeystroke(keyCode: keyCode, modifiers: modifiers)
            return nil
            
        case .systemFunction(let feature):
            performSystemFeature(feature)
            return nil
            
        case .navigation(let navAction):
            performNavigation(navAction)
            return nil
            
        case .none:
            return event
        }
    }
    
    // Smooth Scrolling logic
    private func startSmoothTimer() {
        // If a timer exists already, we don't create a new one
        if scrollTimer != nil { return }
        
        // 60fps timer -> 0.016 sec
        DispatchQueue.main.async {
            self.scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] timer in
                guard let self = self else { timer.invalidate(); return }
                self.processSmoothTick()
            }
        }
    }
    
    private func processSmoothTick() {
        // Apply friction
        velocityY *= friction
        velocityX *= friction
        
        // if speed is almost zero, stop
        if abs(velocityY) < stopThreshold && abs(velocityX) < stopThreshold {
            stopSmoothTimer()
            return
        }
        
        // Compute the delta frame
        // If 'Invert' is enabled, values are inverted here
        let direction = userProfile.invertScrolling ? -1.0 : 1.0
        let deltaY = Int64(round(velocityY * direction))
        let deltaX = Int64(round(velocityX * direction))
        
        // if values are 0 (but speed > threshold), no empty events are returned
        if deltaY == 0 && deltaX == 0 { return }
        
        // Syntetic event scroll
        if let event = CGEvent(scrollWheelEvent2Source: nil,
                               units: .pixel,
                               wheelCount: 2,
                               wheel1: Int32(deltaY),
                               wheel2: Int32(deltaX),
                               wheel3: 0) {
            // magic number for recognize the vent in handle()
            event.setIntegerValueField(.eventSourceUserData, value: magicNumber)
            event.post(tap: .cghidEventTap)
        }
    }
    
    private func stopSmoothTimer() {
        scrollTimer?.invalidate()
        scrollTimer = nil
        velocityX = 0
        velocityY = 0
    }
    
    // Helper: Simulates a physical keyboard press
    private func simulateKeystroke(keyCode: Int, modifiers: ModifierSet) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Create Key Down
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true) else { return }
        
        // Apply modifiers to the event flags
        var flags = CGEventFlags()
        if modifiers.contains(.command) { flags.insert(.maskCommand) }
        if modifiers.contains(.shift) { flags.insert(.maskShift) }
        if modifiers.contains(.control) { flags.insert(.maskControl) }
        if modifiers.contains(.option) { flags.insert(.maskAlternate) }
        keyDown.flags = flags
        
        // Create Key Up
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false) else { return }
        keyUp.flags = flags
        
        // Post events
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
    
    private func performSystemFeature(_ feature: SystemFeature) {
        // Implementation depends on the feature.
        // Some can be triggered via NSWorkspace, others need shortcuts.
        switch feature {
        case .missionControl:
            // Default shortcut for Mission Control is usually Ctrl + Arrow Up.
            // A more robust way involves using private APIs or specific performKeyEquivalents.
            print("System Feature Triggered: \(feature.rawValue)")
            // NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Mission Control.app"))
        default:
            print("Feature not implemented yet: \(feature.rawValue)")
        }
    }
    
    private func performNavigation(_ action: NavigationAction) {
        switch action {
        case .back:
            // Standard shortcut for "Back" in browsers/Finder is CMD + left arrow
            simulateKeystroke(keyCode: 123, modifiers: .command)
        case .forward:
            // Standard shortcut for "Forward" is CMD + right arrow
            simulateKeystroke(keyCode: 124, modifiers: .command)
        case .spaceLeft:
            // Ctrl + left arrow (switch space/desktop)
            simulateKeystroke(keyCode: 123, modifiers: .control)
        case .spaceRight:
            // Ctrl + right arrow (switch space/desktop)
            simulateKeystroke(keyCode: 124, modifiers: .control)
        default:
            print("Navigation: \(action.rawValue)")
        }
    }
}
