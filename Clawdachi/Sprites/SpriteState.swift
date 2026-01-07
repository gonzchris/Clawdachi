//
//  SpriteState.swift
//  Clawdachi
//
//  Centralized state machine for sprite animations
//

import Foundation

/// Primary animation state for the sprite (mutually exclusive)
enum SpriteState: Equatable, CustomStringConvertible {
    /// Normal idle state - breathing, blinking, can transition to substates
    case idle

    /// User is dragging the sprite
    case dragging

    /// Sleeping mode (user-triggered)
    case sleeping

    /// Dancing to music (music-triggered)
    case dancing

    /// Claude is actively thinking/coding
    case claudeThinking

    /// Claude is in plan mode (lightbulb)
    case claudePlanning

    /// Claude is waiting for user input (question mark)
    case claudeWaiting

    /// Claude session ended (party celebration)
    case claudeCelebrating

    /// Voice input listening mode
    case listening

    // MARK: - Idle Substates

    /// Idle substate: whistling animation in progress
    case whistling

    /// Idle substate: eyes looking around
    case lookingAround

    /// Idle substate: smoking animation
    case smoking

    /// Idle substate: performing a click reaction (wave, bounce)
    case performingAction

    // MARK: - Description

    var description: String {
        switch self {
        case .idle: return "idle"
        case .dragging: return "dragging"
        case .sleeping: return "sleeping"
        case .dancing: return "dancing"
        case .claudeThinking: return "claudeThinking"
        case .claudePlanning: return "claudePlanning"
        case .claudeWaiting: return "claudeWaiting"
        case .claudeCelebrating: return "claudeCelebrating"
        case .listening: return "listening"
        case .whistling: return "whistling"
        case .lookingAround: return "lookingAround"
        case .smoking: return "smoking"
        case .performingAction: return "performingAction"
        }
    }

    // MARK: - State Categories

    /// Whether this is an idle substate (can only enter from idle)
    var isIdleSubstate: Bool {
        switch self {
        case .whistling, .lookingAround, .smoking, .performingAction:
            return true
        default:
            return false
        }
    }

    /// Whether this is a Claude integration state
    var isClaudeState: Bool {
        switch self {
        case .claudeThinking, .claudePlanning, .claudeWaiting, .claudeCelebrating:
            return true
        default:
            return false
        }
    }

    /// Whether this is the voice input listening state
    var isListeningState: Bool {
        self == .listening
    }

    /// Whether idle animations should be paused in this state
    var pausesIdleAnimations: Bool {
        switch self {
        case .idle:
            return false
        default:
            return true
        }
    }

    /// Whether mouse tracking should be enabled in this state
    var allowsMouseTracking: Bool {
        switch self {
        case .idle, .whistling, .lookingAround, .performingAction:
            return true
        case .dancing:
            return true  // Can still track during dance
        default:
            return false
        }
    }
}

// MARK: - State Manager

/// Manages sprite state transitions with validation
class SpriteStateManager {

    /// Current primary state
    private(set) var currentState: SpriteState = .idle

    /// Callback when state changes
    var onStateChanged: ((SpriteState, SpriteState) -> Void)?

    // MARK: - Transition Validation

    /// Check if transition from current state to new state is allowed
    func canTransitionTo(_ newState: SpriteState) -> Bool {
        // Same state - no transition needed
        if currentState == newState { return false }

        switch (currentState, newState) {
        // Note: Dragging is now an overlay behavior, not a state transition
        // This case is kept for backwards compatibility but rarely used
        case (_, .dragging):
            return true

        // Can always return to idle (cleanup)
        case (_, .idle):
            return true

        // From idle, can go to any state
        case (.idle, _):
            return true

        // Idle substates can transition to each other or back to idle
        case let (from, to) where from.isIdleSubstate && to.isIdleSubstate:
            return false  // Can't go directly between substates
        case let (from, _) where from.isIdleSubstate:
            return true  // Can exit substate to any non-substate

        // Claude states can transition between each other
        case let (from, to) where from.isClaudeState && to.isClaudeState:
            return true
        // From Claude states, only allow idle or dragging (already handled above)
        case let (from, _) where from.isClaudeState:
            return false

        // From sleeping, only dragging or idle (already handled above)
        case (.sleeping, _):
            return false

        // From dancing, Claude states or listening can interrupt (dragging/idle already handled above)
        case (.dancing, let to) where to.isClaudeState || to.isListeningState:
            return true
        case (.dancing, _):
            return false

        // Listening can be entered from most states
        case (_, .listening):
            return true

        // From listening, can return to idle (handled above) or claude states
        case (.listening, let to) where to.isClaudeState:
            return true
        case (.listening, _):
            return false

        // Default: allow transition
        default:
            return true
        }
    }

    /// Attempt to transition to a new state
    /// - Returns: true if transition occurred, false if blocked
    @discardableResult
    func transitionTo(_ newState: SpriteState) -> Bool {
        guard canTransitionTo(newState) else { return false }

        let oldState = currentState
        currentState = newState
        onStateChanged?(oldState, newState)
        return true
    }

    /// Force transition without validation (use sparingly)
    func forceState(_ newState: SpriteState) {
        let oldState = currentState
        currentState = newState
        onStateChanged?(oldState, newState)
    }

    /// Reset to idle state
    func reset() {
        transitionTo(.idle)
    }

    // MARK: - Convenience Queries

    /// Check if currently in an idle or idle-substate
    var isEffectivelyIdle: Bool {
        currentState == .idle || currentState.isIdleSubstate
    }

    /// Check if a Claude animation is active
    var isClaudeActive: Bool {
        currentState.isClaudeState
    }

    /// Check if idle animations should run
    var shouldRunIdleAnimations: Bool {
        !currentState.pausesIdleAnimations
    }
}
