//
//  ClawdachiSprite+Claude.swift
//  Clawdachi
//
//  Claude Code integration animations: thinking pose when Claude is working
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Textures

    /// Cached textures for thinking dots (small, medium, large orange dots)
    private static var thinkingDotTextures: [(texture: SKTexture, size: CGSize)] = {
        [
            (ClawdachiFaceSprites.generateThinkingDotSmall(), CGSize(width: 2, height: 2)),
            (ClawdachiFaceSprites.generateThinkingDotMedium(), CGSize(width: 3, height: 3)),
            (ClawdachiFaceSprites.generateThinkingDotLarge(), CGSize(width: 4, height: 4))
        ]
    }()

    /// Focused eye textures for thinking: > <
    private static var focusedLeftEyeTexture: SKTexture = {
        ClawdachiFaceSprites.generateEyeTexture(state: .squint)  // >
    }()

    private static var focusedRightEyeTexture: SKTexture = {
        ClawdachiFaceSprites.generateEyeTexture(state: .squintLeft)  // <
    }()

    /// Cached texture for completion lightbulb
    private static var lightbulbTexture: SKTexture = {
        ClawdachiFaceSprites.generateLightbulbTexture()
    }()

    /// Name for the lightbulb node
    private static let lightbulbName = "completionLightbulb"

    // MARK: - Thinking Animation

    /// Start the thinking pose animation (when Claude is processing)
    func startClaudeThinking() {
        guard !isClaudeThinking, !isDragging else { return }
        isClaudeThinking = true

        // Pause competing animations
        pauseIdleAnimations()
        stopDancing()

        // Focused eyes: > <
        isMouseTrackingEnabled = false
        leftEyeNode.texture = Self.focusedLeftEyeTexture
        rightEyeNode.texture = Self.focusedRightEyeTexture

        // Reset eye position to center
        leftEyeNode.position = leftEyeBasePos
        rightEyeNode.position = rightEyeBasePos

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

        // Start occasional blinks
        startThinkingBlinks()
    }

    /// Stop the thinking animation and return to normal
    func stopClaudeThinking() {
        guard isClaudeThinking else { return }
        isClaudeThinking = false

        // Stop thinking animations
        removeAction(forKey: "thinkingTilt")
        removeAction(forKey: "thinkingBob")
        removeAction(forKey: "thinkingParticleSpawner")
        removeAction(forKey: "thinkingBlink")

        // Reset body scale
        let resetScale = SKAction.scaleY(to: 1.0, duration: 0.2)
        resetScale.timingMode = .easeOut
        run(resetScale)

        // Reset eyes to open
        leftEyeNode.texture = eyeOpenTexture
        rightEyeNode.texture = eyeOpenTexture

        // Re-enable mouse tracking
        isMouseTrackingEnabled = true

        // Resume idle animations
        resumeIdleAnimations()
    }

    // MARK: - Thinking Dots

    private func startThinkingParticles() {
        let spawnAction = SKAction.run { [weak self] in
            guard let self = self, self.isClaudeThinking else { return }
            self.spawnThinkingDot()
        }
        // Spawn dots at a steady pace
        let wait = SKAction.wait(forDuration: TimeInterval.random(in: 0.6...1.0))
        let loop = SKAction.repeatForever(SKAction.sequence([spawnAction, wait]))
        run(loop, withKey: "thinkingParticleSpawner")
    }

    private func spawnThinkingDot() {
        // Pick a random dot size
        let dotData = Self.thinkingDotTextures.randomElement()!

        let dot = SKSpriteNode(texture: dotData.texture)
        dot.size = dotData.size
        dot.position = CGPoint(x: CGFloat.random(in: -3...3), y: 10)
        dot.alpha = 0
        dot.zPosition = SpriteZPositions.effects
        dot.setScale(0.5)
        addChild(dot)

        // Float up duration
        let floatDuration: TimeInterval = TimeInterval.random(in: 1.0...1.4)

        // Quick fade in
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)

        // Float up with slight drift (keep within sprite bounds)
        let floatUp = SKAction.moveBy(x: CGFloat.random(in: -2...2), y: CGFloat.random(in: 6...9), duration: floatDuration)
        floatUp.timingMode = .easeOut

        // Gentle grow as it rises
        let grow = SKAction.scale(to: 0.8, duration: floatDuration * 0.7)
        grow.timingMode = .easeOut

        // Pop/burst at the top - quick clean pop then fade
        let popScale = SKAction.scale(to: 1.6, duration: 0.08)
        popScale.timingMode = .easeOut
        let popFade = SKAction.fadeOut(withDuration: 0.1)
        let pop = SKAction.group([popScale, popFade])

        let sequence = SKAction.sequence([
            fadeIn,
            SKAction.group([floatUp, grow]),
            pop,
            SKAction.removeFromParent()
        ])
        dot.run(sequence)
    }

    // MARK: - Thinking Blinks

    private func startThinkingBlinks() {
        let blinkAction = SKAction.run { [weak self] in
            guard let self = self, self.isClaudeThinking else { return }
            self.performThinkingBlink()
        }
        // Blink occasionally (every 4-7 seconds)
        let wait = SKAction.wait(forDuration: TimeInterval.random(in: 4.0...7.0))
        let loop = SKAction.repeatForever(SKAction.sequence([wait, blinkAction]))
        run(loop, withKey: "thinkingBlink")
    }

    private func performThinkingBlink() {
        // Quick blink: > < → closed → > <
        let close = SKAction.run { [weak self] in
            self?.leftEyeNode.texture = self?.eyeClosedTexture
            self?.rightEyeNode.texture = self?.eyeClosedTexture
        }
        let open = SKAction.run { [weak self] in
            guard let self = self, self.isClaudeThinking else { return }
            self.leftEyeNode.texture = Self.focusedLeftEyeTexture
            self.rightEyeNode.texture = Self.focusedRightEyeTexture
        }
        let blinkSequence = SKAction.sequence([
            close,
            SKAction.wait(forDuration: 0.1),
            open
        ])
        run(blinkSequence)
    }

    // MARK: - Completion Lightbulb

    /// Show the "eureka" lightbulb above the sprite's head
    func showCompletionLightbulb() {
        // Remove any existing lightbulb
        childNode(withName: Self.lightbulbName)?.removeFromParent()

        let bulb = SKSpriteNode(texture: Self.lightbulbTexture)
        bulb.name = Self.lightbulbName
        bulb.size = CGSize(width: 8.5, height: 12)
        bulb.position = CGPoint(x: 0, y: 15)
        bulb.alpha = 0
        bulb.zPosition = SpriteZPositions.effects + 1
        bulb.setScale(0.3)
        addChild(bulb)

        // Pop in animation
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.scale(to: 1.2, duration: 0.15)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        settle.timingMode = .easeOut

        // Gentle floating bob while visible
        let bobUp = SKAction.moveBy(x: 0, y: 1.0, duration: 0.6)
        let bobDown = SKAction.moveBy(x: 0, y: -1.0, duration: 0.6)
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        let floatLoop = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))

        bulb.run(SKAction.sequence([popIn, settle, floatLoop]))
    }

    /// Dismiss the lightbulb with a fade out
    func dismissLightbulb() {
        guard let bulb = childNode(withName: Self.lightbulbName) else { return }

        bulb.removeAllActions()
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        bulb.run(SKAction.sequence([fadeOut, remove]))
    }

    /// Check if lightbulb is currently visible
    var isLightbulbVisible: Bool {
        childNode(withName: Self.lightbulbName) != nil
    }
}
