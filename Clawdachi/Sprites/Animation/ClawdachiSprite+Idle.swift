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

    // Note: IdleAnimationType enum and nextIdleAnimation property are defined in ClawdachiSprite.swift

    /// Start the alternating whistle/smoke cycle
    /// Pattern: 20s → whistle → 20s → smoke → 20s → whistle → ...
    func startIdleAnimationCycle() {
        // Reset to whistle first
        nextIdleAnimation = .whistle
        scheduleNextIdleAnimation()
    }

    func scheduleNextIdleAnimation() {
        // Determine wait time based on which animation is next
        let waitTime: TimeInterval
        switch nextIdleAnimation {
        case .whistle:
            waitTime = 20.0  // Whistle after 20s of idle
        case .smoke:
            waitTime = 20.0  // Smoke 20s after whistle completes
        }

        let wait = SKAction.wait(forDuration: waitTime)
        let perform = SKAction.run { [weak self] in
            self?.performNextIdleAnimation()
        }
        run(SKAction.sequence([wait, perform]), withKey: AnimationKey.idleAnimationCycle.rawValue)
    }

    private func performNextIdleAnimation() {
        switch nextIdleAnimation {
        case .whistle:
            // Try to perform whistle
            if canPerformWhistle() {
                nextIdleAnimation = .smoke  // Next will be smoke
                performWhistleAnimation()
            } else {
                // Can't whistle right now, try again in a few seconds
                let retry = SKAction.sequence([
                    SKAction.wait(forDuration: 3.0),
                    SKAction.run { [weak self] in self?.performNextIdleAnimation() }
                ])
                run(retry, withKey: AnimationKey.idleAnimationCycle.rawValue)
                return
            }

        case .smoke:
            // Try to perform smoke
            if canPerformSmoking() {
                nextIdleAnimation = .whistle  // Next will be whistle
                performSmokingAnimation()
            } else {
                // Can't smoke right now, try again in a few seconds
                let retry = SKAction.sequence([
                    SKAction.wait(forDuration: 3.0),
                    SKAction.run { [weak self] in self?.performNextIdleAnimation() }
                ])
                run(retry, withKey: AnimationKey.idleAnimationCycle.rawValue)
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
        // Show brief satisfied squint expression for personality
        showPostWhistleExpression()
    }

    /// Show a brief satisfied squint after whistling for organic feel
    private func showPostWhistleExpression() {
        // Squint eyes briefly (satisfied expression)
        let squint = SKAction.run { [weak self] in
            self?.leftEyeNode.texture = self?.eyeSquintTexture
            self?.rightEyeNode.texture = self?.eyeSquintTexture
        }

        let hold = SKAction.wait(forDuration: 0.35)

        let reset = SKAction.run { [weak self] in
            guard let self = self else { return }
            // Only reset if still in idle/whistling state
            if self.currentState == .idle || self.currentState == .whistling {
                self.leftEyeNode.texture = self.eyeOpenTexture
                self.rightEyeNode.texture = self.eyeOpenTexture
            }
            // Schedule next idle animation regardless
            self.scheduleNextIdleAnimation()
        }

        run(SKAction.sequence([squint, hold, reset]))
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
        bodyNode.run(SKAction.repeatForever(breatheAction), withKey: AnimationKey.breathing.rawValue)

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
        mouthNode.run(SKAction.repeatForever(faceBreath), withKey: AnimationKey.faceBreathing.rawValue)
    }

    func startSwayAnimation() {
        let pulseUp = SKAction.scaleX(to: 1.02, duration: swayDuration / 2)
        let pulseDown = SKAction.scaleX(to: 0.98, duration: swayDuration / 2)
        pulseUp.timingMode = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut

        let swayCycle = SKAction.sequence([pulseUp, pulseDown])
        run(SKAction.repeatForever(swayCycle), withKey: AnimationKey.sway.rawValue)
    }

    // MARK: - Looking Around

    func scheduleNextLookAround() {
        // Use organic timing with occasional longer pauses for natural feel
        let interval = AnimationTimings.lookAroundTiming.nextInterval()
        let wait = SKAction.wait(forDuration: interval)
        let look = SKAction.run { [weak self] in self?.performLookAround() }
        run(SKAction.sequence([wait, look]), withKey: AnimationKey.lookAroundSchedule.rawValue)
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
        // Use organic timing with occasional longer pauses for natural feel
        let interval = AnimationTimings.blinkTiming.nextInterval()
        let wait = SKAction.wait(forDuration: interval)
        let blink = SKAction.run { [weak self] in self?.performBlink() }
        run(SKAction.sequence([wait, blink]), withKey: AnimationKey.blinkSchedule.rawValue)
    }

    func performBlink() {
        guard !isBlinking else { return }
        // Don't blink if in Claude state (prevents texture conflicts)
        guard !currentState.isClaudeState else {
            scheduleNextBlink()
            return
        }
        isBlinking = true

        // Use manual texture management instead of restore:true to prevent
        // race conditions when state changes mid-blink
        let blinkAnimation = SKAction.animate(
            with: blinkFrames,
            timePerFrame: blinkDuration / Double(blinkFrames.count),
            resize: false,
            restore: false
        )

        let completion = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isBlinking = false
            // Only restore to open eyes if still in idle state
            // (prevents overwriting focused eyes if state changed mid-blink)
            if !self.currentState.isClaudeState && self.currentState != .sleeping {
                self.leftEyeNode.texture = self.eyeOpenTexture
                self.rightEyeNode.texture = self.eyeOpenTexture
            }
            // Only schedule next blink if still in an idle-compatible state
            // (prevents scheduling blinks during Claude states)
            if self.currentState == .idle || self.currentState == .dancing {
                self.scheduleNextBlink()
            }
        }

        leftEyeNode.run(SKAction.sequence([blinkAnimation, completion]), withKey: AnimationKey.blink.rawValue)
        rightEyeNode.run(blinkAnimation, withKey: AnimationKey.blink.rawValue)
    }

    // MARK: - Whistling

    /// Perform the whistle animation (called by the coordinated idle cycle)
    func performWhistleAnimation() {
        // Acquire mouth ownership
        guard acquireMouth(for: .whistling) else {
            // Can't get mouth, reschedule
            scheduleNextIdleAnimation()
            return
        }
        isWhistling = true

        // Move mouth to side position for whistle (matches smoking position)
        mouthNode.position = CGPoint(x: 2, y: -4)
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
        run(SKAction.sequence([liftUp, holdLift, liftBack]), withKey: AnimationKey.whistleLift.rawValue)

        let completion = SKAction.sequence([
            SKAction.wait(forDuration: whistleDuration + 0.2),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.isWhistling = false
                self.releaseMouth(from: .whistling)
                self.onWhistleComplete()  // Schedule next in coordinated cycle
            }
        ])
        run(completion, withKey: AnimationKey.whistleCompletion.rawValue)
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
        removeAction(forKey: AnimationKey.sway.rawValue)
        removeAction(forKey: AnimationKey.idleAnimationCycle.rawValue)  // Stop coordinated whistle/smoke cycle
        removeAction(forKey: AnimationKey.blinkSchedule.rawValue)
        removeAction(forKey: AnimationKey.lookAroundSchedule.rawValue)
        // Stop any currently running blink animation on eye nodes
        // (prevents restore: true from overwriting thinking eye textures)
        leftEyeNode.removeAction(forKey: AnimationKey.blink.rawValue)
        rightEyeNode.removeAction(forKey: AnimationKey.blink.rawValue)

        // Stop whistling visuals if active
        removeAction(forKey: AnimationKey.whistleLift.rawValue)
        removeAction(forKey: AnimationKey.whistleCompletion.rawValue)
        if currentMouthOwner == .whistling {
            releaseMouth(from: .whistling)
        }
        isWhistling = false

        // Always try to stop smoking (stopSmoking checks for cigarette node)
        stopSmoking()
    }

    func resumeIdleAnimations() {
        isPerformingAction = false
        setScale(1.0)

        // Reset eye textures to open state (prevents stuck focused eyes)
        leftEyeNode.texture = eyeOpenTexture
        rightEyeNode.texture = eyeOpenTexture

        // Reset eye positions to base (in case they were modified)
        leftEyeNode.position = leftEyeBasePos
        rightEyeNode.position = rightEyeBasePos

        // Re-enable mouse tracking
        isMouseTrackingEnabled = true

        startSwayAnimation()
        scheduleNextBlink()
        scheduleNextLookAround()
        // Resume the coordinated whistle/smoke cycle
        scheduleNextIdleAnimation()
    }
}
