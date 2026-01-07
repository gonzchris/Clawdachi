//
//  ClawdachiSprite+Claude.swift
//  Clawdachi
//
//  Claude Code integration animations: thinking pose when Claude is working
//

import SpriteKit

extension ClawdachiSprite {

    // MARK: - Textures

    /// Cached texture for main thought cloud (large static cloud above head)
    private static var mainCloudTexture: SKTexture = {
        ClawdachiFaceSprites.generateMainCloudTexture()
    }()

    /// Cached textures for mini clouds (floating past main cloud)
    private static var miniCloudTextures: [(texture: SKTexture, size: CGSize)] = {
        [
            (ClawdachiFaceSprites.generateMiniCloud1(), CGSize(width: 7, height: 5)),
            (ClawdachiFaceSprites.generateMiniCloud2(), CGSize(width: 9, height: 5)),
            (ClawdachiFaceSprites.generateMiniCloud3(), CGSize(width: 6, height: 4))
        ]
    }()

    /// Cached textures for lightbulb sparks (small, medium, large yellow/white)
    private static var sparkTextures: [(texture: SKTexture, size: CGSize)] = {
        [
            (ClawdachiFaceSprites.generateSparkSmall(), CGSize(width: 2, height: 2)),
            (ClawdachiFaceSprites.generateSparkMedium(), CGSize(width: 3, height: 3)),
            (ClawdachiFaceSprites.generateSparkLarge(), CGSize(width: 4, height: 4))
        ]
    }()

    /// Cached texture for thinking orbs (tiny orange dots)
    private static var thinkingOrbTexture: SKTexture = {
        ClawdachiFaceSprites.generateThinkingOrbTiny()
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

    /// Cached texture for question mark (waiting for input)
    private static var questionMarkTexture: SKTexture = {
        ClawdachiFaceSprites.generateQuestionMarkTexture()
    }()

    /// Cached textures for party celebration
    private static var partyHatTexture: SKTexture = {
        ClawdachiFaceSprites.generatePartyHatTexture()
    }()

    private static var partyBlowerRetractedTexture: SKTexture = {
        ClawdachiFaceSprites.generatePartyBlowerRetractedTexture()
    }()

    private static var partyBlowerExtendedTexture: SKTexture = {
        ClawdachiFaceSprites.generatePartyBlowerExtendedTexture()
    }()

    /// Cached texture for gear (thinking indicator)
    private static var gearTexture: SKTexture = {
        ClawdachiFaceSprites.generateGearTexture()
    }()

    /// Name for the lightbulb node
    private static let lightbulbName = "completionLightbulb"

    /// Name for the question mark node
    private static let questionMarkName = "waitingQuestionMark"

    /// Names for party celebration nodes
    private static let partyHatName = "partyHat"
    private static let partyBlowerName = "partyBlower"

    /// Name for the main thought cloud node
    private static let mainCloudName = "mainThoughtCloud"

    // MARK: - Claude Animation Cleanup

    /// Clean up all Claude-related animations (called before transitioning between Claude states)
    /// - Parameters:
    ///   - animated: Whether to fade out visuals gracefully (default: false for quick cleanup)
    ///   - completion: Called after cleanup is complete
    private func cleanupClaudeAnimations(animated: Bool = false, completion: (() -> Void)? = nil) {
        // Remove all thinking-related actions
        removeAction(forKey: AnimationKey.thinkingTilt.rawValue)
        removeAction(forKey: AnimationKey.thinkingBob.rawValue)
        removeAction(forKey: AnimationKey.thinkingParticleSpawner.rawValue)
        removeAction(forKey: AnimationKey.thinkingOrbSpawner.rawValue)
        removeAction(forKey: AnimationKey.thinkingBlink.rawValue)
        removeAction(forKey: AnimationKey.thinkingBlinkSequence.rawValue)
        removeAction(forKey: AnimationKey.thinkingArmTilt.rawValue)

        // Remove all planning-related actions
        removeAction(forKey: AnimationKey.planningTilt.rawValue)
        removeAction(forKey: AnimationKey.planningBob.rawValue)
        removeAction(forKey: AnimationKey.planningBlink.rawValue)
        removeAction(forKey: AnimationKey.planningBlinkSequence.rawValue)
        removeAction(forKey: AnimationKey.lightbulbSparkSpawner.rawValue)

        // Cancel any blink animations on eye nodes to prevent texture conflicts
        leftEyeNode.removeAction(forKey: AnimationKey.blink.rawValue)
        rightEyeNode.removeAction(forKey: AnimationKey.blink.rawValue)

        // Remove party celebration actions
        removeAction(forKey: AnimationKey.blowerCycle.rawValue)
        removeAction(forKey: AnimationKey.partyBounce.rawValue)
        leftArmNode.removeAction(forKey: AnimationKey.partyArm.rawValue)
        rightArmNode.removeAction(forKey: AnimationKey.partyArm.rawValue)

        // Reset arm positions (in case thinking arm tilt was in progress)
        leftArmNode.removeAllActions()
        rightArmNode.removeAllActions()
        leftArmNode.zRotation = 0
        rightArmNode.zRotation = 0

        // Reset body transform
        let resetDuration = animated ? AnimationTimings.overlayFadeDuration : 0.1
        let resetScale = SKAction.scaleY(to: 1.0, duration: resetDuration)
        run(resetScale)

        if animated {
            // Dismiss visuals gracefully, then call completion
            let transitionDelay = AnimationTimings.overlayFadeDuration
            dismissLightbulb()
            dismissQuestionMark()
            dismissPartyCelebration()
            dismissMainCloud()
            removeFloatingOrbs()

            // Short delay to let visuals fade, then proceed
            run(SKAction.sequence([
                SKAction.wait(forDuration: transitionDelay),
                SKAction.run { completion?() }
            ]))
        } else {
            // Immediate cleanup
            dismissLightbulb()
            dismissQuestionMark()
            dismissPartyCelebration()
            dismissMainCloud()
            removeFloatingOrbs()
            completion?()
        }
    }

    /// Gracefully transition between Claude states
    /// - Parameters:
    ///   - newState: The target Claude state
    ///   - setupNewState: Closure to set up the new state after cleanup
    private func transitionToClaudeState(_ newState: SpriteState, setupNewState: @escaping () -> Void) {
        let current = currentState

        // If transitioning between different Claude states, animate the transition
        if current.isClaudeState && current != newState {
            cleanupClaudeAnimations(animated: true) {
                setupNewState()
            }
        } else {
            // Coming from non-Claude state, do immediate cleanup
            cleanupClaudeAnimations(animated: false)
            setupNewState()
        }
    }

    // MARK: - Planning Animation

    /// Start the planning animation (when Claude is in plan mode)
    /// Shows lightbulb with flickering sparks - designing a solution
    func startClaudePlanning() {
        guard !isClaudePlanning else { return }

        // Use graceful transition helper for smooth state changes
        transitionToClaudeState(.claudePlanning) { [weak self] in
            self?.setupPlanningState()
        }
    }

    /// Set up the planning state (called after transition cleanup)
    private func setupPlanningState() {
        isClaudePlanning = true

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
        run(tiltForward, withKey: AnimationKey.planningTilt.rawValue)

        // Gentle head bob loop
        let bobHalfDuration = AnimationTimings.thinkingBobDuration / 2
        let bobUp = SKAction.moveBy(x: 0, y: 0.5, duration: bobHalfDuration)
        let bobDown = SKAction.moveBy(x: 0, y: -0.5, duration: bobHalfDuration)
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        let bobCycle = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))
        run(bobCycle, withKey: AnimationKey.planningBob.rawValue)

        // Start occasional blinks
        startPlanningBlinks()

        // Show lightbulb with flickering sparks
        showPlanningLightbulb()
        startLightbulbSparks()
    }

    /// Stop the planning animation and return to normal
    func stopClaudePlanning() {
        guard isClaudePlanning else { return }
        isClaudePlanning = false

        // Stop planning animations (including active blink sequence)
        removeAction(forKey: AnimationKey.planningTilt.rawValue)
        removeAction(forKey: AnimationKey.planningBob.rawValue)
        removeAction(forKey: AnimationKey.planningBlink.rawValue)
        removeAction(forKey: AnimationKey.planningBlinkSequence.rawValue)
        removeAction(forKey: AnimationKey.lightbulbSparkSpawner.rawValue)

        // Also cancel any blink animations on eye nodes to prevent texture conflicts
        leftEyeNode.removeAction(forKey: AnimationKey.blink.rawValue)
        rightEyeNode.removeAction(forKey: AnimationKey.blink.rawValue)

        // Dismiss the planning lightbulb
        dismissLightbulb()

        // Reset body scale
        let resetScale = SKAction.scaleY(to: 1.0, duration: 0.2)
        resetScale.timingMode = .easeOut
        run(resetScale)

        // Force reset eyes to open (done after action removal to ensure no race)
        leftEyeNode.texture = eyeOpenTexture
        rightEyeNode.texture = eyeOpenTexture

        // Re-enable mouse tracking
        isMouseTrackingEnabled = true

        // Resume idle animations
        resumeIdleAnimations()
    }

    // MARK: - Planning Blinks

    private func startPlanningBlinks() {
        let blinkAction = SKAction.run { [weak self] in
            guard let self = self, self.isClaudePlanning else { return }
            self.performPlanningBlink()
        }
        let wait = SKAction.wait(forDuration: TimeInterval.random(in: 4.0...7.0))
        let loop = SKAction.repeatForever(SKAction.sequence([wait, blinkAction]))
        run(loop, withKey: AnimationKey.planningBlink.rawValue)
    }

    private func performPlanningBlink() {
        // Cancel any pending blink sequence before starting new one
        removeAction(forKey: AnimationKey.planningBlinkSequence.rawValue)

        let close = SKAction.run { [weak self] in
            self?.leftEyeNode.texture = self?.eyeClosedTexture
            self?.rightEyeNode.texture = self?.eyeClosedTexture
        }
        let open = SKAction.run { [weak self] in
            // Double-check state to prevent stuck eyes after state change
            guard let self = self, self.currentState == .claudePlanning else { return }
            self.leftEyeNode.texture = Self.focusedLeftEyeTexture
            self.rightEyeNode.texture = Self.focusedRightEyeTexture
        }
        let blinkSequence = SKAction.sequence([
            close,
            SKAction.wait(forDuration: 0.1),
            open
        ])
        run(blinkSequence, withKey: AnimationKey.planningBlinkSequence.rawValue)
    }

    // MARK: - Lightbulb Sparks

    private func startLightbulbSparks() {
        let spawnAction = SKAction.run { [weak self] in
            guard let self = self, self.isClaudePlanning else { return }
            self.spawnLightbulbSpark()
        }
        let wait = SKAction.wait(forDuration: TimeInterval.random(in: 0.15...0.35))
        let loop = SKAction.repeatForever(SKAction.sequence([spawnAction, wait]))
        run(loop, withKey: AnimationKey.lightbulbSparkSpawner.rawValue)
    }

    private func spawnLightbulbSpark() {
        // Pick a random yellow/white spark texture
        let sparkData = Self.sparkTextures.randomElement()!

        let spark = SKSpriteNode(texture: sparkData.texture)
        spark.size = CGSize(width: sparkData.size.width * 0.6, height: sparkData.size.height * 0.6)

        // Position around the lightbulb (which is at y: 15)
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let radius = CGFloat.random(in: 3...6)
        let offsetX = cos(angle) * radius
        let offsetY = sin(angle) * radius + 15  // 15 is lightbulb Y position

        spark.position = CGPoint(x: offsetX, y: offsetY)
        spark.alpha = 0
        spark.zPosition = SpriteZPositions.effects + 2
        spark.setScale(0.3)
        addChild(spark)

        // Quick flicker animation: pop in, hold briefly, fade out
        let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.05)
        let grow = SKAction.scale(to: 0.8, duration: 0.05)
        let popIn = SKAction.group([fadeIn, grow])

        let hold = SKAction.wait(forDuration: TimeInterval.random(in: 0.08...0.15))

        let fadeOut = SKAction.fadeOut(withDuration: 0.1)
        let shrink = SKAction.scale(to: 0.4, duration: 0.1)
        let popOut = SKAction.group([fadeOut, shrink])

        let sequence = SKAction.sequence([
            popIn,
            hold,
            popOut,
            SKAction.removeFromParent()
        ])
        spark.run(sequence)
    }

    /// Show a glowing lightbulb for planning mode
    private func showPlanningLightbulb() {
        // Remove any existing lightbulb
        childNode(withName: Self.lightbulbName)?.removeFromParent()

        let bulb = SKSpriteNode(texture: Self.lightbulbTexture)
        bulb.name = Self.lightbulbName
        bulb.size = CGSize(width: 6.8, height: 9.6)  // 20% smaller
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

        // Gentle floating bob while visible (synced with body bob)
        let bobUp = SKAction.moveBy(x: 0, y: 1.0, duration: 0.6)
        let bobDown = SKAction.moveBy(x: 0, y: -1.0, duration: 0.6)
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        let floatLoop = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))

        // Add subtle glow pulse while planning
        let glowUp = SKAction.colorize(with: NSColor.yellow, colorBlendFactor: 0.3, duration: 0.8)
        let glowDown = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.8)
        glowUp.timingMode = .easeInEaseOut
        glowDown.timingMode = .easeInEaseOut
        let glowLoop = SKAction.repeatForever(SKAction.sequence([glowUp, glowDown]))

        bulb.run(SKAction.sequence([popIn, settle, SKAction.group([floatLoop, glowLoop])]))
    }

    // MARK: - Thinking Animation

    /// Start the thinking pose animation (when Claude is processing)
    func startClaudeThinking() {
        // Don't start regular thinking if already planning or thinking
        guard !isClaudeThinking, !isClaudePlanning else { return }

        // Use graceful transition helper for smooth state changes
        transitionToClaudeState(.claudeThinking) { [weak self] in
            self?.setupThinkingState()
        }
    }

    /// Set up the thinking state (called after transition cleanup)
    private func setupThinkingState() {
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

        // Gentle head bob loop (thinking rhythm)
        let bobHalfDuration = AnimationTimings.thinkingBobDuration / 2
        let bobUp = SKAction.moveBy(x: 0, y: 0.5, duration: bobHalfDuration)
        let bobDown = SKAction.moveBy(x: 0, y: -0.5, duration: bobHalfDuration)
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        let bobCycle = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))
        run(bobCycle, withKey: AnimationKey.thinkingBob.rawValue)

        // Show main thought cloud above head
        showMainCloud()

        // Start occasional blinks
        startThinkingBlinks()

        // Start occasional arm tilts (thinking pose)
        startThinkingArmTilts()

        // Start floating orbs after cloud has risen into place (0.6s delay)
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in
                guard let self = self, self.isClaudeThinking else { return }
                self.startFloatingOrbs()
            }
        ]))
    }

    /// Stop the thinking animation and return to normal
    func stopClaudeThinking() {
        guard isClaudeThinking else { return }
        isClaudeThinking = false

        // Stop thinking animations (including active blink sequence)
        removeAction(forKey: AnimationKey.thinkingTilt.rawValue)
        removeAction(forKey: AnimationKey.thinkingBob.rawValue)
        removeAction(forKey: AnimationKey.thinkingParticleSpawner.rawValue)
        removeAction(forKey: AnimationKey.thinkingOrbSpawner.rawValue)
        removeAction(forKey: AnimationKey.thinkingBlink.rawValue)
        removeAction(forKey: AnimationKey.thinkingBlinkSequence.rawValue)
        removeAction(forKey: AnimationKey.thinkingArmTilt.rawValue)

        // Also cancel any blink animations on eye nodes to prevent texture conflicts
        leftEyeNode.removeAction(forKey: AnimationKey.blink.rawValue)
        rightEyeNode.removeAction(forKey: AnimationKey.blink.rawValue)

        // Reset arm positions
        leftArmNode.removeAllActions()
        rightArmNode.removeAllActions()
        leftArmNode.zRotation = 0
        rightArmNode.zRotation = 0

        // Dismiss the main thought cloud and floating orbs
        dismissMainCloud()
        removeFloatingOrbs()

        // Reset body scale
        let resetScale = SKAction.scaleY(to: 1.0, duration: 0.2)
        resetScale.timingMode = .easeOut
        run(resetScale)

        // Force reset eyes to open (done after action removal to ensure no race)
        leftEyeNode.texture = eyeOpenTexture
        rightEyeNode.texture = eyeOpenTexture

        // Re-enable mouse tracking
        isMouseTrackingEnabled = true

        // Resume idle animations
        resumeIdleAnimations()
    }

    // MARK: - Floating Clouds

    private static let thinkingCloudName = "thinkingCloud"
    private static let maxThinkingClouds = 3

    /// Start spawning floating mini clouds
    private func startFloatingClouds() {
        let spawnAction = SKAction.run { [weak self] in
            guard let self = self, self.isClaudeThinking else { return }
            self.spawnMiniCloud()
        }
        // Spawn clouds every 2.7 seconds
        let wait = SKAction.wait(forDuration: 2.7)
        let loop = SKAction.repeatForever(SKAction.sequence([spawnAction, wait]))
        run(loop, withKey: AnimationKey.thinkingParticleSpawner.rawValue)

        // Spawn first cloud immediately
        spawnMiniCloud()
    }

    private func spawnMiniCloud() {
        // Limit to 3 clouds at a time
        let existingClouds = children.filter { $0.name == Self.thinkingCloudName }
        guard existingClouds.count < Self.maxThinkingClouds else { return }

        // Pick a random cloud texture
        let cloudData = Self.miniCloudTextures.randomElement()!

        let cloud = SKSpriteNode(texture: cloudData.texture)
        cloud.name = Self.thinkingCloudName
        cloud.size = CGSize(width: cloudData.size.width * 1.2, height: cloudData.size.height * 1.2)

        // Start position - at head level, spread horizontally to float past main cloud
        let startX = CGFloat.random(in: -6...6)
        cloud.position = CGPoint(x: startX, y: 10)
        cloud.alpha = 0
        cloud.zPosition = SpriteZPositions.effects  // Behind main cloud
        addChild(cloud)

        // Float duration
        let floatDuration: TimeInterval = 5.5

        // Fade in
        let fadeIn = SKAction.fadeAlpha(to: 0.85, duration: 0.4)

        // Sway while floating up - gentle side-to-side motion
        let swayDistance: CGFloat = 2.5
        let swayDuration: TimeInterval = 1.4
        let swayRight = SKAction.moveBy(x: swayDistance, y: 0, duration: swayDuration / 2)
        let swayLeft = SKAction.moveBy(x: -swayDistance * 2, y: 0, duration: swayDuration)
        let swayBack = SKAction.moveBy(x: swayDistance, y: 0, duration: swayDuration / 2)
        swayRight.timingMode = .easeInEaseOut
        swayLeft.timingMode = .easeInEaseOut
        swayBack.timingMode = .easeInEaseOut
        let swayCycle = SKAction.sequence([swayRight, swayLeft, swayBack])
        let swayLoop = SKAction.repeatForever(swayCycle)

        // Float upward - past the main cloud
        let floatUp = SKAction.moveBy(x: 0, y: 25, duration: floatDuration)
        floatUp.timingMode = .easeOut

        // Fade out near end
        let waitBeforeFade = SKAction.wait(forDuration: floatDuration - 1.2)
        let fadeOut = SKAction.fadeOut(withDuration: 1.2)
        let fadeSequence = SKAction.sequence([waitBeforeFade, fadeOut])

        // Run sway and float together, then remove
        let movement = SKAction.group([swayLoop, floatUp, fadeSequence])
        let sequence = SKAction.sequence([
            fadeIn,
            movement,
            SKAction.removeFromParent()
        ])
        cloud.run(sequence)
    }

    // MARK: - Floating Orbs

    private static let thinkingOrbName = "thinkingOrb"
    private static let maxThinkingOrbs = 8

    /// Start spawning floating orbs around the thought cloud
    private func startFloatingOrbs() {
        let spawnAction = SKAction.run { [weak self] in
            guard let self = self, self.isClaudeThinking else { return }
            self.spawnThinkingOrb()
        }
        // Spawn orbs every 0.6-1.0 seconds (medium density)
        let wait = SKAction.wait(forDuration: TimeInterval.random(in: 0.6...1.0))
        let loop = SKAction.repeatForever(SKAction.sequence([spawnAction, wait]))
        run(loop, withKey: AnimationKey.thinkingOrbSpawner.rawValue)

        // Spawn first orb immediately
        spawnThinkingOrb()
    }

    private func spawnThinkingOrb() {
        // Limit to 8 orbs at a time
        let existingOrbs = children.filter { $0.name == Self.thinkingOrbName }
        guard existingOrbs.count < Self.maxThinkingOrbs else { return }

        let orb = SKSpriteNode(texture: Self.thinkingOrbTexture)
        orb.name = Self.thinkingOrbName
        orb.size = CGSize(width: 2, height: 2)  // Tiny 2x2 orbs

        // Start position - center of main cloud (cloud is at y: 16)
        let startX = CGFloat.random(in: -2...2)
        orb.position = CGPoint(x: startX, y: 16)
        orb.alpha = 0
        orb.zPosition = SpriteZPositions.effects
        addChild(orb)

        // Random float parameters
        let floatDuration = TimeInterval.random(in: 1.8...2.2)
        let floatDistance = CGFloat.random(in: 18...22)

        // Fade in
        let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 0.15)

        // Float upward
        let floatUp = SKAction.moveBy(x: 0, y: floatDistance, duration: floatDuration)
        floatUp.timingMode = .easeOut

        // Sway left or right while floating
        let swayDirection: CGFloat = Bool.random() ? 1 : -1
        let swayDistance: CGFloat = CGFloat.random(in: 2...4) * swayDirection
        let swayDuration: TimeInterval = 0.5
        let swayOut = SKAction.moveBy(x: swayDistance, y: 0, duration: swayDuration)
        let swayBack = SKAction.moveBy(x: -swayDistance, y: 0, duration: swayDuration)
        swayOut.timingMode = .easeInEaseOut
        swayBack.timingMode = .easeInEaseOut
        let swayCycle = SKAction.sequence([swayOut, swayBack])
        let swayLoop = SKAction.repeat(swayCycle, count: Int(floatDuration / (swayDuration * 2)) + 1)

        // Fade out near end
        let waitBeforeFade = SKAction.wait(forDuration: floatDuration - 0.4)
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let fadeSequence = SKAction.sequence([waitBeforeFade, fadeOut])

        // Run float, sway, and fade together
        let movement = SKAction.group([floatUp, swayLoop, fadeSequence])
        let sequence = SKAction.sequence([
            fadeIn,
            movement,
            SKAction.removeFromParent()
        ])
        orb.run(sequence)
    }

    /// Remove all floating orbs
    private func removeFloatingOrbs() {
        children.filter { $0.name == Self.thinkingOrbName }.forEach { orb in
            orb.removeAllActions()
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            let remove = SKAction.removeFromParent()
            orb.run(SKAction.sequence([fadeOut, remove]))
        }
    }

    // MARK: - Main Cloud

    /// Show the main thought cloud above the sprite's head
    private func showMainCloud() {
        // Remove any existing main cloud
        childNode(withName: Self.mainCloudName)?.removeFromParent()

        let cloud = SKSpriteNode(texture: Self.mainCloudTexture)
        cloud.name = Self.mainCloudName
        cloud.size = CGSize(width: 15, height: 11)
        cloud.position = CGPoint(x: 0, y: 10)  // Start lower
        cloud.alpha = 0
        cloud.zPosition = SpriteZPositions.effects + 1
        cloud.setScale(0.5)
        addChild(cloud)

        // Gentle float up while fading in
        let floatUp = SKAction.moveTo(y: 16, duration: 0.4)
        floatUp.timingMode = .easeOut
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.4)
        scaleUp.timingMode = .easeOut
        let riseIn = SKAction.group([floatUp, fadeIn, scaleUp])

        // Gentle floating bob while visible
        let bobUp = SKAction.moveBy(x: 0, y: 1.0, duration: 0.6)
        let bobDown = SKAction.moveBy(x: 0, y: -1.0, duration: 0.6)
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        let floatLoop = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))

        // Pulsing glow effect
        let glowUp = SKAction.colorize(with: NSColor(white: 1.0, alpha: 1.0), colorBlendFactor: 0.15, duration: 0.8)
        let glowDown = SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.8)
        glowUp.timingMode = .easeInEaseOut
        glowDown.timingMode = .easeInEaseOut
        let glowLoop = SKAction.repeatForever(SKAction.sequence([glowUp, glowDown]))

        cloud.run(SKAction.sequence([riseIn, SKAction.group([floatLoop, glowLoop])]))

        // Add thinking dots inside cloud
        addThinkingDots(to: cloud)
    }

    /// Add three animated thinking dots inside the cloud
    private func addThinkingDots(to cloud: SKSpriteNode) {
        let dotSize: CGFloat = 1.2
        let spacing: CGFloat = 2.5
        let dotY: CGFloat = 0  // Center of cloud

        // Match cloud outline color (dark blue-gray)
        let dotColor = NSColor(red: 50/255, green: 55/255, blue: 70/255, alpha: 1.0)

        for i in 0..<3 {
            let dot = SKShapeNode(rectOf: CGSize(width: dotSize, height: dotSize))
            dot.fillColor = dotColor
            dot.strokeColor = .clear
            dot.position = CGPoint(x: CGFloat(i - 1) * spacing, y: dotY)
            dot.zPosition = 1
            cloud.addChild(dot)

            // Staggered bounce animation
            let delay = SKAction.wait(forDuration: Double(i) * 0.2)
            let moveUp = SKAction.moveBy(x: 0, y: 1.5, duration: 0.25)
            let moveDown = SKAction.moveBy(x: 0, y: -1.5, duration: 0.25)
            moveUp.timingMode = .easeOut
            moveDown.timingMode = .easeIn
            let pause = SKAction.wait(forDuration: 0.4)
            let bounce = SKAction.sequence([moveUp, moveDown, pause])
            let loop = SKAction.repeatForever(bounce)

            dot.run(SKAction.sequence([delay, loop]))
        }
    }

    /// Dismiss the main thought cloud with a fade out
    private func dismissMainCloud() {
        guard let cloud = childNode(withName: Self.mainCloudName) else { return }

        cloud.removeAllActions()
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        cloud.run(SKAction.sequence([fadeOut, remove]))
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
        run(loop, withKey: AnimationKey.thinkingBlink.rawValue)
    }

    private func performThinkingBlink() {
        // Cancel any pending blink sequence before starting new one
        removeAction(forKey: AnimationKey.thinkingBlinkSequence.rawValue)

        // Quick blink: > < → closed → > <
        let close = SKAction.run { [weak self] in
            self?.leftEyeNode.texture = self?.eyeClosedTexture
            self?.rightEyeNode.texture = self?.eyeClosedTexture
        }
        let open = SKAction.run { [weak self] in
            // Double-check state to prevent stuck eyes after state change
            guard let self = self, self.currentState == .claudeThinking else { return }
            self.leftEyeNode.texture = Self.focusedLeftEyeTexture
            self.rightEyeNode.texture = Self.focusedRightEyeTexture
        }
        let blinkSequence = SKAction.sequence([
            close,
            SKAction.wait(forDuration: 0.1),
            open
        ])
        run(blinkSequence, withKey: AnimationKey.thinkingBlinkSequence.rawValue)
    }

    // MARK: - Thinking Arm Tilts

    private func startThinkingArmTilts() {
        let tiltAction = SKAction.run { [weak self] in
            guard let self = self, self.isClaudeThinking else { return }
            self.performThinkingArmTilt()
        }
        // Tilt arms occasionally (every 3-5 seconds)
        let wait = SKAction.wait(forDuration: TimeInterval.random(in: 3.0...5.0))
        let loop = SKAction.repeatForever(SKAction.sequence([wait, tiltAction]))
        run(loop, withKey: AnimationKey.thinkingArmTilt.rawValue)
    }

    private func performThinkingArmTilt() {
        // Tilt both arms up like pondering
        let tiltUp = SKAction.rotate(toAngle: 0.8, duration: 0.25)
        let hold = SKAction.wait(forDuration: TimeInterval.random(in: 1.5...2.5))
        let tiltDown = SKAction.rotate(toAngle: 0, duration: 0.3)
        tiltUp.timingMode = .easeOut
        tiltDown.timingMode = .easeInEaseOut

        let sequence = SKAction.sequence([tiltUp, hold, tiltDown])

        leftArmNode.run(sequence)
        rightArmNode.run(SKAction.sequence([
            SKAction.rotate(toAngle: -0.8, duration: 0.25),
            hold,
            SKAction.rotate(toAngle: 0, duration: 0.3)
        ]))
    }

    // MARK: - Completion Lightbulb

    /// Show the "eureka" lightbulb above the sprite's head
    /// Persists until dismissed by user click, CLI close, or new CLI status
    func showCompletionLightbulb() {
        // Remove any existing lightbulb
        childNode(withName: Self.lightbulbName)?.removeFromParent()

        let bulb = SKSpriteNode(texture: Self.lightbulbTexture)
        bulb.name = Self.lightbulbName
        bulb.size = CGSize(width: 6.8, height: 9.6)  // 20% smaller
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

        // Gentle floating bob while visible (loops forever until dismissed)
        let bobUp = SKAction.moveBy(x: 0, y: 1.0, duration: 0.6)
        let bobDown = SKAction.moveBy(x: 0, y: -1.0, duration: 0.6)
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        let floatLoop = SKAction.repeatForever(SKAction.sequence([bobUp, bobDown]))

        bulb.run(SKAction.sequence([popIn, settle, floatLoop]))
    }

    /// Dismiss the lightbulb with a fade out
    /// - Parameter completion: Called after lightbulb is fully removed
    func dismissLightbulb(completion: (() -> Void)? = nil) {
        guard let bulb = childNode(withName: Self.lightbulbName) else {
            completion?()
            return
        }

        bulb.removeAllActions()
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let callCompletion = SKAction.run { completion?() }
        bulb.run(SKAction.sequence([fadeOut, remove, callCompletion]))
    }

    /// Check if lightbulb is currently visible
    var isLightbulbVisible: Bool {
        childNode(withName: Self.lightbulbName) != nil
    }

    // MARK: - Question Mark (Waiting for Input)

    /// Show the question mark above the sprite's head (waiting for user input)
    func showQuestionMark() {
        // Use graceful transition helper for smooth state changes
        transitionToClaudeState(.claudeWaiting) { [weak self] in
            self?.setupQuestionMarkState()
        }
    }

    /// Set up the question mark state (called after transition cleanup)
    private func setupQuestionMarkState() {
        // Set state before pausing animations
        isClaudeWaiting = true

        // Pause competing animations
        pauseIdleAnimations()
        stopDancing()

        // Remove any existing question mark
        childNode(withName: Self.questionMarkName)?.removeFromParent()

        let mark = SKSpriteNode(texture: Self.questionMarkTexture)
        mark.name = Self.questionMarkName
        mark.size = CGSize(width: 5, height: 9)
        mark.position = CGPoint(x: 0, y: 14)
        mark.alpha = 0
        mark.zPosition = SpriteZPositions.effects + 1
        mark.setScale(0.3)
        addChild(mark)

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

        mark.run(SKAction.sequence([popIn, settle, floatLoop]))
    }

    /// Dismiss the question mark with a fade out
    /// - Parameter completion: Called after question mark is fully removed
    func dismissQuestionMark(completion: (() -> Void)? = nil) {
        guard let mark = childNode(withName: Self.questionMarkName) else {
            // Still reset state even if node not found
            if isClaudeWaiting { isClaudeWaiting = false }
            completion?()
            return
        }

        mark.removeAllActions()
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let resetState = SKAction.run { [weak self] in
            self?.isClaudeWaiting = false
        }
        let callCompletion = SKAction.run { completion?() }
        mark.run(SKAction.sequence([fadeOut, remove, resetState, callCompletion]))
    }

    /// Check if question mark is currently visible
    var isQuestionMarkVisible: Bool {
        childNode(withName: Self.questionMarkName) != nil
    }

    // MARK: - Party Celebration

    /// Show the party celebration - hat on head and blower cycling
    /// Persists until dismissed by user click or new CLI activity
    func showPartyCelebration() {
        // Use graceful transition helper for smooth state changes
        transitionToClaudeState(.claudeCelebrating) { [weak self] in
            self?.setupPartyCelebrationState()
        }
    }

    /// Set up the party celebration state (called after transition cleanup)
    private func setupPartyCelebrationState() {
        // Set state before pausing animations
        isClaudeCelebrating = true

        // Pause competing animations
        pauseIdleAnimations()
        stopDancing()

        // Remove any existing celebration
        childNode(withName: Self.partyHatName)?.removeFromParent()
        childNode(withName: Self.partyBlowerName)?.removeFromParent()

        // Create party hat
        let hat = SKSpriteNode(texture: Self.partyHatTexture)
        hat.name = Self.partyHatName
        hat.size = CGSize(width: 7, height: 9)
        hat.position = CGPoint(x: 0, y: 12)  // On top of head
        hat.alpha = 0
        hat.zPosition = SpriteZPositions.effects + 1
        hat.setScale(0.3)
        addChild(hat)

        // Create party blower (starts retracted, positioned at side of mouth like whistle)
        let blower = SKSpriteNode(texture: Self.partyBlowerRetractedTexture)
        blower.name = Self.partyBlowerName
        blower.size = CGSize(width: 4, height: 3)
        blower.anchorPoint = CGPoint(x: 0, y: 0.5)  // Anchor at mouthpiece end
        blower.position = CGPoint(x: 3, y: -4)  // Side of mouth (similar to whistle)
        blower.alpha = 0
        blower.zPosition = SpriteZPositions.effects
        blower.setScale(0.3)
        addChild(blower)

        // Pop in hat animation
        let hatPopIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.scale(to: 1.2, duration: 0.15)
        ])
        let hatSettle = SKAction.scale(to: 1.0, duration: 0.1)
        hatSettle.timingMode = .easeOut

        // Gentle hat wobble while celebrating
        let hatWobbleLeft = SKAction.rotate(byAngle: 0.08, duration: 0.4)
        let hatWobbleRight = SKAction.rotate(byAngle: -0.08, duration: 0.4)
        hatWobbleLeft.timingMode = .easeInEaseOut
        hatWobbleRight.timingMode = .easeInEaseOut
        let hatWobbleLoop = SKAction.repeatForever(SKAction.sequence([hatWobbleLeft, hatWobbleRight]))

        hat.run(SKAction.sequence([hatPopIn, hatSettle, hatWobbleLoop]))

        // Pop in blower animation
        let blowerPopIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])

        // Start blower cycling after pop-in
        let startCycling = SKAction.run { [weak self] in
            self?.startPartyBlowerCycle()
        }

        blower.run(SKAction.sequence([blowerPopIn, startCycling]))
    }

    /// Cycle the party blower - appear, blow, disappear, wait, repeat
    private func startPartyBlowerCycle() {
        guard let blower = childNode(withName: Self.partyBlowerName) as? SKSpriteNode else { return }

        let cycleAction = SKAction.run { [weak self] in
            self?.performBlowerCycle()
        }

        // First cycle immediately, then repeat
        blower.run(SKAction.sequence([cycleAction]))
    }

    /// Perform one full blower cycle: appear → blow → retract → disappear → wait
    private func performBlowerCycle() {
        guard let blower = childNode(withName: Self.partyBlowerName) as? SKSpriteNode else { return }

        // Reset state
        blower.texture = Self.partyBlowerRetractedTexture
        blower.size = CGSize(width: 4, height: 3)
        blower.zRotation = 0
        blower.xScale = 1.0

        // Pop in
        blower.alpha = 0
        blower.setScale(0.5)
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])

        // Extend: swap texture and grow width
        let extend = SKAction.run {
            blower.texture = Self.partyBlowerExtendedTexture
            blower.size = CGSize(width: 10, height: 3)
        }

        // Quick extend with upward rotation kick
        let extendScale = SKAction.scaleX(to: 1.1, duration: 0.12)
        let rotateKick = SKAction.rotate(toAngle: 0.15, duration: 0.12)
        extendScale.timingMode = .easeOut
        rotateKick.timingMode = .easeOut
        let extendGroup = SKAction.group([extendScale, rotateKick])

        // Flutter wobble while extended
        let wobbleUp = SKAction.rotate(toAngle: 0.2, duration: 0.08)
        let wobbleDown = SKAction.rotate(toAngle: 0.08, duration: 0.08)
        wobbleUp.timingMode = .easeInEaseOut
        wobbleDown.timingMode = .easeInEaseOut
        let wobbleCycle = SKAction.sequence([wobbleUp, wobbleDown, wobbleUp, wobbleDown, wobbleUp, wobbleDown])

        // Hold extended for a moment
        let holdExtended = SKAction.wait(forDuration: 0.7)

        // Retract: swap texture back and shrink
        let retract = SKAction.run {
            blower.texture = Self.partyBlowerRetractedTexture
            blower.size = CGSize(width: 4, height: 3)
        }

        // Quick retract with rotation reset
        let retractScale = SKAction.scaleX(to: 1.0, duration: 0.08)
        let rotateBack = SKAction.rotate(toAngle: 0, duration: 0.08)
        retractScale.timingMode = .easeIn
        rotateBack.timingMode = .easeIn
        let retractGroup = SKAction.group([retractScale, rotateBack])

        // Fade out after retract
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)

        // Wait 1 second while invisible
        let waitInvisible = SKAction.wait(forDuration: 1.0)

        // Schedule next cycle
        let nextCycle = SKAction.run { [weak self] in
            self?.performBlowerCycle()
        }

        blower.run(SKAction.sequence([
            popIn,
            extend,
            extendGroup,
            wobbleCycle,
            holdExtended,
            retract,
            retractGroup,
            fadeOut,
            waitInvisible,
            nextCycle
        ]), withKey: AnimationKey.blowerCycle.rawValue)

        // Small body bounce for tactile feedback (toot!)
        let bounceUp = SKAction.moveBy(x: 0, y: 0.8, duration: 0.08)
        let bounceDown = SKAction.moveBy(x: 0, y: -0.8, duration: 0.12)
        bounceUp.timingMode = .easeOut
        bounceDown.timingMode = .easeIn
        run(SKAction.sequence([bounceUp, bounceDown]), withKey: AnimationKey.partyBounce.rawValue)

        // Arms up during the toot!
        let armsUp = SKAction.rotate(toAngle: 0.6, duration: 0.1)
        let armsDown = SKAction.rotate(toAngle: 0, duration: 0.15)
        armsUp.timingMode = .easeOut
        armsDown.timingMode = .easeInEaseOut
        let armsCelebrate = SKAction.sequence([armsUp, armsDown])
        leftArmNode.run(armsCelebrate, withKey: AnimationKey.partyArm.rawValue)
        rightArmNode.run(SKAction.sequence([
            SKAction.rotate(toAngle: -0.6, duration: 0.1),
            SKAction.rotate(toAngle: 0, duration: 0.15)
        ]), withKey: AnimationKey.partyArm.rawValue)
    }

    /// Dismiss the party celebration with a fade out
    /// - Parameter completion: Called after celebration is fully removed
    func dismissPartyCelebration(completion: (() -> Void)? = nil) {
        let hat = childNode(withName: Self.partyHatName)
        let blower = childNode(withName: Self.partyBlowerName)

        guard hat != nil || blower != nil else {
            // Still reset state even if nodes not found
            if isClaudeCelebrating { isClaudeCelebrating = false }
            completion?()
            return
        }

        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let fadeAndRemove = SKAction.sequence([fadeOut, remove])

        hat?.removeAllActions()
        blower?.removeAllActions()
        removeAction(forKey: AnimationKey.partyBounce.rawValue)
        leftArmNode.removeAction(forKey: AnimationKey.partyArm.rawValue)
        rightArmNode.removeAction(forKey: AnimationKey.partyArm.rawValue)
        leftArmNode.zRotation = 0
        rightArmNode.zRotation = 0

        // Reset state and call completion after animation
        let resetAndComplete = SKAction.run { [weak self] in
            self?.isClaudeCelebrating = false
            completion?()
        }

        // Determine which node should call completion (prefer blower, fallback to hat)
        if let blower = blower {
            hat?.run(fadeAndRemove)
            blower.run(SKAction.sequence([fadeAndRemove, resetAndComplete]))
        } else if let hat = hat {
            hat.run(SKAction.sequence([fadeAndRemove, resetAndComplete]))
        }
    }

    /// Check if party celebration is currently visible
    var isPartyCelebrationVisible: Bool {
        childNode(withName: Self.partyHatName) != nil || childNode(withName: Self.partyBlowerName) != nil
    }
}
