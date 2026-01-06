//
//  ClawdachiSprite+Smoking.swift
//  Clawdachi
//
//  Smoking idle animation - Clawdachi takes a cigarette break
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Smoking Animation Scheduling

    func scheduleNextSmoking() {
        let interval = TimeInterval.random(in: smokingMinInterval...smokingMaxInterval)
        let wait = SKAction.wait(forDuration: interval)
        let smoke = SKAction.run { [weak self] in self?.performSmoking() }
        run(SKAction.sequence([wait, smoke]), withKey: "smokingSchedule")
    }

    // MARK: - Main Smoking Animation

    func performSmoking() {
        // Don't smoke during other activities
        guard !isSmoking && !isWhistling && !isPerformingAction && !isDragging &&
              !isClaudeThinking && !isQuestionMarkVisible && !isLightbulbVisible &&
              !isPartyCelebrationVisible && !isDancing else {
            scheduleNextSmoking()
            return
        }

        isSmoking = true

        // Mouth starts hidden, will show during puff cycles
        mouthNode.texture = whistleMouthTexture
        mouthNode.alpha = 0

        // Create and show cigarette in right hand
        createCigaretteNode()

        // Raise arm slightly for relaxed smoking pose
        let raiseArm = SKAction.rotate(toAngle: 0.3, duration: 0.3)
        raiseArm.timingMode = .easeOut
        rightArmNode.run(raiseArm, withKey: "smokingArmRaise")

        // Start puff cycle - puff every smokePuffInterval seconds
        startPuffCycle()

        // Schedule end of smoking
        let endSmoking = SKAction.sequence([
            SKAction.wait(forDuration: smokingDuration),
            SKAction.run { [weak self] in
                self?.stopSmoking()
            }
        ])
        run(endSmoking, withKey: "smokingEnd")
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
        cig.setScale(0.5)
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
        let newHeight = max(currentHeight * 0.88, 1.5)  // Don't go below minimum

        let shrink = SKAction.resize(toWidth: cig.size.width, height: newHeight, duration: 0.3)
        shrink.timingMode = .easeOut
        cig.run(shrink)
    }

    private func startEmberGlow() {
        guard let cig = cigaretteNode else { return }

        // Very subtle color pulse on the cigarette
        let glowUp = SKAction.colorize(with: NSColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0), colorBlendFactor: 0.15, duration: 0.8)
        let glowDown = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.8)
        let glowCycle = SKAction.sequence([glowUp, glowDown])
        cig.run(SKAction.repeatForever(glowCycle), withKey: "emberGlow")
    }

    private func startCigaretteSmoke() {
        // Spawn tiny smoke wisps from cigarette tip periodically (subtle)
        let spawnSmoke = SKAction.run { [weak self] in
            self?.spawnCigaretteTipSmoke()
        }
        let wait = SKAction.wait(forDuration: 2.5)  // Less frequent
        let cycle = SKAction.sequence([spawnSmoke, wait])
        run(SKAction.repeatForever(cycle), withKey: "cigaretteSmoke")
    }

    private func spawnCigaretteTipSmoke() {
        guard isSmoking, let cig = cigaretteNode else { return }

        // Convert cigarette tip position from arm space to sprite space
        let tipInArm = CGPoint(x: cig.position.x + 2.5, y: cig.position.y)
        let tipInSprite = rightArmNode.convert(tipInArm, to: self)

        // Spawn a tiny, subtle smoke wisp (smaller than exhale smoke)
        let smoke = SKSpriteNode(texture: smokeTexture)
        smoke.size = CGSize(width: 4, height: 4)  // Smaller size
        smoke.position = tipInSprite
        smoke.alpha = 0
        smoke.zPosition = SpriteZPositions.effects
        smoke.setScale(0.25)  // Start very small
        addChild(smoke)

        let fadeIn = SKAction.fadeAlpha(to: 0.4, duration: 0.1)  // More transparent
        let floatUp = SKAction.moveBy(x: CGFloat.random(in: -1...1), y: CGFloat.random(in: 4...6), duration: 1.0)
        floatUp.timingMode = .easeOut
        let expand = SKAction.scale(to: 0.6, duration: 1.0)
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
        run(SKAction.sequence([initialDelay, firstPuff]), withKey: "puffCycle")
    }

    private func performPuff() {
        guard isSmoking else { return }

        // Arm raises cigarette toward mouth
        let raiseToMouth = SKAction.rotate(toAngle: 0.8, duration: 0.4)
        raiseToMouth.timingMode = .easeInEaseOut

        // Hold at mouth (taking a drag)
        let holdAtMouth = SKAction.wait(forDuration: 0.3)

        // Lower arm back
        let lowerArm = SKAction.rotate(toAngle: 0.3, duration: 0.4)
        lowerArm.timingMode = .easeInEaseOut

        // Arm sequence
        let armSequence = SKAction.sequence([raiseToMouth, holdAtMouth, lowerArm])
        rightArmNode.run(armSequence, withKey: "puff")

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

        let mouthSequence = SKAction.sequence([waitForLower, showMouth, exhale, shrinkCig, waitForSmokeToClear, hideMouth])
        run(mouthSequence, withKey: "mouthPuff")

        // Schedule next puff
        let scheduleNext = SKAction.sequence([
            SKAction.wait(forDuration: smokePuffInterval),
            SKAction.run { [weak self] in
                guard let self = self, self.isSmoking else { return }
                self.performPuff()
            }
        ])
        run(scheduleNext, withKey: "puffSchedule")
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
        guard isSmoking else { return }

        // Remove puff-related actions
        removeAction(forKey: "puffCycle")
        removeAction(forKey: "puffSchedule")
        removeAction(forKey: "mouthPuff")
        removeAction(forKey: "smokingEnd")
        removeAction(forKey: "cigaretteSmoke")
        rightArmNode.removeAction(forKey: "puff")
        rightArmNode.removeAction(forKey: "smokingArmRaise")
        cigaretteNode?.removeAction(forKey: "emberGlow")

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

        isSmoking = false

        // Schedule next smoking session
        scheduleNextSmoking()
    }
}
