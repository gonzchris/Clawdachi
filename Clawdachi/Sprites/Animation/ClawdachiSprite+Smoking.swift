//
//  ClawdachiSprite+Smoking.swift
//  Clawdachi
//
//  Smoking idle animation - Clawdachi takes a cigarette break
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Main Smoking Animation

    /// Perform the smoking animation (called by the coordinated idle cycle)
    func performSmokingAnimation() {
        // Acquire mouth ownership for smoking
        guard acquireMouth(for: .smoking) else {
            // Can't get mouth, reschedule
            scheduleNextIdleAnimation()
            return
        }
        isSmoking = true

        // Mouth starts hidden, will show during puff cycles
        mouthNode.texture = whistleMouthTexture
        mouthNode.alpha = 0

        // Create and show cigarette in right hand
        createCigaretteNode()

        // Raise arm slightly for relaxed smoking pose
        let raiseArm = SKAction.rotate(toAngle: SmokingConstants.armRestAngle, duration: 0.3)
        raiseArm.timingMode = .easeOut
        rightArmNode.run(raiseArm, withKey: AnimationKey.smokingArmRaise.rawValue)

        // Start puff cycle - puff every smokePuffInterval seconds
        startPuffCycle()

        // Schedule end of smoking
        let endSmoking = SKAction.sequence([
            SKAction.wait(forDuration: smokingDuration),
            SKAction.run { [weak self] in
                self?.stopSmoking()
            }
        ])
        run(endSmoking, withKey: AnimationKey.smokingEnd.rawValue)
    }

    // MARK: - Cigarette Management

    private func createCigaretteNode() {
        // Remove any existing cigarette
        cigaretteNode?.removeFromParent()

        let cig = SKSpriteNode(texture: cigaretteTexture)
        cig.size = CGSize(width: 1.2, height: 5)  // Much smaller, ~80% reduction
        // Position at end of right arm, relative to arm node
        cig.position = CGPoint(x: 5, y: 0)
        cig.anchorPoint = CGPoint(x: 0.0, y: 0.5)  // Anchor at held end
        cig.zRotation = 4.71  // Tilted about +6 degrees total
        cig.zPosition = SpriteZPositions.effects
        cig.alpha = 0
        cig.setScale(SmokingConstants.cigaretteScale)
        rightArmNode.addChild(cig)  // Child of arm so it moves with hand

        // Pop in animation
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        cig.run(popIn)

        cigaretteNode = cig

        // Add subtle ember glow effect (pulsing)
        startEmberGlow()

        // Start ambient smoke from cigarette tip
        startCigaretteSmoke()
    }

    private func shrinkCigarette() {
        guard let cig = cigaretteNode else { return }

        // Shrink the cigarette height by ~12% each puff
        let currentHeight = cig.size.height
        let newHeight = max(currentHeight * SmokingConstants.puffShrinkFactor, SmokingConstants.minCigaretteHeight)

        let shrink = SKAction.resize(toWidth: cig.size.width, height: newHeight, duration: 0.3)
        shrink.timingMode = .easeOut
        cig.run(shrink)
    }

    private func startEmberGlow() {
        guard let cig = cigaretteNode else { return }

        // Very subtle color pulse on the cigarette
        let glowUp = SKAction.colorize(with: NSColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0), colorBlendFactor: SmokingConstants.emberGlowIntensity, duration: 0.8)
        let glowDown = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.8)
        let glowCycle = SKAction.sequence([glowUp, glowDown])
        cig.run(SKAction.repeatForever(glowCycle), withKey: AnimationKey.emberGlow.rawValue)
    }

    private func startCigaretteSmoke() {
        // Spawn tiny smoke wisps from cigarette tip periodically (subtle)
        let spawnSmoke = SKAction.run { [weak self] in
            self?.spawnCigaretteTipSmoke()
        }
        let wait = SKAction.wait(forDuration: 2.5)  // Less frequent
        let cycle = SKAction.sequence([spawnSmoke, wait])
        run(SKAction.repeatForever(cycle), withKey: AnimationKey.cigaretteSmoke.rawValue)
    }

    private func spawnCigaretteTipSmoke() {
        guard isSmoking, tipSmokeEnabled, let cig = cigaretteNode else { return }

        // Convert cigarette tip position from arm space to sprite space
        let tipInArm = CGPoint(x: cig.position.x + 2.5, y: cig.position.y)
        let tipInSprite = rightArmNode.convert(tipInArm, to: self)

        // Spawn a tiny, subtle smoke wisp (smaller than exhale smoke)
        let smoke = SKSpriteNode(texture: smokeTexture)
        smoke.size = CGSize(width: 4, height: 4)  // Smaller size
        smoke.position = tipInSprite
        smoke.alpha = 0
        smoke.zPosition = SpriteZPositions.effects
        smoke.setScale(SmokingConstants.smokeInitialScale)
        addChild(smoke)

        let fadeIn = SKAction.fadeAlpha(to: SmokingConstants.smokeOpacity, duration: 0.1)
        let floatUp = SKAction.moveBy(x: CGFloat.random(in: -1...1), y: CGFloat.random(in: 4...6), duration: 1.0)
        floatUp.timingMode = .easeOut
        let expand = SKAction.scale(to: SmokingConstants.smokeFinalScale, duration: 1.0)
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeOut(withDuration: 0.5)
        ])
        let animation = SKAction.sequence([
            fadeIn,
            SKAction.group([floatUp, expand, fadeOut]),
            SKAction.removeFromParent()
        ])
        smoke.run(animation)
    }

    // MARK: - Puff Cycle

    private func startPuffCycle() {
        // Perform first puff after a short delay
        let initialDelay = SKAction.wait(forDuration: 0.5)
        let firstPuff = SKAction.run { [weak self] in
            self?.performPuff()
        }
        run(SKAction.sequence([initialDelay, firstPuff]), withKey: AnimationKey.puffCycle.rawValue)
    }

    private func performPuff() {
        guard isSmoking else { return }

        // Disable tip smoke during puff to prevent particle overload
        tipSmokeEnabled = false

        // Arm raises cigarette toward mouth
        let raiseToMouth = SKAction.rotate(toAngle: SmokingConstants.armMouthAngle, duration: 0.4)
        raiseToMouth.timingMode = .easeInEaseOut

        // Hold at mouth (taking a drag)
        let holdAtMouth = SKAction.wait(forDuration: 0.3)

        // Lower arm back
        let lowerArm = SKAction.rotate(toAngle: SmokingConstants.armRestAngle, duration: 0.4)
        lowerArm.timingMode = .easeInEaseOut

        // Arm sequence
        let armSequence = SKAction.sequence([raiseToMouth, holdAtMouth, lowerArm])
        rightArmNode.run(armSequence, withKey: AnimationKey.puff.rawValue)

        // Mouth and smoke sequence (runs in parallel with arm)
        let waitForLower = SKAction.wait(forDuration: 0.7)  // Wait for arm to start lowering
        let showMouth = SKAction.run { [weak self] in
            self?.mouthNode.alpha = 1
        }
        let exhale = SKAction.run { [weak self] in
            self?.exhaleSmoke()
        }
        let waitForSmokeToClear = SKAction.wait(forDuration: 2.0)  // Smoke float duration
        let hideMouth = SKAction.run { [weak self] in
            self?.mouthNode.alpha = 0
        }
        let shrinkCig = SKAction.run { [weak self] in
            self?.shrinkCigarette()
        }
        let reEnableTipSmoke = SKAction.run { [weak self] in
            self?.tipSmokeEnabled = true
        }

        let mouthSequence = SKAction.sequence([waitForLower, showMouth, exhale, shrinkCig, waitForSmokeToClear, hideMouth, reEnableTipSmoke])
        run(mouthSequence, withKey: AnimationKey.mouthPuff.rawValue)

        // Schedule next puff
        let scheduleNext = SKAction.sequence([
            SKAction.wait(forDuration: smokePuffInterval),
            SKAction.run { [weak self] in
                guard let self = self, self.isSmoking else { return }
                self.performPuff()
            }
        ])
        run(scheduleNext, withKey: AnimationKey.puffSchedule.rawValue)
    }

    private func exhaleSmoke() {
        guard isSmoking else { return }

        // Spawn 2-3 smoke particles from mouth area with staggered timing
        let smokePosition = CGPoint(x: 2, y: -4)  // Near center mouth position

        ParticleSpawner.spawnSmoke(
            texture: smokeTexture,
            startPosition: smokePosition,
            variation: 0,
            delay: 0,
            parent: self
        )
        ParticleSpawner.spawnSmoke(
            texture: smokeTexture,
            startPosition: smokePosition,
            variation: 1,
            delay: 0.15,
            parent: self
        )
        ParticleSpawner.spawnSmoke(
            texture: smokeTexture,
            startPosition: smokePosition,
            variation: 2,
            delay: 0.3,
            parent: self
        )
    }

    // MARK: - Stop Smoking

    func stopSmoking() {
        // Check for cigarette node presence OR state flag (handles state machine transitions)
        guard isSmoking || cigaretteNode != nil else { return }

        // Remove puff-related actions
        removeAction(forKey: AnimationKey.puffCycle.rawValue)
        removeAction(forKey: AnimationKey.puffSchedule.rawValue)
        removeAction(forKey: AnimationKey.mouthPuff.rawValue)
        removeAction(forKey: AnimationKey.smokingEnd.rawValue)
        removeAction(forKey: AnimationKey.cigaretteSmoke.rawValue)
        rightArmNode.removeAction(forKey: AnimationKey.puff.rawValue)
        rightArmNode.removeAction(forKey: AnimationKey.smokingArmRaise.rawValue)
        cigaretteNode?.removeAction(forKey: AnimationKey.emberGlow.rawValue)

        // Hide mouth
        mouthNode.alpha = 0

        // Lower arm back to normal
        let lowerArm = SKAction.rotate(toAngle: 0, duration: 0.3)
        lowerArm.timingMode = .easeInEaseOut
        rightArmNode.run(lowerArm)

        // Fade out and remove cigarette
        if let cig = cigaretteNode {
            let fadeOut = SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 0.5, duration: 0.2)
            ])
            let remove = SKAction.run { [weak self] in
                self?.cigaretteNode?.removeFromParent()
                self?.cigaretteNode = nil
            }
            cig.run(SKAction.sequence([fadeOut, remove]))
        }

        // Release mouth ownership
        releaseMouth(from: .smoking)

        // Only reset state and reschedule if we were actually in smoking state
        // (not if called during cleanup from another state transition)
        if currentState == .smoking {
            isSmoking = false
            onSmokingComplete()  // Schedule next in coordinated cycle
        }
    }
}
