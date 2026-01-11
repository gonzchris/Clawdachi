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
    private var terminalLabel: NSTextField!
    private var terminalPopup: NSPopUpButton!

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
        setupTerminalSelector()
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

    private func setupTerminalSelector() {
        // Label
        terminalLabel = NSTextField(labelWithString: "Launch Claude Code in:")
        terminalLabel.frame = NSRect(x: 20, y: 160, width: 180, height: 20)
        terminalLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        terminalLabel.textColor = C.textColor
        addSubview(terminalLabel)

        // Popup button
        terminalPopup = NSPopUpButton(frame: NSRect(x: 20, y: 185, width: 150, height: 24), pullsDown: false)
        terminalPopup.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        terminalPopup.target = self
        terminalPopup.action = #selector(terminalChanged(_:))

        // Add terminal options
        for terminal in ClaudeLauncher.Terminal.allCases {
            let isInstalled = ClaudeLauncher.shared.isTerminalInstalled(terminal)
            let title = isInstalled ? terminal.displayName : "\(terminal.displayName) (not installed)"
            terminalPopup.addItem(withTitle: title)
            terminalPopup.lastItem?.tag = terminal.hashValue
            terminalPopup.lastItem?.isEnabled = isInstalled
            terminalPopup.lastItem?.representedObject = terminal
        }

        addSubview(terminalPopup)
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

        // Select current terminal preference
        let currentTerminal = ClaudeLauncher.shared.preferredTerminal
        for (index, item) in terminalPopup.itemArray.enumerated() {
            if let terminal = item.representedObject as? ClaudeLauncher.Terminal,
               terminal == currentTerminal {
                terminalPopup.selectItem(at: index)
                break
            }
        }
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

    @objc private func terminalChanged(_ sender: NSPopUpButton) {
        guard let selectedItem = sender.selectedItem,
              let terminal = selectedItem.representedObject as? ClaudeLauncher.Terminal else {
            return
        }
        ClaudeLauncher.shared.preferredTerminal = terminal
    }
}
