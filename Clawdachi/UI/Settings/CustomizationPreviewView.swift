//
//  CustomizationPreviewView.swift
//  Clawdachi
//
//  Preview panel showing a live mirror of the main Clawdachi sprite
//

import AppKit
import SpriteKit

/// Left panel view showing live mirror of the main Clawdachi sprite
class CustomizationPreviewView: NSView {

    private typealias C = SettingsConstants

    // MARK: - Properties

    private var imageView: NSImageView!
    private var updateTimer: Timer?

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        setupPreviewBox()
    }

    // MARK: - Preview Box

    private func setupPreviewBox() {
        // Create image view centered in the panel
        let boxSize = C.previewBoxSize
        let boxX = (bounds.width - boxSize) / 2
        let boxY = (bounds.height - boxSize) / 2

        let boxFrame = NSRect(x: boxX, y: boxY, width: boxSize, height: boxSize)

        // Background box
        let backgroundView = NSView(frame: boxFrame)
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = C.cellBackgroundColor.cgColor
        backgroundView.layer?.cornerRadius = 6
        backgroundView.layer?.borderWidth = 2
        backgroundView.layer?.borderColor = C.frameColor.cgColor
        addSubview(backgroundView)

        // Image view for the sprite
        imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: boxSize, height: boxSize))
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        backgroundView.addSubview(imageView)
    }

    // MARK: - Drawing

    override var isFlipped: Bool { false }

    // MARK: - Animation Control

    func startAnimation() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.updateMirror()
        }
        updateMirror()
    }

    func stopAnimation() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    // MARK: - Mirror Updates

    private func updateMirror() {
        guard let mainScene = ClawdachiScene.shared,
              let skView = mainScene.view else { return }

        // Capture the entire scene (sprite is positioned within it)
        // The scene is 48x64 points, rendered at 6x scale in the view
        if let texture = skView.texture(from: mainScene) {
            let cgImage = texture.cgImage()

            // Get the actual pixel dimensions from the CGImage
            let pixelWidth = cgImage.width
            let pixelHeight = cgImage.height

            // Create NSImage at the full pixel resolution
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: pixelWidth, height: pixelHeight))
            imageView.image = nsImage
        }
    }

    // MARK: - Preview Updates

    func updatePreview() {
        updateMirror()
    }
}
