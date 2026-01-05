//
//  PixelArtGenerator.swift
//  Claudachi
//

import SpriteKit
import AppKit

/// Represents a single pixel color with RGBA components
struct PixelColor {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let a: UInt8

    static let clear = PixelColor(r: 0, g: 0, b: 0, a: 0)

    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

/// Utility class for generating SpriteKit textures from pixel data
class PixelArtGenerator {

    /// Creates an SKTexture from a 2D array of pixel colors
    /// - Parameters:
    ///   - pixels: 2D array where pixels[y][x] is the color at that position (bottom-up)
    ///   - width: Width in pixels
    ///   - height: Height in pixels
    /// - Returns: SKTexture with nearest-neighbor filtering for crisp pixel art
    static func textureFromPixels(_ pixels: [[PixelColor]], width: Int, height: Int) -> SKTexture {
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                let pixel = pixels[y][x]
                // Flip Y coordinate for SpriteKit (origin at bottom-left)
                let flippedY = height - 1 - y
                let index = (flippedY * width + x) * 4
                pixelData[index] = pixel.r
                pixelData[index + 1] = pixel.g
                pixelData[index + 2] = pixel.b
                pixelData[index + 3] = pixel.a
            }
        }

        let data = Data(pixelData)
        guard let cgImage = createCGImage(from: data, width: width, height: height) else {
            fatalError("Failed to create CGImage from pixel data")
        }

        let texture = SKTexture(cgImage: cgImage)
        texture.filteringMode = .nearest // Critical for crisp pixel art
        return texture
    }

    private static func createCGImage(from data: Data, width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let provider = CGDataProvider(data: data as CFData) else {
            return nil
        }

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
