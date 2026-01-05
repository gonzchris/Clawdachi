//
//  ClawdachiSprite+Claude.swift
//  Clawdachi
//
//  Claude Code integration animations: thinking pose when Claude is working
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Palette Colors (as NSColor for SKShapeNode)

    private var thinkingDotFillColor: NSColor {
        // Matches ClawdachiPalette.primaryOrange (#FF9933)
        NSColor(red: 255/255, green: 153/255, blue: 51/255, alpha: 1.0)
    }

    private var thinkingDotStrokeColor: NSColor {
        // Matches ClawdachiPalette.eyePupil (#222222)
        NSColor(red: 34/255, green: 34/255, blue: 34/255, alpha: 1.0)
    }

    // MARK: - Thinking Animation

    /// Start the thinking pose animation (when Claude is processing)
    func startClaudeThinking() {
        guard !isClaudeThinking, !isDragging else { return }
        isClaudeThinking = true

        // Pause competing animations
        pauseIdleAnimations()
        stopDancing()

        // Eyes look up-left (contemplative thinking pose)
        isMouseTrackingEnabled = false
        targetEyeOffset = CGPoint(x: -0.7, y: 0.6)

        // Subtle body tilt forward (concentrating)
        let tiltForward = SKAction.scaleY(to: 0.97, duration: 0.3)
        tiltForward.timingMode = .easeInEaseOut
        run(tiltForward, withKey: "thinkingTilt")

        // Gentle head bob loop (thinking rhythm)
        let bobHalfDuration = AnimationTimings.thinkingBobDuration / 2
        let bobUp = SKAction.moveBy(x: 0, y: 0.5, duration: bobHalfDuration)
        let bobDown = SKAction.moveBy(x: 0, y: -0.5, duration: bobHalfDuration)
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        let bobCycle = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))
        run(bobCycle, withKey: "thinkingBob")

        // Start spawning thinking particles
        startThinkingParticles()
    }

    /// Stop the thinking animation and return to normal
    func stopClaudeThinking() {
        guard isClaudeThinking else { return }
        isClaudeThinking = false

        // Stop thinking animations
        removeAction(forKey: "thinkingTilt")
        removeAction(forKey: "thinkingBob")
        removeAction(forKey: "thinkingParticles")

        // Reset body scale
        let resetScale = SKAction.scaleY(to: 1.0, duration: 0.2)
        resetScale.timingMode = .easeOut
        run(resetScale)

        // Re-enable mouse tracking
        isMouseTrackingEnabled = true

        // Resume idle animations
        resumeIdleAnimations()
    }

    // MARK: - Thinking Particles

    private func startThinkingParticles() {
        let spawnAction = SKAction.run { [weak self] in
            guard let self = self, self.isClaudeThinking else { return }
            self.spawnThinkingDot()
        }
        let wait = SKAction.wait(forDuration: AnimationTimings.thinkingParticleInterval)
        let loop = SKAction.repeatForever(SKAction.sequence([spawnAction, wait]))
        run(loop, withKey: "thinkingParticles")
    }

    private func spawnThinkingDot() {
        // Create a small dot that floats up (like thought bubble dots)
        let dot = SKShapeNode(circleOfRadius: 1.2)
        dot.fillColor = thinkingDotFillColor
        dot.strokeColor = thinkingDotStrokeColor
        dot.lineWidth = 0.4
        dot.position = CGPoint(x: CGFloat.random(in: -4...4), y: 10)
        dot.alpha = 0
        dot.zPosition = SpriteZPositions.effects
        addChild(dot)

        // Animation: fade in, float up, fade out
        let floatDuration = AnimationTimings.thinkingParticleFloatDuration
        let fadeIn = SKAction.fadeIn(withDuration: AnimationTimings.popInDuration)
        let floatUp = SKAction.moveBy(x: CGFloat.random(in: -2...2), y: 10, duration: floatDuration)
        floatUp.timingMode = .easeOut

        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: floatDuration * 0.6),
            SKAction.fadeOut(withDuration: floatDuration * 0.4)
        ])

        let sequence = SKAction.sequence([
            fadeIn,
            SKAction.group([floatUp, fadeOut]),
            SKAction.removeFromParent()
        ])
        dot.run(sequence)
    }
}
