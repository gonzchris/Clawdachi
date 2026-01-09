//
//  AboutSettingsView.swift
//  Clawdachi
//
//  About section with app info, animated sprite, and credits
//

import AppKit
import SpriteKit

/// About section with version info, credits, and links
class AboutSettingsView: NSView {

    private typealias C = SettingsConstants

    // MARK: - Properties

    private var appNameLabel: NSTextField!
    private var versionLabel: NSTextField!
    private var spriteImageView: NSImageView!
    private var spriteContainer: NSView!
    private var descriptionLabel: NSTextField!
    private var followButton: SettingsButton!
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

        setupAsciiArt()
        setupVersion()
        setupSpritePreview()
        setupDescription()
        setupFollowButton()
        setupCredits()
    }

    override var isFlipped: Bool { true }

    // MARK: - UI Setup

    private func setupAsciiArt() {
        let asciiArt = """
   ██████╗██╗      █████╗ ██╗    ██╗██████╗  █████╗  ██████╗██╗  ██╗██╗
  ██╔════╝██║     ██╔══██╗██║    ██║██╔══██╗██╔══██╗██╔════╝██║  ██║██║
  ██║     ██║     ███████║██║ █╗ ██║██║  ██║███████║██║     ███████║██║
  ██║     ██║     ██╔══██║██║███╗██║██║  ██║██╔══██║██║     ██╔══██║██║
  ╚██████╗███████╗██║  ██║╚███╔███╔╝██████╔╝██║  ██║╚██████╗██║  ██║██║
   ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝
"""
        appNameLabel = NSTextField(labelWithString: asciiArt)
        appNameLabel.frame = NSRect(x: 20, y: 20, width: 220, height: 70)
        appNameLabel.font = NSFont.monospacedSystemFont(ofSize: 5, weight: .regular)
        appNameLabel.textColor = C.accentColor
        appNameLabel.maximumNumberOfLines = 6
        appNameLabel.lineBreakMode = .byClipping
        addSubview(appNameLabel)
    }

    private func setupVersion() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        versionLabel = NSTextField(labelWithString: "v\(version)")
        versionLabel.frame = NSRect(x: 245, y: 50, width: 80, height: 16)
        versionLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        versionLabel.textColor = C.textDimColor
        addSubview(versionLabel)
    }

    private func setupSpritePreview() {
        let spriteSize: CGFloat = 80
        let centerX: CGFloat = 20

        // Container with border
        spriteContainer = NSView(frame: NSRect(x: centerX, y: 88, width: spriteSize, height: spriteSize))
        spriteContainer.wantsLayer = true
        spriteContainer.layer?.backgroundColor = C.cellBackgroundColor.cgColor
        spriteContainer.layer?.cornerRadius = 6
        spriteContainer.layer?.borderWidth = 2
        spriteContainer.layer?.borderColor = C.frameColor.cgColor
        addSubview(spriteContainer)

        // Image view for sprite
        spriteImageView = NSImageView(frame: NSRect(x: 0, y: 0, width: spriteSize, height: spriteSize))
        spriteImageView.imageScaling = .scaleProportionallyUpOrDown
        spriteImageView.imageAlignment = .alignCenter
        spriteContainer.addSubview(spriteImageView)
    }

    private func setupDescription() {
        descriptionLabel = NSTextField(labelWithString: "A desktop companion for Claude Code")
        descriptionLabel.frame = NSRect(x: 20, y: 176, width: 250, height: 20)
        descriptionLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        descriptionLabel.textColor = C.textColor
        addSubview(descriptionLabel)
    }

    private func setupFollowButton() {
        let buttonFrame = NSRect(x: 20, y: 206, width: 150, height: 24)
        followButton = SettingsButton(frame: buttonFrame, title: "𝕏  @clawdachi")
        followButton.target = self
        followButton.action = #selector(followClicked)
        addSubview(followButton)
    }

    private func setupCredits() {
        // Credits section removed
    }

    // MARK: - Animation

    func startAnimation() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            self?.updateSprite()
        }
        updateSprite()
    }

    func stopAnimation() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updateSprite() {
        guard let mainScene = ClawdachiScene.shared,
              let skView = mainScene.view else { return }

        if let texture = skView.texture(from: mainScene) {
            let cgImage = texture.cgImage()
            let pixelWidth = cgImage.width
            let pixelHeight = cgImage.height
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: pixelWidth, height: pixelHeight))
            spriteImageView.image = nsImage
        }
    }

    // MARK: - Actions

    @objc private func followClicked() {
        if let url = URL(string: "https://x.com/clawdachi") {
            NSWorkspace.shared.open(url)
        }
    }
}
