//
//  ClaudachiSprite+Interaction.swift
//  Claudachi
//
//  Interaction animations: click reactions, wave, bounce, heart
//

import SpriteKit

extension ClaudachiSprite {

    // MARK: - Public Methods

    func triggerBlink() {
        removeAction(forKey: "blinkSchedule")
        performBlink()
    }

    func triggerClickReaction() {
        guard !isPerformingAction else { return }

        let reactions: [() -> Void] = [
            { self.triggerBlink() },
            { self.performWave() },
            { self.performBounce() },
            { self.performHeartReaction() }
        ]

        let weights = [3, 2, 2, 1]
        let totalWeight = weights.reduce(0, +)
        let random = Int.random(in: 0..<totalWeight)

        var cumulative = 0
        for (index, weight) in weights.enumerated() {
            cumulative += weight
            if random < cumulative {
                reactions[index]()
                return
            }
        }
    }

    // MARK: - Wave Animation

    func performWave() {
        guard !isPerformingAction else { return }
        isPerformingAction = true

        let anticipate = SKAction.scaleY(to: 0.95, duration: 0.08)
        anticipate.timingMode = .easeIn

        let wave1L = SKAction.rotate(byAngle: 0.18, duration: 0.08)
        let wave1R = SKAction.rotate(byAngle: -0.36, duration: 0.12)
        let wave2L = SKAction.rotate(byAngle: 0.30, duration: 0.10)
        let wave2R = SKAction.rotate(byAngle: -0.24, duration: 0.10)
        let wave3L = SKAction.rotate(byAngle: 0.18, duration: 0.08)
        let wave3R = SKAction.rotate(byAngle: -0.12, duration: 0.08)
        let settle = SKAction.rotate(byAngle: 0.06, duration: 0.06)

        let normalize = SKAction.scaleY(to: 1.0, duration: 0.1)
        normalize.timingMode = .easeOut

        let waveSequence = SKAction.sequence([
            anticipate,
            SKAction.group([
                SKAction.sequence([wave1L, wave1R, wave2L, wave2R, wave3L, wave3R, settle]),
                normalize
            ])
        ])

        let completion = SKAction.run { [weak self] in
            self?.isPerformingAction = false
        }

        run(SKAction.sequence([waveSequence, completion]), withKey: "wave")
    }

    // MARK: - Bounce Animation

    func performBounce() {
        guard !isPerformingAction else { return }
        isPerformingAction = true

        let crouch = SKAction.scaleY(to: 0.8, duration: 0.1)
        crouch.timingMode = .easeIn
        let crouchX = SKAction.scaleX(to: 1.15, duration: 0.1)
        crouchX.timingMode = .easeIn
        let anticipation = SKAction.group([crouch, crouchX])

        let stretchUp = SKAction.scaleY(to: 1.25, duration: 0.12)
        stretchUp.timingMode = .easeOut
        let squeezeX = SKAction.scaleX(to: 0.85, duration: 0.12)
        squeezeX.timingMode = .easeOut
        let jumpPhase = SKAction.group([stretchUp, squeezeX])

        let landSquash = SKAction.scaleY(to: 0.8, duration: 0.08)
        landSquash.timingMode = .easeIn
        let landSquashX = SKAction.scaleX(to: 1.2, duration: 0.08)
        landSquashX.timingMode = .easeIn
        let landPhase = SKAction.group([landSquash, landSquashX])

        let overshoot = SKAction.group([
            SKAction.scaleY(to: 1.08, duration: 0.08),
            SKAction.scaleX(to: 0.95, duration: 0.08)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        settle.timingMode = .easeOut

        let singleBounce = SKAction.sequence([anticipation, jumpPhase, landPhase, overshoot, settle])

        let smallCrouch = SKAction.group([
            SKAction.scaleY(to: 0.9, duration: 0.06),
            SKAction.scaleX(to: 1.08, duration: 0.06)
        ])
        let smallStretch = SKAction.group([
            SKAction.scaleY(to: 1.12, duration: 0.08),
            SKAction.scaleX(to: 0.92, duration: 0.08)
        ])
        let smallLand = SKAction.group([
            SKAction.scaleY(to: 0.92, duration: 0.05),
            SKAction.scaleX(to: 1.06, duration: 0.05)
        ])
        let finalSettle = SKAction.scale(to: 1.0, duration: 0.12)
        finalSettle.timingMode = .easeOut

        let smallBounce = SKAction.sequence([smallCrouch, smallStretch, smallLand, finalSettle])
        let doubleBounce = SKAction.sequence([singleBounce, smallBounce])

        let completion = SKAction.run { [weak self] in
            self?.isPerformingAction = false
        }

        run(SKAction.sequence([doubleBounce, completion]), withKey: "bounce")
    }

    // MARK: - Heart Reaction

    func performHeartReaction() {
        guard !isPerformingAction else { return }
        isPerformingAction = true

        let squish = SKAction.group([
            SKAction.scaleY(to: 0.9, duration: 0.08),
            SKAction.scaleX(to: 1.1, duration: 0.08)
        ])
        let unsquish = SKAction.scale(to: 1.0, duration: 0.1)
        unsquish.timingMode = .easeOut

        run(SKAction.sequence([squish, unsquish]))

        spawnHeart(delay: 0, offsetX: 0, offsetY: 10, size: 1.0)
        spawnHeart(delay: 0.15, offsetX: -5, offsetY: 8, size: 0.7)
        spawnHeart(delay: 0.25, offsetX: 5, offsetY: 9, size: 0.8)

        let completion = SKAction.run { [weak self] in
            self?.isPerformingAction = false
        }
        run(SKAction.sequence([SKAction.wait(forDuration: 1.0), completion]))
    }

    func spawnHeart(delay: TimeInterval, offsetX: CGFloat, offsetY: CGFloat, size: CGFloat) {
        ParticleSpawner.spawnHeart(
            texture: heartTexture,
            offsetX: offsetX,
            offsetY: offsetY,
            size: size,
            delay: delay,
            parent: self
        )
    }
}
