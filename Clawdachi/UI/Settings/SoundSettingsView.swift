//
//  SoundSettingsView.swift
//  Clawdachi
//
//  Sound settings section
//

import AppKit

/// Sound settings section with notification toggles
class SoundSettingsView: NSView {

    private typealias C = SettingsConstants

    // MARK: - Properties

    private var titleLabel: NSTextField!
    private var questionSoundCheckbox: NSButton!
    private var questionDescLabel: NSTextField!
    private var completionSoundCheckbox: NSButton!
    private var completionDescLabel: NSTextField!

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
        loadSettings()
    }

    override var isFlipped: Bool { true }

    // MARK: - UI Setup

    private func setupTitle() {
        titleLabel = NSTextField(labelWithString: "SOUND")
        titleLabel.frame = NSRect(x: 20, y: 20, width: 200, height: 20)
        titleLabel.font = NSFont.monospacedSystemFont(ofSize: C.titleFontSize, weight: .bold)
        titleLabel.textColor = C.accentColor
        addSubview(titleLabel)
    }

    private func setupCheckboxes() {
        // Question notification sound
        questionSoundCheckbox = NSButton(checkboxWithTitle: "Question notification", target: self, action: #selector(checkboxChanged(_:)))
        questionSoundCheckbox.frame = NSRect(x: 20, y: 60, width: 200, height: 24)
        styleCheckbox(questionSoundCheckbox)
        addSubview(questionSoundCheckbox)

        questionDescLabel = NSTextField(labelWithString: "Play sound when waiting for input")
        questionDescLabel.frame = NSRect(x: 40, y: 84, width: 250, height: 16)
        questionDescLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        questionDescLabel.textColor = C.textDimColor
        addSubview(questionDescLabel)

        // Completion notification sound
        completionSoundCheckbox = NSButton(checkboxWithTitle: "Completion notification", target: self, action: #selector(checkboxChanged(_:)))
        completionSoundCheckbox.frame = NSRect(x: 20, y: 120, width: 220, height: 24)
        styleCheckbox(completionSoundCheckbox)
        addSubview(completionSoundCheckbox)

        completionDescLabel = NSTextField(labelWithString: "Play sound when session ends")
        completionDescLabel.frame = NSRect(x: 40, y: 144, width: 250, height: 16)
        completionDescLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        completionDescLabel.textColor = C.textDimColor
        addSubview(completionDescLabel)
    }

    private func styleCheckbox(_ checkbox: NSButton) {
        checkbox.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        checkbox.contentTintColor = C.accentColor
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
        questionSoundCheckbox.state = SettingsManager.shared.questionSoundEnabled ? .on : .off
        completionSoundCheckbox.state = SettingsManager.shared.completionSoundEnabled ? .on : .off
    }

    @objc private func checkboxChanged(_ sender: NSButton) {
        if sender === questionSoundCheckbox {
            SettingsManager.shared.questionSoundEnabled = (sender.state == .on)
        } else if sender === completionSoundCheckbox {
            SettingsManager.shared.completionSoundEnabled = (sender.state == .on)
        }
    }
}
