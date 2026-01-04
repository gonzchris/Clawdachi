//
//  ClaudachiFaceSprites.swift
//  Claudachi
//

import SpriteKit

/// Generates face element textures (eyes, mouth) with animation frames
class ClaudachiFaceSprites {

    private typealias P = ClaudachiPalette

    // MARK: - Eye States

    enum EyeState {
        case open
        case halfClosed
        case closed
    }

    /// Generates an eye texture for the given state
    /// Eye size: 3x4 pixels
    static func generateEyeTexture(state: EyeState) -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 4)

        switch state {
        case .open:
            // Simple 3x4 dark eye
            for row in 0..<4 {
                for col in 0..<3 {
                    pixels[row][col] = P.eyePupil
                }
            }

        case .halfClosed:
            // Bottom 2 rows only
            for row in 0..<2 {
                for col in 0..<3 {
                    pixels[row][col] = P.eyePupil
                }
            }

        case .closed:
            // Single row horizontal line
            for col in 0..<3 {
                pixels[1][col] = P.eyePupil
            }
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 4)
    }

    /// Generates all blink animation frames
    /// - Returns: Array of 5 textures: open -> half -> closed -> half -> open
    static func generateBlinkFrames() -> [SKTexture] {
        return [
            generateEyeTexture(state: .open),
            generateEyeTexture(state: .halfClosed),
            generateEyeTexture(state: .closed),
            generateEyeTexture(state: .halfClosed),
            generateEyeTexture(state: .open)
        ]
    }

    // MARK: - Mouth

    /// Generates a whistle "o" mouth texture
    /// Mouth size: 3x3 pixels
    static func generateWhistleMouthTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 3)

        // Small "o" shape for whistling
        pixels[0][1] = P.mouthColor  // Bottom
        pixels[1][0] = P.mouthColor  // Left
        pixels[1][2] = P.mouthColor  // Right
        pixels[2][1] = P.mouthColor  // Top

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generates a musical note texture for whistle effect
    /// Note size: 3x5 pixels
    static func generateMusicNoteTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 5)

        // Simple music note shape
        pixels[0][0] = P.eyePupil  // Note head
        pixels[0][1] = P.eyePupil
        pixels[1][0] = P.eyePupil
        pixels[1][2] = P.eyePupil  // Stem
        pixels[2][2] = P.eyePupil
        pixels[3][2] = P.eyePupil
        pixels[4][2] = P.eyePupil
        pixels[4][1] = P.eyePupil  // Flag

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 5)
    }

    // MARK: - Effect Textures

    /// Generates an exclamation mark texture for "getting idea" animation
    /// Size: 3x7 pixels
    static func generateExclamationTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 7)

        // Exclamation mark "!"
        // Vertical line (top part)
        for row in 2..<7 {
            pixels[row][1] = P.effectGreen
        }
        // Dot at bottom
        pixels[0][1] = P.effectGreen

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 7)
    }

    /// Generates a thought bubble dot texture
    /// Size: 2x2 pixels
    static func generateThoughtDotTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 2), count: 2)

        pixels[0][0] = P.eyeWhite
        pixels[0][1] = P.eyeWhite
        pixels[1][0] = P.eyeWhite
        pixels[1][1] = P.eyeWhite

        return PixelArtGenerator.textureFromPixels(pixels, width: 2, height: 2)
    }

    /// Generates a heart texture for happy reactions
    /// Size: 5x5 pixels
    static func generateHeartTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 5), count: 5)

        let heart = P.primary  // Orange heart to match character

        // Heart shape
        pixels[4][1] = heart
        pixels[4][3] = heart
        pixels[3][0] = heart
        pixels[3][1] = heart
        pixels[3][2] = heart
        pixels[3][3] = heart
        pixels[3][4] = heart
        pixels[2][0] = heart
        pixels[2][1] = heart
        pixels[2][2] = heart
        pixels[2][3] = heart
        pixels[2][4] = heart
        pixels[1][1] = heart
        pixels[1][2] = heart
        pixels[1][3] = heart
        pixels[0][2] = heart

        return PixelArtGenerator.textureFromPixels(pixels, width: 5, height: 5)
    }

    /// Generates a star/sparkle texture for success celebrations
    /// Size: 5x5 pixels
    static func generateSparkleTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 5), count: 5)

        let spark = P.effectGreen

        // 4-point star shape
        pixels[2][2] = spark  // Center
        pixels[0][2] = spark  // Top
        pixels[4][2] = spark  // Bottom
        pixels[2][0] = spark  // Left
        pixels[2][4] = spark  // Right
        // Diagonal hints
        pixels[1][1] = spark
        pixels[1][3] = spark
        pixels[3][1] = spark
        pixels[3][3] = spark

        return PixelArtGenerator.textureFromPixels(pixels, width: 5, height: 5)
    }

    /// Generates a "Z" texture for sleeping animation
    /// Size: 4x5 pixels
    static func generateZzzTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 4), count: 5)

        let z = P.eyeWhite

        // Z shape
        pixels[4][0] = z
        pixels[4][1] = z
        pixels[4][2] = z
        pixels[4][3] = z
        pixels[3][2] = z
        pixels[2][1] = z
        pixels[1][0] = z
        pixels[0][0] = z
        pixels[0][1] = z
        pixels[0][2] = z
        pixels[0][3] = z

        return PixelArtGenerator.textureFromPixels(pixels, width: 4, height: 5)
    }

    /// Generates a small smile mouth texture
    /// Size: 5x2 pixels
    static func generateSmileMouthTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 5), count: 2)

        // Simple curved smile
        pixels[1][1] = P.mouthColor
        pixels[1][2] = P.mouthColor
        pixels[1][3] = P.mouthColor
        pixels[0][0] = P.mouthColor
        pixels[0][4] = P.mouthColor

        return PixelArtGenerator.textureFromPixels(pixels, width: 5, height: 2)
    }
}
