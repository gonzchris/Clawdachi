//
//  AnimationHelpers.swift
//  Clawdachi
//
//  Reusable animation action factories to reduce code duplication
//

import SpriteKit

/// Reusable animation action factories
enum AnimationHelpers {

    // MARK: - Vertical Bob/Float Animations

    /// Create a vertical bob animation (up and down)
    /// - Parameters:
    ///   - distance: Distance to move in each direction
    ///   - duration: Total duration of one up-down cycle
    ///   - easing: Whether to use easeInEaseOut timing
    /// - Returns: A forever-repeating bob action
    static func verticalBob(
        distance: CGFloat,
        duration: TimeInterval,
        easing: Bool = true
    ) -> SKAction {
        let halfDuration = duration / 2
        let bobUp = SKAction.moveBy(x: 0, y: distance, duration: halfDuration)
        let bobDown = SKAction.moveBy(x: 0, y: -distance, duration: halfDuration)
        if easing {
            bobUp.timingMode = .easeInEaseOut
            bobDown.timingMode = .easeInEaseOut
        }
        return SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))
    }

    /// Create a single up-down bob cycle (non-repeating)
    static func verticalBobOnce(
        distance: CGFloat,
        duration: TimeInterval,
        easing: Bool = true
    ) -> SKAction {
        let halfDuration = duration / 2
        let bobUp = SKAction.moveBy(x: 0, y: distance, duration: halfDuration)
        let bobDown = SKAction.moveBy(x: 0, y: -distance, duration: halfDuration)
        if easing {
            bobUp.timingMode = .easeInEaseOut
            bobDown.timingMode = .easeInEaseOut
        }
        return SKAction.sequence([bobUp, bobDown])
    }

    // MARK: - Pop-In Animations

    /// Create a pop-in animation with overshoot (fade + scale up then settle)
    /// - Parameters:
    ///   - overshoot: Scale to overshoot to (default 1.2)
    ///   - duration: Duration of pop-in phase
    ///   - settleDuration: Duration of settle back to 1.0
    /// - Returns: A pop-in animation sequence
    static func popIn(
        overshoot: CGFloat = 1.2,
        duration: TimeInterval = 0.15,
        settleDuration: TimeInterval = 0.1
    ) -> SKAction {
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: duration),
            SKAction.scale(to: overshoot, duration: duration)
        ])
        let settle = SKAction.scale(to: 1.0, duration: settleDuration)
        settle.timingMode = .easeOut
        return SKAction.sequence([popIn, settle])
    }

    /// Create a pop-in from zero scale with overshoot
    static func popInFromZero(
        overshoot: CGFloat = 1.2,
        duration: TimeInterval = 0.15,
        settleDuration: TimeInterval = 0.1
    ) -> SKAction {
        // Note: Caller should set scale to 0 before running this action
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: duration),
            SKAction.scale(to: overshoot, duration: duration)
        ])
        let settle = SKAction.scale(to: 1.0, duration: settleDuration)
        settle.timingMode = .easeOut
        return SKAction.sequence([popIn, settle])
    }

    // MARK: - Fade-Out Animations

    /// Create a standard fade-out using AnimationTimings
    static func fadeOut(duration: TimeInterval = AnimationTimings.fadeOutDuration) -> SKAction {
        SKAction.fadeOut(withDuration: duration)
    }

    /// Create a fade-out that also removes the node from parent
    static func fadeOutAndRemove(duration: TimeInterval = AnimationTimings.fadeOutDuration) -> SKAction {
        SKAction.sequence([
            SKAction.fadeOut(withDuration: duration),
            SKAction.removeFromParent()
        ])
    }

    /// Create a scale-down + fade-out combined animation
    static func shrinkAndFadeOut(
        scaleTo: CGFloat = 0.0,
        duration: TimeInterval = AnimationTimings.fadeOutDuration
    ) -> SKAction {
        SKAction.group([
            SKAction.scale(to: scaleTo, duration: duration),
            SKAction.fadeOut(withDuration: duration)
        ])
    }

    // MARK: - Particle Float Animations

    /// Create a float-up animation for particles (music notes, thinking dots, etc.)
    /// - Parameters:
    ///   - floatDistance: Vertical distance to float
    ///   - horizontalDrift: Random horizontal drift range
    ///   - duration: Total float duration
    ///   - fadeOutPortion: What portion of duration is fade-out (0.0-1.0)
    /// - Returns: A float animation that fades out and removes
    static func floatUp(
        floatDistance: CGFloat,
        horizontalDrift: CGFloat = 0,
        duration: TimeInterval,
        fadeOutPortion: CGFloat = 0.3
    ) -> SKAction {
        let drift = horizontalDrift > 0 ? CGFloat.random(in: -horizontalDrift...horizontalDrift) : 0
        let fadeStart = duration * Double(1.0 - fadeOutPortion)
        let fadeDuration = duration * Double(fadeOutPortion)

        let float = SKAction.moveBy(x: drift, y: floatDistance, duration: duration)
        float.timingMode = .easeOut

        let waitThenFade = SKAction.sequence([
            SKAction.wait(forDuration: fadeStart),
            SKAction.fadeOut(withDuration: fadeDuration)
        ])

        return SKAction.sequence([
            SKAction.group([float, waitThenFade]),
            SKAction.removeFromParent()
        ])
    }

    // MARK: - Rotation Animations

    /// Create a gentle wobble rotation (for party hats, etc.)
    static func wobble(angle: CGFloat = 0.05, duration: TimeInterval = 0.3) -> SKAction {
        let wobbleLeft = SKAction.rotate(toAngle: -angle, duration: duration / 2)
        let wobbleRight = SKAction.rotate(toAngle: angle, duration: duration / 2)
        wobbleLeft.timingMode = .easeInEaseOut
        wobbleRight.timingMode = .easeInEaseOut
        return SKAction.repeatForever(SKAction.sequence([wobbleLeft, wobbleRight]))
    }

    // MARK: - Scheduled Actions

    /// Create a scheduled action that runs at random intervals
    /// - Parameters:
    ///   - minInterval: Minimum time between runs
    ///   - maxInterval: Maximum time between runs
    ///   - action: The action to run
    /// - Returns: A forever-repeating scheduled action
    static func randomInterval(
        min minInterval: TimeInterval,
        max maxInterval: TimeInterval,
        action: @escaping () -> Void
    ) -> SKAction {
        return SKAction.repeatForever(
            SKAction.sequence([
                SKAction.wait(forDuration: TimeInterval.random(in: minInterval...maxInterval)),
                SKAction.run(action)
            ])
        )
    }
}
