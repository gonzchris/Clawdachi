//
//  ClawdachiSprite+Listening.swift
//  Clawdachi
//
//  Voice input listening animation: attentive pose with sound wave indicators
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Textures

    /// Cached texture for sound wave arcs above head
    private static var soundWaveTextures: [SKTexture] = {
        [
            ClawdachiFaceSprites.generateSoundWaveTexture(intensity: 0),
            ClawdachiFaceSprites.generateSoundWaveTexture(intensity: 1),
            ClawdachiFaceSprites.generateSoundWaveTexture(intensity: 2)
        ]
    }()

    /// Name for the sound wave node
    private static let soundWavesName = "listeningSoundWaves"

    // MARK: - Listening Animation

    /// Start the listening animation (voice input recording)
    func startListening() {
        guard currentState != .listening else { return }

        // Transition to listening state
        stateManager.transitionTo(.listening)

        // Pause competing animations
        pauseIdleAnimations()
        stopDancing()

        // Stop any Claude animations if active
        if currentState.isClaudeState {
            stopClaudeThinking()
            stopClaudePlanning()
            dismissQuestionMark()
            dismissPartyCelebration()
        }

        // Attentive expression: eyes wide open
        isMouseTrackingEnabled = false
        leftEyeNode.texture = eyeOpenTexture
        rightEyeNode.texture = eyeOpenTexture

        // Reset eye position to center
        leftEyeNode.position = leftEyeBasePos
        rightEyeNode.position = rightEyeBasePos

        // Faster breathing pulse (attentive/excited)
        let pulseUp = SKAction.scaleY(to: 1.03, duration: 0.25)
        let pulseDown = SKAction.scaleY(to: 0.97, duration: 0.25)
        pulseUp.timingMode = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut
        let pulseCycle = SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown]))
        run(pulseCycle, withKey: AnimationKey.listeningPulse.rawValue)

        // Show sound wave indicators above head
        showListeningSoundWaves()

        // Start spawning sound wave particles
        startListeningParticles()
    }

    /// Stop the listening animation and return to normal
    func stopListening() {
        guard currentState == .listening else { return }

        // Remove listening animations
        removeAction(forKey: AnimationKey.listeningPulse.rawValue)
        removeAction(forKey: AnimationKey.listeningSoundWaves.rawValue)
        removeAction(forKey: AnimationKey.listeningParticleSpawner.rawValue)

        // Remove sound wave node
        if let waves = childNode(withName: Self.soundWavesName) {
            let fadeOut = SKAction.fadeOut(withDuration: 0.15)
            waves.run(SKAction.sequence([fadeOut, SKAction.removeFromParent()]))
        }

        // Reset body scale
        let resetScale = SKAction.scaleY(to: 1.0, duration: 0.2)
        resetScale.timingMode = .easeOut
        run(resetScale)

        // Re-enable mouse tracking
        isMouseTrackingEnabled = true

        // Transition back to idle
        stateManager.transitionTo(.idle)

        // Resume idle animations
        resumeIdleAnimations()
    }

    // MARK: - Sound Waves Visual

    private func showListeningSoundWaves() {
        // Remove any existing
        childNode(withName: Self.soundWavesName)?.removeFromParent()

        // Create container for sound wave arcs
        let waves = SKNode()
        waves.name = Self.soundWavesName
        waves.position = CGPoint(x: 0, y: 14)
        waves.zPosition = SpriteZPositions.effects + 1
        addChild(waves)

        // Create animated arc sprite
        let arcSprite = SKSpriteNode(texture: Self.soundWaveTextures[0])
        arcSprite.size = CGSize(width: 12, height: 6)
        arcSprite.position = .zero
        arcSprite.alpha = 0
        waves.addChild(arcSprite)

        // Pop in
        let fadeIn = SKAction.fadeIn(withDuration: 0.15)
        arcSprite.run(fadeIn)

        // Animate through intensity frames
        let animate = SKAction.animate(
            with: Self.soundWaveTextures,
            timePerFrame: 0.2
        )
        arcSprite.run(SKAction.repeatForever(animate), withKey: AnimationKey.listeningSoundWaves.rawValue)
    }

    // MARK: - Sound Wave Particles

    private func startListeningParticles() {
        let spawn = SKAction.run { [weak self] in
            guard let self = self, self.currentState == .listening else { return }
            self.spawnSoundWaveParticle()
        }
        let wait = SKAction.wait(forDuration: 0.4)
        let loop = SKAction.repeatForever(SKAction.sequence([spawn, wait]))
        run(loop, withKey: AnimationKey.listeningParticleSpawner.rawValue)
    }

    private func spawnSoundWaveParticle() {
        // Small arc that expands outward and fades
        let arc = SKSpriteNode(texture: Self.soundWaveTextures[1])
        arc.size = CGSize(width: 4, height: 2)
        arc.alpha = 0

        // Spawn from either side of head
        let side = Bool.random() ? 1.0 : -1.0
        arc.position = CGPoint(x: 8 * side, y: 10)
        arc.zPosition = SpriteZPositions.effects
        addChild(arc)

        // Expand outward animation
        let fadeIn = SKAction.fadeAlpha(to: 0.7, duration: 0.1)
        let expand = SKAction.group([
            SKAction.moveBy(x: 4 * side, y: 2, duration: 0.4),
            SKAction.scale(to: 1.5, duration: 0.4)
        ])
        expand.timingMode = .easeOut

        let fadeOut = SKAction.fadeOut(withDuration: 0.2)

        let sequence = SKAction.sequence([
            fadeIn,
            expand,
            fadeOut,
            SKAction.removeFromParent()
        ])
        arc.run(sequence)
    }
}
