//
//  MouseEventHandler.swift
//  mac-mouse-controller
//
//  Created by Rocco Ferrari on 26/01/26.
//

import CoreGraphics

/// Protocol for any class that wants to process or modify mouse events.
protocol MouseEventHandler {
    /// Handles an incoming event.
    /// - Parameters:
    ///   - type: The type of the event (click, scroll, move).
    ///   - event: The native CGEvent.
    /// - Returns: The event (possibly modified) to pass to the next handler,
    ///            or `nil` if the event should be blocked (consumed).
    func handle(type: CGEventType, event: CGEvent) -> CGEvent?
}
