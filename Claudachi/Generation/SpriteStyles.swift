//
//  SpriteStyles.swift
//  Claudachi
//
//  Style presets and palettes for AI sprite generation
//

import Foundation

/// Available sprite sizes
enum SpriteSize: Int, CaseIterable {
    case tiny = 8      // Tiny icons, effects
    case small = 12    // Small accessories
    case medium = 16   // Standard items (default)
    case large = 24    // Larger, detailed items

    var dimension: Int { rawValue }
    var pixelCount: Int { rawValue * rawValue }
}

/// Style presets for generated sprites
enum SpriteStyle: String, CaseIterable {
    case claudachi   // Orange-complementary, warm palette
    case gameboy     // 4-color Game Boy green
    case nes         // Classic NES palette
    case monochrome  // Black, white, grays
    case pastel      // Soft, muted colors

    /// Colors as [r,g,b,a] arrays for prompt
    var paletteDescription: String {
        switch self {
        case .claudachi:
            return """
            PALETTE (Claudachi style - warm, complementary to orange):
            - Outline: [34,34,34,255] (dark gray)
            - Shadow: [102,68,34,255] (warm brown)
            - Midtone: [170,119,68,255] (tan)
            - Highlight: [238,204,136,255] (cream)
            - Accent1: [68,136,170,255] (teal - complements orange)
            - Accent2: [136,102,170,255] (purple - for magic/special)
            """
        case .gameboy:
            return """
            PALETTE (Game Boy - exactly 4 colors):
            - Darkest: [15,56,15,255]
            - Dark: [48,98,48,255]
            - Light: [139,172,15,255]
            - Lightest: [155,188,15,255]
            """
        case .nes:
            return """
            PALETTE (NES-inspired - bold, saturated):
            - Black: [0,0,0,255]
            - White: [255,255,255,255]
            - Red: [188,60,60,255]
            - Blue: [60,60,188,255]
            - Green: [60,188,60,255]
            - Yellow: [255,204,0,255]
            - Brown: [139,90,43,255]
            - Gray: [128,128,128,255]
            """
        case .monochrome:
            return """
            PALETTE (Monochrome - grayscale only):
            - Black: [0,0,0,255]
            - Dark gray: [68,68,68,255]
            - Mid gray: [136,136,136,255]
            - Light gray: [204,204,204,255]
            - White: [255,255,255,255]
            """
        case .pastel:
            return """
            PALETTE (Pastel - soft, muted):
            - Outline: [102,102,102,255]
            - Pink: [255,182,193,255]
            - Lavender: [200,162,200,255]
            - Mint: [170,212,170,255]
            - Peach: [255,218,185,255]
            - Sky: [173,216,230,255]
            """
        }
    }

    /// Maximum colors allowed for this style
    var maxColors: Int {
        switch self {
        case .gameboy: return 4
        case .monochrome: return 5
        case .claudachi, .nes, .pastel: return 8
        }
    }

    /// Style guidelines for the prompt
    var styleGuidelines: String {
        switch self {
        case .claudachi:
            return """
            - Chunky, friendly shapes
            - 1-pixel dark outlines on outer edges
            - Warm, inviting feel
            - No anti-aliasing or gradients
            """
        case .gameboy:
            return """
            - Exactly 4 colors from the palette
            - High contrast between shades
            - Iconic, recognizable silhouettes
            - Dithering allowed for texture
            """
        case .nes:
            return """
            - Bold, saturated colors
            - Strong outlines (1-2 pixels)
            - Iconic 8-bit aesthetic
            - Clear, punchy designs
            """
        case .monochrome:
            return """
            - Strong contrast
            - Clear silhouettes
            - Use hatching for shading
            - Black outlines required
            """
        case .pastel:
            return """
            - Soft, rounded shapes
            - Minimal dark outlines
            - Gentle, kawaii aesthetic
            - Subtle shading
            """
        }
    }
}

/// Category-specific composition rules
extension ItemCategory {
    var compositionRules: String {
        switch self {
        case .hat:
            return """
            COMPOSITION (hat):
            - Position in upper 2/3 of sprite
            - Leave 2-3 rows at bottom for head overlap
            - Hat should be 10-14 pixels wide
            - Clear brim/crown shape
            """
        case .glasses:
            return """
            COMPOSITION (glasses):
            - Center horizontally
            - Position in middle third vertically
            - Bridge in center, lenses on each side
            - 12-14 pixels wide
            """
        case .food:
            return """
            COMPOSITION (food):
            - Center in sprite
            - Use 10-12 pixel diameter
            - Recognizable from iconic features
            - Include small detail (bite mark, topping)
            """
        case .prop:
            return """
            COMPOSITION (prop):
            - Center with slight bottom-heavy balance
            - Leave margins on all sides
            - Vertical orientation preferred
            - Clear iconic shape
            """
        }
    }
}

/// Palette enforcement utilities
struct PaletteEnforcer {

    /// Snap a color to the nearest color in the given style's palette
    static func snapToNearestPaletteColor(_ color: PixelColor, style: SpriteStyle) -> PixelColor {
        let palette = getPaletteColors(for: style)

        // Preserve transparency
        if color.a < 128 {
            return PixelColor.clear
        }

        var bestMatch = palette[0]
        var bestDistance = colorDistance(color, palette[0])

        for paletteColor in palette.dropFirst() {
            let distance = colorDistance(color, paletteColor)
            if distance < bestDistance {
                bestDistance = distance
                bestMatch = paletteColor
            }
        }

        return bestMatch
    }

    /// Get palette colors for a style
    static func getPaletteColors(for style: SpriteStyle) -> [PixelColor] {
        switch style {
        case .claudachi:
            return [
                PixelColor(r: 34, g: 34, b: 34),        // Outline
                PixelColor(r: 102, g: 68, b: 34),      // Shadow
                PixelColor(r: 170, g: 119, b: 68),     // Midtone
                PixelColor(r: 238, g: 204, b: 136),    // Highlight
                PixelColor(r: 68, g: 136, b: 170),     // Teal accent
                PixelColor(r: 136, g: 102, b: 170),    // Purple accent
                PixelColor(r: 255, g: 153, b: 51),     // Claudachi orange
                PixelColor(r: 204, g: 102, b: 0),      // Dark orange
            ]
        case .gameboy:
            return [
                PixelColor(r: 15, g: 56, b: 15),
                PixelColor(r: 48, g: 98, b: 48),
                PixelColor(r: 139, g: 172, b: 15),
                PixelColor(r: 155, g: 188, b: 15),
            ]
        case .nes:
            return [
                PixelColor(r: 0, g: 0, b: 0),
                PixelColor(r: 255, g: 255, b: 255),
                PixelColor(r: 188, g: 60, b: 60),
                PixelColor(r: 60, g: 60, b: 188),
                PixelColor(r: 60, g: 188, b: 60),
                PixelColor(r: 255, g: 204, b: 0),
                PixelColor(r: 139, g: 90, b: 43),
                PixelColor(r: 128, g: 128, b: 128),
            ]
        case .monochrome:
            return [
                PixelColor(r: 0, g: 0, b: 0),
                PixelColor(r: 68, g: 68, b: 68),
                PixelColor(r: 136, g: 136, b: 136),
                PixelColor(r: 204, g: 204, b: 204),
                PixelColor(r: 255, g: 255, b: 255),
            ]
        case .pastel:
            return [
                PixelColor(r: 102, g: 102, b: 102),
                PixelColor(r: 255, g: 182, b: 193),
                PixelColor(r: 200, g: 162, b: 200),
                PixelColor(r: 170, g: 212, b: 170),
                PixelColor(r: 255, g: 218, b: 185),
                PixelColor(r: 173, g: 216, b: 230),
            ]
        }
    }

    /// Calculate color distance (simple Euclidean in RGB space)
    private static func colorDistance(_ a: PixelColor, _ b: PixelColor) -> Int {
        let dr = Int(a.r) - Int(b.r)
        let dg = Int(a.g) - Int(b.g)
        let db = Int(a.b) - Int(b.b)
        return dr * dr + dg * dg + db * db
    }

    /// Enforce palette on a full sprite
    static func enforceStyle(pixels: [[PixelColor]], style: SpriteStyle) -> [[PixelColor]] {
        return pixels.map { row in
            row.map { pixel in
                snapToNearestPaletteColor(pixel, style: style)
            }
        }
    }
}
