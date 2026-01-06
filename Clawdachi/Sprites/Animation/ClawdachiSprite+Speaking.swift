//
//  ClawdachiSprite+Speaking.swift
//  Clawdachi
//
//  Speaking animation - mouth opens and closes when chat bubble is shown
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Speaking Animation

    /// Start the speaking animation with variety
    func startSpeaking(duration: TimeInterval = 2.0) {
        guard !isSpeaking && !isWhistling else { return }
        isSpeaking = true

        // Show the mouth node with speaking texture, centered on face
        mouthNode.position = SpritePositions.mouth
        mouthNode.texture = speakingClosedMouthTexture
        mouthNode.size = CGSize(width: 3, height: 1)
        mouthNode.alpha = 1.0

        // Create mouth actions
        let openMouth = SKAction.run { [weak self] in
            self?.mouthNode.texture = self?.speakingOpenMouthTexture
            self?.mouthNode.size = CGSize(width: 3, height: 3)
        }
        let closedMouth = SKAction.run { [weak self] in
            self?.mouthNode.texture = self?.speakingClosedMouthTexture
            self?.mouthNode.size = CGSize(width: 3, height: 1)
        }

        // Pick a random speaking pattern for variety
        let patterns: [[SKAction]] = [
            // Pattern 1: -O-O (classic)
            [closedMouth, SKAction.wait(forDuration: 0.12),
             openMouth, SKAction.wait(forDuration: 0.18),
             closedMouth, SKAction.wait(forDuration: 0.12),
             openMouth, SKAction.wait(forDuration: 0.18)],

            // Pattern 2: -O-O-O (longer)
            [closedMouth, SKAction.wait(forDuration: 0.1),
             openMouth, SKAction.wait(forDuration: 0.15),
             closedMouth, SKAction.wait(forDuration: 0.1),
             openMouth, SKAction.wait(forDuration: 0.15),
             closedMouth, SKAction.wait(forDuration: 0.1),
             openMouth, SKAction.wait(forDuration: 0.15)],

            // Pattern 3: -OO-O (quick double)
            [closedMouth, SKAction.wait(forDuration: 0.1),
             openMouth, SKAction.wait(forDuration: 0.12),
             closedMouth, SKAction.wait(forDuration: 0.06),
             openMouth, SKAction.wait(forDuration: 0.12),
             closedMouth, SKAction.wait(forDuration: 0.15),
             openMouth, SKAction.wait(forDuration: 0.18)],

            // Pattern 4: -O--O (pause in middle)
            [closedMouth, SKAction.wait(forDuration: 0.1),
             openMouth, SKAction.wait(forDuration: 0.2),
             closedMouth, SKAction.wait(forDuration: 0.25),
             openMouth, SKAction.wait(forDuration: 0.2)],
        ]

        let selectedPattern = patterns.randomElement()!
        let speakPattern = SKAction.sequence(selectedPattern)

        let cleanup = SKAction.run { [weak self] in
            self?.stopSpeaking()
        }

        mouthNode.run(SKAction.sequence([speakPattern, cleanup]), withKey: "speaking")
    }

    /// Stop the speaking animation
    func stopSpeaking() {
        isSpeaking = false
        mouthNode.removeAction(forKey: "speaking")

        // Restore mouth to center position and fade out
        mouthNode.position = SpritePositions.mouth
        mouthNode.texture = whistleMouthTexture
        mouthNode.size = CGSize(width: 3, height: 3)
        mouthNode.alpha = 0
    }
}
