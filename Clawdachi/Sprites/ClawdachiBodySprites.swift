//
//  ClawdachiBodySprites.swift
//  Clawdachi
//

import SpriteKit

/// Generates body textures for Clawdachi with breathing animation frames
class ClawdachiBodySprites {

    private typealias P = ClawdachiPalette

    /// Generates all breathing animation frames
    /// - Returns: Array of 4 textures: contracted, neutral (expanding), expanded, neutral (contracting)
    static func generateBreathingFrames() -> [SKTexture] {
        return [
            generateBodyTexture(breathPhase: .contracted),
            generateBodyTexture(breathPhase: .neutral),
            generateBodyTexture(breathPhase: .expanded),
            generateBodyTexture(breathPhase: .neutral)
        ]
    }

    enum BreathPhase {
        case contracted  // Slightly squashed
        case neutral     // Normal size
        case expanded    // Slightly stretched
    }

    /// Generates a body texture for a specific breathing phase (without arms/legs - those are separate)
    static func generateBodyTexture(breathPhase: BreathPhase) -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 32), count: 32)

        // Vertical offset based on breath phase
        let yOffset: Int
        switch breathPhase {
        case .contracted: yOffset = 0
        case .neutral: yOffset = 0
        case .expanded: yOffset = 1
        }

        // Draw the friendly blob body (without arms/legs)
        drawBody(into: &pixels, yOffset: yOffset, phase: breathPhase)

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    private static func drawBody(into pixels: inout [[PixelColor]], yOffset: Int, phase: BreathPhase) {
        let c = P.primaryOrange
        let s = P.shadowOrange
        let h = P.highlightOrange

        // Body dimensions adjust slightly based on breath phase
        let extraWidth = (phase == .contracted) ? 1 : 0
        let bodyWidth = 10 + extraWidth  // Half-width of body

        // Main body only (rows 7-22) - arms and legs are separate nodes now
        for row in 7...22 {
            let adjustedRow = row + yOffset
            if adjustedRow < 0 || adjustedRow >= 32 { continue }

            // Slight corner rounding only at very top and bottom rows
            var width = bodyWidth
            if row == 7 || row == 22 {
                width = bodyWidth - 1  // Slight corner cut
            }

            let left = 16 - width
            let right = 16 + width - 1

            for x in left...right {
                // Left edge shadow (2 pixels)
                if x < left + 2 {
                    pixels[adjustedRow][x] = s
                }
                // Right edge highlight (2 pixels)
                else if x > right - 2 {
                    pixels[adjustedRow][x] = h
                }
                // Top highlight (top 2 rows)
                else if row >= 21 {
                    pixels[adjustedRow][x] = h
                }
                // Bottom shadow (bottom row of body)
                else if row == 7 {
                    pixels[adjustedRow][x] = s
                }
                // Main body color
                else {
                    pixels[adjustedRow][x] = c
                }
            }
        }
    }

    // MARK: - Limb Textures

    /// Generate left arm texture (3x3 pixels - horizontal stub)
    static func generateLeftArmTexture() -> SKTexture {
        let c = P.primaryOrange
        let s = P.shadowOrange

        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 3)

        // 3x3 arm block
        for row in 0..<3 {
            for x in 0..<3 {
                if row == 0 {
                    pixels[row][x] = s  // Bottom shadow
                } else if x == 0 {
                    pixels[row][x] = s  // Left shadow
                } else {
                    pixels[row][x] = c
                }
            }
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generate right arm texture (3x3 pixels - horizontal stub)
    static func generateRightArmTexture() -> SKTexture {
        let c = P.primaryOrange
        let h = P.highlightOrange
        let s = P.shadowOrange

        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 3)

        // 3x3 arm block
        for row in 0..<3 {
            for x in 0..<3 {
                if row == 0 {
                    pixels[row][x] = s  // Bottom shadow
                } else if x == 2 {
                    pixels[row][x] = h  // Right highlight
                } else {
                    pixels[row][x] = c
                }
            }
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generate left leg texture (2x5 pixels)
    static func generateLeftLegTexture() -> SKTexture {
        let c = P.primaryOrange
        let s = P.shadowOrange

        var pixels = Array(repeating: Array(repeating: P.clear, count: 2), count: 5)

        // Bottom row - shadow
        pixels[0][0] = s
        pixels[0][1] = s

        // Middle rows - left shadow, right main
        for row in 1..<5 {
            pixels[row][0] = s  // Left edge shadow
            pixels[row][1] = c  // Main color
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: 2, height: 5)
    }

    /// Generate right leg texture (2x5 pixels)
    static func generateRightLegTexture() -> SKTexture {
        let c = P.primaryOrange
        let h = P.highlightOrange
        let s = P.shadowOrange

        var pixels = Array(repeating: Array(repeating: P.clear, count: 2), count: 5)

        // Bottom row - shadow
        pixels[0][0] = s
        pixels[0][1] = s

        // Middle rows - main, right highlight
        for row in 1..<5 {
            pixels[row][0] = c  // Main color
            pixels[row][1] = h  // Right edge highlight
        }

        return PixelArtGenerator.textureFromPixels(pixels, width: 2, height: 5)
    }

    // MARK: - Astronaut Limb Textures (NASA style)

    private static let suitWhite = PixelColor(r: 240, g: 240, b: 245)
    private static let suitGray = PixelColor(r: 180, g: 185, b: 190)
    private static let suitLight = PixelColor(r: 255, g: 255, b: 255)
    private static let nasaRed = PixelColor(r: 200, g: 50, b: 50)
    private static let nasaBlue = PixelColor(r: 30, g: 60, b: 120)
    private static let bootGray = PixelColor(r: 90, g: 95, b: 100)
    private static let bootDark = PixelColor(r: 60, g: 65, b: 70)

    /// Generate astronaut left arm texture (3x3 pixels) - white with gray gloves
    static func generateWhiteLeftArmTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 3)

        // Row 2 (top/inner) - white suit
        pixels[2][0] = suitGray
        pixels[2][1] = suitWhite
        pixels[2][2] = suitWhite

        // Row 1 (middle) - white suit
        pixels[1][0] = suitGray
        pixels[1][1] = suitWhite
        pixels[1][2] = suitWhite

        // Row 0 (bottom/outer) - gray glove
        pixels[0][0] = bootDark
        pixels[0][1] = bootGray
        pixels[0][2] = bootGray

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generate astronaut right arm texture (3x3 pixels) - white with gray gloves
    static func generateWhiteRightArmTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 3), count: 3)

        // Row 2 (top/inner) - white suit
        pixels[2][0] = suitWhite
        pixels[2][1] = suitWhite
        pixels[2][2] = suitLight

        // Row 1 (middle) - white suit
        pixels[1][0] = suitWhite
        pixels[1][1] = suitWhite
        pixels[1][2] = suitLight

        // Row 0 (bottom/outer) - gray glove
        pixels[0][0] = bootGray
        pixels[0][1] = bootGray
        pixels[0][2] = bootDark

        return PixelArtGenerator.textureFromPixels(pixels, width: 3, height: 3)
    }

    /// Generate astronaut left leg texture (2x5 pixels) - NASA style with blue band and gray boots
    static func generateWhiteLeftLegTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 2), count: 5)

        // Row 4 (top) - white
        pixels[4][0] = suitGray
        pixels[4][1] = suitWhite

        // Row 3 - blue band
        pixels[3][0] = nasaBlue
        pixels[3][1] = nasaBlue

        // Row 2 - white
        pixels[2][0] = suitGray
        pixels[2][1] = suitWhite

        // Rows 0-1 (bottom) - gray boots
        pixels[1][0] = bootGray
        pixels[1][1] = bootGray
        pixels[0][0] = bootDark
        pixels[0][1] = bootDark

        return PixelArtGenerator.textureFromPixels(pixels, width: 2, height: 5)
    }

    /// Generate astronaut right leg texture (2x5 pixels) - NASA style with blue band and gray boots
    static func generateWhiteRightLegTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: P.clear, count: 2), count: 5)

        // Row 4 (top) - white
        pixels[4][0] = suitWhite
        pixels[4][1] = suitLight

        // Row 3 - blue band
        pixels[3][0] = nasaBlue
        pixels[3][1] = nasaBlue

        // Row 2 - white
        pixels[2][0] = suitWhite
        pixels[2][1] = suitLight

        // Rows 0-1 (bottom) - gray boots
        pixels[1][0] = bootGray
        pixels[1][1] = bootGray
        pixels[0][0] = bootDark
        pixels[0][1] = bootDark

        return PixelArtGenerator.textureFromPixels(pixels, width: 2, height: 5)
    }

}
