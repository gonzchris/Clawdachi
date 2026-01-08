//
//  ClawdachiSprite+Drag.swift
//  Clawdachi
//
//  Drag animations: wiggling limbs, sweat drops
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Drag Animation

    func startDragWiggle() {
        guard !isDragging else { return }
        isDragging = true

        // Check if in a Claude state - skip arm wiggle to preserve Claude animations
        let inClaudeState = isClaudeThinking || isClaudePlanning || isClaudeWaiting || isClaudeCelebrating

        // Eyes return to center during drag (only if not in Claude state)
        if !inClaudeState {
            targetEyeOffset = .zero
        }

        // Only wiggle arms if not in a Claude state
        if !inClaudeState {
            let armWiggleDuration: TimeInterval = 0.12

            let leftArmUp = SKAction.rotate(toAngle: 0.4, duration: armWiggleDuration)
            let leftArmDown = SKAction.rotate(toAngle: -0.3, duration: armWiggleDuration)
            leftArmUp.timingMode = .easeInEaseOut
            leftArmDown.timingMode = .easeInEaseOut
            let leftArmWiggle = SKAction.sequence([leftArmUp, leftArmDown])
            leftArmNode.run(SKAction.repeatForever(leftArmWiggle), withKey: AnimationKey.dragWiggle.rawValue)

            let rightArmUp = SKAction.rotate(toAngle: -0.4, duration: armWiggleDuration)
            let rightArmDown = SKAction.rotate(toAngle: 0.3, duration: armWiggleDuration)
            rightArmUp.timingMode = .easeInEaseOut
            rightArmDown.timingMode = .easeInEaseOut
            let rightArmWiggle = SKAction.sequence([rightArmDown, rightArmUp])
            rightArmNode.run(SKAction.repeatForever(rightArmWiggle), withKey: AnimationKey.dragWiggle.rawValue)
        }

        let legWiggleDuration: TimeInterval = 0.15

        // Outer legs wiggle outward
        let outerLeftOut = SKAction.rotate(toAngle: -0.3, duration: legWiggleDuration)
        let outerLeftIn = SKAction.rotate(toAngle: 0.15, duration: legWiggleDuration)
        outerLeftOut.timingMode = .easeInEaseOut
        outerLeftIn.timingMode = .easeInEaseOut
        let outerLeftWiggle = SKAction.sequence([outerLeftOut, outerLeftIn])
        outerLeftLegNode.run(SKAction.repeatForever(outerLeftWiggle), withKey: AnimationKey.dragWiggle.rawValue)

        let outerRightOut = SKAction.rotate(toAngle: 0.3, duration: legWiggleDuration)
        let outerRightIn = SKAction.rotate(toAngle: -0.15, duration: legWiggleDuration)
        outerRightOut.timingMode = .easeInEaseOut
        outerRightIn.timingMode = .easeInEaseOut
        let outerRightWiggle = SKAction.sequence([outerRightIn, outerRightOut])
        outerRightLegNode.run(SKAction.repeatForever(outerRightWiggle), withKey: AnimationKey.dragWiggle.rawValue)

        // Inner legs wiggle with offset timing
        let innerLeftOut = SKAction.rotate(toAngle: -0.2, duration: legWiggleDuration)
        let innerLeftIn = SKAction.rotate(toAngle: 0.25, duration: legWiggleDuration)
        innerLeftOut.timingMode = .easeInEaseOut
        innerLeftIn.timingMode = .easeInEaseOut
        let innerLeftWiggle = SKAction.sequence([innerLeftIn, innerLeftOut])
        innerLeftLegNode.run(SKAction.repeatForever(innerLeftWiggle), withKey: AnimationKey.dragWiggle.rawValue)

        let innerRightOut = SKAction.rotate(toAngle: 0.2, duration: legWiggleDuration)
        let innerRightIn = SKAction.rotate(toAngle: -0.25, duration: legWiggleDuration)
        innerRightOut.timingMode = .easeInEaseOut
        innerRightIn.timingMode = .easeInEaseOut
        let innerRightWiggle = SKAction.sequence([innerRightOut, innerRightIn])
        innerRightLegNode.run(SKAction.repeatForever(innerRightWiggle), withKey: AnimationKey.dragWiggle.rawValue)

        // Delay sweat drops so they only appear during prolonged drags
        let sweatDelay = TimeInterval.random(in: 1.0...2.0)
        run(SKAction.sequence([
            SKAction.wait(forDuration: sweatDelay),
            SKAction.run { [weak self] in self?.spawnSweatDrop() }
        ]), withKey: AnimationKey.sweatDropSchedule.rawValue)

        // Start surprised "O" mouth animation (skip during Claude states)
        if !inClaudeState {
            startDragMouthAnimation()
        }
    }

    private func startDragMouthAnimation() {
        // Try to acquire mouth ownership
        guard acquireMouth(for: .dragging) else { return }

        // Double-check not in Claude state
        guard !isClaudeThinking, !isClaudePlanning, !isClaudeWaiting, !isClaudeCelebrating else { return }

        mouthNode.removeAction(forKey: AnimationKey.faceBreathing.rawValue)
        mouthNode.position = SpritePositions.mouth  // Center on face
        mouthNode.texture = whistleMouthTexture
        mouthNode.setScale(0.8)
        mouthNode.alpha = 0

        // Delay before mouth appears
        let showDelay = TimeInterval.random(in: 0.4...0.7)
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        let popIn = SKAction.scale(to: 1.0, duration: 0.1)
        popIn.timingMode = .easeOut

        mouthNode.run(SKAction.sequence([
            SKAction.wait(forDuration: showDelay),
            SKAction.group([fadeIn, popIn]),
            SKAction.run { [weak self] in self?.scheduleDragMouthPop() }
        ]), withKey: AnimationKey.dragMouthPop.rawValue)
    }

    private func scheduleDragMouthPop() {
        guard isDragging else { return }

        // Randomly pick an animation variation
        let variation = Int.random(in: 0...3)
        var actions: [SKAction] = []

        let delay = TimeInterval.random(in: 0.2...0.6)
        actions.append(SKAction.wait(forDuration: delay))

        switch variation {
        case 0:
            // Quick pop
            let popOut = SKAction.scale(to: 1.3, duration: 0.06)
            let popIn = SKAction.scale(to: 1.0, duration: 0.08)
            popOut.timingMode = .easeOut
            popIn.timingMode = .easeInEaseOut
            actions.append(contentsOf: [popOut, popIn])

        case 1:
            // Bigger gasp
            let popOut = SKAction.scale(to: 1.5, duration: 0.1)
            let hold = SKAction.wait(forDuration: 0.15)
            let popIn = SKAction.scale(to: 1.0, duration: 0.12)
            popOut.timingMode = .easeOut
            popIn.timingMode = .easeInEaseOut
            actions.append(contentsOf: [popOut, hold, popIn])

        case 2:
            // Double pop
            let pop1 = SKAction.scale(to: 1.2, duration: 0.05)
            let back1 = SKAction.scale(to: 1.0, duration: 0.05)
            let pop2 = SKAction.scale(to: 1.25, duration: 0.06)
            let back2 = SKAction.scale(to: 1.0, duration: 0.06)
            actions.append(contentsOf: [pop1, back1, pop2, back2])

        default:
            // Gentle wobble
            let wobbleLeft = SKAction.moveBy(x: -0.3, y: 0, duration: 0.06)
            let wobbleRight = SKAction.moveBy(x: 0.6, y: 0, duration: 0.12)
            let wobbleBack = SKAction.moveBy(x: -0.3, y: 0, duration: 0.06)
            wobbleLeft.timingMode = .easeInEaseOut
            wobbleRight.timingMode = .easeInEaseOut
            wobbleBack.timingMode = .easeInEaseOut
            actions.append(contentsOf: [wobbleLeft, wobbleRight, wobbleBack])
        }

        actions.append(SKAction.run { [weak self] in self?.scheduleDragMouthPop() })
        mouthNode.run(SKAction.sequence(actions), withKey: AnimationKey.dragMouthPop.rawValue)
    }

    func stopDragWiggle() {
        // Always clean up, even if not currently dragging (safety)
        isDragging = false

        removeAction(forKey: AnimationKey.sweatDropSchedule.rawValue)

        // Check if in a Claude state - skip arm reset to preserve Claude animations
        let inClaudeState = isClaudeThinking || isClaudePlanning || isClaudeWaiting || isClaudeCelebrating

        // Release mouth ownership (handles cleanup) - only if not in Claude state
        if !inClaudeState {
            mouthNode.removeAction(forKey: AnimationKey.dragMouthPop.rawValue)
            releaseMouth(from: .dragging)
        }

        // Remove drag wiggle actions (safe even if not running)
        leftArmNode.removeAction(forKey: AnimationKey.dragWiggle.rawValue)
        rightArmNode.removeAction(forKey: AnimationKey.dragWiggle.rawValue)
        outerLeftLegNode.removeAction(forKey: AnimationKey.dragWiggle.rawValue)
        innerLeftLegNode.removeAction(forKey: AnimationKey.dragWiggle.rawValue)
        innerRightLegNode.removeAction(forKey: AnimationKey.dragWiggle.rawValue)
        outerRightLegNode.removeAction(forKey: AnimationKey.dragWiggle.rawValue)

        let resetDuration: TimeInterval = 0.15
        let resetRotation = SKAction.rotate(toAngle: 0, duration: resetDuration)
        resetRotation.timingMode = .easeOut

        // Only reset arms if not in a Claude state
        if !inClaudeState {
            leftArmNode.run(resetRotation)
            rightArmNode.run(resetRotation)
        }

        // Always reset legs
        outerLeftLegNode.run(resetRotation)
        innerLeftLegNode.run(resetRotation)
        innerRightLegNode.run(resetRotation)
        outerRightLegNode.run(resetRotation)
    }

    func spawnSweatDrop() {
        guard isDragging else { return }

        let isLeftSide = Bool.random()
        ParticleSpawner.spawnSweatDrop(
            texture: sweatDropTexture,
            isLeftSide: isLeftSide,
            parent: self
        )

        let nextDelay = TimeInterval.random(in: 0.5...0.9)
        run(SKAction.sequence([
            SKAction.wait(forDuration: nextDelay),
            SKAction.run { [weak self] in self?.spawnSweatDrop() }
        ]), withKey: AnimationKey.sweatDropSchedule.rawValue)
    }

    // MARK: - Sleepy Drag (disturbed while sleeping)

    func startSleepyDrag() {
        guard !isDragging else { return }
        isDragging = true

        // Animate both eyes opening upward (closed → half-open)
        let openUp = SKAction.animate(
            with: [eyeClosedTexture, blinkFrames[1]],
            timePerFrame: 0.15,
            resize: false,
            restore: false
        )
        leftEyeNode.run(openUp, withKey: AnimationKey.sleepyPeek.rawValue)
        rightEyeNode.run(openUp, withKey: AnimationKey.sleepyPeek.rawValue)

        // Schedule sleepy blinks
        scheduleSleepyBlink()
    }

    private func scheduleSleepyBlink() {
        guard isDragging else { return }

        let delay = TimeInterval.random(in: 0.8...1.5)
        run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.run { [weak self] in self?.performSleepyBlink() }
        ]), withKey: AnimationKey.sleepyBlinkSchedule.rawValue)
    }

    private func performSleepyBlink() {
        guard isDragging else { return }

        // Quick blink: half-open → closed → half-open
        let blink = SKAction.animate(
            with: [eyeClosedTexture, blinkFrames[1]],
            timePerFrame: 0.1,
            resize: false,
            restore: false
        )
        leftEyeNode.run(blink, withKey: AnimationKey.sleepyBlink.rawValue)
        rightEyeNode.run(blink, withKey: AnimationKey.sleepyBlink.rawValue)

        // Schedule next blink
        scheduleSleepyBlink()
    }

    func stopSleepyDrag() {
        isDragging = false

        // Stop blink scheduling
        removeAction(forKey: AnimationKey.sleepyBlinkSchedule.rawValue)
        leftEyeNode.removeAction(forKey: AnimationKey.sleepyPeek.rawValue)
        leftEyeNode.removeAction(forKey: AnimationKey.sleepyBlink.rawValue)
        rightEyeNode.removeAction(forKey: AnimationKey.sleepyPeek.rawValue)
        rightEyeNode.removeAction(forKey: AnimationKey.sleepyBlink.rawValue)

        // Animate both eyes closing back down
        let closeDown = SKAction.animate(
            with: [blinkFrames[1], eyeClosedTexture],
            timePerFrame: 0.12,
            resize: false,
            restore: false
        )
        leftEyeNode.run(closeDown, withKey: AnimationKey.sleepyClose.rawValue)
        rightEyeNode.run(closeDown, withKey: AnimationKey.sleepyClose.rawValue)
    }
}
