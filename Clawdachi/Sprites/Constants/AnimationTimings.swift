//
//  AnimationTimings.swift
//  Clawdachi
//
//  Centralized animation timing constants for easy tuning
//

import Foundation

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
    static let whistleMinInterval: TimeInterval = 12.0

    /// Maximum interval between whistles
    static let whistleMaxInterval: TimeInterval = 25.0

    /// Duration of the whistle animation
    static let whistleDuration: TimeInterval = 2.0

    // MARK: - Looking Around

    /// Minimum interval between look-around animations
    static let lookAroundMinInterval: TimeInterval = 5.0

    /// Maximum interval between look-around animations
    static let lookAroundMaxInterval: TimeInterval = 12.0

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
}
