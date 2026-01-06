//
//  ClawdachiSprite+Speaking.swift
//  Clawdachi
//
//  Speaking animation - mouth opens and closes when chat bubble is shown
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Cached Speaking Patterns

    /// Speaking pattern timings (built once, reused)
    private enum SpeakingPatterns {
        // Pattern durations: [(isClosed, duration)]
        static let pattern1: [(Bool, TimeInterval)] = [
            // -O-O (classic)
            (true, 0.12), (false, 0.18), (true, 0.12), (false, 0.18)
        ]
        static let pattern2: [(Bool, TimeInterval)] = [
            // -O-O-O (longer)
            (true, 0.1), (false, 0.15), (true, 0.1), (false, 0.15), (true, 0.1), (false, 0.15)
        ]
        static let pattern3: [(Bool, TimeInterval)] = [
            // -OO-O (quick double)
            (true, 0.1), (false, 0.12), (true, 0.06), (false, 0.12), (true, 0.15), (false, 0.18)
        ]
        static let pattern4: [(Bool, TimeInterval)] = [
            // -O--O (pause in middle)
            (true, 0.1), (false, 0.2), (true, 0.25), (false, 0.2)
        ]

        static let all: [[(Bool, TimeInterval)]] = [pattern1, pattern2, pattern3, pattern4]
    }

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

        // Build actions from selected cached pattern
        let selectedPattern = SpeakingPatterns.all.randomElement()!
        var actions: [SKAction] = []

        for (isClosed, waitDuration) in selectedPattern {
            if isClosed {
                actions.append(SKAction.run { [weak self] in
                    self?.mouthNode.texture = self?.speakingClosedMouthTexture
                    self?.mouthNode.size = CGSize(width: 3, height: 1)
                })
            } else {
                actions.append(SKAction.run { [weak self] in
                    self?.mouthNode.texture = self?.speakingOpenMouthTexture
                    self?.mouthNode.size = CGSize(width: 3, height: 3)
                })
            }
            actions.append(SKAction.wait(forDuration: waitDuration))
        }

        actions.append(SKAction.run { [weak self] in
            self?.stopSpeaking()
        })

        mouthNode.run(SKAction.sequence(actions), withKey: "speaking")
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
