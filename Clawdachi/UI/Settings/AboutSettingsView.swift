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

    private var titleLabel: NSTextField!
    private var spriteImageView: NSImageView!
    private var spriteContainer: NSView!
    private var appNameLabel: NSTextField!
    private var versionLabel: NSTextField!
    private var descriptionLabel: NSTextField!
    private var githubButton: SettingsButton!
    private var creditsLabel: NSTextField!
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

        setupTitle()
        setupSpritePreview()
        setupAppInfo()
        setupGithubButton()
        setupCredits()
    }

    override var isFlipped: Bool { true }

    // MARK: - UI Setup

    private func setupTitle() {
        titleLabel = NSTextField(labelWithString: "ABOUT")
        titleLabel.frame = NSRect(x: 20, y: 20, width: 200, height: 20)
        titleLabel.font = NSFont.monospacedSystemFont(ofSize: C.titleFontSize, weight: .bold)
        titleLabel.textColor = C.accentColor
        addSubview(titleLabel)
    }

    private func setupSpritePreview() {
        let spriteSize: CGFloat = 100
        let spriteX: CGFloat = 20
        let spriteY: CGFloat = 55

        // Container with border
        spriteContainer = NSView(frame: NSRect(x: spriteX, y: spriteY, width: spriteSize, height: spriteSize))
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

    private func setupAppInfo() {
        let textX: CGFloat = 140

        // App name
        appNameLabel = NSTextField(labelWithString: "Clawdachi")
        appNameLabel.frame = NSRect(x: textX, y: 60, width: 200, height: 24)
        appNameLabel.font = NSFont.monospacedSystemFont(ofSize: 16, weight: .bold)
        appNameLabel.textColor = C.accentColor
        addSubview(appNameLabel)

        // Version
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        versionLabel = NSTextField(labelWithString: "v\(version) (\(build))")
        versionLabel.frame = NSRect(x: textX, y: 88, width: 200, height: 16)
        versionLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        versionLabel.textColor = C.textDimColor
        addSubview(versionLabel)

        // Description
        descriptionLabel = NSTextField(labelWithString: "A desktop companion\nfor Claude Code")
        descriptionLabel.frame = NSRect(x: textX, y: 112, width: 250, height: 36)
        descriptionLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        descriptionLabel.textColor = C.textColor
        descriptionLabel.maximumNumberOfLines = 2
        addSubview(descriptionLabel)
    }

    private func setupGithubButton() {
        let buttonFrame = NSRect(x: 20, y: 175, width: 140, height: 24)
        githubButton = SettingsButton(frame: buttonFrame, title: "View on GitHub")
        githubButton.target = self
        githubButton.action = #selector(githubClicked)
        addSubview(githubButton)
    }

    private func setupCredits() {
        creditsLabel = NSTextField(labelWithString: "Made with <3 by Chris")
        creditsLabel.frame = NSRect(x: 20, y: 220, width: 200, height: 16)
        creditsLabel.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        creditsLabel.textColor = C.textDimColor
        addSubview(creditsLabel)
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

    @objc private func githubClicked() {
        if let url = URL(string: "https://github.com/chrisgonzgonz/Clawdachi") {
            NSWorkspace.shared.open(url)
        }
    }
}
