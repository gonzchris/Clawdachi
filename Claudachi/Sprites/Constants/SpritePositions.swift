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
    // Body is 32x32 centered at 0,0
    // Arms at rows 11-13 (y = -4), left at x = -11, right at x = 11
    // Feet at rows 5-6 (y = -10), left at x = -6, right at x = 6

    /// Left arm attachment point
    static let leftArm = CGPoint(x: -11, y: -4)

    /// Right arm attachment point
    static let rightArm = CGPoint(x: 11, y: -4)

    /// Left foot attachment point
    static let leftFoot = CGPoint(x: -6, y: -10)

    /// Right foot attachment point
    static let rightFoot = CGPoint(x: 6, y: -10)

    // MARK: - Accessories

    /// Hat resting position (on head)
    static let hat = CGPoint(x: 0, y: 12)

    /// Hat drop animation start position
    static let hatDropStart: CGFloat = 24

    /// Bottom accessory position (bowl, apron bottom, etc.)
    static let bottomAccessory = CGPoint(x: 16, y: -10)

    // MARK: - Effects Spawn Points

    /// Music note spawn position (near mouth)
    static let musicNoteSpawn = CGPoint(x: 4, y: -2)

    /// Exclamation mark position (above head)
    static let exclamation = CGPoint(x: 7, y: 14)

    /// Sleep Z spawn position
    static let sleepZ = CGPoint(x: 5, y: 5)
}

/// Z-position layer ordering for Claudachi sprites
enum SpriteZPositions {

    // MARK: - Background Layers

    /// Behind character effects (chef mode bowl)
    static let behindCharacter: CGFloat = -10

    // MARK: - Character Layers

    /// Limbs (arms, feet) - behind body
    static let limbs: CGFloat = 0

    /// Main body
    static let body: CGFloat = 1

    /// Face elements (eyes, mouth)
    static let face: CGFloat = 2

    /// Floating effects (music notes, hearts, sparkles)
    static let effects: CGFloat = 3

    /// Important effects (exclamation, thought dots)
    static let importantEffects: CGFloat = 4

    /// Hat and headwear
    static let hat: CGFloat = 5

    /// Held items in front (frying pan)
    static let heldItems: CGFloat = 10

    /// Recording indicator (topmost)
    static let overlay: CGFloat = 1000
}
