//
//  ClawdachiSprite+Sleep.swift
//  Clawdachi
//
//  Sleep animations: entering sleep, Z spawning, waking up
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Sleep Animation

    func startSleeping() {
        guard !isPerformingAction else { return }
        isPerformingAction = true

        disableMouseTracking()

        removeAction(forKey: AnimationKey.whistleSchedule.rawValue)
        removeAction(forKey: AnimationKey.blinkSchedule.rawValue)
        removeAction(forKey: AnimationKey.lookAroundSchedule.rawValue)
        removeAction(forKey: AnimationKey.sway.rawValue)

        let droop = SKAction.scaleY(to: 0.95, duration: 0.5)
        droop.timingMode = .easeInEaseOut
        run(droop)

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.leftEyeNode.texture = self.eyeClosedTexture
                self.rightEyeNode.texture = self.eyeClosedTexture
            }
        ]))

        let sleepBreath = SKAction.sequence([
            SKAction.scaleX(to: 1.02, duration: 2.0),
            SKAction.scaleX(to: 0.98, duration: 2.0)
        ])
        sleepBreath.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(sleepBreath), withKey: AnimationKey.sleepSway.rawValue)

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
        ]), withKey: AnimationKey.sleepZSchedule.rawValue)
    }

    func wakeUp(completion: (() -> Void)? = nil) {
        removeAction(forKey: AnimationKey.sleepZSchedule.rawValue)
        removeAction(forKey: AnimationKey.sleepSway.rawValue)

        // Phase 1: Start drowsy - eyes half open
        leftEyeNode.texture = blinkFrames[1]
        rightEyeNode.texture = blinkFrames[1]

        // Phase 2: Yawn builds - mouth starts small, grows
        mouthNode.texture = yawnMouthTexture
        mouthNode.size = CGSize(width: 5, height: 4)
        mouthNode.setScale(0.6)
        mouthNode.alpha = 0

        let mouthAppear = SKAction.fadeIn(withDuration: 0.1)
        let mouthGrow = SKAction.scale(to: 1.0, duration: 0.2)
        mouthGrow.timingMode = .easeOut

        // Phase 3: Peak of yawn - eyes squeeze shut, hold
        let peakHold = SKAction.wait(forDuration: 0.35)

        // Phase 4: Yawn releases - mouth shrinks and fades
        let mouthShrink = SKAction.scale(to: 0.7, duration: 0.15)
        let mouthFade = SKAction.fadeOut(withDuration: 0.15)
        let mouthClose = SKAction.group([mouthShrink, mouthFade])

        let resetMouth = SKAction.run { [weak self] in
            self?.mouthNode.texture = self?.whistleMouthTexture
            self?.mouthNode.size = CGSize(width: 3, height: 3)
            self?.mouthNode.setScale(1.0)
        }

        mouthNode.run(SKAction.sequence([
            mouthAppear,
            mouthGrow,
            peakHold,
            mouthClose,
            resetMouth
        ]), withKey: AnimationKey.yawn.rawValue)

        // Eye animation - squint tighter at peak, then open
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                // Eyes close tighter at yawn peak
                self?.leftEyeNode.texture = self?.eyeClosedTexture
                self?.rightEyeNode.texture = self?.eyeClosedTexture
            },
            SKAction.wait(forDuration: 0.35),
            SKAction.run { [weak self] in
                // Eyes half open as yawn ends
                self?.leftEyeNode.texture = self?.blinkFrames[1]
                self?.rightEyeNode.texture = self?.blinkFrames[1]
            },
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in
                // Eyes fully open
                self?.leftEyeNode.texture = self?.eyeOpenTexture
                self?.rightEyeNode.texture = self?.eyeOpenTexture
            }
        ]))

        // Subtle body movement - slight tilt back during yawn
        let tiltBack = SKAction.scaleY(to: 1.03, duration: 0.25)
        tiltBack.timingMode = .easeOut
        let holdTilt = SKAction.wait(forDuration: 0.3)
        let settleBack = SKAction.scaleY(to: 1.0, duration: 0.2)
        settleBack.timingMode = .easeInEaseOut

        // Little shake at the end (post-yawn shudder)
        let shakeL = SKAction.moveBy(x: -0.3, y: 0, duration: 0.03)
        let shakeR = SKAction.moveBy(x: 0.6, y: 0, duration: 0.06)
        let shakeBack = SKAction.moveBy(x: -0.3, y: 0, duration: 0.03)
        let shake = SKAction.sequence([shakeL, shakeR, shakeBack])

        run(SKAction.sequence([tiltBack, holdTilt, settleBack, shake]), withKey: AnimationKey.wakeUp.rawValue)

        let completionAction = SKAction.run { [weak self] in
            self?.isPerformingAction = false
            self?.enableMouseTracking()
            self?.startSwayAnimation()
            self?.scheduleNextBlink()
            self?.scheduleNextLookAround()
            self?.scheduleNextIdleAnimation()  // Restart coordinated whistle/smoke cycle
            completion?()
        }
        run(SKAction.sequence([SKAction.wait(forDuration: 1.0), completionAction]))
    }
}
