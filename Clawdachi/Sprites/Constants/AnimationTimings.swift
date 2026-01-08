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
    static let whistleMinInterval: TimeInterval = 120.0

    /// Maximum interval between whistles
    static let whistleMaxInterval: TimeInterval = 180.0

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
    /// The Notification hook fires every 60s during long operations to refresh the timestamp.
    /// Set to 90s to allow for slight delays while still cleaning up crashed sessions quickly.
    static let sessionStalenessThreshold: TimeInterval = 90.0

    // MARK: - Claude Planning Animation

    /// Min interval between planning spark spawns
    static let planningSparkMinInterval: TimeInterval = 0.15

    /// Max interval between planning spark spawns
    static let planningSparkMaxInterval: TimeInterval = 0.35

    /// Planning spark lifetime (how long before fading)
    static let planningSparkLifetime: TimeInterval = 0.25

    // MARK: - Smoking Animation

    /// Minimum interval between smoking animations
    static let smokingMinInterval: TimeInterval = 120.0

    /// Maximum interval between smoking animations
    static let smokingMaxInterval: TimeInterval = 180.0

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

// MARK: - Dance Animation Constants

/// Constants for music-reactive dancing animation
enum DanceConstants {
    /// Rotation angle for body sway (radians)
    static let swayAngle: CGFloat = 0.06

    /// Rotation angle for arm wave (radians)
    static let armWaveAngle: CGFloat = 0.5

    /// Rotation angle for leg tap (radians)
    static let legTapAngle: CGFloat = 0.2

    /// Initial scale for music note pop-in
    static let noteInitialScale: CGFloat = 0.6

    /// Float height for music notes
    static let noteFloatHeight: CGFloat = 12

    /// Note rotation angle during float
    static let noteRotationAngle: CGFloat = 0.3
}

// MARK: - Smoking Animation Constants

/// Constants for smoking animation
enum SmokingConstants {
    /// Arm angle when holding cigarette at rest
    static let armRestAngle: CGFloat = 0.3

    /// Arm angle when cigarette at mouth
    static let armMouthAngle: CGFloat = 0.8

    /// Initial scale for cigarette
    static let cigaretteScale: CGFloat = 0.5

    /// Shrink factor per puff (multiply height by this)
    static let puffShrinkFactor: CGFloat = 0.88

    /// Minimum cigarette height
    static let minCigaretteHeight: CGFloat = 1.5

    /// Initial smoke particle scale
    static let smokeInitialScale: CGFloat = 0.25

    /// Final smoke particle scale
    static let smokeFinalScale: CGFloat = 0.6

    /// Smoke particle opacity
    static let smokeOpacity: CGFloat = 0.4

    /// Ember glow color blend factor
    static let emberGlowIntensity: CGFloat = 0.15
}

// MARK: - Claude Thinking Animation Constants

/// Constants for Claude Code thinking animation
enum ClaudeThinkingConstants {
    /// Lightbulb size (width, height)
    static let lightbulbSize = CGSize(width: 6.8, height: 9.6)

    /// Lightbulb position above head
    static let lightbulbPosition = CGPoint(x: 0, y: 15)

    /// Initial scale for lightbulb pop-in
    static let lightbulbInitialScale: CGFloat = 0.3

    /// Glance offset for focused eyes
    static let glanceOffset = CGPoint(x: 0, y: 1.0)

    /// Math symbol scale
    static let mathSymbolScale: CGFloat = 0.35

    /// Math symbol container initial scale
    static let symbolContainerScale: CGFloat = 0.6

    /// Math symbol fountain height range (min, max)
    static let fountainHeightMin: CGFloat = 8
    static let fountainHeightMax: CGFloat = 12

    /// Math symbol horizontal drift range
    static let symbolDriftRange: CGFloat = 4

    /// Math symbol rotation range
    static let symbolRotationRange: CGFloat = 0.8

    /// Thinking orb size
    static let orbSize = CGSize(width: 2, height: 2)

    /// Orb float distance range (min, max)
    static let orbFloatDistanceMin: CGFloat = 18
    static let orbFloatDistanceMax: CGFloat = 22

    /// Orb sway distance range
    static let orbSwayMin: CGFloat = 2
    static let orbSwayMax: CGFloat = 4

    /// Main cloud size
    static let mainCloudSize = CGSize(width: 15, height: 11)

    /// Cloud starting position
    static let cloudStartPosition = CGPoint(x: 0, y: 10)

    /// Cloud initial scale
    static let cloudInitialScale: CGFloat = 0.5
}

// MARK: - Claude Planning Animation Constants

/// Constants for Claude Code planning animation (lightbulb sparks)
enum ClaudePlanningConstants {
    /// Spark scale factor relative to texture size
    static let sparkScaleFactor: CGFloat = 0.6

    /// Spark spawn radius range (min, max)
    static let sparkRadiusMin: CGFloat = 3
    static let sparkRadiusMax: CGFloat = 6

    /// Initial scale for spark pop-in
    static let sparkInitialScale: CGFloat = 0.3

    /// Color blend factor for glow effect
    static let glowColorBlend: CGFloat = 0.3

    /// Cloud scale factor for mini clouds
    static let cloudScaleFactor: CGFloat = 1.2
}

// MARK: - Particle Constants

/// Constants for particle effects (notes, hearts, sweat, etc.)
enum ParticleConstants {
    /// Standard particle pop-in duration
    static let popInDuration: TimeInterval = 0.1

    /// Standard particle fade-out duration
    static let fadeOutDuration: TimeInterval = 0.3

    /// Mini cloud sizes (from texture generation)
    static let miniCloud1Size = CGSize(width: 7, height: 5)
    static let miniCloud2Size = CGSize(width: 9, height: 5)
    static let miniCloud3Size = CGSize(width: 6, height: 4)

    /// Spark sizes (from texture generation)
    static let sparkSmallSize = CGSize(width: 2, height: 2)
    static let sparkMediumSize = CGSize(width: 3, height: 3)
    static let sparkLargeSize = CGSize(width: 4, height: 4)
}
