//
//  ClawdachiOutfitSprites.swift
//  Clawdachi
//
//  Generates outfit textures for Clawdachi customization
//

import SpriteKit

/// Generates outfit textures for the closet system
class ClawdachiOutfitSprites {

    // MARK: - Bikini Colors

    private static let bikiniPink = PixelColor(r: 255, g: 105, b: 180)       // Hot pink
    private static let bikiniPinkLight = PixelColor(r: 255, g: 150, b: 200)  // Light pink highlight
    private static let bikiniPinkDark = PixelColor(r: 200, g: 80, b: 140)    // Dark pink shadow

    // MARK: - Bikini Mode

    /// Generates a pink bikini overlay texture (32x32 to match body)
    static func generateBikiniTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let p = bikiniPink
        let h = bikiniPinkLight
        let s = bikiniPinkDark

        // Bikini top (rows 11-13, 1px narrower)
        // The body spans x: 6-25 approximately (width ~20 pixels centered at 16)

        // Row 13 - top edge with highlight
        pixels[13][8] = h
        pixels[13][9] = h
        pixels[13][10] = p
        pixels[13][11] = p
        pixels[13][12] = p
        pixels[13][13] = p
        // gap in middle for cleavage look
        pixels[13][18] = p
        pixels[13][19] = p
        pixels[13][20] = p
        pixels[13][21] = p
        pixels[13][22] = h
        pixels[13][23] = h

        // Row 12 - main bikini top
        pixels[12][7] = s
        pixels[12][8] = p
        pixels[12][9] = p
        pixels[12][10] = p
        pixels[12][11] = p
        pixels[12][12] = p
        pixels[12][13] = s
        // gap
        pixels[12][18] = s
        pixels[12][19] = p
        pixels[12][20] = p
        pixels[12][21] = p
        pixels[12][22] = p
        pixels[12][23] = p
        pixels[12][24] = s

        // Row 11 - bottom of top with shadow
        pixels[11][8] = s
        pixels[11][9] = p
        pixels[11][10] = p
        pixels[11][11] = p
        pixels[11][12] = s
        // gap
        pixels[11][19] = s
        pixels[11][20] = p
        pixels[11][21] = p
        pixels[11][22] = p
        pixels[11][23] = s

        // Thin strap wrapping around (row 12, connecting cups and going to edges)
        // Center connection
        pixels[12][14] = s
        pixels[12][15] = p
        pixels[12][16] = p
        pixels[12][17] = s
        // Left side wrap (goes to edge of sprite body)
        pixels[12][6] = s
        pixels[12][5] = p
        // Right side wrap
        pixels[12][25] = s
        pixels[12][26] = p

        // Shoulder straps going up from cups
        // Left strap (from left cup up toward shoulder)
        pixels[14][9] = p
        pixels[15][8] = p
        pixels[16][8] = p
        pixels[17][7] = p
        pixels[18][7] = p
        pixels[19][6] = s
        // Right strap (from right cup up toward shoulder)
        pixels[14][22] = p
        pixels[15][23] = p
        pixels[16][23] = p
        pixels[17][24] = p
        pixels[18][24] = p
        pixels[19][25] = s

        // Bikini bottom (rows 7-8, moved 1px down)

        // Row 8 - top with waistband
        pixels[8][8] = s
        pixels[8][9] = p
        pixels[8][10] = p
        pixels[8][11] = p
        pixels[8][12] = p
        pixels[8][13] = h
        pixels[8][14] = h
        pixels[8][15] = h
        pixels[8][16] = h
        pixels[8][17] = h
        pixels[8][18] = h
        pixels[8][19] = p
        pixels[8][20] = p
        pixels[8][21] = p
        pixels[8][22] = p
        pixels[8][23] = s

        // Row 7 - bottom edge
        pixels[7][9] = s
        pixels[7][10] = s
        pixels[7][11] = p
        pixels[7][12] = p
        pixels[7][13] = p
        pixels[7][14] = p
        pixels[7][15] = p
        pixels[7][16] = p
        pixels[7][17] = p
        pixels[7][18] = p
        pixels[7][19] = p
        pixels[7][20] = p
        pixels[7][21] = s
        pixels[7][22] = s

        // Thin strap wrapping around sides (row 8, like the top)
        // Left side wrap
        pixels[8][7] = s
        pixels[8][6] = p
        pixels[8][5] = p
        // Right side wrap
        pixels[8][24] = s
        pixels[8][25] = p
        pixels[8][26] = p

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Outfit Texture Lookup

    /// Returns the texture for a given outfit ID, or nil if not found
    static func texture(for outfitId: String) -> SKTexture? {
        switch outfitId {
        case "bikini":
            return generateBikiniTexture()
        default:
            return nil
        }
    }
}
