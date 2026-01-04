//
//  GeneratedSprite.swift
//  Claudachi
//
//  Domain model for AI-generated sprites
//

import SpriteKit

/// A generated sprite with its metadata
struct GeneratedSprite {
    let texture: SKTexture
    let pixelData: [[PixelColor]]
    let item: String
    let category: ItemCategory
    let width: Int
    let height: Int
    let style: SpriteStyle
}
