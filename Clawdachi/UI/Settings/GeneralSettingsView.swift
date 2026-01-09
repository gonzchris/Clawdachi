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
    private var hideDockIconCheckbox: NSButton!
    private var showMenuBarCheckbox: NSButton!

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

        // Hide dock icon
        hideDockIconCheckbox = NSButton(checkboxWithTitle: "Hide dock icon", target: self, action: #selector(checkboxChanged(_:)))
        hideDockIconCheckbox.frame = NSRect(x: 20, y: 90, width: 200, height: 24)
        styleCheckbox(hideDockIconCheckbox)
        addSubview(hideDockIconCheckbox)

        // Show menu bar icon
        showMenuBarCheckbox = NSButton(checkboxWithTitle: "Show menu bar icon", target: self, action: #selector(checkboxChanged(_:)))
        showMenuBarCheckbox.frame = NSRect(x: 20, y: 120, width: 200, height: 24)
        styleCheckbox(showMenuBarCheckbox)
        addSubview(showMenuBarCheckbox)
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
        hideDockIconCheckbox.state = SettingsManager.shared.hideDockIcon ? .on : .off
        showMenuBarCheckbox.state = SettingsManager.shared.showMenuBarIcon ? .on : .off
    }

    @objc private func checkboxChanged(_ sender: NSButton) {
        if sender === launchAtLoginCheckbox {
            SettingsManager.shared.launchAtLogin = (sender.state == .on)
        } else if sender === hideDockIconCheckbox {
            SettingsManager.shared.hideDockIcon = (sender.state == .on)
        } else if sender === showMenuBarCheckbox {
            SettingsManager.shared.showMenuBarIcon = (sender.state == .on)
            NotificationCenter.default.post(name: .menuBarIconSettingChanged, object: nil)
        }
    }
}
