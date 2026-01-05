//
//  ClawdachiSprite.swift
//  Clawdachi
//
//  Main Clawdachi character sprite with layered composition.
//  Animation methods are in extension files under Animation/
//

import SpriteKit

/// Main Clawdachi character sprite with layered composition and polished animations
class ClawdachiSprite: SKNode {

    // MARK: - Sprite Layers (internal for extension access)

    var bodyNode: SKSpriteNode!
    var leftEyeNode: SKSpriteNode!
    var rightEyeNode: SKSpriteNode!
    var mouthNode: SKSpriteNode!

    // Limbs (separate nodes for animation)
    var leftArmNode: SKSpriteNode!
    var rightArmNode: SKSpriteNode!
    var outerLeftLegNode: SKSpriteNode!
    var innerLeftLegNode: SKSpriteNode!
    var innerRightLegNode: SKSpriteNode!
    var outerRightLegNode: SKSpriteNode!

    // MARK: - Animation Textures (internal for extension access)

    var breathingFrames: [SKTexture] = []
    var eyeOpenTexture: SKTexture!
    var eyeClosedTexture: SKTexture!
    var eyeSquintTexture: SKTexture!
    var blinkFrames: [SKTexture] = []
    var whistleMouthTexture: SKTexture!
    var musicNoteTexture: SKTexture!
    var doubleNoteTexture: SKTexture!
    var heartTexture: SKTexture!
    var zzzTexture: SKTexture!
    var smileMouthTexture: SKTexture!
    var yawnMouthTexture: SKTexture!
    var sweatDropTexture: SKTexture!

    // MARK: - Animation State (internal for extension access)

    var isBlinking = false
    var isWhistling = false
    var isPerformingAction = false
    var isLookingAround = false
    var isDragging = false
    var isDancing = false

    // MARK: - Eye Tracking State

    var eyeBreathPhase: CGFloat = 0
    var currentEyeOffset: CGPoint = .zero
    var targetEyeOffset: CGPoint = .zero
    var isMouseTrackingEnabled = true
    var lastEyeUpdateTime: TimeInterval = 0
    var lastMousePosition: CGPoint = .zero

    // MARK: - Position Aliases

    var leftEyeBasePos: CGPoint { SpritePositions.leftEye }
    var rightEyeBasePos: CGPoint { SpritePositions.rightEye }
    var leftArmBasePos: CGPoint { SpritePositions.leftArm }
    var rightArmBasePos: CGPoint { SpritePositions.rightArm }
    var outerLeftLegBasePos: CGPoint { SpritePositions.outerLeftLeg }
    var innerLeftLegBasePos: CGPoint { SpritePositions.innerLeftLeg }
    var innerRightLegBasePos: CGPoint { SpritePositions.innerRightLeg }
    var outerRightLegBasePos: CGPoint { SpritePositions.outerRightLeg }

    // MARK: - Timing Aliases

    var breathingDuration: TimeInterval { AnimationTimings.breathingDuration }
    var swayDuration: TimeInterval { AnimationTimings.swayDuration }
    var blinkMinInterval: TimeInterval { AnimationTimings.blinkMinInterval }
    var blinkMaxInterval: TimeInterval { AnimationTimings.blinkMaxInterval }
    var blinkDuration: TimeInterval { AnimationTimings.blinkDuration }
    var whistleMinInterval: TimeInterval { AnimationTimings.whistleMinInterval }
    var whistleMaxInterval: TimeInterval { AnimationTimings.whistleMaxInterval }
    var whistleDuration: TimeInterval { AnimationTimings.whistleDuration }
    var lookAroundMinInterval: TimeInterval { AnimationTimings.lookAroundMinInterval }
    var lookAroundMaxInterval: TimeInterval { AnimationTimings.lookAroundMaxInterval }

    // MARK: - Initialization

    override init() {
        super.init()
        generateTextures()
        setupSprites()
        startAnimations()  // Defined in ClawdachiSprite+Idle.swift
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeAllActions()
    }

    // MARK: - Setup

    private func generateTextures() {
        breathingFrames = ClawdachiBodySprites.generateBreathingFrames()
        blinkFrames = ClawdachiFaceSprites.generateBlinkFrames()
        eyeOpenTexture = ClawdachiFaceSprites.generateEyeTexture(state: .open)
        eyeClosedTexture = ClawdachiFaceSprites.generateEyeTexture(state: .closed)
        eyeSquintTexture = ClawdachiFaceSprites.generateEyeTexture(state: .squint)
        whistleMouthTexture = ClawdachiFaceSprites.generateWhistleMouthTexture()
        musicNoteTexture = ClawdachiFaceSprites.generateMusicNoteTexture()
        doubleNoteTexture = ClawdachiFaceSprites.generateDoubleNoteTexture()

        heartTexture = ClawdachiFaceSprites.generateHeartTexture()
        zzzTexture = ClawdachiFaceSprites.generateZzzTexture()
        smileMouthTexture = ClawdachiFaceSprites.generateSmileMouthTexture()
        yawnMouthTexture = ClawdachiFaceSprites.generateYawnMouthTexture()
        sweatDropTexture = ClawdachiFaceSprites.generateSweatDropTexture()
    }

    private func setupSprites() {
        // Limbs first (Layer 0) - behind body
        leftArmNode = SKSpriteNode(texture: ClawdachiBodySprites.generateLeftArmTexture())
        leftArmNode.size = CGSize(width: 3, height: 3)
        leftArmNode.position = leftArmBasePos
        leftArmNode.anchorPoint = CGPoint(x: 1.0, y: 0.5)
        leftArmNode.zPosition = 0
        addChild(leftArmNode)

        rightArmNode = SKSpriteNode(texture: ClawdachiBodySprites.generateRightArmTexture())
        rightArmNode.size = CGSize(width: 3, height: 3)
        rightArmNode.position = rightArmBasePos
        rightArmNode.anchorPoint = CGPoint(x: 0.0, y: 0.5)
        rightArmNode.zPosition = 0
        addChild(rightArmNode)

        outerLeftLegNode = SKSpriteNode(texture: ClawdachiBodySprites.generateLeftLegTexture())
        outerLeftLegNode.size = CGSize(width: 2, height: 5)
        outerLeftLegNode.position = outerLeftLegBasePos
        outerLeftLegNode.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        outerLeftLegNode.zPosition = 0
        addChild(outerLeftLegNode)

        innerLeftLegNode = SKSpriteNode(texture: ClawdachiBodySprites.generateLeftLegTexture())
        innerLeftLegNode.size = CGSize(width: 2, height: 5)
        innerLeftLegNode.position = innerLeftLegBasePos
        innerLeftLegNode.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        innerLeftLegNode.zPosition = 0
        addChild(innerLeftLegNode)

        innerRightLegNode = SKSpriteNode(texture: ClawdachiBodySprites.generateRightLegTexture())
        innerRightLegNode.size = CGSize(width: 2, height: 5)
        innerRightLegNode.position = innerRightLegBasePos
        innerRightLegNode.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        innerRightLegNode.zPosition = 0
        addChild(innerRightLegNode)

        outerRightLegNode = SKSpriteNode(texture: ClawdachiBodySprites.generateRightLegTexture())
        outerRightLegNode.size = CGSize(width: 2, height: 5)
        outerRightLegNode.position = outerRightLegBasePos
        outerRightLegNode.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        outerRightLegNode.zPosition = 0
        addChild(outerRightLegNode)

        // Body (Layer 1)
        bodyNode = SKSpriteNode(texture: breathingFrames[1])
        bodyNode.size = CGSize(width: 32, height: 32)
        bodyNode.position = .zero
        bodyNode.zPosition = 1
        addChild(bodyNode)

        // Left Eye (Layer 2)
        leftEyeNode = SKSpriteNode(texture: eyeOpenTexture)
        leftEyeNode.size = CGSize(width: 2, height: 3)
        leftEyeNode.position = leftEyeBasePos
        leftEyeNode.zPosition = 2
        addChild(leftEyeNode)

        // Right Eye (Layer 2)
        rightEyeNode = SKSpriteNode(texture: eyeOpenTexture)
        rightEyeNode.size = CGSize(width: 2, height: 3)
        rightEyeNode.position = rightEyeBasePos
        rightEyeNode.zPosition = 2
        addChild(rightEyeNode)

        // Mouth (Layer 2) - hidden by default, positioned to right for side whistle
        mouthNode = SKSpriteNode(texture: whistleMouthTexture)
        mouthNode.size = CGSize(width: 3, height: 3)
        mouthNode.position = CGPoint(x: 5, y: -2)
        mouthNode.zPosition = 2
        mouthNode.alpha = 0
        addChild(mouthNode)
    }
}
