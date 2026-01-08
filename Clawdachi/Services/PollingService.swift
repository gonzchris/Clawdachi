//
//  PollingService.swift
//  Clawdachi
//
//  Shared polling infrastructure for services that need periodic status checks
//

import Foundation

/// Protocol for services that poll periodically
protocol PollingService: AnyObject {
    /// Polling interval in seconds
    var pollInterval: TimeInterval { get }

    /// Called on each poll cycle - implement your check logic here
    func poll()

    /// Internal timer storage - do not set directly, use startPolling/stopPolling
    var pollTimer: Timer? { get set }
}

// MARK: - Default Implementation

extension PollingService {

    /// Start polling - checks immediately, then at pollInterval
    /// Uses RunLoop.main with .common mode so polling continues during UI tracking (dragging, scrolling)
    func startPolling() {
        // Check immediately
        poll()

        // Then poll periodically with common mode so it fires during UI interactions
        pollTimer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
        RunLoop.main.add(pollTimer!, forMode: .common)
    }

    /// Stop polling and clean up timer
    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}
