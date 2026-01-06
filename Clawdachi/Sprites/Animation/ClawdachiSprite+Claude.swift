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

    /// Name for the lightbulb node
    private static let lightbulbName = "completionLightbulb"

    /// Name for the question mark node
    private static let questionMarkName = "waitingQuestionMark"

    /// Names for party celebration nodes
    private static let partyHatName = "partyHat"
    private static let partyBlowerName = "partyBlower"

    // MARK: - Planning Animation

    /// Start the planning animation (when Claude is in plan mode)
    /// Combines thinking pose with lightbulb - designing a solution
    func startClaudePlanning() {
        guard !isClaudePlanning, !isDragging else { return }
        isClaudePlanning = true

        // Also set thinking flag since planning uses thinking animations
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

        // Show lightbulb above head (the "planning idea" indicator)
        showPlanningLightbulb()
    }

    /// Stop the planning animation and return to normal
    func stopClaudePlanning() {
        guard isClaudePlanning else { return }
        isClaudePlanning = false
        isClaudeThinking = false

        // Stop thinking animations
        removeAction(forKey: "thinkingTilt")
        removeAction(forKey: "thinkingBob")
        removeAction(forKey: "thinkingParticleSpawner")
        removeAction(forKey: "thinkingBlink")

        // Dismiss the planning lightbulb
        dismissLightbulb()

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

    /// Show a glowing lightbulb for planning mode
    private func showPlanningLightbulb() {
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
        // Don't start regular thinking if already planning
        guard !isClaudeThinking, !isClaudePlanning, !isDragging else { return }
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
    /// Persists until dismissed by user click, CLI close, or new CLI status
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
            completion?()
            return
        }

        mark.removeAllActions()
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let callCompletion = SKAction.run { completion?() }
        mark.run(SKAction.sequence([fadeOut, remove, callCompletion]))
    }

    /// Check if question mark is currently visible
    var isQuestionMarkVisible: Bool {
        childNode(withName: Self.questionMarkName) != nil
    }

    // MARK: - Party Celebration

    /// Show the party celebration - hat on head and blower cycling
    /// Persists until dismissed by user click or new CLI activity
    func showPartyCelebration() {
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
        ]), withKey: "blowerCycle")

        // Small body bounce for tactile feedback (toot!)
        let bounceUp = SKAction.moveBy(x: 0, y: 0.8, duration: 0.08)
        let bounceDown = SKAction.moveBy(x: 0, y: -0.8, duration: 0.12)
        bounceUp.timingMode = .easeOut
        bounceDown.timingMode = .easeIn
        run(SKAction.sequence([bounceUp, bounceDown]), withKey: "partyBounce")

        // Arms up during the toot!
        let armsUp = SKAction.rotate(toAngle: 0.6, duration: 0.1)
        let armsDown = SKAction.rotate(toAngle: 0, duration: 0.15)
        armsUp.timingMode = .easeOut
        armsDown.timingMode = .easeInEaseOut
        let armsCelebrate = SKAction.sequence([armsUp, armsDown])
        leftArmNode.run(armsCelebrate, withKey: "partyArm")
        rightArmNode.run(SKAction.sequence([
            SKAction.rotate(toAngle: -0.6, duration: 0.1),
            SKAction.rotate(toAngle: 0, duration: 0.15)
        ]), withKey: "partyArm")
    }

    /// Dismiss the party celebration with a fade out
    /// - Parameter completion: Called after celebration is fully removed
    func dismissPartyCelebration(completion: (() -> Void)? = nil) {
        let hat = childNode(withName: Self.partyHatName)
        let blower = childNode(withName: Self.partyBlowerName)

        guard hat != nil || blower != nil else {
            completion?()
            return
        }

        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let fadeAndRemove = SKAction.sequence([fadeOut, remove])

        hat?.removeAllActions()
        blower?.removeAllActions()
        removeAction(forKey: "partyBounce")
        leftArmNode.removeAction(forKey: "partyArm")
        rightArmNode.removeAction(forKey: "partyArm")
        leftArmNode.zRotation = 0
        rightArmNode.zRotation = 0

        // Determine which node should call completion (prefer blower, fallback to hat)
        if let blower = blower {
            hat?.run(fadeAndRemove)
            blower.run(SKAction.sequence([fadeAndRemove, SKAction.run { completion?() }]))
        } else if let hat = hat {
            hat.run(SKAction.sequence([fadeAndRemove, SKAction.run { completion?() }]))
        }
    }

    /// Check if party celebration is currently visible
    var isPartyCelebrationVisible: Bool {
        childNode(withName: Self.partyHatName) != nil || childNode(withName: Self.partyBlowerName) != nil
    }
}
