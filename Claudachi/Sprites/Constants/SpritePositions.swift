//
//  SpritePositions.swift
//  Claudachi
//
//  Centralized sprite positioning and z-ordering constants
//

import CoreGraphics

/// Position constants for Claudachi sprite composition
enum SpritePositions {

    // MARK: - Face Elements

    /// Left eye base position relative to body center
    static let leftEye = CGPoint(x: -4, y: 0)

    /// Right eye base position relative to body center
    static let rightEye = CGPoint(x: 4, y: 0)

    /// Mouth position relative to body center
    static let mouth = CGPoint(x: 0, y: -4)

    // MARK: - Limbs

    /// Left arm attachment point
    static let leftArm = CGPoint(x: -11, y: 0)

    /// Right arm attachment point
    static let rightArm = CGPoint(x: 11, y: 0)

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
}

/// Z-position layer ordering for Claudachi sprites
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
