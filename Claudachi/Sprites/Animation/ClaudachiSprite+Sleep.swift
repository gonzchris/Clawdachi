//
//  ClaudachiSprite+Sleep.swift
//  Claudachi
//
//  Sleep animations: entering sleep, Z spawning, waking up
//

import SpriteKit

extension ClaudachiSprite {

    // MARK: - Sleep Animation

    func startSleeping() {
        guard !isPerformingAction else { return }
        isPerformingAction = true

        removeAction(forKey: "whistleSchedule")
        removeAction(forKey: "blinkSchedule")
        removeAction(forKey: "lookAroundSchedule")
        removeAction(forKey: "sway")

        let droop = SKAction.scaleY(to: 0.95, duration: 0.5)
        droop.timingMode = .easeInEaseOut
        run(droop)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.run { [weak self] in
                let closedTexture = ClaudachiFaceSprites.generateEyeTexture(state: .closed)
                self?.leftEyeNode.texture = closedTexture
                self?.rightEyeNode.texture = closedTexture
            }
        ]))

        let sleepBreath = SKAction.sequence([
            SKAction.scaleX(to: 1.02, duration: 2.0),
            SKAction.scaleX(to: 0.98, duration: 2.0)
        ])
        sleepBreath.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(sleepBreath), withKey: "sleepSway")

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in self?.spawnSleepZ() }
        ]))
    }

    func spawnSleepZ() {
        guard isPerformingAction else { return }

        ParticleSpawner.spawnSleepZ(texture: zzzTexture, parent: self)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in self?.spawnSleepZ() }
        ]), withKey: "sleepZSchedule")
    }

    func wakeUp(completion: (() -> Void)? = nil) {
        removeAction(forKey: "sleepZSchedule")
        removeAction(forKey: "sleepSway")

        leftEyeNode.texture = eyeOpenTexture
        rightEyeNode.texture = eyeOpenTexture

        let bigStretch = SKAction.group([
            SKAction.scaleY(to: 1.25, duration: 0.3),
            SKAction.scaleX(to: 0.9, duration: 0.3)
        ])
        bigStretch.timingMode = .easeOut

        let wideStretch = SKAction.group([
            SKAction.scaleY(to: 1.1, duration: 0.2),
            SKAction.scaleX(to: 1.15, duration: 0.2)
        ])

        let settle = SKAction.scale(to: 1.0, duration: 0.15)
        settle.timingMode = .easeOut

        let stretchSequence = SKAction.sequence([bigStretch, wideStretch, settle])
        run(stretchSequence, withKey: "wakeUp")

        let completionAction = SKAction.run { [weak self] in
            self?.isPerformingAction = false
            self?.startSwayAnimation()
            self?.scheduleNextBlink()
            self?.scheduleNextWhistle()
            self?.scheduleNextLookAround()
            completion?()
        }
        run(SKAction.sequence([SKAction.wait(forDuration: 0.7), completionAction]))
    }
}
