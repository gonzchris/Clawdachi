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
    var outfitNode: SKSpriteNode!
    var hatNode: SKSpriteNode!
    var glassesNode: SKSpriteNode!
    var heldItemNode: SKSpriteNode!
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
    var cigaretteTexture: SKTexture!
    var smokeTexture: SKTexture!
    var speakingOpenMouthTexture: SKTexture!
    var speakingClosedMouthTexture: SKTexture!

    // MARK: - State Machine

    /// Centralized state manager for animation states
    let stateManager = SpriteStateManager()

    /// Current sprite state (convenience accessor)
    var currentState: SpriteState { stateManager.currentState }

    // MARK: - Animation State

    // Overlay behaviors (can occur during any primary state, not mutually exclusive)
    var isBlinking = false
    var isSpeaking = false

    // MARK: - Idle Animation Cycle

    /// Which idle animation (whistle or smoke) comes next in the alternating cycle
    enum IdleAnimationType {
        case whistle
        case smoke
    }

    /// Tracks which idle animation is next (instance-based, not static)
    var nextIdleAnimation: IdleAnimationType = .whistle

    // MARK: - Mouth Ownership System

    /// Which animation currently owns the mouth (prevents conflicts)
    enum MouthOwner: String {
        case none
        case whistling
        case speaking
        case dragging
        case smoking
    }

    /// Current owner of the mouth animation
    private(set) var currentMouthOwner: MouthOwner = .none

    /// Request ownership of the mouth for an animation
    /// - Parameters:
    ///   - owner: The animation requesting ownership
    /// - Returns: True if ownership was granted, false if denied
    func acquireMouth(for owner: MouthOwner) -> Bool {
        // Speaking can briefly interrupt whistling (common case)
        if currentMouthOwner == .whistling && owner == .speaking {
            return true
        }
        // Otherwise, only acquire if mouth is free
        guard currentMouthOwner == .none else { return false }
        currentMouthOwner = owner
        return true
    }

    /// Release ownership of the mouth
    /// - Parameter owner: The animation releasing ownership
    func releaseMouth(from owner: MouthOwner) {
        if currentMouthOwner == owner {
            currentMouthOwner = .none
            // Reset mouth to default state
            mouthNode.alpha = 0
            mouthNode.position = SpritePositions.mouth
            mouthNode.texture = whistleMouthTexture
        }
    }

    /// Force release mouth ownership (for cleanup)
    func forceReleaseMouth() {
        currentMouthOwner = .none
    }

    // MARK: - State Machine Computed Properties
    // These provide backwards-compatible boolean access to the centralized state machine

    var isWhistling: Bool {
        get { currentState == .whistling }
        set { if newValue { stateManager.transitionTo(.whistling) } else if currentState == .whistling { stateManager.transitionTo(.idle) } }
    }
    var isPerformingAction: Bool {
        get { currentState == .performingAction }
        set { if newValue { stateManager.transitionTo(.performingAction) } else if currentState == .performingAction { stateManager.transitionTo(.idle) } }
    }
    var isLookingAround: Bool {
        get { currentState == .lookingAround }
        set { if newValue { stateManager.transitionTo(.lookingAround) } else if currentState == .lookingAround { stateManager.transitionTo(.idle) } }
    }
    // Dragging is an overlay behavior (like blinking/speaking) - can occur during any state
    var isDragging = false
    var isDancing: Bool {
        get { currentState == .dancing }
        set { if newValue { stateManager.transitionTo(.dancing) } else if currentState == .dancing { stateManager.transitionTo(.idle) } }
    }
    var isSmoking: Bool {
        get { currentState == .smoking }
        set { if newValue { stateManager.transitionTo(.smoking) } else if currentState == .smoking { stateManager.transitionTo(.idle) } }
    }

    // Claude integration states
    var isClaudeThinking: Bool {
        get { currentState == .claudeThinking }
        set { if newValue { stateManager.transitionTo(.claudeThinking) } else if currentState == .claudeThinking { stateManager.transitionTo(.idle) } }
    }
    var isClaudePlanning: Bool {
        get { currentState == .claudePlanning }
        set { if newValue { stateManager.transitionTo(.claudePlanning) } else if currentState == .claudePlanning { stateManager.transitionTo(.idle) } }
    }
    var isClaudeWaiting: Bool {
        get { currentState == .claudeWaiting }
        set { if newValue { stateManager.transitionTo(.claudeWaiting) } else if currentState == .claudeWaiting { stateManager.transitionTo(.idle) } }
    }
    var isClaudeCelebrating: Bool {
        get { currentState == .claudeCelebrating }
        set { if newValue { stateManager.transitionTo(.claudeCelebrating) } else if currentState == .claudeCelebrating { stateManager.transitionTo(.idle) } }
    }

    // Smoking animation node (created/destroyed during animation)
    var cigaretteNode: SKSpriteNode?
    // Controls tip smoke to prevent particle overload during puffs
    var tipSmokeEnabled = true

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
    var smokingMinInterval: TimeInterval { AnimationTimings.smokingMinInterval }
    var smokingMaxInterval: TimeInterval { AnimationTimings.smokingMaxInterval }
    var smokingDuration: TimeInterval { AnimationTimings.smokingDuration }
    var smokePuffInterval: TimeInterval { AnimationTimings.smokePuffInterval }

    // MARK: - Initialization

    override init() {
        super.init()
        generateTextures()
        setupSprites()
        setupNotifications()
        startAnimations()  // Defined in ClawdachiSprite+Idle.swift
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeAllActions()
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClosetChange),
            name: .closetItemChanged,
            object: nil
        )
    }

    @objc private func handleClosetChange() {
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            self?.updateOutfit()
            self?.updateHat()
            self?.updateGlasses()
            self?.updateHeldItem()
        }
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
        cigaretteTexture = ClawdachiFaceSprites.generateCigaretteTexture()
        smokeTexture = ClawdachiFaceSprites.generateSmokeParticleTexture()
        speakingOpenMouthTexture = ClawdachiFaceSprites.generateSpeakingOpenMouthTexture()
        speakingClosedMouthTexture = ClawdachiFaceSprites.generateSpeakingClosedMouthTexture()
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

        // Outfit overlay (sibling of face elements so it bobs in sync)
        outfitNode = SKSpriteNode()
        outfitNode.size = CGSize(width: 32, height: 32)
        outfitNode.position = .zero
        outfitNode.zPosition = 1.5  // Between body and face
        outfitNode.alpha = 0  // Hidden by default
        addChild(outfitNode)

        // Hat overlay (on top of head)
        hatNode = SKSpriteNode()
        hatNode.size = CGSize(width: 32, height: 32)
        hatNode.position = .zero
        hatNode.zPosition = 3  // On top of everything
        hatNode.alpha = 0  // Hidden by default
        addChild(hatNode)

        // Glasses overlay (over eyes)
        glassesNode = SKSpriteNode()
        glassesNode.size = CGSize(width: 32, height: 32)
        glassesNode.position = .zero
        glassesNode.zPosition = 2.5  // Above face, below hat
        glassesNode.alpha = 0  // Hidden by default
        addChild(glassesNode)

        // Held item overlay (in front of body, behind face)
        heldItemNode = SKSpriteNode()
        heldItemNode.size = CGSize(width: 32, height: 32)
        heldItemNode.position = .zero
        heldItemNode.zPosition = 1.6  // In front of outfit
        heldItemNode.alpha = 0  // Hidden by default
        addChild(heldItemNode)

        // Apply any equipped outfit, hat, glasses, and held item
        updateOutfit()
        updateHat()
        updateGlasses()
        updateHeldItem()

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
        mouthNode.position = SpritePositions.mouth  // Default center position
        mouthNode.zPosition = 2
        mouthNode.alpha = 0
        addChild(mouthNode)
    }

    // MARK: - Outfit Management

    /// Updates the outfit overlay based on currently equipped outfit
    func updateOutfit() {
        let equippedOutfit = ClosetManager.shared.equippedOutfit

        if let outfit = equippedOutfit,
           let texture = ClawdachiOutfitSprites.texture(for: outfit.id) {
            outfitNode.texture = texture
            outfitNode.alpha = 1

            // Swap limb textures for specific outfits
            if outfit.id == "astronaut" {
                leftArmNode.texture = ClawdachiBodySprites.generateWhiteLeftArmTexture()
                rightArmNode.texture = ClawdachiBodySprites.generateWhiteRightArmTexture()
                outerLeftLegNode.texture = ClawdachiBodySprites.generateWhiteLeftLegTexture()
                innerLeftLegNode.texture = ClawdachiBodySprites.generateWhiteLeftLegTexture()
                innerRightLegNode.texture = ClawdachiBodySprites.generateWhiteRightLegTexture()
                outerRightLegNode.texture = ClawdachiBodySprites.generateWhiteRightLegTexture()
            } else if outfit.id == "pirate" {
                leftArmNode.texture = ClawdachiBodySprites.generatePirateLeftArmTexture()
                rightArmNode.texture = ClawdachiBodySprites.generatePirateRightArmTexture()
                outerLeftLegNode.texture = ClawdachiBodySprites.generatePirateLeftLegTexture()
                innerLeftLegNode.texture = ClawdachiBodySprites.generatePirateLeftLegTexture()
                innerRightLegNode.texture = ClawdachiBodySprites.generatePirateRightLegTexture()
                outerRightLegNode.texture = ClawdachiBodySprites.generatePirateRightLegTexture()
            } else {
                restoreNormalLimbTextures()
            }
        } else {
            outfitNode.texture = nil
            outfitNode.alpha = 0
            restoreNormalLimbTextures()
        }
    }

    /// Restores limb textures to normal orange colors
    private func restoreNormalLimbTextures() {
        leftArmNode.texture = ClawdachiBodySprites.generateLeftArmTexture()
        rightArmNode.texture = ClawdachiBodySprites.generateRightArmTexture()
        outerLeftLegNode.texture = ClawdachiBodySprites.generateLeftLegTexture()
        innerLeftLegNode.texture = ClawdachiBodySprites.generateLeftLegTexture()
        innerRightLegNode.texture = ClawdachiBodySprites.generateRightLegTexture()
        outerRightLegNode.texture = ClawdachiBodySprites.generateRightLegTexture()
    }

    // MARK: - Hat Management

    /// Updates the hat overlay based on currently equipped hat
    func updateHat() {
        let equippedHat = ClosetManager.shared.equippedHat

        if let hat = equippedHat,
           let texture = ClawdachiOutfitSprites.hatTexture(for: hat.id) {
            hatNode.texture = texture
            hatNode.alpha = 1
        } else {
            hatNode.texture = nil
            hatNode.alpha = 0
        }
    }

    // MARK: - Glasses Management

    /// Updates the glasses overlay based on currently equipped glasses
    func updateGlasses() {
        let equippedGlasses = ClosetManager.shared.equippedGlasses

        if let glasses = equippedGlasses,
           let texture = ClawdachiOutfitSprites.glassesTexture(for: glasses.id) {
            glassesNode.texture = texture
            glassesNode.alpha = 1
        } else {
            glassesNode.texture = nil
            glassesNode.alpha = 0
        }
    }

    // MARK: - Held Item Management

    /// Updates the held item overlay based on currently equipped held item
    func updateHeldItem() {
        let equippedHeld = ClosetManager.shared.equippedHeld

        // Stop all held item animations first
        stopCoffeeSteamAnimation()
        stopCigaretteSmokeAnimation()

        if let heldItem = equippedHeld,
           let texture = ClawdachiOutfitSprites.heldItemTexture(for: heldItem.id) {
            heldItemNode.texture = texture
            heldItemNode.alpha = 1

            // Start item-specific animations
            switch heldItem.id {
            case "coffee":
                startCoffeeSteamAnimation()
            case "cigarette":
                startCigaretteSmokeAnimation()
            default:
                break
            }
        } else {
            heldItemNode.texture = nil
            heldItemNode.alpha = 0
        }
    }

    // MARK: - Held Item Animations

    /// Starts the coffee steam animation
    func startCoffeeSteamAnimation() {
        // Don't start if already running
        guard action(forKey: AnimationKey.coffeeSteam.rawValue) == nil else { return }

        var steamVariation = 0
        let steamSpawn = SKAction.run { [weak self] in
            guard let self = self else { return }
            ParticleSpawner.spawnCoffeeSteam(
                texture: self.smokeTexture,
                variation: steamVariation,
                parent: self
            )
            steamVariation = (steamVariation + 1) % 3
        }

        // Spawn steam every 0.8-1.2 seconds
        let steamSequence = SKAction.sequence([
            steamSpawn,
            SKAction.wait(forDuration: 0.8, withRange: 0.4)
        ])
        run(SKAction.repeatForever(steamSequence), withKey: AnimationKey.coffeeSteam.rawValue)
    }

    /// Stops the coffee steam animation
    func stopCoffeeSteamAnimation() {
        removeAction(forKey: AnimationKey.coffeeSteam.rawValue)
    }

    /// Starts the cigarette smoke animation
    func startCigaretteSmokeAnimation() {
        // Don't start if already running
        guard action(forKey: AnimationKey.cigaretteHeldSmoke.rawValue) == nil else { return }

        var smokeVariation = 0
        let smokeSpawn = SKAction.run { [weak self] in
            guard let self = self else { return }
            ParticleSpawner.spawnCigaretteHeldSmoke(
                texture: self.smokeTexture,
                variation: smokeVariation,
                parent: self
            )
            smokeVariation = (smokeVariation + 1) % 3
        }

        // Spawn smoke every 0.6-1.0 seconds
        let smokeSequence = SKAction.sequence([
            smokeSpawn,
            SKAction.wait(forDuration: 0.6, withRange: 0.4)
        ])
        run(SKAction.repeatForever(smokeSequence), withKey: AnimationKey.cigaretteHeldSmoke.rawValue)
    }

    /// Stops the cigarette smoke animation
    func stopCigaretteSmokeAnimation() {
        removeAction(forKey: AnimationKey.cigaretteHeldSmoke.rawValue)
    }

    // MARK: - Theme Support

    /// Regenerates all body textures when theme changes
    func regenerateTextures() {
        // Regenerate breathing frames with new colors
        breathingFrames = ClawdachiBodySprites.generateBreathingFrames()

        // Restart breathing animation with new frames
        // (replaces the running animation since it uses a key)
        startBreathingAnimation()

        // Regenerate limb textures
        leftArmNode.texture = ClawdachiBodySprites.generateLeftArmTexture()
        rightArmNode.texture = ClawdachiBodySprites.generateRightArmTexture()
        outerLeftLegNode.texture = ClawdachiBodySprites.generateLeftLegTexture()
        innerLeftLegNode.texture = ClawdachiBodySprites.generateLeftLegTexture()
        innerRightLegNode.texture = ClawdachiBodySprites.generateRightLegTexture()
        outerRightLegNode.texture = ClawdachiBodySprites.generateRightLegTexture()

        // Regenerate effect textures (music notes, hearts, Z's, etc.)
        musicNoteTexture = ClawdachiFaceSprites.generateMusicNoteTexture()
        doubleNoteTexture = ClawdachiFaceSprites.generateDoubleNoteTexture()
        heartTexture = ClawdachiFaceSprites.generateHeartTexture()
        zzzTexture = ClawdachiFaceSprites.generateZzzTexture()

        // Regenerate Claude animation cached textures
        ClawdachiSprite.regenerateThemeTextures()
    }
}
