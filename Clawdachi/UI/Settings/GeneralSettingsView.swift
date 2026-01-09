//
//  GeneralSettingsView.swift
//  Clawdachi
//
//  General settings section
//

import AppKit

/// General settings section with launch at login and position options
class GeneralSettingsView: NSView {

    private typealias C = SettingsConstants

    // MARK: - Properties

    private var titleLabel: NSTextField!
    private var launchAtLoginCheckbox: NSButton!
    private var rememberPositionCheckbox: NSButton!
    private var resetPositionButton: SettingsButton!

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
        setupCheckboxes()
        setupResetButton()
        loadSettings()
    }

    override var isFlipped: Bool { true }

    // MARK: - UI Setup

    private func setupTitle() {
        titleLabel = NSTextField(labelWithString: "GENERAL")
        titleLabel.frame = NSRect(x: 20, y: 20, width: 200, height: 20)
        titleLabel.font = NSFont.monospacedSystemFont(ofSize: C.titleFontSize, weight: .bold)
        titleLabel.textColor = C.accentColor
        addSubview(titleLabel)
    }

    private func setupCheckboxes() {
        // Launch at login
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: self, action: #selector(checkboxChanged(_:)))
        launchAtLoginCheckbox.frame = NSRect(x: 20, y: 60, width: 200, height: 24)
        styleCheckbox(launchAtLoginCheckbox)
        addSubview(launchAtLoginCheckbox)

        // Remember position
        rememberPositionCheckbox = NSButton(checkboxWithTitle: "Remember window position", target: self, action: #selector(checkboxChanged(_:)))
        rememberPositionCheckbox.frame = NSRect(x: 20, y: 100, width: 250, height: 24)
        styleCheckbox(rememberPositionCheckbox)
        addSubview(rememberPositionCheckbox)
    }

    private func setupResetButton() {
        let resetFrame = NSRect(x: 20, y: 150, width: 120, height: 24)
        resetPositionButton = SettingsButton(frame: resetFrame, title: "Reset Position")
        resetPositionButton.target = self
        resetPositionButton.action = #selector(resetPositionClicked)
        addSubview(resetPositionButton)
    }

    private func styleCheckbox(_ checkbox: NSButton) {
        checkbox.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        checkbox.contentTintColor = C.accentColor
        // Set text color through attributed title
        if let title = checkbox.title as NSString? {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: C.textColor
            ]
            checkbox.attributedTitle = NSAttributedString(string: title as String, attributes: attrs)
        }
    }

    // MARK: - Settings

    private func loadSettings() {
        launchAtLoginCheckbox.state = SettingsManager.shared.launchAtLogin ? .on : .off
        rememberPositionCheckbox.state = SettingsManager.shared.rememberPosition ? .on : .off
    }

    @objc private func checkboxChanged(_ sender: NSButton) {
        if sender === launchAtLoginCheckbox {
            SettingsManager.shared.launchAtLogin = (sender.state == .on)
        } else if sender === rememberPositionCheckbox {
            SettingsManager.shared.rememberPosition = (sender.state == .on)
        }
    }

    @objc private func resetPositionClicked() {
        // Reset to default position (center of screen)
        NotificationCenter.default.post(name: .resetSpritePosition, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let resetSpritePosition = Notification.Name("resetSpritePosition")
}
