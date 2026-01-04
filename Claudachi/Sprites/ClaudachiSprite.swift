//
//  ClaudachiSprite.swift
//  Claudachi
//

import SpriteKit

/// Main Claudachi character sprite with layered composition and polished animations
class ClaudachiSprite: SKNode {

    // MARK: - Sprite Layers

    private var bodyNode: SKSpriteNode!
    private var leftEyeNode: SKSpriteNode!
    private var rightEyeNode: SKSpriteNode!
    private var mouthNode: SKSpriteNode!
    private var hatNode: SKSpriteNode!  // For chef mode
    private var chefMode: ChefModeSprite!  // Mixing bowl effect

    // Limbs (separate nodes for animation)
    private var leftArmNode: SKSpriteNode!
    private var rightArmNode: SKSpriteNode!
    private var leftFootNode: SKSpriteNode!
    private var rightFootNode: SKSpriteNode!

    // MARK: - Animation Textures

    private var breathingFrames: [SKTexture] = []
    private var eyeOpenTexture: SKTexture!
    private var blinkFrames: [SKTexture] = []
    private var whistleMouthTexture: SKTexture!
    private var musicNoteTexture: SKTexture!
    private var exclamationTexture: SKTexture!
    private var thoughtDotTexture: SKTexture!
    private var heartTexture: SKTexture!
    private var sparkleTexture: SKTexture!
    private var zzzTexture: SKTexture!
    private var smileMouthTexture: SKTexture!
    private var sweatDropTexture: SKTexture!

    // Chef mode textures
    private var chefBreathingFrames: [SKTexture] = []
    private var chefHatTexture: SKTexture!
    private var isInChefMode = false

    // MARK: - Animation State

    private var isBlinking = false
    private var isWhistling = false
    private var isPerformingAction = false
    private var isLookingAround = false
    private var isDragging = false

    // MARK: - Base Positions (for returning after animations)

    private let leftEyeBasePos = CGPoint(x: -4, y: 0)
    private let rightEyeBasePos = CGPoint(x: 4, y: 0)

    // Limb positions relative to body center (sprite is 32x32, center at 0,0)
    // Arms at rows 11-13 means y = 12 - 16 = -4 (center of arm)
    // Left arm at x = 4-6 means x = 5 - 16 = -11
    private let leftArmBasePos = CGPoint(x: -11, y: -4)
    private let rightArmBasePos = CGPoint(x: 11, y: -4)
    // Feet at rows 5-6, left foot at x = 9-11, right at x = 20-22
    private let leftFootBasePos = CGPoint(x: -6, y: -10)
    private let rightFootBasePos = CGPoint(x: 6, y: -10)

    // MARK: - Accessory Positions
    // Body spans y: -9 to +6 (rows 7-22 in 32x32 grid, centered at 0)
    // Accessories can overlap body edges for natural look

    /// Hat position - sits above head, can overlap slightly
    private let hatBasePos = CGPoint(x: 0, y: 12)
    private let hatDropStartY: CGFloat = 24  // Start high for drop animation

    /// Bottom accessory position (bowl, etc.) - hangs below/overlaps with body
    static let bottomAccessoryPos = CGPoint(x: 16, y: -10)

    // MARK: - Animation Constants

    private let breathingDuration: TimeInterval = 3.0      // Slower, more relaxed
    private let swayDuration: TimeInterval = 4.0           // Gentle side sway
    private let blinkMinInterval: TimeInterval = 2.5
    private let blinkMaxInterval: TimeInterval = 6.0
    private let blinkDuration: TimeInterval = 0.18         // Snappier blink
    private let whistleMinInterval: TimeInterval = 12.0
    private let whistleMaxInterval: TimeInterval = 25.0
    private let whistleDuration: TimeInterval = 2.0
    private let lookAroundMinInterval: TimeInterval = 5.0
    private let lookAroundMaxInterval: TimeInterval = 12.0

    // MARK: - Initialization

    override init() {
        super.init()
        generateTextures()
        setupSprites()
        startAnimations()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func generateTextures() {
        breathingFrames = ClaudachiBodySprites.generateBreathingFrames()
        blinkFrames = ClaudachiFaceSprites.generateBlinkFrames()
        eyeOpenTexture = ClaudachiFaceSprites.generateEyeTexture(state: .open)
        whistleMouthTexture = ClaudachiFaceSprites.generateWhistleMouthTexture()
        musicNoteTexture = ClaudachiFaceSprites.generateMusicNoteTexture()

        // Effect textures
        exclamationTexture = ClaudachiFaceSprites.generateExclamationTexture()
        thoughtDotTexture = ClaudachiFaceSprites.generateThoughtDotTexture()
        heartTexture = ClaudachiFaceSprites.generateHeartTexture()
        sparkleTexture = ClaudachiFaceSprites.generateSparkleTexture()
        zzzTexture = ClaudachiFaceSprites.generateZzzTexture()
        smileMouthTexture = ClaudachiFaceSprites.generateSmileMouthTexture()
        sweatDropTexture = ClaudachiFaceSprites.generateSweatDropTexture()

        // Chef mode textures
        chefBreathingFrames = ClaudachiBodySprites.generateChefBreathingFrames()
        chefHatTexture = ClaudachiFaceSprites.generateChefHat()
    }

    private func setupSprites() {
        // Limbs first (Layer 0) - behind body
        leftArmNode = SKSpriteNode(texture: ClaudachiBodySprites.generateLeftArmTexture())
        leftArmNode.size = CGSize(width: 3, height: 3)
        leftArmNode.position = leftArmBasePos
        leftArmNode.anchorPoint = CGPoint(x: 1.0, y: 0.5)  // Anchor at right edge (attaches to body)
        leftArmNode.zPosition = 0
        addChild(leftArmNode)

        rightArmNode = SKSpriteNode(texture: ClaudachiBodySprites.generateRightArmTexture())
        rightArmNode.size = CGSize(width: 3, height: 3)
        rightArmNode.position = rightArmBasePos
        rightArmNode.anchorPoint = CGPoint(x: 0.0, y: 0.5)  // Anchor at left edge (attaches to body)
        rightArmNode.zPosition = 0
        addChild(rightArmNode)

        leftFootNode = SKSpriteNode(texture: ClaudachiBodySprites.generateLeftFootTexture())
        leftFootNode.size = CGSize(width: 3, height: 2)
        leftFootNode.position = leftFootBasePos
        leftFootNode.anchorPoint = CGPoint(x: 0.5, y: 1.0)  // Anchor at top (attaches to body)
        leftFootNode.zPosition = 0
        addChild(leftFootNode)

        rightFootNode = SKSpriteNode(texture: ClaudachiBodySprites.generateRightFootTexture())
        rightFootNode.size = CGSize(width: 3, height: 2)
        rightFootNode.position = rightFootBasePos
        rightFootNode.anchorPoint = CGPoint(x: 0.5, y: 1.0)  // Anchor at top (attaches to body)
        rightFootNode.zPosition = 0
        addChild(rightFootNode)

        // Body (Layer 1)
        bodyNode = SKSpriteNode(texture: breathingFrames[1])
        bodyNode.size = CGSize(width: 32, height: 32)
        bodyNode.position = .zero
        bodyNode.zPosition = 1
        addChild(bodyNode)

        // Left Eye (Layer 2)
        leftEyeNode = SKSpriteNode(texture: eyeOpenTexture)
        leftEyeNode.size = CGSize(width: 3, height: 4)
        leftEyeNode.position = leftEyeBasePos
        leftEyeNode.zPosition = 2
        addChild(leftEyeNode)

        // Right Eye (Layer 2)
        rightEyeNode = SKSpriteNode(texture: eyeOpenTexture)
        rightEyeNode.size = CGSize(width: 3, height: 4)
        rightEyeNode.position = rightEyeBasePos
        rightEyeNode.zPosition = 2
        addChild(rightEyeNode)

        // Mouth (Layer 2) - hidden by default
        mouthNode = SKSpriteNode(texture: whistleMouthTexture)
        mouthNode.size = CGSize(width: 3, height: 3)
        mouthNode.position = CGPoint(x: 0, y: -4)
        mouthNode.zPosition = 2
        mouthNode.alpha = 0
        addChild(mouthNode)

        // Chef hat (Layer 5) - hidden by default, sits on head
        hatNode = SKSpriteNode(texture: chefHatTexture)
        hatNode.size = CGSize(width: 13, height: 12)
        hatNode.position = hatBasePos  // Uses accessory position system
        hatNode.zPosition = 5
        hatNode.alpha = 0
        addChild(hatNode)

        // Mixing bowl effect (Layer -10) - behind character
        chefMode = ChefModeSprite()
        chefMode.position = CGPoint(x: 0, y: 0)
        chefMode.zPosition = -10
        addChild(chefMode)
    }

    // MARK: - Idle Animations

    private func startAnimations() {
        startBreathingAnimation()
        startSwayAnimation()
        scheduleNextBlink()
        scheduleNextWhistle()
        scheduleNextLookAround()
    }

    private func startBreathingAnimation() {
        // Smooth breathing with custom timing
        let breatheAction = SKAction.animate(
            with: breathingFrames,
            timePerFrame: breathingDuration / Double(breathingFrames.count),
            resize: false,
            restore: false
        )
        bodyNode.run(SKAction.repeatForever(breatheAction), withKey: "breathing")

        // Face follows breathing with slight delay for organic feel
        let faceUp = SKAction.moveBy(x: 0, y: 0.4, duration: breathingDuration / 2)
        let faceDown = SKAction.moveBy(x: 0, y: -0.4, duration: breathingDuration / 2)
        faceUp.timingMode = .easeInEaseOut
        faceDown.timingMode = .easeInEaseOut

        let faceBreath = SKAction.sequence([
            SKAction.wait(forDuration: 0.1),  // Slight delay
            faceUp,
            faceDown
        ])

        leftEyeNode.run(SKAction.repeatForever(faceBreath), withKey: "faceBreathing")
        rightEyeNode.run(SKAction.repeatForever(faceBreath), withKey: "faceBreathing")
        mouthNode.run(SKAction.repeatForever(faceBreath), withKey: "faceBreathing")
    }

    private func startSwayAnimation() {
        // Gentle breathing pulse using scale (no position movement)
        let pulseUp = SKAction.scaleX(to: 1.02, duration: swayDuration / 2)
        let pulseDown = SKAction.scaleX(to: 0.98, duration: swayDuration / 2)
        pulseUp.timingMode = .easeInEaseOut
        pulseDown.timingMode = .easeInEaseOut

        let swayCycle = SKAction.sequence([pulseUp, pulseDown])
        run(SKAction.repeatForever(swayCycle), withKey: "sway")
    }

    // MARK: - Looking Around

    private func scheduleNextLookAround() {
        let interval = TimeInterval.random(in: lookAroundMinInterval...lookAroundMaxInterval)
        let wait = SKAction.wait(forDuration: interval)
        let look = SKAction.run { [weak self] in self?.performLookAround() }
        run(SKAction.sequence([wait, look]), withKey: "lookAroundSchedule")
    }

    private func performLookAround() {
        guard !isLookingAround && !isPerformingAction else {
            scheduleNextLookAround()
            return
        }
        isLookingAround = true

        // Random direction to look
        let directions: [(x: CGFloat, y: CGFloat)] = [
            (1, 0),    // Right
            (-1, 0),   // Left
            (0, 0.5),  // Up slightly
            (1, 0.5),  // Up-right
            (-1, 0.5), // Up-left
        ]
        let dir = directions.randomElement()!

        // Move eyes to look in direction
        let lookOffset: CGFloat = 1.0
        let lookDuration: TimeInterval = 0.25
        let holdDuration = TimeInterval.random(in: 0.8...2.0)

        let moveToLook = SKAction.moveBy(x: dir.x * lookOffset, y: dir.y * lookOffset, duration: lookDuration)
        moveToLook.timingMode = .easeOut

        let hold = SKAction.wait(forDuration: holdDuration)

        let returnToCenter = SKAction.move(to: leftEyeBasePos, duration: lookDuration)
        returnToCenter.timingMode = .easeInEaseOut

        let returnToCenterRight = SKAction.move(to: rightEyeBasePos, duration: lookDuration)
        returnToCenterRight.timingMode = .easeInEaseOut

        let leftSequence = SKAction.sequence([moveToLook, hold, returnToCenter])
        let rightSequence = SKAction.sequence([moveToLook.copy() as! SKAction, hold, returnToCenterRight])

        leftEyeNode.run(leftSequence)
        rightEyeNode.run(rightSequence)

        // Schedule next look
        let totalDuration = lookDuration * 2 + holdDuration
        run(SKAction.sequence([
            SKAction.wait(forDuration: totalDuration),
            SKAction.run { [weak self] in
                self?.isLookingAround = false
                self?.scheduleNextLookAround()
            }
        ]))
    }

    // MARK: - Blinking

    private func scheduleNextBlink() {
        let interval = TimeInterval.random(in: blinkMinInterval...blinkMaxInterval)
        let wait = SKAction.wait(forDuration: interval)
        let blink = SKAction.run { [weak self] in self?.performBlink() }
        run(SKAction.sequence([wait, blink]), withKey: "blinkSchedule")
    }

    private func performBlink() {
        guard !isBlinking else { return }
        isBlinking = true

        // Quick, snappy blink
        let blinkAnimation = SKAction.animate(
            with: blinkFrames,
            timePerFrame: blinkDuration / Double(blinkFrames.count),
            resize: false,
            restore: true
        )

        let completion = SKAction.run { [weak self] in
            self?.isBlinking = false
            self?.scheduleNextBlink()
        }

        leftEyeNode.run(SKAction.sequence([blinkAnimation, completion]), withKey: "blink")
        rightEyeNode.run(blinkAnimation, withKey: "blink")
    }

    // MARK: - Whistling

    private func scheduleNextWhistle() {
        let interval = TimeInterval.random(in: whistleMinInterval...whistleMaxInterval)
        let wait = SKAction.wait(forDuration: interval)
        let whistle = SKAction.run { [weak self] in self?.performWhistle() }
        run(SKAction.sequence([wait, whistle]), withKey: "whistleSchedule")
    }

    private func performWhistle() {
        guard !isWhistling && !isPerformingAction else { return }
        isWhistling = true

        // Mouth animation with bounce
        mouthNode.setScale(0.8)
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: 1.1, duration: 0.1)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.08)
        let hold = SKAction.wait(forDuration: whistleDuration - 0.3)
        let popOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.scale(to: 0.8, duration: 0.15)
        ])
        mouthNode.run(SKAction.sequence([popIn, settle, hold, popOut]))

        // Spawn notes with varied timing and paths
        spawnMusicNote(delay: 0.2, variation: 0)
        spawnMusicNote(delay: 0.7, variation: 1)
        spawnMusicNote(delay: 1.2, variation: 2)

        // Slight body lift while whistling (scale-based)
        let liftUp = SKAction.scaleY(to: 1.03, duration: 0.3)
        liftUp.timingMode = .easeOut
        let holdLift = SKAction.wait(forDuration: whistleDuration - 0.5)
        let liftBack = SKAction.scaleY(to: 1.0, duration: 0.2)
        liftBack.timingMode = .easeInEaseOut
        run(SKAction.sequence([liftUp, holdLift, liftBack]), withKey: "whistleLift")

        let completion = SKAction.sequence([
            SKAction.wait(forDuration: whistleDuration + 0.2),
            SKAction.run { [weak self] in
                self?.isWhistling = false
                self?.scheduleNextWhistle()
            }
        ])
        run(completion, withKey: "whistleCompletion")
    }

    private func spawnMusicNote(delay: TimeInterval, variation: Int) {
        let note = SKSpriteNode(texture: musicNoteTexture)
        note.size = CGSize(width: 3, height: 5)
        note.position = CGPoint(x: 4, y: -2)
        note.alpha = 0
        note.zPosition = 3
        note.setScale(0.6)
        addChild(note)

        // Varied paths for each note
        let paths: [(dx: CGFloat, dy: CGFloat, rotation: CGFloat)] = [
            (5, 12, 0.3),
            (7, 10, -0.2),
            (4, 14, 0.4)
        ]
        let path = paths[variation % paths.count]

        let wait = SKAction.wait(forDuration: delay)

        // Pop in with bounce
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.12),
            SKAction.scale(to: 1.1, duration: 0.12)
        ])
        let settleScale = SKAction.scale(to: 1.0, duration: 0.08)

        // Float with slight wave motion
        let floatDuration: TimeInterval = 1.0
        let floatUp = SKAction.moveBy(x: path.dx, y: path.dy, duration: floatDuration)
        floatUp.timingMode = .easeOut

        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: path.rotation, duration: floatDuration / 2),
            SKAction.rotate(byAngle: -path.rotation, duration: floatDuration / 2)
        ])

        let fadeOut = SKAction.fadeOut(withDuration: 0.25)
        let floatSequence = SKAction.group([
            floatUp,
            wobble,
            SKAction.sequence([SKAction.wait(forDuration: floatDuration - 0.25), fadeOut])
        ])

        note.run(SKAction.sequence([wait, popIn, settleScale, floatSequence, SKAction.removeFromParent()]))
    }

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

        // Anticipation - slight crouch
        let anticipate = SKAction.scaleY(to: 0.95, duration: 0.08)
        anticipate.timingMode = .easeIn

        // Wave with decreasing amplitude
        let wave1L = SKAction.rotate(byAngle: 0.18, duration: 0.08)
        let wave1R = SKAction.rotate(byAngle: -0.36, duration: 0.12)
        let wave2L = SKAction.rotate(byAngle: 0.30, duration: 0.10)
        let wave2R = SKAction.rotate(byAngle: -0.24, duration: 0.10)
        let wave3L = SKAction.rotate(byAngle: 0.18, duration: 0.08)
        let wave3R = SKAction.rotate(byAngle: -0.12, duration: 0.08)
        let settle = SKAction.rotate(byAngle: 0.06, duration: 0.06)

        // Normalize scale
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

        // Anticipation - crouch before jump (squash)
        let crouch = SKAction.scaleY(to: 0.8, duration: 0.1)
        crouch.timingMode = .easeIn
        let crouchX = SKAction.scaleX(to: 1.15, duration: 0.1)
        crouchX.timingMode = .easeIn
        let anticipation = SKAction.group([crouch, crouchX])

        // Jump - stretch tall and thin (no position movement)
        let stretchUp = SKAction.scaleY(to: 1.25, duration: 0.12)
        stretchUp.timingMode = .easeOut
        let squeezeX = SKAction.scaleX(to: 0.85, duration: 0.12)
        squeezeX.timingMode = .easeOut

        let jumpPhase = SKAction.group([stretchUp, squeezeX])

        // Land - squash back down
        let landSquash = SKAction.scaleY(to: 0.8, duration: 0.08)
        landSquash.timingMode = .easeIn
        let landSquashX = SKAction.scaleX(to: 1.2, duration: 0.08)
        landSquashX.timingMode = .easeIn
        let landPhase = SKAction.group([landSquash, landSquashX])

        // Overshoot and settle
        let overshoot = SKAction.group([
            SKAction.scaleY(to: 1.08, duration: 0.08),
            SKAction.scaleX(to: 0.95, duration: 0.08)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        settle.timingMode = .easeOut

        let singleBounce = SKAction.sequence([anticipation, jumpPhase, landPhase, overshoot, settle])

        // Second smaller bounce
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

        // Happy squish
        let squish = SKAction.group([
            SKAction.scaleY(to: 0.9, duration: 0.08),
            SKAction.scaleX(to: 1.1, duration: 0.08)
        ])
        let unsquish = SKAction.scale(to: 1.0, duration: 0.1)
        unsquish.timingMode = .easeOut

        run(SKAction.sequence([squish, unsquish]))

        // Spawn multiple hearts
        spawnHeart(delay: 0, offsetX: 0, offsetY: 10, size: 1.0)
        spawnHeart(delay: 0.15, offsetX: -5, offsetY: 8, size: 0.7)
        spawnHeart(delay: 0.25, offsetX: 5, offsetY: 9, size: 0.8)

        let completion = SKAction.run { [weak self] in
            self?.isPerformingAction = false
        }
        run(SKAction.sequence([SKAction.wait(forDuration: 1.0), completion]))
    }

    private func spawnHeart(delay: TimeInterval, offsetX: CGFloat, offsetY: CGFloat, size: CGFloat) {
        let heart = SKSpriteNode(texture: heartTexture)
        heart.size = CGSize(width: 5 * size, height: 5 * size)
        heart.position = CGPoint(x: offsetX, y: offsetY)
        heart.alpha = 0
        heart.zPosition = 4
        heart.setScale(0.3)
        addChild(heart)

        let wait = SKAction.wait(forDuration: delay)

        // Pop in with overshoot
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: size * 1.3, duration: 0.15)
        ])
        popIn.timingMode = .easeOut

        let settleScale = SKAction.scale(to: size, duration: 0.1)
        settleScale.timingMode = .easeInEaseOut

        // Float up with gentle sway
        let floatDuration: TimeInterval = 0.7
        let floatUp = SKAction.moveBy(x: CGFloat.random(in: -2...2), y: 8, duration: floatDuration)
        floatUp.timingMode = .easeOut

        let pulse = SKAction.sequence([
            SKAction.scale(to: size * 1.1, duration: 0.15),
            SKAction.scale(to: size * 0.95, duration: 0.15)
        ])

        let fadeOut = SKAction.fadeOut(withDuration: 0.2)

        let floatSequence = SKAction.group([
            floatUp,
            pulse,
            SKAction.sequence([SKAction.wait(forDuration: floatDuration - 0.2), fadeOut])
        ])

        heart.run(SKAction.sequence([wait, popIn, settleScale, floatSequence, SKAction.removeFromParent()]))
    }

    // MARK: - Getting Idea Animation

    func performGettingIdea(completion: (() -> Void)? = nil) {
        guard !isPerformingAction else {
            completion?()
            return
        }
        isPerformingAction = true

        // Quick anticipation then perk up
        let crouch = SKAction.scaleY(to: 0.92, duration: 0.06)
        let perkUp = SKAction.scaleY(to: 1.12, duration: 0.12)
        perkUp.timingMode = .easeOut
        let hold = SKAction.wait(forDuration: 0.9)
        let settle = SKAction.scaleY(to: 1.0, duration: 0.15)
        settle.timingMode = .easeInEaseOut

        run(SKAction.sequence([crouch, perkUp, hold, settle]), withKey: "gettingIdeaBody")

        // Exclamation with bounce
        let exclamation = SKSpriteNode(texture: exclamationTexture)
        exclamation.size = CGSize(width: 3, height: 7)
        exclamation.position = CGPoint(x: 7, y: 14)
        exclamation.alpha = 0
        exclamation.zPosition = 4
        exclamation.setScale(0.3)
        addChild(exclamation)

        let delay = SKAction.wait(forDuration: 0.08)

        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.08),
            SKAction.scale(to: 1.4, duration: 0.12)
        ])
        popIn.timingMode = .easeOut

        // Bounce settle
        let bounce1 = SKAction.scale(to: 0.9, duration: 0.06)
        let bounce2 = SKAction.scale(to: 1.15, duration: 0.08)
        let bounce3 = SKAction.scale(to: 1.0, duration: 0.06)

        let holdExcl = SKAction.wait(forDuration: 0.6)
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)

        exclamation.run(SKAction.sequence([
            delay, popIn, bounce1, bounce2, bounce3, holdExcl, fadeOut, SKAction.removeFromParent()
        ]))

        let completionAction = SKAction.run { [weak self] in
            self?.isPerformingAction = false
            completion?()
        }
        run(SKAction.sequence([SKAction.wait(forDuration: 1.3), completionAction]))
    }

    // MARK: - Thinking Animation

    func performThinking(duration: TimeInterval = 2.0, completion: (() -> Void)? = nil) {
        guard !isPerformingAction else {
            completion?()
            return
        }
        isPerformingAction = true

        // Thought dots with staggered bounce
        let dotPositions: [CGPoint] = [
            CGPoint(x: 7, y: 9),
            CGPoint(x: 10, y: 10),
            CGPoint(x: 13, y: 9)
        ]

        for (index, pos) in dotPositions.enumerated() {
            let dot = SKSpriteNode(texture: thoughtDotTexture)
            dot.size = CGSize(width: 2, height: 2)
            dot.position = pos
            dot.alpha = 0
            dot.zPosition = 4
            dot.setScale(0.5)
            addChild(dot)

            let delay = SKAction.wait(forDuration: Double(index) * 0.2)

            // Pop in
            let popIn = SKAction.group([
                SKAction.fadeIn(withDuration: 0.1),
                SKAction.scale(to: 1.2, duration: 0.1)
            ])
            let settle = SKAction.scale(to: 1.0, duration: 0.08)

            // Continuous gentle bounce
            let bounceUp = SKAction.moveBy(x: 0, y: 0.8, duration: 0.4)
            bounceUp.timingMode = .easeInEaseOut
            let bounceDown = SKAction.moveBy(x: 0, y: -0.8, duration: 0.4)
            bounceDown.timingMode = .easeInEaseOut
            let bounceCycle = SKAction.sequence([bounceUp, bounceDown])
            let repeatBounce = SKAction.repeat(bounceCycle, count: Int(duration / 0.8))

            let fadeOut = SKAction.fadeOut(withDuration: 0.15)

            dot.run(SKAction.sequence([delay, popIn, settle, repeatBounce, fadeOut, SKAction.removeFromParent()]))
        }

        // Gentle pulse while thinking (scale-based)
        let pulseWide = SKAction.scaleX(to: 1.03, duration: 0.8)
        pulseWide.timingMode = .easeInEaseOut
        let pulseNormal = SKAction.scaleX(to: 0.97, duration: 0.8)
        pulseNormal.timingMode = .easeInEaseOut
        let pulseCycle = SKAction.sequence([pulseWide, pulseNormal])
        run(SKAction.repeat(pulseCycle, count: Int(duration / 1.6) + 1), withKey: "thinkingSway")

        let completionAction = SKAction.run { [weak self] in
            self?.isPerformingAction = false
            completion?()
        }
        run(SKAction.sequence([SKAction.wait(forDuration: duration + 0.3), completionAction]))
    }

    // MARK: - Celebrate Animation

    func performCelebrate(completion: (() -> Void)? = nil) {
        guard !isPerformingAction else {
            completion?()
            return
        }
        isPerformingAction = true

        // Anticipation - crouch
        let windUp = SKAction.group([
            SKAction.scaleY(to: 0.8, duration: 0.08),
            SKAction.scaleX(to: 1.15, duration: 0.08)
        ])

        // Jump - stretch tall (no position movement)
        let jumpStretch = SKAction.group([
            SKAction.scaleY(to: 1.3, duration: 0.12),
            SKAction.scaleX(to: 0.85, duration: 0.12)
        ])
        jumpStretch.timingMode = .easeOut

        // Land - squash
        let landSquash = SKAction.group([
            SKAction.scaleY(to: 0.82, duration: 0.08),
            SKAction.scaleX(to: 1.18, duration: 0.08)
        ])
        landSquash.timingMode = .easeIn

        let recover = SKAction.scale(to: 1.0, duration: 0.1)
        recover.timingMode = .easeOut

        let jump = SKAction.sequence([
            windUp,
            jumpStretch,
            landSquash,
            recover
        ])

        // Two jumps
        run(SKAction.sequence([jump, jump]), withKey: "celebrateJump")

        // Sparkles burst outward
        spawnCelebrateSparkles()

        // Wiggle with decreasing intensity
        let wiggle = SKAction.sequence([
            SKAction.rotate(byAngle: 0.12, duration: 0.05),
            SKAction.rotate(byAngle: -0.24, duration: 0.08),
            SKAction.rotate(byAngle: 0.18, duration: 0.06),
            SKAction.rotate(byAngle: -0.12, duration: 0.05),
            SKAction.rotate(byAngle: 0.06, duration: 0.04),
            SKAction.rotate(toAngle: 0, duration: 0.06)
        ])
        run(SKAction.sequence([SKAction.wait(forDuration: 0.1), wiggle, wiggle]), withKey: "celebrateWiggle")

        let completionAction = SKAction.run { [weak self] in
            self?.isPerformingAction = false
            completion?()
        }
        run(SKAction.sequence([SKAction.wait(forDuration: 1.2), completionAction]))
    }

    private func spawnCelebrateSparkles() {
        let positions: [(x: CGFloat, y: CGFloat, delay: TimeInterval)] = [
            (-8, 6, 0.0),
            (8, 8, 0.05),
            (-5, -2, 0.1),
            (10, 2, 0.08),
            (0, 12, 0.03),
            (-10, 0, 0.12),
            (6, -4, 0.15)
        ]

        for pos in positions {
            let sparkle = SKSpriteNode(texture: sparkleTexture)
            sparkle.size = CGSize(width: 5, height: 5)
            sparkle.position = CGPoint(x: pos.x * 0.3, y: pos.y * 0.3)  // Start near center
            sparkle.alpha = 0
            sparkle.zPosition = 4
            sparkle.setScale(0.2)
            addChild(sparkle)

            let delay = SKAction.wait(forDuration: pos.delay)

            // Burst outward
            let moveOut = SKAction.move(to: CGPoint(x: pos.x, y: pos.y), duration: 0.2)
            moveOut.timingMode = .easeOut

            let popIn = SKAction.group([
                SKAction.fadeIn(withDuration: 0.08),
                SKAction.scale(to: 1.3, duration: 0.15)
            ])

            let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.3)

            let settleAndFade = SKAction.group([
                SKAction.scale(to: 0.8, duration: 0.3),
                SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.fadeOut(withDuration: 0.15)])
            ])

            sparkle.run(SKAction.sequence([
                delay,
                SKAction.group([popIn, moveOut]),
                spin,
                settleAndFade,
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Confused Animation

    func performConfused(completion: (() -> Void)? = nil) {
        guard !isPerformingAction else {
            completion?()
            return
        }
        isPerformingAction = true

        // Slight deflate/droop using scale (no position movement, no rotation)
        let deflate = SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.group([
                SKAction.scaleY(to: 0.92, duration: 0.3),
                SKAction.scaleX(to: 1.05, duration: 0.3)
            ]),
            SKAction.wait(forDuration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.25)
        ])

        run(deflate, withKey: "confused")

        let completionAction = SKAction.run { [weak self] in
            self?.isPerformingAction = false
            completion?()
        }
        run(SKAction.sequence([SKAction.wait(forDuration: 1.2), completionAction]))
    }

    // MARK: - Sleep Animation

    func startSleeping() {
        guard !isPerformingAction else { return }
        isPerformingAction = true

        // Stop idle animations
        removeAction(forKey: "whistleSchedule")
        removeAction(forKey: "blinkSchedule")
        removeAction(forKey: "lookAroundSchedule")
        removeAction(forKey: "sway")

        // Slow droop into sleep using scale (no position movement)
        let droop = SKAction.scaleY(to: 0.95, duration: 0.5)
        droop.timingMode = .easeInEaseOut
        run(droop)

        // Close eyes with slight delay
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.run { [weak self] in
                let closedTexture = ClaudachiFaceSprites.generateEyeTexture(state: .closed)
                self?.leftEyeNode.texture = closedTexture
                self?.rightEyeNode.texture = closedTexture
            }
        ]))

        // Gentle sleeping breathing (scale-based)
        let sleepBreath = SKAction.sequence([
            SKAction.scaleX(to: 1.02, duration: 2.0),
            SKAction.scaleX(to: 0.98, duration: 2.0)
        ])
        sleepBreath.timingMode = .easeInEaseOut
        run(SKAction.repeatForever(sleepBreath), withKey: "sleepSway")

        // Start Z spawning after settling
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.8),
            SKAction.run { [weak self] in self?.spawnSleepZ() }
        ]))
    }

    private func spawnSleepZ() {
        guard isPerformingAction else { return }

        let z = SKSpriteNode(texture: zzzTexture)
        z.size = CGSize(width: 4, height: 5)
        z.position = CGPoint(x: 5, y: 5)
        z.alpha = 0
        z.zPosition = 4
        z.setScale(0.5)
        addChild(z)

        let fadeIn = SKAction.fadeIn(withDuration: 0.4)
        let floatUp = SKAction.moveBy(x: 5, y: 12, duration: 2.0)
        floatUp.timingMode = .easeOut
        let grow = SKAction.scale(to: 1.0, duration: 2.0)
        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.15, duration: 1.0),
            SKAction.rotate(byAngle: -0.15, duration: 1.0)
        ])
        let floatSequence = SKAction.group([floatUp, grow, wobble])
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)

        z.run(SKAction.sequence([fadeIn, floatSequence, fadeOut, SKAction.removeFromParent()]))

        // Schedule next Z
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in self?.spawnSleepZ() }
        ]), withKey: "sleepZSchedule")
    }

    func wakeUp(completion: (() -> Void)? = nil) {
        removeAction(forKey: "sleepZSchedule")
        removeAction(forKey: "sleepSway")

        // Open eyes
        leftEyeNode.texture = eyeOpenTexture
        rightEyeNode.texture = eyeOpenTexture

        // Wake up stretch (scale-based, no position movement)
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

    // MARK: - Coding Flow

    /// Perform the full coding sequence: idea → typing → result
    /// - Parameters:
    ///   - item: The item being "coded"
    ///   - codingDuration: How long to show the typing animation
    ///   - onCodingStart: Called when terminal appears and typing begins
    ///   - onComplete: Called when the entire sequence finishes (after celebration/failure)
    func performCodingSequence(
        item: String,
        codingDuration: TimeInterval = 3.0,
        onCodingStart: (() -> Void)? = nil,
        onSuccess: (() -> Void)? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        guard !isPerformingAction else {
            onComplete?()
            return
        }

        // Stop idle animations during coding
        pauseIdleAnimations()

        // Step 1: Getting idea animation
        performGettingIdea { [weak self] in
            guard let self = self else { return }

            // Step 2: Activate chef mode
            self.chefMode.activate {
                onCodingStart?()
            }

            // Step 3: Focused coding pose (slight squish toward terminal using scale)
            let focusPose = SKAction.group([
                SKAction.scaleX(to: 0.95, duration: 0.3),
                SKAction.scaleY(to: 1.02, duration: 0.3)
            ])
            focusPose.timingMode = .easeOut
            self.run(focusPose, withKey: "codingLean")

            // Step 4: After coding duration, show result
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: codingDuration),
                SKAction.run { [weak self] in
                    self?.finishCoding(success: true, onSuccess: onSuccess, onComplete: onComplete)
                }
            ]), withKey: "codingSequence")
        }
    }

    /// Finish the coding sequence with success or failure
    private func finishCoding(success: Bool, onSuccess: (() -> Void)?, onComplete: (() -> Void)?) {
        // Deactivate chef mode
        chefMode.deactivate(success: success)

        // Return to normal pose (scale-based)
        let resetPose = SKAction.scale(to: 1.0, duration: 0.2)
        resetPose.timingMode = .easeOut
        run(resetPose)

        // Wait for terminal to hide, then show result
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.run { [weak self] in
                guard let self = self else { return }

                if success {
                    onSuccess?()
                    self.performCelebrate {
                        self.resumeIdleAnimations()
                        onComplete?()
                    }
                } else {
                    self.performConfused {
                        self.resumeIdleAnimations()
                        onComplete?()
                    }
                }
            }
        ]))
    }

    /// Cancel an in-progress coding sequence
    func cancelCoding() {
        removeAction(forKey: "codingSequence")
        removeAction(forKey: "codingLean")
        chefMode.reset()

        // Reset to normal scale
        let resetScale = SKAction.scale(to: 1.0, duration: 0.2)
        run(resetScale)

        resumeIdleAnimations()
    }

    // MARK: - Async Coding Animation

    /// Start the coding animation (loops until stopCodingAnimation is called)
    /// - Parameter item: The item being coded (for display)
    func startCodingAnimation(item: String) {
        guard !isPerformingAction else { return }

        // Stop idle animations during coding
        pauseIdleAnimations()

        // Step 1: Getting idea animation, then activate chef mode
        performGettingIdea { [weak self] in
            guard let self = self else { return }

            // Step 2: Enter chef mode - swap textures!
            self.enterChefMode()

            // Step 3: Focused coding pose
            let focusPose = SKAction.group([
                SKAction.scaleX(to: 0.95, duration: 0.3),
                SKAction.scaleY(to: 1.02, duration: 0.3)
            ])
            focusPose.timingMode = .easeOut
            self.run(focusPose, withKey: "codingLean")
        }
    }

    /// Stop the coding animation and show result
    /// - Parameters:
    ///   - success: Whether coding succeeded
    ///   - completion: Called after the celebration/failure animation
    func stopCodingAnimation(success: Bool, completion: @escaping () -> Void) {
        // Exit chef mode - restore normal textures
        exitChefMode()

        // Return to normal pose
        let resetPose = SKAction.scale(to: 1.0, duration: 0.2)
        resetPose.timingMode = .easeOut
        run(resetPose)

        // Wait for transition, then show result
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                guard let self = self else { return }

                if success {
                    self.performCelebrate {
                        self.resumeIdleAnimations()
                        completion()
                    }
                } else {
                    self.performConfused {
                        self.resumeIdleAnimations()
                        completion()
                    }
                }
            }
        ]))
    }

    // MARK: - Chef Mode

    private func enterChefMode() {
        guard !isInChefMode else { return }
        isInChefMode = true

        // Swap body texture to chef apron version
        bodyNode.removeAction(forKey: "breathing")
        bodyNode.texture = chefBreathingFrames[1]

        // Start chef breathing animation
        let chefBreathe = SKAction.animate(
            with: chefBreathingFrames,
            timePerFrame: breathingDuration / 4,
            resize: false,
            restore: false
        )
        bodyNode.run(SKAction.repeatForever(chefBreathe), withKey: "breathing")

        // Drop chef hat from above with squish bounce
        hatNode.position.y = hatDropStartY
        hatNode.alpha = 1
        hatNode.setScale(1.0)

        let dropDown = SKAction.moveTo(y: hatBasePos.y, duration: 0.25)
        dropDown.timingMode = .easeIn

        // Squish on landing then bounce back
        let squish = SKAction.group([
            SKAction.scaleY(to: 0.8, duration: 0.06),
            SKAction.scaleX(to: 1.15, duration: 0.06)
        ])
        let bounce = SKAction.group([
            SKAction.scaleY(to: 1.1, duration: 0.08),
            SKAction.scaleX(to: 0.95, duration: 0.08)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.06)

        hatNode.run(SKAction.sequence([dropDown, squish, bounce, settle]))

        // Activate mixing bowl
        chefMode.activate()
    }

    private func exitChefMode() {
        guard isInChefMode else { return }
        isInChefMode = false

        // Swap body texture back to normal
        bodyNode.removeAction(forKey: "breathing")
        bodyNode.texture = breathingFrames[1]

        // Restart normal breathing animation
        let normalBreathe = SKAction.animate(
            with: breathingFrames,
            timePerFrame: breathingDuration / 4,
            resize: false,
            restore: false
        )
        bodyNode.run(SKAction.repeatForever(normalBreathe), withKey: "breathing")

        // Hat floats up and fades
        let floatUp = SKAction.group([
            SKAction.moveTo(y: 18, duration: 0.3),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.rotate(byAngle: 0.15, duration: 0.3)
        ])
        floatUp.timingMode = .easeOut
        hatNode.run(floatUp)

        // Deactivate mixing bowl
        chefMode.deactivate(success: true)
    }

    // MARK: - Drag Animation

    /// Start a subtle wiggle when being dragged - arms wave up/down, legs kick in/out
    func startDragWiggle() {
        guard !isDragging else { return }
        isDragging = true

        // Arms wave up and down at an angle (rotate around attachment point)
        let armWiggleDuration: TimeInterval = 0.12

        // Left arm - waves up and down
        let leftArmUp = SKAction.rotate(toAngle: 0.4, duration: armWiggleDuration)
        let leftArmDown = SKAction.rotate(toAngle: -0.3, duration: armWiggleDuration)
        leftArmUp.timingMode = .easeInEaseOut
        leftArmDown.timingMode = .easeInEaseOut
        let leftArmWiggle = SKAction.sequence([leftArmUp, leftArmDown])
        leftArmNode.run(SKAction.repeatForever(leftArmWiggle), withKey: "dragWiggle")

        // Right arm - opposite phase
        let rightArmUp = SKAction.rotate(toAngle: -0.4, duration: armWiggleDuration)
        let rightArmDown = SKAction.rotate(toAngle: 0.3, duration: armWiggleDuration)
        rightArmUp.timingMode = .easeInEaseOut
        rightArmDown.timingMode = .easeInEaseOut
        let rightArmWiggle = SKAction.sequence([rightArmDown, rightArmUp])
        rightArmNode.run(SKAction.repeatForever(rightArmWiggle), withKey: "dragWiggle")

        // Legs kick in and out at an angle
        let legWiggleDuration: TimeInterval = 0.15

        // Left foot - kicks outward and inward
        let leftFootOut = SKAction.rotate(toAngle: -0.35, duration: legWiggleDuration)
        let leftFootIn = SKAction.rotate(toAngle: 0.2, duration: legWiggleDuration)
        leftFootOut.timingMode = .easeInEaseOut
        leftFootIn.timingMode = .easeInEaseOut
        let leftFootWiggle = SKAction.sequence([leftFootOut, leftFootIn])
        leftFootNode.run(SKAction.repeatForever(leftFootWiggle), withKey: "dragWiggle")

        // Right foot - opposite phase
        let rightFootOut = SKAction.rotate(toAngle: 0.35, duration: legWiggleDuration)
        let rightFootIn = SKAction.rotate(toAngle: -0.2, duration: legWiggleDuration)
        rightFootOut.timingMode = .easeInEaseOut
        rightFootIn.timingMode = .easeInEaseOut
        let rightFootWiggle = SKAction.sequence([rightFootIn, rightFootOut])
        rightFootNode.run(SKAction.repeatForever(rightFootWiggle), withKey: "dragWiggle")

        // Start spawning sweat drops
        spawnSweatDrop()
    }

    /// Stop the drag wiggle and return to normal
    func stopDragWiggle() {
        guard isDragging else { return }
        isDragging = false

        // Stop sweat drop spawning
        removeAction(forKey: "sweatDropSchedule")

        // Stop all limb wiggling
        leftArmNode.removeAction(forKey: "dragWiggle")
        rightArmNode.removeAction(forKey: "dragWiggle")
        leftFootNode.removeAction(forKey: "dragWiggle")
        rightFootNode.removeAction(forKey: "dragWiggle")

        // Return limbs to neutral rotation
        let resetDuration: TimeInterval = 0.15
        let resetRotation = SKAction.rotate(toAngle: 0, duration: resetDuration)
        resetRotation.timingMode = .easeOut

        leftArmNode.run(resetRotation)
        rightArmNode.run(resetRotation)
        leftFootNode.run(resetRotation)
        rightFootNode.run(resetRotation)
    }

    private func spawnSweatDrop() {
        guard isDragging else { return }

        // Spawn a sweat drop from the top edges of the sprite
        let drop = SKSpriteNode(texture: sweatDropTexture)
        drop.size = CGSize(width: 3, height: 6)

        // Randomly spawn from left or right edge of head
        let isLeftSide = Bool.random()
        let xOffset: CGFloat = isLeftSide ? CGFloat.random(in: -8 ... -5) : CGFloat.random(in: 5...8)
        drop.position = CGPoint(x: xOffset, y: 5)
        drop.alpha = 0
        drop.zPosition = 4
        drop.setScale(0.8)

        // Angle the drop slightly outward
        drop.zRotation = isLeftSide ? 0.2 : -0.2
        addChild(drop)

        // Pop in
        let fadeIn = SKAction.fadeIn(withDuration: 0.08)

        // Fall down at an angle (outward from the side it spawned)
        let fallDuration: TimeInterval = 0.5
        let fallDistance: CGFloat = 22
        let horizontalDrift: CGFloat = isLeftSide ? -3 : 3  // Drift outward

        let fallDown = SKAction.moveBy(x: horizontalDrift, y: -fallDistance, duration: fallDuration)
        fallDown.timingMode = .easeIn

        // Fade out near the end
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: fallDuration * 0.6),
            SKAction.fadeOut(withDuration: fallDuration * 0.4)
        ])

        drop.run(SKAction.sequence([
            fadeIn,
            SKAction.group([fallDown, fadeOut]),
            SKAction.removeFromParent()
        ]))

        // Schedule next sweat drop
        let nextDelay = TimeInterval.random(in: 0.5...0.9)
        run(SKAction.sequence([
            SKAction.wait(forDuration: nextDelay),
            SKAction.run { [weak self] in self?.spawnSweatDrop() }
        ]), withKey: "sweatDropSchedule")
    }

    // MARK: - Idle Animation Control

    private func pauseIdleAnimations() {
        removeAction(forKey: "sway")
        removeAction(forKey: "whistleSchedule")
        removeAction(forKey: "blinkSchedule")
        removeAction(forKey: "lookAroundSchedule")
        isWhistling = false
        isLookingAround = false
    }

    private func resumeIdleAnimations() {
        isPerformingAction = false
        // Ensure scale is reset to normal before resuming
        setScale(1.0)
        startSwayAnimation()
        scheduleNextBlink()
        scheduleNextWhistle()
        scheduleNextLookAround()
    }
}
