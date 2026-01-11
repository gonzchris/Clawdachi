//
//  AboutSettingsView.swift
//  Clawdachi
//
//  About section with app info and links
//

import AppKit

/// About section with version info, credits, and links
class AboutSettingsView: NSView {

    private typealias C = SettingsConstants

    // MARK: - Properties

    private var appNameLabel: NSTextField!
    private var versionLabel: NSTextField!
    private var descriptionLabel: NSTextField!
    private var websiteButton: SettingsButton!
    private var githubButton: SettingsButton!
    private var clawdachiButton: SettingsButton!
    private var twitterButton: SettingsButton!

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
        setupDescription()
        setupLinks()
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

    private func setupDescription() {
        descriptionLabel = NSTextField(labelWithString: "A desktop companion for Claude Code")
        descriptionLabel.frame = NSRect(x: 20, y: 100, width: 250, height: 20)
        descriptionLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        descriptionLabel.textColor = C.textColor
        addSubview(descriptionLabel)
    }

    private func setupLinks() {
        // Buttons inline horizontally
        let buttonY: CGFloat = 130
        var buttonX: CGFloat = 20

        // Website button
        let websiteFrame = NSRect(x: buttonX, y: buttonY, width: 100, height: 24)
        websiteButton = SettingsButton(frame: websiteFrame, title: "clawdachi.app")
        websiteButton.target = self
        websiteButton.action = #selector(websiteClicked)
        addSubview(websiteButton)
        buttonX += 110

        // GitHub button
        let githubFrame = NSRect(x: buttonX, y: buttonY, width: 70, height: 24)
        githubButton = SettingsButton(frame: githubFrame, title: "GitHub")
        githubButton.target = self
        githubButton.action = #selector(githubClicked)
        addSubview(githubButton)
        buttonX += 80

        // Clawdachi Twitter button
        let clawdachiFrame = NSRect(x: buttonX, y: buttonY, width: 100, height: 24)
        clawdachiButton = SettingsButton(frame: clawdachiFrame, title: "@clawdachi")
        clawdachiButton.target = self
        clawdachiButton.action = #selector(clawdachiClicked)
        addSubview(clawdachiButton)
        buttonX += 110

        // Chris Twitter button
        let twitterFrame = NSRect(x: buttonX, y: buttonY, width: 120, height: 24)
        twitterButton = SettingsButton(frame: twitterFrame, title: "@chrisgonzalez")
        twitterButton.target = self
        twitterButton.action = #selector(twitterClicked)
        addSubview(twitterButton)
    }

    // MARK: - Actions

    @objc private func websiteClicked() {
        if let url = URL(string: "https://clawdachi.app") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func githubClicked() {
        if let url = URL(string: "https://github.com/gonzchris/Clawdachi") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func clawdachiClicked() {
        if let url = URL(string: "https://x.com/clawdachi") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func twitterClicked() {
        if let url = URL(string: "https://x.com/chrisgonzalez") {
            NSWorkspace.shared.open(url)
        }
    }
}
