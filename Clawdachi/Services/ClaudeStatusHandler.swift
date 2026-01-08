//
//  ClaudeStatusHandler.swift
//  Clawdachi
//

import Foundation

/// Handles Claude session status transitions, sound effects, and tracking
/// Extracts the status change logic from ClawdachiScene for better separation of concerns
class ClaudeStatusHandler {

    // MARK: - Callbacks

    /// Called when animations should be updated for a status change
    var onUpdateAnimations: ((String?) -> Void)?

    /// Called when a thinking message should be shown
    var onShowThinkingMessage: (() -> Void)?

    /// Called when a planning message should be shown
    var onShowPlanningMessage: (() -> Void)?

    /// Called when a waiting message should be shown (with question mark)
    var onShowWaitingMessage: (() -> Void)?

    /// Called when completion should be celebrated
    var onShowCompletion: (() -> Void)?

    // MARK: - Session Tracking

    /// Last known status per session (to detect actual state transitions vs tab switches)
    private var sessionLastStatus: [String: String] = [:]

    /// Track which sessions have played sounds this work cycle
    private var sessionsPlayedQuestionSound: Set<String> = []
    private var sessionsPlayedCompleteSound: Set<String> = []

    // MARK: - Public Methods

    /// Handle a Claude status change notification
    /// - Parameters:
    ///   - isActive: Whether any session is active
    ///   - status: The current status string (thinking, planning, waiting, idle, etc.)
    ///   - sessionId: The session ID for sound/transition tracking
    func handleStatusChanged(isActive: Bool, status: String?, sessionId: String?) {
        // Always update animations to reflect current monitored session's state
        onUpdateAnimations?(status)

        // For sound logic, we need a valid session ID
        guard let id = sessionId else { return }

        let currentStatus = status ?? "none"
        let previousStatus = sessionLastStatus[id]

        // Update stored status
        sessionLastStatus[id] = currentStatus

        // Check if this is an actual state transition (not just a tab switch)
        let isRealTransition = previousStatus != currentStatus

        guard isRealTransition else {
            // Just switched tabs to view this session - no sounds
            return
        }

        // Determine if previous status was "working"
        let wasWorking = previousStatus == "thinking" || previousStatus == "tools" || previousStatus == "planning"

        // Handle actual state transitions
        if currentStatus == "waiting" && wasWorking {
            // Transitioned from working to waiting - play question sound
            if !sessionsPlayedQuestionSound.contains(id) {
                sessionsPlayedQuestionSound.insert(id)
                SoundManager.shared.playQuestionSound()
                onShowWaitingMessage?()
            }
        } else if currentStatus == "idle" && wasWorking {
            // Transitioned from working to idle - play complete sound
            if !sessionsPlayedCompleteSound.contains(id) {
                sessionsPlayedCompleteSound.insert(id)
                SoundManager.shared.playCompleteSound()
                onShowCompletion?()
            }
        } else if currentStatus == "thinking" || currentStatus == "tools" || currentStatus == "planning" {
            // Started working - reset sound tracking for fresh cycle
            sessionsPlayedQuestionSound.remove(id)
            sessionsPlayedCompleteSound.remove(id)
        }
    }

    /// Clear all session tracking (e.g., when going to sleep)
    func clearTracking() {
        sessionLastStatus.removeAll()
        sessionsPlayedQuestionSound.removeAll()
        sessionsPlayedCompleteSound.removeAll()
    }
}
