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
}
