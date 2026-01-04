//
//  GIFExporter.swift
//  Claudachi
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

class GIFExporter {

    /// Creates an animated GIF from an array of CGImages
    /// - Parameters:
    ///   - frames: Array of CGImage frames to include in the GIF
    ///   - frameDelay: Delay between frames in seconds
    ///   - outputURL: Destination URL for the GIF file
    /// - Returns: true if successful, false otherwise
    static func createGIF(
        from frames: [CGImage],
        frameDelay: Double,
        outputURL: URL
    ) -> Bool {
        guard !frames.isEmpty else {
            print("GIFExporter: No frames to export")
            return false
        }

        // Create destination for GIF
        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.gif.identifier as CFString,
            frames.count,
            nil
        ) else {
            print("GIFExporter: Failed to create image destination")
            return false
        }

        // GIF file properties - loop forever
        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0  // 0 = infinite loop
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        // Frame properties - delay time
        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: frameDelay,
                kCGImagePropertyGIFUnclampedDelayTime as String: frameDelay
            ]
        ]

        // Add each frame
        for frame in frames {
            CGImageDestinationAddImage(destination, frame, frameProperties as CFDictionary)
        }

        // Finalize and write to disk
        let success = CGImageDestinationFinalize(destination)

        if success {
            print("GIFExporter: Successfully saved GIF to \(outputURL.path)")
        } else {
            print("GIFExporter: Failed to finalize GIF")
        }

        return success
    }

    /// Generates a unique filename for the GIF
    /// Falls back to Documents or temp directory if Desktop unavailable
    static func generateOutputURL() -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let filename = "Claudachi-\(timestamp).gif"

        // Try Desktop first, fall back to Documents, then temp directory
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            return desktopURL.appendingPathComponent(filename)
        } else if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            print("GIFExporter: Desktop unavailable, using Documents folder")
            return documentsURL.appendingPathComponent(filename)
        } else {
            print("GIFExporter: Using temp directory as fallback")
            return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        }
    }
}
