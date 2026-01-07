//
//  AnimationTimings.swift
//  Clawdachi
//
//  Centralized animation timing constants for easy tuning
//

import Foundation

/// Weighted random timing for organic feel
/// Occasionally produces longer intervals to break predictability
struct IdleTiming {
    let baseInterval: TimeInterval
    let variance: TimeInterval
    let rareChanceMultiplier: Double  // e.g., 0.15 = 15% chance of 2x interval

    /// Generate the next interval with optional rare long pause
    func nextInterval() -> TimeInterval {
        var interval = baseInterval + .random(in: -variance...variance)
        if Double.random(in: 0...1) < rareChanceMultiplier {
            interval *= 2  // Occasional longer pause for natural feel
        }
        return interval
    }
}

/// Animation timing constants for Clawdachi
enum AnimationTimings {

    // MARK: - Idle Animations

    /// Duration of one full breathing cycle
    static let breathingDuration: TimeInterval = 3.0

    /// Duration of one full side-sway cycle
    static let swayDuration: TimeInterval = 4.0

    // MARK: - Blinking

    /// Minimum interval between blinks
    static let blinkMinInterval: TimeInterval = 2.5

    /// Maximum interval between blinks
    static let blinkMaxInterval: TimeInterval = 6.0

    /// Duration of the blink animation
    static let blinkDuration: TimeInterval = 0.18

    // MARK: - Whistling

    /// Minimum interval between whistles
    static let whistleMinInterval: TimeInterval = 18.0

    /// Maximum interval between whistles
    static let whistleMaxInterval: TimeInterval = 35.0

    /// Duration of the whistle animation
    static let whistleDuration: TimeInterval = 2.0

    // MARK: - Looking Around

    /// Minimum interval between look-around animations
    static let lookAroundMinInterval: TimeInterval = 5.0

    /// Maximum interval between look-around animations
    static let lookAroundMaxInterval: TimeInterval = 12.0

    // MARK: - Organic Idle Timing (weighted randomness for natural feel)

    /// Look-around timing with occasional longer pauses
    static let lookAroundTiming = IdleTiming(baseInterval: 8.5, variance: 3.5, rareChanceMultiplier: 0.15)

    /// Blink timing with occasional longer pauses
    static let blinkTiming = IdleTiming(baseInterval: 4.0, variance: 1.5, rareChanceMultiplier: 0.1)

    // MARK: - Action Animations

    /// Standard pop-in animation duration
    static let popInDuration: TimeInterval = 0.12

    /// Standard fade-out duration
    static let fadeOutDuration: TimeInterval = 0.15

    /// Music note float duration
    static let noteFloatDuration: TimeInterval = 1.0

    /// Heart float duration
    static let heartFloatDuration: TimeInterval = 0.7

    /// Sweat drop fall duration
    static let sweatDropFallDuration: TimeInterval = 0.5

    // MARK: - Drag Animation

    /// Arm wiggle duration (one direction)
    static let armWiggleDuration: TimeInterval = 0.12

    /// Leg wiggle duration (one direction)
    static let legWiggleDuration: TimeInterval = 0.15

    /// Min interval between sweat drops
    static let sweatDropMinInterval: TimeInterval = 0.5

    /// Max interval between sweat drops
    static let sweatDropMaxInterval: TimeInterval = 0.9

    // MARK: - Sleep Animation

    /// Interval between Z spawns
    static let sleepZInterval: TimeInterval = 2.5

    // MARK: - Dance Animation

    /// Duration of one full sway cycle (left to right)
    static let danceSwayDuration: TimeInterval = 0.6

    /// Interval between music note spawns while dancing
    static let danceMusicNoteInterval: TimeInterval = 0.8

    // MARK: - Claude Thinking Animation

    /// Duration of one thinking bob cycle (up and down)
    static let thinkingBobDuration: TimeInterval = 2.0

    /// Interval between thinking particle spawns
    static let thinkingParticleInterval: TimeInterval = 0.7

    /// Min interval between thinking dot spawns
    static let thinkingDotMinInterval: TimeInterval = 0.6

    /// Max interval between thinking dot spawns
    static let thinkingDotMaxInterval: TimeInterval = 1.0

    /// Duration of thinking particle float
    static let thinkingParticleFloatDuration: TimeInterval = 1.0

    /// Min interval between thinking blinks
    static let thinkingBlinkMinInterval: TimeInterval = 4.0

    /// Max interval between thinking blinks
    static let thinkingBlinkMaxInterval: TimeInterval = 7.0

    /// Maximum age of session file before considered stale (seconds)
    /// Set to 5 minutes to allow for long thinking periods between hook events.
    /// The Notification hook fires after 60s of inactivity to refresh the timestamp.
    static let sessionStalenessThreshold: TimeInterval = 300.0

    // MARK: - Claude Planning Animation

    /// Min interval between planning spark spawns
    static let planningSparkMinInterval: TimeInterval = 0.15

    /// Max interval between planning spark spawns
    static let planningSparkMaxInterval: TimeInterval = 0.35

    /// Planning spark lifetime (how long before fading)
    static let planningSparkLifetime: TimeInterval = 0.25

    // MARK: - Smoking Animation

    /// Minimum interval between smoking animations
    static let smokingMinInterval: TimeInterval = 20.0

    /// Maximum interval between smoking animations
    static let smokingMaxInterval: TimeInterval = 40.0

    /// Duration of the smoking animation
    static let smokingDuration: TimeInterval = 18.0

    /// Interval between puffs during smoking
    static let smokePuffInterval: TimeInterval = 3.0

    /// Duration of smoke particle float
    static let smokeFloatDuration: TimeInterval = 1.5

    // MARK: - State Transitions

    /// Duration for graceful state transitions (fade out current visuals)
    static let stateTransitionDuration: TimeInterval = 0.25

    /// Duration for overlay effects to fade out
    static let overlayFadeDuration: TimeInterval = 0.2
}
