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

        // Bikini top (rows 11-13)
        // The body spans x: 6-25 approximately (width ~20 pixels centered at 16)

        // Row 13 - top edge with highlight
        pixels[13][9] = h
        pixels[13][10] = h
        pixels[13][11] = p
        pixels[13][12] = p
        pixels[13][13] = p
        // gap in middle for cleavage look
        pixels[13][18] = p
        pixels[13][19] = p
        pixels[13][20] = p
        pixels[13][21] = h
        pixels[13][22] = h

        // Row 12 - main bikini top
        pixels[12][8] = s
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
        pixels[12][23] = s

        // Row 11 - bottom of top with shadow
        pixels[11][9] = s
        pixels[11][10] = p
        pixels[11][11] = p
        pixels[11][12] = s
        // gap
        pixels[11][19] = s
        pixels[11][20] = p
        pixels[11][21] = p
        pixels[11][22] = s

        // Thin strap wrapping around (row 12, connecting cups and going to edges)
        // Center connection
        pixels[12][14] = s
        pixels[12][15] = p
        pixels[12][16] = p
        pixels[12][17] = s
        // Left side wrap (goes to edge of sprite body)
        pixels[12][7] = s
        pixels[12][6] = p
        // Right side wrap
        pixels[12][24] = s
        pixels[12][25] = p

        // Shoulder straps going up from cups
        // Left strap (from left cup up toward shoulder)
        pixels[14][10] = p
        pixels[15][9] = p
        pixels[16][9] = p
        pixels[17][8] = p
        pixels[18][8] = p
        pixels[19][7] = s
        // Right strap (from right cup up toward shoulder)
        pixels[14][21] = p
        pixels[15][22] = p
        pixels[16][22] = p
        pixels[17][23] = p
        pixels[18][23] = p
        pixels[19][24] = s

        // Bikini bottom (rows 7-8)

        // Row 8 - top with waistband
        pixels[8][9] = s
        pixels[8][10] = p
        pixels[8][11] = p
        pixels[8][12] = p
        pixels[8][13] = h
        pixels[8][14] = h
        pixels[8][15] = h
        pixels[8][16] = h
        pixels[8][17] = h
        pixels[8][18] = p
        pixels[8][19] = p
        pixels[8][20] = p
        pixels[8][21] = p
        pixels[8][22] = s

        // Row 7 - bottom edge
        pixels[7][10] = s
        pixels[7][11] = s
        pixels[7][12] = p
        pixels[7][13] = p
        pixels[7][14] = p
        pixels[7][15] = p
        pixels[7][16] = p
        pixels[7][17] = p
        pixels[7][18] = p
        pixels[7][19] = p
        pixels[7][20] = s
        pixels[7][21] = s

        // Thin strap wrapping around sides (row 8, like the top)
        // Left side wrap
        pixels[8][8] = s
        pixels[8][7] = p
        pixels[8][6] = p
        // Right side wrap
        pixels[8][23] = s
        pixels[8][24] = p
        pixels[8][25] = p

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

    // MARK: - Top Hat Colors

    private static let topHatBlack = PixelColor(r: 30, g: 30, b: 35)       // Main black
    private static let topHatHighlight = PixelColor(r: 60, g: 60, b: 70)   // Highlight/shine
    private static let topHatShadow = PixelColor(r: 15, g: 15, b: 20)      // Deep shadow
    private static let topHatBand = PixelColor(r: 140, g: 20, b: 30)       // Red satin band

    // MARK: - Beanie Colors

    private static let beanieMain = PixelColor(r: 70, g: 130, b: 180)      // Steel blue main
    private static let beanieLight = PixelColor(r: 100, g: 160, b: 210)    // Highlight
    private static let beanieDark = PixelColor(r: 50, g: 100, b: 140)      // Shadow
    private static let beanieRib = PixelColor(r: 60, g: 115, b: 160)       // Ribbed cuff

    // MARK: - Crown Colors

    private static let crownGold = PixelColor(r: 255, g: 200, b: 50)       // Main gold
    private static let crownLight = PixelColor(r: 255, g: 230, b: 120)     // Gold highlight
    private static let crownDark = PixelColor(r: 180, g: 140, b: 30)       // Gold shadow
    private static let crownRed = PixelColor(r: 180, g: 30, b: 50)         // Ruby jewel
    private static let crownBlue = PixelColor(r: 40, g: 80, b: 180)        // Sapphire jewel
    private static let crownWhite = PixelColor(r: 255, g: 255, b: 255)     // Jewel shine

    // MARK: - Propeller Cap Colors

    private static let propCapRed = PixelColor(r: 220, g: 50, b: 50)       // Red panel
    private static let propCapYellow = PixelColor(r: 255, g: 220, b: 50)   // Yellow panel
    private static let propCapBlue = PixelColor(r: 50, g: 100, b: 200)     // Blue panel
    private static let propCapGreen = PixelColor(r: 50, g: 180, b: 80)     // Green panel
    private static let propCapDark = PixelColor(r: 40, g: 40, b: 45)       // Shadow/seams
    private static let propBlade = PixelColor(r: 180, g: 180, b: 190)      // Propeller blade
    private static let propBladeLight = PixelColor(r: 220, g: 220, b: 230) // Blade highlight
    private static let propHub = PixelColor(r: 100, g: 100, b: 110)        // Center hub

    // MARK: - Pirate Outfit Colors

    private static let pirateRed = PixelColor(r: 180, g: 40, b: 40)         // Bandana red
    private static let pirateRedDark = PixelColor(r: 130, g: 25, b: 25)     // Dark red
    private static let pirateRedLight = PixelColor(r: 220, g: 70, b: 70)    // Light red
    private static let pirateShirt = PixelColor(r: 245, g: 235, b: 220)     // Cream shirt
    private static let pirateShirtDark = PixelColor(r: 200, g: 190, b: 175) // Shirt shadow
    private static let pirateShirtLight = PixelColor(r: 255, g: 250, b: 245) // Shirt highlight
    private static let pirateBelt = PixelColor(r: 80, g: 50, b: 30)         // Brown belt
    private static let pirateBeltDark = PixelColor(r: 50, g: 30, b: 15)     // Belt shadow
    private static let pirateBuckle = PixelColor(r: 255, g: 200, b: 50)     // Gold buckle
    private static let pirateVest = PixelColor(r: 40, g: 35, b: 30)         // Black vest
    private static let pirateVestLight = PixelColor(r: 60, g: 55, b: 50)    // Vest highlight

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

    // MARK: - Headphones Colors

    private static let headphoneBlack = PixelColor(r: 30, g: 30, b: 35)
    private static let headphoneGray = PixelColor(r: 55, g: 55, b: 60)
    private static let headphoneLight = PixelColor(r: 85, g: 85, b: 90)
    private static let headphonePad = PixelColor(r: 45, g: 45, b: 50)
    private static let headphoneAccent = PixelColor(r: 120, g: 120, b: 125)  // Light gray accent

    // MARK: - Headphones

    /// Generates headphones texture (32x32) positioned on sprite head
    static func generateHeadphonesTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let b = headphoneBlack
        let g = headphoneGray
        let l = headphoneLight
        let p = headphonePad
        let a = headphoneAccent

        // === HEADBAND (rows 22-24) - arched over head ===
        // Row 24 - top center of headband
        for col in 11...20 { pixels[24][col] = l }

        // Row 23 - wider part
        for col in 9...22 { pixels[23][col] = g }
        pixels[23][8] = l
        pixels[23][23] = b

        // Row 22 - bottom of headband, curves down to cups
        pixels[22][7] = g
        pixels[22][8] = g
        pixels[22][23] = g
        pixels[22][24] = g

        // === LEFT EAR CUP (rows 14-20) ===
        // Row 20 - top of cup
        pixels[20][4] = b
        pixels[20][5] = g
        pixels[20][6] = g

        // Rows 15-19 - main cup body
        for row in 15...19 {
            pixels[row][4] = b
            pixels[row][5] = l
            pixels[row][6] = g
            pixels[row][7] = p  // Inner pad
        }

        // Row 14 - bottom of cup
        pixels[14][4] = b
        pixels[14][5] = g
        pixels[14][6] = g

        // Red accent on left cup
        pixels[17][5] = a
        pixels[16][5] = a

        // === RIGHT EAR CUP (rows 14-20) ===
        // Row 20 - top of cup
        pixels[20][25] = g
        pixels[20][26] = g
        pixels[20][27] = b

        // Rows 15-19 - main cup body
        for row in 15...19 {
            pixels[row][24] = p  // Inner pad
            pixels[row][25] = g
            pixels[row][26] = l
            pixels[row][27] = b
        }

        // Row 14 - bottom of cup
        pixels[14][25] = g
        pixels[14][26] = g
        pixels[14][27] = b

        // Red accent on right cup
        pixels[17][26] = a
        pixels[16][26] = a

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Top Hat

    /// Generates a top hat texture (32x32) positioned on top of sprite head
    static func generateTopHatTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let b = topHatBlack
        let h = topHatHighlight
        let s = topHatShadow
        let band = topHatBand

        // === BRIM (rows 22-23) ===
        // Row 22 - bottom of brim (shadow)
        for col in 6...25 { pixels[22][col] = s }

        // Row 23 - top of brim
        for col in 6...25 { pixels[23][col] = b }
        pixels[23][6] = s
        pixels[23][7] = s
        pixels[23][24] = h
        pixels[23][25] = h

        // === BAND (row 24) - red satin ===
        for col in 10...21 { pixels[24][col] = band }
        pixels[24][9] = s
        pixels[24][22] = s

        // === CROWN (rows 25-31) - tall cylinder ===
        // Row 25 - base of crown
        for col in 10...21 { pixels[25][col] = b }
        pixels[25][9] = s
        pixels[25][10] = s
        pixels[25][21] = h
        pixels[25][22] = s

        // Rows 26-29 - main crown body
        for row in 26...29 {
            pixels[row][9] = s
            pixels[row][10] = b
            pixels[row][11] = b
            pixels[row][12] = b
            pixels[row][13] = b
            pixels[row][14] = b
            pixels[row][15] = b
            pixels[row][16] = b
            pixels[row][17] = b
            pixels[row][18] = b
            pixels[row][19] = b
            pixels[row][20] = b
            pixels[row][21] = h
            pixels[row][22] = s
        }
        // Highlight stripe on right side
        for row in 26...29 {
            pixels[row][20] = h
        }

        // Row 30 - near top
        for col in 10...21 { pixels[30][col] = b }
        pixels[30][9] = s
        pixels[30][10] = s
        pixels[30][20] = h
        pixels[30][21] = h

        // Row 31 - flat top
        for col in 11...20 { pixels[31][col] = h }
        pixels[31][11] = b
        pixels[31][12] = b

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Beanie

    /// Generates a beanie texture (32x32) - cozy knit cap
    static func generateBeanieTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let m = beanieMain
        let l = beanieLight
        let d = beanieDark
        let r = beanieRib

        // === RIBBED CUFF (rows 21-23) - sits on head ===
        // Row 21 - bottom of cuff (widest)
        for col in 6...25 { pixels[21][col] = d }

        // Row 22 - middle cuff with ribbing pattern
        for col in 6...25 {
            if col % 2 == 0 {
                pixels[22][col] = r
            } else {
                pixels[22][col] = d
            }
        }
        pixels[22][6] = d
        pixels[22][25] = d

        // Row 23 - top of cuff (slightly narrower)
        for col in 7...24 {
            if col % 2 == 0 {
                pixels[23][col] = m
            } else {
                pixels[23][col] = r
            }
        }
        pixels[23][7] = d
        pixels[23][24] = l

        // === MAIN BODY (rows 24-27) ===
        // Row 24
        for col in 8...23 { pixels[24][col] = m }
        pixels[24][8] = d
        pixels[24][9] = d
        pixels[24][22] = l
        pixels[24][23] = l

        // Row 25
        for col in 9...22 { pixels[25][col] = m }
        pixels[25][9] = d
        pixels[25][21] = l
        pixels[25][22] = l

        // Row 26
        for col in 10...21 { pixels[26][col] = m }
        pixels[26][10] = d
        pixels[26][20] = l
        pixels[26][21] = l

        // Row 27
        for col in 11...20 { pixels[27][col] = m }
        pixels[27][11] = d
        pixels[27][19] = l
        pixels[27][20] = l

        // === ROUNDED TOP (rows 28-29) ===
        // Row 28
        for col in 12...19 { pixels[28][col] = m }
        pixels[28][12] = d
        pixels[28][18] = l
        pixels[28][19] = l

        // Row 29 - very top
        for col in 14...17 { pixels[29][col] = l }
        pixels[29][14] = m
        pixels[29][15] = m

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Crown

    /// Generates a crown texture (32x32) - royal gold crown with jewels
    static func generateCrownTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let g = crownGold
        let l = crownLight
        let d = crownDark
        let r = crownRed
        let b = crownBlue
        let w = crownWhite

        // === BASE BAND (rows 22-23) ===
        // Row 22 - bottom of crown
        for col in 8...23 { pixels[22][col] = d }

        // Row 23 - band with center jewel
        for col in 8...23 { pixels[23][col] = g }
        pixels[23][8] = d
        pixels[23][9] = d
        pixels[23][22] = l
        pixels[23][23] = l
        // Center ruby
        pixels[23][15] = r
        pixels[23][16] = r

        // === CROWN BODY (rows 24-25) ===
        // Row 24
        for col in 9...22 { pixels[24][col] = g }
        pixels[24][9] = d
        pixels[24][21] = l
        pixels[24][22] = l
        // Side sapphires
        pixels[24][11] = b
        pixels[24][20] = b

        // Row 25
        for col in 9...22 { pixels[25][col] = g }
        pixels[25][9] = d
        pixels[25][21] = l
        pixels[25][22] = l

        // === SPIRES (rows 26-29) - 5 pointed peaks ===
        // Row 26 - base of spires
        pixels[26][9] = d    // Left spire
        pixels[26][10] = g
        pixels[26][12] = g   // Left-mid spire
        pixels[26][13] = g
        pixels[26][15] = g   // Center spire
        pixels[26][16] = g
        pixels[26][18] = g   // Right-mid spire
        pixels[26][19] = g
        pixels[26][21] = g   // Right spire
        pixels[26][22] = l

        // Row 27
        pixels[27][9] = d
        pixels[27][10] = g
        pixels[27][12] = g
        pixels[27][13] = l
        pixels[27][15] = g
        pixels[27][16] = l
        pixels[27][18] = g
        pixels[27][19] = l
        pixels[27][21] = l
        pixels[27][22] = l

        // Row 28 - tips forming
        pixels[28][9] = g
        pixels[28][10] = l
        pixels[28][12] = l
        pixels[28][15] = g
        pixels[28][16] = l
        pixels[28][19] = l
        pixels[28][21] = l

        // Row 29 - top points
        pixels[29][9] = l    // Left tip
        pixels[29][12] = l   // Left-mid tip
        pixels[29][15] = l   // Center tip (tallest)
        pixels[29][16] = l
        pixels[29][19] = l   // Right-mid tip
        pixels[29][22] = l   // Right tip

        // Row 30 - center spire extends higher
        pixels[30][15] = l
        pixels[30][16] = l

        // === JEWEL HIGHLIGHTS ===
        pixels[23][15] = w  // Ruby shine
        pixels[24][11] = w  // Left sapphire shine

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Propeller Cap

    /// Generates a propeller cap texture (32x32) - colorful beanie with spinning propeller
    static func generatePropellerCapTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let r = propCapRed
        let y = propCapYellow
        let b = propCapBlue
        let g = propCapGreen
        let d = propCapDark
        let blade = propBlade
        let bl = propBladeLight
        let hub = propHub

        // === CAP BASE (rows 22-24) - colorful panels ===
        // Row 22 - bottom edge
        for col in 7...24 { pixels[22][col] = d }

        // Row 23 - 4 color panels
        for col in 7...10 { pixels[23][col] = r }   // Red
        for col in 11...15 { pixels[23][col] = y }  // Yellow
        for col in 16...20 { pixels[23][col] = b }  // Blue
        for col in 21...24 { pixels[23][col] = g }  // Green
        pixels[23][7] = d
        pixels[23][11] = d  // Seam
        pixels[23][16] = d  // Seam
        pixels[23][21] = d  // Seam

        // Row 24 - panels continue
        for col in 8...10 { pixels[24][col] = r }
        for col in 11...15 { pixels[24][col] = y }
        for col in 16...20 { pixels[24][col] = b }
        for col in 21...23 { pixels[24][col] = g }
        pixels[24][8] = d
        pixels[24][11] = d
        pixels[24][16] = d
        pixels[24][21] = d

        // === CAP DOME (rows 25-27) ===
        // Row 25
        for col in 9...22 { pixels[25][col] = y }
        pixels[25][9] = r
        pixels[25][10] = r
        pixels[25][11] = d
        pixels[25][16] = d
        pixels[25][17] = b
        pixels[25][18] = b
        pixels[25][19] = b
        pixels[25][20] = b
        pixels[25][21] = g
        pixels[25][22] = g

        // Row 26
        for col in 10...21 { pixels[26][col] = y }
        pixels[26][10] = r
        pixels[26][11] = d
        pixels[26][16] = d
        pixels[26][17] = b
        pixels[26][18] = b
        pixels[26][19] = b
        pixels[26][20] = b
        pixels[26][21] = g

        // Row 27
        for col in 12...19 { pixels[27][col] = y }
        pixels[27][12] = d
        pixels[27][17] = b
        pixels[27][18] = b
        pixels[27][19] = d

        // === PROPELLER HUB (rows 28) ===
        pixels[28][15] = hub
        pixels[28][16] = hub

        // === PROPELLER BLADES (rows 29-30) ===
        // Left blade
        pixels[29][11] = blade
        pixels[29][12] = blade
        pixels[29][13] = bl
        pixels[29][14] = bl
        pixels[30][10] = blade
        pixels[30][11] = bl

        // Right blade
        pixels[29][17] = bl
        pixels[29][18] = bl
        pixels[29][19] = blade
        pixels[29][20] = blade
        pixels[30][20] = bl
        pixels[30][21] = blade

        // Hub top
        pixels[29][15] = hub
        pixels[29][16] = hub

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Pirate Outfit

    /// Generates pirate outfit with bandana, vest, and belt
    static func generatePirateTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let r = pirateRed
        let rd = pirateRedDark
        let rl = pirateRedLight
        let s = pirateShirt
        let sd = pirateShirtDark
        let sl = pirateShirtLight
        let v = pirateVest
        let vl = pirateVestLight
        let b = pirateBelt
        let bd = pirateBeltDark
        let bu = pirateBuckle

        // === RED BANDANA (rows 22-25) ===
        // Row 25 - top knot
        pixels[25][18] = rd
        pixels[25][19] = r
        pixels[25][20] = r
        pixels[25][21] = rd

        // Row 24 - bandana top with knot
        for col in 8...23 { pixels[24][col] = r }
        pixels[24][8] = rd
        pixels[24][9] = rd
        pixels[24][22] = rl
        pixels[24][23] = rl
        // Knot tails
        pixels[24][24] = rd
        pixels[24][25] = r

        // Row 23 - main bandana
        for col in 6...25 { pixels[23][col] = r }
        pixels[23][6] = rd
        pixels[23][7] = rd
        pixels[23][24] = rl
        pixels[23][25] = rl
        // Tail hanging down
        pixels[23][26] = r
        pixels[23][27] = rd

        // Row 22 - bandana bottom edge
        for col in 5...26 { pixels[22][col] = rd }
        // Tail continues
        pixels[22][27] = r
        pixels[22][28] = rd

        // === VEST AND SHIRT (rows 10-21) ===
        for row in 10...21 {
            // Left vest edge
            pixels[row][4] = bd
            pixels[row][5] = v
            pixels[row][6] = v
            pixels[row][7] = vl  // Vest inner edge

            // Shirt showing in middle (face opening area)
            // Leave cols 8-23 clear for face

            // Right vest edge
            pixels[row][24] = vl  // Vest inner edge
            pixels[row][25] = v
            pixels[row][26] = v
            pixels[row][27] = bd
        }

        // === BELT (rows 8-9) ===
        // Row 9 - belt top
        for col in 5...26 { pixels[9][col] = b }
        pixels[9][5] = bd
        pixels[9][6] = bd
        pixels[9][25] = b
        pixels[9][26] = b
        // Gold buckle
        pixels[9][14] = bu
        pixels[9][15] = bu
        pixels[9][16] = bu
        pixels[9][17] = bu

        // Row 8 - belt bottom
        for col in 5...26 { pixels[8][col] = bd }
        // Buckle continues
        pixels[8][14] = bu
        pixels[8][15] = bu
        pixels[8][16] = bu
        pixels[8][17] = bu

        // Row 7 - shirt bottom peeking below belt
        for col in 6...25 { pixels[7][col] = sd }
        pixels[7][6] = bd
        pixels[7][25] = bd

        // === SHIRT V-NECK DETAIL (visible in face area) ===
        // Shirt collar peeking at top of opening
        pixels[21][8] = sl
        pixels[21][9] = s
        pixels[21][22] = s
        pixels[21][23] = sl

        pixels[20][8] = s
        pixels[20][23] = s

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Glasses Colors

    private static let glassesFrame = PixelColor(r: 25, g: 25, b: 30)       // Dark frame
    private static let glassesLens = PixelColor(r: 40, g: 45, b: 55)        // Dark lens
    private static let glassesShine = PixelColor(r: 80, g: 90, b: 110)      // Lens reflection

    // Nerd glasses colors
    private static let nerdFrame = PixelColor(r: 35, g: 30, b: 25)          // Dark brown/black frame
    private static let nerdFrameLight = PixelColor(r: 60, g: 50, b: 40)     // Frame highlight
    private static let nerdLens = PixelColor(r: 200, g: 220, b: 240, a: 100) // Clear lens with slight tint
    private static let nerdShine = PixelColor(r: 255, g: 255, b: 255, a: 150) // Lens glare

    // 3D glasses colors
    private static let glasses3dFrame = PixelColor(r: 240, g: 240, b: 245)   // White cardboard frame
    private static let glasses3dFrameDark = PixelColor(r: 200, g: 200, b: 205) // Frame shadow
    private static let glasses3dRed = PixelColor(r: 220, g: 40, b: 40)       // Red lens
    private static let glasses3dRedLight = PixelColor(r: 255, g: 100, b: 100) // Red lens highlight
    private static let glasses3dCyan = PixelColor(r: 40, g: 200, b: 220)     // Cyan lens
    private static let glasses3dCyanLight = PixelColor(r: 100, g: 230, b: 245) // Cyan lens highlight

    // MARK: - Sunglasses

    /// Generates sunglasses texture (32x32) positioned over eyes
    static func generateSunglassesTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let f = glassesFrame
        let l = glassesLens
        let s = glassesShine

        // Eyes are around rows 16-18, left eye cols 11-13, right eye cols 18-20
        // Sunglasses should cover rows 15-19

        // === LEFT LENS (cols 9-14) ===
        // Top frame
        for col in 9...14 { pixels[19][col] = f }
        // Lens rows
        for col in 9...14 {
            pixels[18][col] = l
            pixels[17][col] = l
            pixels[16][col] = l
        }
        // Bottom frame
        for col in 9...14 { pixels[15][col] = f }
        // Side frames
        for row in 15...19 {
            pixels[row][9] = f
            pixels[row][14] = f
        }
        // Lens shine
        pixels[18][10] = s
        pixels[18][11] = s

        // === RIGHT LENS (cols 17-22) ===
        // Top frame
        for col in 17...22 { pixels[19][col] = f }
        // Lens rows
        for col in 17...22 {
            pixels[18][col] = l
            pixels[17][col] = l
            pixels[16][col] = l
        }
        // Bottom frame
        for col in 17...22 { pixels[15][col] = f }
        // Side frames
        for row in 15...19 {
            pixels[row][17] = f
            pixels[row][22] = f
        }
        // Lens shine
        pixels[18][20] = s
        pixels[18][21] = s

        // === BRIDGE (connects lenses) ===
        pixels[18][15] = f
        pixels[18][16] = f

        // === TEMPLE ARMS (sides going back) ===
        // Left arm
        pixels[18][8] = f
        pixels[18][7] = f
        pixels[18][6] = f
        // Right arm
        pixels[18][23] = f
        pixels[18][24] = f
        pixels[18][25] = f

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - Nerd Glasses

    /// Generates nerd glasses texture (32x32) with round frames
    static func generateNerdGlassesTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let f = nerdFrame
        let fl = nerdFrameLight
        let l = nerdLens
        let s = nerdShine

        // Round frames - more circular than sunglasses
        // Eyes are around rows 16-18, left eye cols 11-13, right eye cols 18-20

        // === LEFT LENS (round, cols 9-14, rows 15-20) ===
        // Row 20 - top of round frame
        pixels[20][10] = f
        pixels[20][11] = f
        pixels[20][12] = f
        pixels[20][13] = f

        // Row 19
        pixels[19][9] = f
        pixels[19][10] = l
        pixels[19][11] = l
        pixels[19][12] = l
        pixels[19][13] = l
        pixels[19][14] = f

        // Row 18
        pixels[18][9] = f
        pixels[18][10] = l
        pixels[18][11] = s  // Shine
        pixels[18][12] = l
        pixels[18][13] = l
        pixels[18][14] = fl

        // Row 17
        pixels[17][9] = f
        pixels[17][10] = l
        pixels[17][11] = l
        pixels[17][12] = l
        pixels[17][13] = l
        pixels[17][14] = fl

        // Row 16
        pixels[16][9] = f
        pixels[16][10] = l
        pixels[16][11] = l
        pixels[16][12] = l
        pixels[16][13] = l
        pixels[16][14] = f

        // Row 15 - bottom of round frame
        pixels[15][10] = f
        pixels[15][11] = f
        pixels[15][12] = f
        pixels[15][13] = f

        // === RIGHT LENS (round, cols 17-22, rows 15-20) ===
        // Row 20 - top of round frame
        pixels[20][18] = f
        pixels[20][19] = f
        pixels[20][20] = f
        pixels[20][21] = f

        // Row 19
        pixels[19][17] = f
        pixels[19][18] = l
        pixels[19][19] = l
        pixels[19][20] = l
        pixels[19][21] = l
        pixels[19][22] = f

        // Row 18
        pixels[18][17] = f
        pixels[18][18] = l
        pixels[18][19] = s  // Shine
        pixels[18][20] = l
        pixels[18][21] = l
        pixels[18][22] = fl

        // Row 17
        pixels[17][17] = f
        pixels[17][18] = l
        pixels[17][19] = l
        pixels[17][20] = l
        pixels[17][21] = l
        pixels[17][22] = fl

        // Row 16
        pixels[16][17] = f
        pixels[16][18] = l
        pixels[16][19] = l
        pixels[16][20] = l
        pixels[16][21] = l
        pixels[16][22] = f

        // Row 15 - bottom of round frame
        pixels[15][18] = f
        pixels[15][19] = f
        pixels[15][20] = f
        pixels[15][21] = f

        // === BRIDGE (thick, connects lenses) ===
        pixels[18][15] = f
        pixels[18][16] = f
        pixels[17][15] = f
        pixels[17][16] = f

        // === TEMPLE ARMS (thicker for nerd look) ===
        // Left arm
        pixels[18][8] = f
        pixels[18][7] = f
        pixels[18][6] = fl
        pixels[17][8] = f
        // Right arm
        pixels[18][23] = f
        pixels[18][24] = f
        pixels[18][25] = fl
        pixels[17][23] = f

        return PixelArtGenerator.textureFromPixels(pixels, width: 32, height: 32)
    }

    // MARK: - 3D Glasses

    /// Generates 3D glasses texture (32x32) with red/cyan lenses
    static func generate3DGlassesTexture() -> SKTexture {
        var pixels = Array(repeating: Array(repeating: PixelColor.clear, count: 32), count: 32)

        let f = glasses3dFrame
        let fd = glasses3dFrameDark
        let r = glasses3dRed
        let rl = glasses3dRedLight
        let c = glasses3dCyan
        let cl = glasses3dCyanLight

        // Classic cardboard 3D glasses shape - wider rectangular lenses
        // Eyes are around rows 16-18, left eye cols 11-13, right eye cols 18-20

        // === LEFT LENS - RED (cols 8-14, rows 15-19) ===
        // Top frame
        for col in 8...14 { pixels[19][col] = f }
        pixels[19][8] = fd

        // Lens rows
        for row in 16...18 {
            pixels[row][8] = fd
            pixels[row][9] = r
            pixels[row][10] = r
            pixels[row][11] = r
            pixels[row][12] = r
            pixels[row][13] = r
            pixels[row][14] = f
        }
        // Red highlight
        pixels[18][10] = rl
        pixels[18][11] = rl

        // Bottom frame
        for col in 8...14 { pixels[15][col] = fd }

        // === RIGHT LENS - CYAN (cols 17-23, rows 15-19) ===
        // Top frame
        for col in 17...23 { pixels[19][col] = f }
        pixels[19][23] = fd

        // Lens rows
        for row in 16...18 {
            pixels[row][17] = f
            pixels[row][18] = c
            pixels[row][19] = c
            pixels[row][20] = c
            pixels[row][21] = c
            pixels[row][22] = c
            pixels[row][23] = fd
        }
        // Cyan highlight
        pixels[18][20] = cl
        pixels[18][21] = cl

        // Bottom frame
        for col in 17...23 { pixels[15][col] = fd }

        // === BRIDGE (white cardboard connecting lenses) ===
        pixels[18][15] = f
        pixels[18][16] = f
        pixels[17][15] = fd
        pixels[17][16] = fd

        // === TEMPLE ARMS (cardboard arms) ===
        // Left arm
        pixels[18][7] = f
        pixels[18][6] = f
        pixels[18][5] = fd
        pixels[17][7] = fd
        // Right arm
        pixels[18][24] = f
        pixels[18][25] = f
        pixels[18][26] = fd
        pixels[17][24] = fd

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
        case "pirate":
            return generatePirateTexture()
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
        case "tophat":
            return generateTopHatTexture()
        case "beanie":
            return generateBeanieTexture()
        case "crown":
            return generateCrownTexture()
        case "propeller":
            return generatePropellerCapTexture()
        default:
            return nil
        }
    }

    // MARK: - Glasses Texture Lookup

    /// Returns the texture for a given glasses ID, or nil if not found
    static func glassesTexture(for glassesId: String) -> SKTexture? {
        switch glassesId {
        case "sunglasses":
            return generateSunglassesTexture()
        case "nerd":
            return generateNerdGlassesTexture()
        case "3d":
            return generate3DGlassesTexture()
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
        case "headphones":
            return generateHeadphonesTexture()
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

    /// Generates a preview NSImage of the sprite with glasses (for grid display)
    /// Returns nil if glasses not found
    static func generateGlassesPreviewImage(for glassesId: String, size: CGFloat) -> NSImage? {
        // Get glasses texture
        guard let glassesTexture = glassesTexture(for: glassesId) else { return nil }

        return generateCompositePreview(overlayTexture: glassesTexture, size: size)
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
