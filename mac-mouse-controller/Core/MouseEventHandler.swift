//
//  MouseEventHandler.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import CoreGraphics

/// Protocol for any class that wants to process or modify mouse events.
///
/// **Architecture Role:** Strategy / Chain of Responsibility
/// This interface defines the contract for any logic that sits between the raw OS input
/// and the final system action.
///
/// Concrete implementations (like `ConfigurableHandler`) are added to the `MouseHookService`
/// to intercept, modify, or block events based on user settings.
protocol MouseEventHandler {
    /// Handles an incoming event.
    ///
    /// - Parameters:
    ///   - type: The specific type of the event (e.g., `.leftMouseDown`, `.scrollWheel`).
    ///   - event: The native `CGEvent` object containing data like coordinates, button number, and modifiers.
    /// - Returns:
    ///   - The `CGEvent` (modified or original) to pass it to the next handler in the chain or to the system.
    ///   - `nil` if the event should be **blocked/consumed** (preventing the system from seeing it).
    func handle(type: CGEventType, event: CGEvent) -> CGEvent?
}
