//
//  ClaudachiSprite.swift
//  Claudachi
//

import SpriteKit

/// Main Claudachi character sprite with layered composition and idle animations
class ClaudachiSprite: SKNode {

    // MARK: - Sprite Layers

    private var bodyNode: SKSpriteNode!
    private var leftEyeNode: SKSpriteNode!
    private var rightEyeNode: SKSpriteNode!
    private var mouthNode: SKSpriteNode!

    // MARK: - Animation Textures

    private var breathingFrames: [SKTexture] = []
    private var eyeOpenTexture: SKTexture!
    private var blinkFrames: [SKTexture] = []
    private var whistleMouthTexture: SKTexture!
    private var musicNoteTexture: SKTexture!

    // MARK: - Animation State

    private var isBlinking = false
    private var isWhistling = false

    // MARK: - Animation Constants

    private let breathingDuration: TimeInterval = 2.5  // Full breathing cycle
    private let blinkMinInterval: TimeInterval = 3.0   // Minimum time between blinks
    private let blinkMaxInterval: TimeInterval = 8.0   // Maximum time between blinks
    private let blinkDuration: TimeInterval = 0.25     // Duration of blink animation
    private let whistleMinInterval: TimeInterval = 8.0  // Minimum time between whistles
    private let whistleMaxInterval: TimeInterval = 15.0 // Maximum time between whistles
    private let whistleDuration: TimeInterval = 1.5     // How long the whistle lasts

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
    }

    private func setupSprites() {
        // Body (Layer 1)
        bodyNode = SKSpriteNode(texture: breathingFrames[1]) // Start at neutral
        bodyNode.size = CGSize(width: 32, height: 32)
        bodyNode.position = .zero
        bodyNode.zPosition = 1
        addChild(bodyNode)

        // Left Eye (Layer 2) - simple 3x4 dark pupil
        leftEyeNode = SKSpriteNode(texture: eyeOpenTexture)
        leftEyeNode.size = CGSize(width: 3, height: 4)
        leftEyeNode.position = CGPoint(x: -4, y: 4)
        leftEyeNode.zPosition = 2
        addChild(leftEyeNode)

        // Right Eye (Layer 2) - simple 3x4 dark pupil
        rightEyeNode = SKSpriteNode(texture: eyeOpenTexture)
        rightEyeNode.size = CGSize(width: 3, height: 4)
        rightEyeNode.position = CGPoint(x: 4, y: 4)
        rightEyeNode.zPosition = 2
        addChild(rightEyeNode)

        // Mouth (Layer 2) - hidden by default, shown during whistle
        mouthNode = SKSpriteNode(texture: whistleMouthTexture)
        mouthNode.size = CGSize(width: 3, height: 3)
        mouthNode.position = CGPoint(x: 0, y: -1)
        mouthNode.zPosition = 2
        mouthNode.alpha = 0  // Hidden by default
        addChild(mouthNode)
    }

    // MARK: - Animations

    private func startAnimations() {
        startBreathingAnimation()
        scheduleNextBlink()
        scheduleNextWhistle()
    }

    private func startBreathingAnimation() {
        // Body texture animation
        let breatheAction = SKAction.animate(
            with: breathingFrames,
            timePerFrame: breathingDuration / Double(breathingFrames.count),
            resize: false,
            restore: false
        )
        let repeatBreathing = SKAction.repeatForever(breatheAction)
        bodyNode.run(repeatBreathing, withKey: "breathing")

        // Subtle vertical movement for face elements to follow body
        let faceBreathUp = SKAction.moveBy(x: 0, y: 0.5, duration: breathingDuration / 2)
        let faceBreathDown = SKAction.moveBy(x: 0, y: -0.5, duration: breathingDuration / 2)
        faceBreathUp.timingMode = .easeInEaseOut
        faceBreathDown.timingMode = .easeInEaseOut
        let faceBreathCycle = SKAction.sequence([faceBreathUp, faceBreathDown])
        let repeatFaceBreath = SKAction.repeatForever(faceBreathCycle)

        leftEyeNode.run(repeatFaceBreath, withKey: "faceBreathing")
        rightEyeNode.run(repeatFaceBreath.copy() as! SKAction, withKey: "faceBreathing")
    }

    // MARK: - Whistling

    private func scheduleNextWhistle() {
        let interval = TimeInterval.random(in: whistleMinInterval...whistleMaxInterval)

        let waitAction = SKAction.wait(forDuration: interval)
        let whistleAction = SKAction.run { [weak self] in
            self?.performWhistle()
        }
        run(SKAction.sequence([waitAction, whistleAction]), withKey: "whistleSchedule")
    }

    private func performWhistle() {
        guard !isWhistling else { return }
        isWhistling = true

        // Show mouth
        let showMouth = SKAction.fadeIn(withDuration: 0.1)
        let hideMouth = SKAction.fadeOut(withDuration: 0.1)
        let waitDuration = SKAction.wait(forDuration: whistleDuration)
        let mouthSequence = SKAction.sequence([showMouth, waitDuration, hideMouth])
        mouthNode.run(mouthSequence)

        // Spawn floating music notes
        spawnMusicNote(delay: 0.0)
        spawnMusicNote(delay: 0.5)
        spawnMusicNote(delay: 1.0)

        // Schedule next whistle
        let completionWait = SKAction.wait(forDuration: whistleDuration + 0.2)
        let completionAction = SKAction.run { [weak self] in
            self?.isWhistling = false
            self?.scheduleNextWhistle()
        }
        run(SKAction.sequence([completionWait, completionAction]), withKey: "whistleCompletion")
    }

    private func spawnMusicNote(delay: TimeInterval) {
        let note = SKSpriteNode(texture: musicNoteTexture)
        note.size = CGSize(width: 3, height: 5)
        note.position = CGPoint(x: 5, y: 2)
        note.alpha = 0
        note.zPosition = 3
        addChild(note)

        // Animate: fade in, float up and right, fade out
        let wait = SKAction.wait(forDuration: delay)
        let fadeIn = SKAction.fadeIn(withDuration: 0.15)
        let moveUp = SKAction.moveBy(x: 6, y: 10, duration: 0.8)
        moveUp.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let moveAndFade = SKAction.group([moveUp, SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            fadeOut
        ])])
        let remove = SKAction.removeFromParent()

        note.run(SKAction.sequence([wait, fadeIn, moveAndFade, remove]))
    }

    // MARK: - Blinking

    private func scheduleNextBlink() {
        let interval = TimeInterval.random(in: blinkMinInterval...blinkMaxInterval)

        let waitAction = SKAction.wait(forDuration: interval)
        let blinkAction = SKAction.run { [weak self] in
            self?.performBlink()
        }
        run(SKAction.sequence([waitAction, blinkAction]), withKey: "blinkSchedule")
    }

    private func performBlink() {
        guard !isBlinking else { return }
        isBlinking = true

        let blinkAnimation = SKAction.animate(
            with: blinkFrames,
            timePerFrame: blinkDuration / Double(blinkFrames.count),
            resize: false,
            restore: true
        )

        let completionAction = SKAction.run { [weak self] in
            self?.isBlinking = false
            self?.scheduleNextBlink()
        }

        let fullBlinkSequence = SKAction.sequence([blinkAnimation, completionAction])

        // Both eyes blink together
        leftEyeNode.run(fullBlinkSequence, withKey: "blink")
        rightEyeNode.run(blinkAnimation, withKey: "blink")
    }

    // MARK: - Public Methods

    /// Trigger a blink immediately (e.g., when clicked)
    func triggerBlink() {
        removeAction(forKey: "blinkSchedule")
        performBlink()
    }
}
