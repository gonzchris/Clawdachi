//
//  SessionSelector.swift
//  Clawdachi
//
//  Selects which Claude session to monitor based on activity priority
//

import Foundation

/// Protocol for session selection strategies
protocol SessionSelector {
    /// Select a session from the available sessions
    /// - Parameter sessions: Available sessions to choose from
    /// - Returns: The selected session, or nil if no valid session
    func select(from sessions: [SessionInfo]) -> SessionInfo?
}

/// Selects the most active session with hysteresis to prevent flickering
class MostActiveSessionSelector: SessionSelector {

    // MARK: - Hysteresis State

    /// Last selected session ID
    private var lastMonitoredSessionId: String?

    /// Time when the last session was selected
    private var lastMonitoredTime: Date?

    /// How long to "stick" with the current session before switching
    private let stickinessInterval: TimeInterval

    // MARK: - Initialization

    /// Create a new selector with the given stickiness interval
    /// - Parameter stickinessInterval: How long to prefer the current session (default 5 seconds)
    init(stickinessInterval: TimeInterval = 5.0) {
        self.stickinessInterval = stickinessInterval
    }

    // MARK: - Selection

    func select(from sessions: [SessionInfo]) -> SessionInfo? {
        // Sort by activity priority (desc), then timestamp (desc)
        let sortedByPriority = sessions.sorted { lhs, rhs in
            if lhs.activityPriority != rhs.activityPriority {
                return lhs.activityPriority > rhs.activityPriority
            }
            return lhs.timestamp > rhs.timestamp
        }

        guard let topSession = sortedByPriority.first else { return nil }

        // Apply hysteresis to prevent flickering between equal-priority sessions
        if let lastId = lastMonitoredSessionId,
           let currentSession = sessions.first(where: { $0.id == lastId }),
           currentSession.activityPriority >= topSession.activityPriority,
           let lastTime = lastMonitoredTime,
           Date().timeIntervalSince(lastTime) < stickinessInterval {
            return currentSession
        }

        // Switch to new top session
        lastMonitoredSessionId = topSession.id
        lastMonitoredTime = Date()
        return topSession
    }

    /// Reset the selector state (useful when selection mode changes)
    func reset() {
        lastMonitoredSessionId = nil
        lastMonitoredTime = nil
    }
}
