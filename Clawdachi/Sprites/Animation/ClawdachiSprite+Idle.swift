//
//  ClawdachiSprite+Idle.swift
//  Clawdachi
//
//  Idle animations: breathing, blinking, whistling, looking around
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Start All Idle Animations

    func startAnimations() {
        startBreathingAnimation()
        startSwayAnimation()
        scheduleNextBlink()
        scheduleNextLookAround()
        // Start the coordinated whistle/smoke cycle (they alternate, never overlap)
        startIdleAnimationCycle()
    }

    // MARK: - Coordinated Whistle/Smoke Cycle

    /// Tracks which idle animation is next in the cycle
    private static var nextIdleAnimation: IdleAnimationType = .whistle

    private enum IdleAnimationType {
        case whistle
        case smoke
    }

    /// Start the alternating whistle/smoke cycle
    /// Pattern: 20s → whistle → 20s → smoke → 20s → whistle → ...
    func startIdleAnimationCycle() {
        // Reset to whistle first
        Self.nextIdleAnimation = .whistle
        scheduleNextIdleAnimation()
    }

    func scheduleNextIdleAnimation() {
        // Determine wait time based on which animation is next
        let waitTime: TimeInterval
        switch Self.nextIdleAnimation {
        case .whistle:
            waitTime = 20.0  // Whistle after 20s of idle
        case .smoke:
            waitTime = 20.0  // Smoke 20s after whistle completes
        }

        let wait = SKAction.wait(forDuration: waitTime)
        let perform = SKAction.run { [weak self] in
            self?.performNextIdleAnimation()
        }
        run(SKAction.sequence([wait, perform]), withKey: "idleAnimationCycle")
    }

    private func performNextIdleAnimation() {
        switch Self.nextIdleAnimation {
        case .whistle:
            // Try to perform whistle
            if canPerformWhistle() {
                Self.nextIdleAnimation = .smoke  // Next will be smoke
                performWhistleAnimation()
            } else {
                // Can't whistle right now, try again in a few seconds
                let retry = SKAction.sequence([
                    SKAction.wait(forDuration: 3.0),
                    SKAction.run { [weak self] in self?.performNextIdleAnimation() }
                ])
                run(retry, withKey: "idleAnimationCycle")
                return
            }

        case .smoke:
            // Try to perform smoke
            if canPerformSmoking() {
                Self.nextIdleAnimation = .whistle  // Next will be whistle
                performSmokingAnimation()
            } else {
                // Can't smoke right now, try again in a few seconds
                let retry = SKAction.sequence([
                    SKAction.wait(forDuration: 3.0),
                    SKAction.run { [weak self] in self?.performNextIdleAnimation() }
                ])
                run(retry, withKey: "idleAnimationCycle")
                return
            }
        }
    }

    /// Check if whistling can be performed (without triggering it)
    private func canPerformWhistle() -> Bool {
        // Must be in pure idle state (not in any idle substate or Claude state)
        return currentState == .idle && !isSpeaking
    }

    /// Check if smoking can be performed (without triggering it)
    private func canPerformSmoking() -> Bool {
        // Must be in pure idle state (not in any idle substate or Claude state)
        return currentState == .idle
    }

    /// Called when whistle animation completes - schedules next in cycle
    func onWhistleComplete() {
        scheduleNextIdleAnimation()
    }

    /// Called when smoking animation completes - schedules next in cycle
    func onSmokingComplete() {
        scheduleNextIdleAnimation()
    }

    // MARK: - Breathing

    func startBreathingAnimation() {
        let breatheAction = SKAction.animate(
            with: breathingFrames,
            timePerFrame: breathingDuration / Double(breathingFrames.count),
            resize: false,
            restore: false
        )
        bodyNode.run(SKAction.repeatForever(breatheAction), withKey: "breathing")

        let faceUp = SKAction.moveBy(x: 0, y: 0.4, duration: breathingDuration / 2)
        let faceDown = SKAction.moveBy(x: 0, y: -0.4, duration: breathingDuration / 2)
        faceUp.timingMode = .easeInEaseOut
        faceDown.timingMode = .easeInEaseOut

        let faceBreath = SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            faceUp,
            faceDown
        ])

        // Note: Eye breathing is now handled by updateEyePositions() in EyeTracking extension
        // This allows eye tracking offset + breathing bob to coexist
        mouthNode.run(SKAction.repeatForever(faceBreath), withKey: "faceBreathing")
    }

    func startSwayAnimation() {
        let pulseUp = SKAction.scaleX(to: 1.02, duration: swayDuration / 2)
        let pulseDown = SKAction.scaleX(to: 0.98, duration: swayDuration / 2)
        pulseUp.timingMode = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut

        let swayCycle = SKAction.sequence([pulseUp, pulseDown])
        run(SKAction.repeatForever(swayCycle), withKey: "sway")
    }

    // MARK: - Looking Around

    func scheduleNextLookAround() {
        let interval = TimeInterval.random(in: lookAroundMinInterval...lookAroundMaxInterval)
        let wait = SKAction.wait(forDuration: interval)
        let look = SKAction.run { [weak self] in self?.performLookAround() }
        run(SKAction.sequence([wait, look]), withKey: "lookAroundSchedule")
    }

    func performLookAround() {
        guard !isLookingAround && !isPerformingAction else {
            scheduleNextLookAround()
            return
        }
        isLookingAround = true

        // Temporarily disable mouse tracking during look-around
        isMouseTrackingEnabled = false

        let directions: [(x: CGFloat, y: CGFloat)] = [
            (1, 0), (-1, 0), (0, 0.5), (1, 0.5), (-1, 0.5)
        ]
        let dir = directions.randomElement()!

        let holdDuration = TimeInterval.random(in: 0.8...2.0)

        // Set target offset directly (eye tracking lerp will animate smoothly)
        targetEyeOffset = CGPoint(x: dir.x, y: dir.y * 0.5)

        // After hold duration, return to mouse tracking
        let totalDuration = holdDuration + 0.5
        run(SKAction.sequence([
            SKAction.wait(forDuration: totalDuration),
            SKAction.run { [weak self] in
                self?.isLookingAround = false
                self?.isMouseTrackingEnabled = true
                self?.scheduleNextLookAround()
            }
        ]))
    }

    // MARK: - Blinking

    func scheduleNextBlink() {
        let interval = TimeInterval.random(in: blinkMinInterval...blinkMaxInterval)
        let wait = SKAction.wait(forDuration: interval)
        let blink = SKAction.run { [weak self] in self?.performBlink() }
        run(SKAction.sequence([wait, blink]), withKey: "blinkSchedule")
    }

    func performBlink() {
        guard !isBlinking else { return }
        isBlinking = true

        let blinkAnimation = SKAction.animate(
            with: blinkFrames,
            timePerFrame: blinkDuration / Double(blinkFrames.count),
            resize: false,
            restore: true
        )

        let completion = SKAction.run { [weak self] in
            self?.isBlinking = false
            self?.scheduleNextBlink()
        }

        leftEyeNode.run(SKAction.sequence([blinkAnimation, completion]), withKey: "blink")
        rightEyeNode.run(blinkAnimation, withKey: "blink")
    }

    // MARK: - Whistling

    /// Perform the whistle animation (called by the coordinated idle cycle)
    func performWhistleAnimation() {
        isWhistling = true

        // Move mouth to side position for whistle
        mouthNode.position = CGPoint(x: 5, y: -5)
        mouthNode.setScale(0.8)
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: 1.1, duration: 0.1)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.08)
        let hold = SKAction.wait(forDuration: whistleDuration - 0.3)
        let popOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.scale(to: 0.8, duration: 0.15)
        ])
        let resetPosition = SKAction.run { [weak self] in
            self?.mouthNode.position = SpritePositions.mouth
        }
        mouthNode.run(SKAction.sequence([popIn, settle, hold, popOut, resetPosition]))

        spawnMusicNote(delay: 0.2, variation: 0)
        spawnMusicNote(delay: 0.7, variation: 1)
        spawnMusicNote(delay: 1.2, variation: 2)

        let liftUp = SKAction.scaleY(to: 1.03, duration: 0.3)
        liftUp.timingMode = .easeOut
        let holdLift = SKAction.wait(forDuration: whistleDuration - 0.5)
        let liftBack = SKAction.scaleY(to: 1.0, duration: 0.2)
        liftBack.timingMode = .easeInEaseOut
        run(SKAction.sequence([liftUp, holdLift, liftBack]), withKey: "whistleLift")

        let completion = SKAction.sequence([
            SKAction.wait(forDuration: whistleDuration + 0.2),
            SKAction.run { [weak self] in
                self?.mouthNode.texture = self?.whistleMouthTexture  // Reset texture
                self?.isWhistling = false
                self?.onWhistleComplete()  // Schedule next in coordinated cycle
            }
        ])
        run(completion, withKey: "whistleCompletion")
    }

    func spawnMusicNote(delay: TimeInterval, variation: Int) {
        ParticleSpawner.spawnMusicNote(
            texture: musicNoteTexture,
            variation: variation,
            delay: delay,
            parent: self
        )
    }

    // MARK: - Idle Animation Control

    func pauseIdleAnimations() {
        removeAction(forKey: "sway")
        removeAction(forKey: "idleAnimationCycle")  // Stop coordinated whistle/smoke cycle
        removeAction(forKey: "blinkSchedule")
        removeAction(forKey: "lookAroundSchedule")
        // Stop any currently running blink animation on eye nodes
        // (prevents restore: true from overwriting thinking eye textures)
        leftEyeNode.removeAction(forKey: "blink")
        rightEyeNode.removeAction(forKey: "blink")

        // Stop whistling visuals if active
        removeAction(forKey: "whistleLift")
        removeAction(forKey: "whistleCompletion")
        mouthNode.alpha = 0

        // Always try to stop smoking (stopSmoking checks for cigarette node)
        stopSmoking()
    }

    func resumeIdleAnimations() {
        isPerformingAction = false
        setScale(1.0)
        startSwayAnimation()
        scheduleNextBlink()
        scheduleNextLookAround()
        // Resume the coordinated whistle/smoke cycle
        scheduleNextIdleAnimation()
    }
}
