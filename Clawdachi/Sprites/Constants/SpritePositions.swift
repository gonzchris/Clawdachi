//
//  SpritePositions.swift
//  Clawdachi
//
//  Centralized sprite positioning and z-ordering constants
//

import CoreGraphics

/// Position constants for Clawdachi sprite composition
enum SpritePositions {

    // MARK: - Face Elements

    /// Left eye base position relative to body center
    static let leftEye = CGPoint(x: -4, y: 1)

    /// Right eye base position relative to body center
    static let rightEye = CGPoint(x: 4, y: 1)

    /// Mouth position relative to body center
    static let mouth = CGPoint(x: 0, y: -4)

    // MARK: - Limbs

    /// Left arm attachment point
    static let leftArm = CGPoint(x: -10, y: 0)

    /// Right arm attachment point
    static let rightArm = CGPoint(x: 10, y: 0)

    /// Outer left leg attachment point
    static let outerLeftLeg = CGPoint(x: -8, y: -9)

    /// Inner left leg attachment point
    static let innerLeftLeg = CGPoint(x: -5, y: -9)

    /// Inner right leg attachment point
    static let innerRightLeg = CGPoint(x: 5, y: -9)

    /// Outer right leg attachment point
    static let outerRightLeg = CGPoint(x: 8, y: -9)

    // MARK: - Effects Spawn Points

    /// Music note spawn position (near mouth)
    static let musicNoteSpawn = CGPoint(x: 4, y: -2)

    /// Sleep Z spawn position
    static let sleepZ = CGPoint(x: 5, y: 5)

    /// Dancing music note spawn Y position
    static let danceMusicNoteSpawnY: CGFloat = 10

    // MARK: - Claude Integration Elements

    /// Lightbulb position above head (planning mode)
    static let lightbulb = CGPoint(x: 0, y: 15)

    /// Lightbulb size (20% smaller than original)
    static let lightbulbSize = CGSize(width: 6.8, height: 9.6)

    /// Question mark position above head (waiting mode)
    static let questionMark = CGPoint(x: 0, y: 14)

    /// Party hat position above head (celebration mode)
    static let partyHat = CGPoint(x: 0, y: 11)

    /// Party blower position near mouth
    static let partyBlower = CGPoint(x: 3, y: -4)

    /// Thinking dot spawn position range
    static let thinkingDotSpawnX: ClosedRange<CGFloat> = -3...3
    static let thinkingDotSpawnY: CGFloat = 10

    // MARK: - Whistle/Smoking Positions

    /// Whistle mouth offset from face center
    static let whistleMouth = CGPoint(x: 5, y: -5)

    /// Cigarette position when held
    static let cigarette = CGPoint(x: 5, y: 0)

    /// Cigarette tip offset from cigarette position
    static let cigaretteTipOffset: CGFloat = 2.5

    /// Smoke particle spawn position (relative to cigarette)
    static let smokeSpawn = CGPoint(x: 2, y: -4)
}

/// Z-position layer ordering for Clawdachi sprites
enum SpriteZPositions {

    // MARK: - Character Layers

    /// Limbs (arms, feet) - behind body
    static let limbs: CGFloat = 0

    /// Main body
    static let body: CGFloat = 1

    /// Face elements (eyes, mouth)
    static let face: CGFloat = 2

    /// Floating effects (music notes, hearts)
    static let effects: CGFloat = 3

    /// Recording indicator (topmost)
    static let overlay: CGFloat = 1000
}
