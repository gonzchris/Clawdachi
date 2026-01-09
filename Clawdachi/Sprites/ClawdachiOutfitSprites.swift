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

    // MARK: - Coffee Mug Colors

    private static let mugWhite = PixelColor(r: 250, g: 248, b: 245)         // Main mug ceramic
    private static let mugCream = PixelColor(r: 255, g: 253, b: 250)         // Highlight
    private static let mugGray = PixelColor(r: 220, g: 215, b: 210)          // Shadow
    private static let mugDark = PixelColor(r: 180, g: 175, b: 170)          // Deep shadow
    private static let coffeeBrown = PixelColor(r: 101, g: 67, b: 33)        // Coffee color
    private static let coffeeDark = PixelColor(r: 70, g: 45, b: 20)          // Coffee shadow
    private static let coffeeHighlight = PixelColor(r: 139, g: 90, b: 43)    // Coffee highlight
    private static let steamWhite = PixelColor(r: 255, g: 255, b: 255, a: 180) // Steam wisp

    // MARK: - Cigarette Colors

    private static let cigarettePaper = PixelColor(r: 245, g: 240, b: 230)    // Off-white paper
    private static let cigaretteShadow = PixelColor(r: 220, g: 215, b: 205)   // Paper shadow
    private static let tobaccoBrown = PixelColor(r: 180, g: 100, b: 40)       // Brown tobacco
    private static let ashGray = PixelColor(r: 180, g: 180, b: 175)           // Gray ash
    private static let emberOrange = PixelColor(r: 255, g: 120, b: 50)        // Orange ember glow
    private static let emberRed = PixelColor(r: 255, g: 80, b: 30)            // Red ember core

    // MARK: - Astronaut Colors

    private static let suitWhite = PixelColor(r: 240, g: 240, b: 245)        // Main suit white
    private static let suitLight = PixelColor(r: 255, g: 255, b: 255)        // Highlight
    private static let suitGray = PixelColor(r: 180, g: 185, b: 190)         // Shadow
    private static let suitDark = PixelColor(r: 120, g: 125, b: 130)         // Deep shadow
    private static let visorGold = PixelColor(r: 255, g: 200, b: 80)         // Gold visor
    private static let visorDark = PixelColor(r: 200, g: 150, b: 50)         // Visor shadow
    // Visor colors
    private static let visorBlue = PixelColor(r: 45, g: 65, b: 110)          // Dark blue visor
    private static let visorBlueDark = PixelColor(r: 30, g: 45, b: 80)       // Darker blue edge
    private static let visorReflect = PixelColor(r: 180, g: 210, b: 240)     // Light blue reflection
    private static let visorReflectBright = PixelColor(r: 220, g: 240, b: 255) // Bright reflection
    // Accent colors
    private static let accentOrange = PixelColor(r: 255, g: 150, b: 50)      // Orange stripe
    private static let accentOrangeDark = PixelColor(r: 200, g: 110, b: 30)  // Dark orange
    private static let beltGray = PixelColor(r: 90, g: 95, b: 100)           // Gray belt/collar
    private static let beltGrayLight = PixelColor(r: 120, g: 125, b: 130)    // Lighter gray
    // Antenna colors
    private static let antennaGray = PixelColor(r: 140, g: 145, b: 150)      // Antenna pole
    private static let antennaRed = PixelColor(r: 220, g: 70, b: 60)         // Red tip
    private static let antennaWhite = PixelColor(r: 255, g: 255, b: 255)     // White tip

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

    // MARK: - Astronaut Suit

    /// Generates astronaut helmet covering entire body with visor opening for face
    static func generateAstronautTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let w = suitWhite
        let l = suitLight
        let g = suitGray
        let vbd = visorBlueDark
        let vr = visorReflect
        let vrb = visorReflectBright

        // NASA accent colors
        let nasaRed = PixelColor(r: 200, g: 50, b: 50)       // NASA red stripe
        let nasaBlue = PixelColor(r: 30, g: 60, b: 120)     // NASA blue accent

        // === FULL HELMET SHELL (covers entire body) ===
        // Row 24 - very top (rounded)
        for col in 10...21 { pixels[24][col] = l }
        pixels[24][9] = g
        pixels[24][22] = g

        // Row 23
        for col in 8...23 { pixels[23][col] = w }
        pixels[23][7] = g
        pixels[23][24] = g

        // Row 22
        for col in 6...25 { pixels[22][col] = w }
        pixels[22][5] = g
        pixels[22][26] = g

        // Rows 7-21 - full helmet body
        for row in 7...21 {
            // Left side
            pixels[row][4] = g
            pixels[row][5] = w
            pixels[row][6] = w
            // Right side
            pixels[row][25] = w
            pixels[row][26] = w
            pixels[row][27] = g
        }

        // === NASA RED STRIPES (on helmet sides) ===
        for row in 10...20 {
            pixels[row][5] = nasaRed   // Left red stripe
            pixels[row][26] = nasaRed  // Right red stripe
        }

        // === DARK BLUE VISOR FRAME ===
        // Top frame (row 21) - raised 1px for taller visor
        for col in 7...24 { pixels[21][col] = vbd }

        // Left frame
        for row in 10...20 { pixels[row][7] = vbd }

        // Right frame
        for row in 10...20 { pixels[row][24] = vbd }

        // Bottom frame (row 9)
        for col in 7...24 { pixels[9][col] = vbd }

        // Fill white below visor (rows 7-8)
        for col in 7...24 { pixels[8][col] = w }
        for col in 7...24 { pixels[7][col] = w }

        // === NASA BLUE ACCENT (below visor, after white fill) ===
        pixels[8][8] = nasaBlue
        pixels[8][9] = nasaBlue
        pixels[8][22] = nasaBlue
        pixels[8][23] = nasaBlue

        // === VISOR REFLECTIONS ===
        pixels[19][22] = vrb
        pixels[19][23] = vrb
        pixels[18][23] = vr
        pixels[18][22] = vr
        pixels[20][22] = vr
        pixels[10][8] = vr

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Cowboy Hat Colors

    private static let hatBrown = PixelColor(r: 139, g: 90, b: 43)        // Main brown
    private static let hatBrownLight = PixelColor(r: 180, g: 120, b: 60)  // Highlight
    private static let hatBrownDark = PixelColor(r: 101, g: 67, b: 33)    // Shadow
    private static let hatBand = PixelColor(r: 60, g: 40, b: 20)          // Dark band

    // MARK: - Cowboy Hat

    /// Generates a cowboy hat texture (32x32) positioned on top of sprite head
    static func generateCowboyHatTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let b = hatBrown
        let l = hatBrownLight
        let d = hatBrownDark
        let band = hatBand

        // === WIDE BRIM (rows 22-23) ===
        // Row 22 - bottom of brim (shadow)
        for col in 3...28 { pixels[22][col] = d }

        // Row 23 - top of brim
        for col in 3...28 { pixels[23][col] = b }
        pixels[23][3] = d
        pixels[23][4] = d
        pixels[23][27] = l
        pixels[23][28] = l

        // === HAT BAND (row 24) ===
        for col in 8...23 { pixels[24][col] = band }
        pixels[24][7] = d
        pixels[24][24] = d

        // === CROWN (rows 25-29) ===
        // Row 25 - base of crown
        for col in 8...23 { pixels[25][col] = b }
        pixels[25][7] = d
        pixels[25][8] = d
        pixels[25][23] = l
        pixels[25][24] = d

        // Row 26
        for col in 9...22 { pixels[26][col] = b }
        pixels[26][8] = d
        pixels[26][9] = d
        pixels[26][22] = l
        pixels[26][23] = d

        // Row 27
        for col in 9...22 { pixels[27][col] = b }
        pixels[27][9] = d
        pixels[27][22] = l

        // Row 28 - near top
        for col in 10...21 { pixels[28][col] = b }
        pixels[28][10] = d
        pixels[28][21] = l

        // Row 29 - top of crown (indented for classic cowboy shape)
        for col in 11...20 { pixels[29][col] = l }
        pixels[29][11] = b
        pixels[29][20] = b

        // Row 30 - very top highlight
        for col in 12...19 { pixels[30][col] = l }

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Coffee Mug

    /// Generates a coffee mug held item texture (32x32 to match body)
    /// Positioned on the right side as if held in hand
    static func generateCoffeeMugTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let w = mugWhite
        let c = mugCream
        let g = mugGray
        let d = mugDark
        let cb = coffeeBrown
        let cd = coffeeDark
        let ch = coffeeHighlight
        let s = steamWhite

        // Mug positioned on right side (x: 24-30, y: 8-16)
        // The sprite's right arm is around x: 28

        // Steam wisps (rows 17-19) - shifted 2px right
        pixels[19][26] = s
        pixels[18][27] = s
        pixels[17][25] = s
        pixels[17][28] = s

        // Mug rim (row 16)
        pixels[16][24] = d
        pixels[16][25] = g
        pixels[16][26] = c
        pixels[16][27] = c
        pixels[16][28] = g
        pixels[16][29] = d

        // Coffee surface (row 15)
        pixels[15][24] = d
        pixels[15][25] = ch
        pixels[15][26] = cb
        pixels[15][27] = cb
        pixels[15][28] = cd
        pixels[15][29] = d

        // Mug body upper (row 14) - with handle start
        pixels[14][24] = d
        pixels[14][25] = c
        pixels[14][26] = w
        pixels[14][27] = w
        pixels[14][28] = g
        pixels[14][29] = d
        // Handle
        pixels[14][30] = d
        pixels[14][31] = g

        // Mug body middle (row 13) - with handle
        pixels[13][24] = d
        pixels[13][25] = c
        pixels[13][26] = w
        pixels[13][27] = w
        pixels[13][28] = g
        pixels[13][29] = d
        // Handle hole
        pixels[13][30] = PixelColor.clear
        pixels[13][31] = g

        // Mug body middle (row 12) - with handle
        pixels[12][24] = d
        pixels[12][25] = c
        pixels[12][26] = w
        pixels[12][27] = w
        pixels[12][28] = g
        pixels[12][29] = d
        // Handle hole
        pixels[12][30] = PixelColor.clear
        pixels[12][31] = g

        // Mug body lower (row 11) - with handle end
        pixels[11][24] = d
        pixels[11][25] = w
        pixels[11][26] = w
        pixels[11][27] = g
        pixels[11][28] = g
        pixels[11][29] = d
        // Handle
        pixels[11][30] = d
        pixels[11][31] = g

        // Mug body (row 10)
        pixels[10][24] = d
        pixels[10][25] = w
        pixels[10][26] = w
        pixels[10][27] = g
        pixels[10][28] = g
        pixels[10][29] = d

        // Mug base (row 9)
        pixels[9][24] = d
        pixels[9][25] = g
        pixels[9][26] = g
        pixels[9][27] = g
        pixels[9][28] = d
        pixels[9][29] = d

        // Mug bottom (row 8)
        pixels[8][25] = d
        pixels[8][26] = d
        pixels[8][27] = d
        pixels[8][28] = d

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Cigarette

    /// Generates a cigarette held item texture (32x32 to match body)
    /// Positioned to match the smoking idle animation (near mouth, extending right)
    static func generateCigaretteTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let p = cigarettePaper
        let s = cigaretteShadow
        let t = tobaccoBrown
        let a = ashGray
        let e = emberOrange
        let r = emberRed

        // Cigarette positioned horizontally near mouth on right side
        // Mouth is at world y=-4, which is pixel row 12
        // Right arm is at world x=10 (pixel col 26), cigarette extends from there
        // Positioned at rows 12-13 (mouth level), columns 18-29

        // Row 13 - top of cigarette
        pixels[13][18] = s  // filter end (held in mouth)
        pixels[13][19] = t  // tobacco
        pixels[13][20] = p  // paper
        pixels[13][21] = p
        pixels[13][22] = p
        pixels[13][23] = p
        pixels[13][24] = p
        pixels[13][25] = p
        pixels[13][26] = a  // ash
        pixels[13][27] = e  // ember
        pixels[13][28] = r  // ember tip

        // Row 12 - bottom of cigarette (with shadow)
        pixels[12][18] = s  // filter end
        pixels[12][19] = t  // tobacco
        pixels[12][20] = s  // paper shadow
        pixels[12][21] = s
        pixels[12][22] = s
        pixels[12][23] = s
        pixels[12][24] = s
        pixels[12][25] = s
        pixels[12][26] = a  // ash
        pixels[12][27] = e  // ember
        pixels[12][28] = r  // ember tip

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Outfit Texture Lookup

    /// Returns the texture for a given outfit ID, or nil if not found
    static func texture(for outfitId: String) -> SKTexture? {
        switch outfitId {
        case "bikini":
            return generateBikiniTexture()
        case "astronaut":
            return generateAstronautTexture()
        default:
            return nil
        }
    }

    // MARK: - Hat Texture Lookup

    /// Returns the texture for a given hat ID, or nil if not found
    static func hatTexture(for hatId: String) -> SKTexture? {
        switch hatId {
        case "cowboy":
            return generateCowboyHatTexture()
        default:
            return nil
        }
    }

    // MARK: - Held Item Texture Lookup

    /// Returns the texture for a given held item ID, or nil if not found
    static func heldItemTexture(for itemId: String) -> SKTexture? {
        switch itemId {
        case "coffee":
            return generateCoffeeMugTexture()
        case "cigarette":
            return generateCigaretteTexture()
        default:
            return nil
        }
    }

    // MARK: - Preview Generation

    /// Generates a preview NSImage of the sprite wearing an outfit (for grid display)
    /// Returns nil if outfit not found
    static func generatePreviewImage(for outfitId: String, size: CGFloat) -> NSImage? {
        // Get outfit texture
        guard let outfitTexture = texture(for: outfitId) else { return nil }

        return generateCompositePreview(overlayTexture: outfitTexture, size: size)
    }

    /// Generates a preview NSImage of the sprite with a hat (for grid display)
    /// Returns nil if hat not found
    static func generateHatPreviewImage(for hatId: String, size: CGFloat) -> NSImage? {
        // Get hat texture
        guard let hatTexture = hatTexture(for: hatId) else { return nil }

        return generateCompositePreview(overlayTexture: hatTexture, size: size)
    }

    /// Generates a preview NSImage of the sprite with a held item (for grid display)
    /// Returns nil if held item not found
    static func generateHeldItemPreviewImage(for itemId: String, size: CGFloat) -> NSImage? {
        // Get held item texture
        guard let heldTexture = heldItemTexture(for: itemId) else { return nil }

        return generateCompositePreview(overlayTexture: heldTexture, size: size)
    }

    /// Shared preview generation - composites body + overlay + eyes
    private static func generateCompositePreview(overlayTexture: SKTexture, size: CGFloat) -> NSImage? {
        // Generate body texture with current theme
        let bodyTexture = ClawdachiBodySprites.generateBreathingFrames()[1] // Neutral frame

        // Create composite image
        let imageSize = NSSize(width: size, height: size)
        let image = NSImage(size: imageSize)

        image.lockFocus()

        // Clear background
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: imageSize).fill()

        // Draw body
        let bodyCG = bodyTexture.cgImage()
        let bodyImage = NSImage(cgImage: bodyCG, size: NSSize(width: 32, height: 32))
        bodyImage.draw(in: NSRect(origin: .zero, size: imageSize),
                      from: .zero,
                      operation: .sourceOver,
                      fraction: 1.0)

        // Draw overlay (outfit or held item)
        let overlayCG = overlayTexture.cgImage()
        let overlayImage = NSImage(cgImage: overlayCG, size: NSSize(width: 32, height: 32))
        overlayImage.draw(in: NSRect(origin: .zero, size: imageSize),
                        from: .zero,
                        operation: .sourceOver,
                        fraction: 1.0)

        // Draw eyes (simple black rectangles at eye positions)
        let scale = size / 32.0
        NSColor.black.setFill()

        // Left eye
        let leftEyeRect = NSRect(x: 12 * scale, y: 18 * scale, width: 2 * scale, height: 3 * scale)
        leftEyeRect.fill()

        // Right eye
        let rightEyeRect = NSRect(x: 18 * scale, y: 18 * scale, width: 2 * scale, height: 3 * scale)
        rightEyeRect.fill()

        image.unlockFocus()

        return image
    }
}
