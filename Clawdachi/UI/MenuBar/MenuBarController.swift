//
//  MenuBarController.swift
//  Clawdachi
//
//  Menu bar extra for quick session switching
//

import AppKit

/// Manages the optional menu bar status item for Clawdachi
class MenuBarController {

    // MARK: - Shared Instance

    static let shared = MenuBarController()

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var currentStatus: String = "idle"

    // MARK: - Initialization

    private init() {
        setupObservers()

        // Create status item if enabled
        if SettingsManager.shared.showMenuBarIcon {
            createStatusItem()
        }
    }

    // MARK: - Setup

    private func setupObservers() {
        // Watch for setting changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(menuBarSettingChanged),
            name: .menuBarIconSettingChanged,
            object: nil
        )

        // Watch for session changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionsDidUpdate(_:)),
            name: .claudeSessionsDidUpdate,
            object: nil
        )

        // Watch for status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(statusDidChange(_:)),
            name: .claudeStatusDidChange,
            object: nil
        )
    }

    @objc private func statusDidChange(_ notification: Notification) {
        let status = notification.userInfo?["status"] as? String ?? "idle"
        updateIcon(for: status)
    }

    @objc private func menuBarSettingChanged() {
        if SettingsManager.shared.showMenuBarIcon {
            createStatusItem()
        } else {
            removeStatusItem()
        }
    }

    @objc private func sessionsDidUpdate(_ notification: Notification) {
        // Rebuild menu when sessions change
        rebuildMenu()
    }

    // MARK: - Status Item Management

    private func createStatusItem() {
        guard statusItem == nil else { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = MenuBarIconGenerator.icon(for: currentStatus)
        }

        rebuildMenu()
    }

    private func removeStatusItem() {
        guard let item = statusItem else { return }
        NSStatusBar.system.removeStatusItem(item)
        statusItem = nil
    }

    // MARK: - Icon Updates

    private func updateIcon(for status: String) {
        currentStatus = status

        guard let button = statusItem?.button else { return }
        button.image = MenuBarIconGenerator.icon(for: status)
    }

    // MARK: - Menu Building

    private func rebuildMenu() {
        guard let statusItem = statusItem else { return }

        let menu = NSMenu()

        // Launch Claude Code submenu
        let launchItem = NSMenuItem(title: "Launch Claude Code", action: nil, keyEquivalent: "")
        launchItem.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)
        let launchSubmenu = NSMenu(title: "Launch Claude Code")
        buildLaunchClaudeSubmenu(launchSubmenu)
        launchItem.submenu = launchSubmenu
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        // Active sessions
        let monitor = ClaudeSessionMonitor.shared
        let sessions = monitor.activeSessions
        let currentMode = monitor.selectionMode

        if sessions.isEmpty {
            let emptyItem = NSMenuItem(title: "No active sessions", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            // Track display names for duplicate detection
            var displayNameCounts: [String: Int] = [:]
            for session in sessions {
                displayNameCounts[session.displayName, default: 0] += 1
            }

            for session in sessions {
                var title = session.displayName
                if displayNameCounts[session.displayName, default: 0] > 1 {
                    let shortId = String(session.id.suffix(6))
                    title = "\(title) (\(shortId))"
                }

                // Status indicator
                let statusLabel = statusDisplayLabel(for: session.status)
                if !statusLabel.isEmpty {
                    title = "\(title) \(statusLabel)"
                }

                let item = NSMenuItem(
                    title: title,
                    action: #selector(selectSession(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = session.id
                item.image = statusIcon(for: session.status)

                // Check mark for currently monitored session
                let isMonitored: Bool
                switch currentMode {
                case .specific(let id):
                    isMonitored = session.id == id
                case .anyActive:
                    isMonitored = session.id == monitor.currentSessionId
                }
                item.state = isMonitored ? .on : .off

                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Sleep mode toggle
        let isSleeping = ClawdachiScene.shared?.isSleeping ?? false
        let sleepItem = NSMenuItem(
            title: isSleeping ? "Wake Up" : "Sleep Mode",
            action: #selector(toggleSleep),
            keyEquivalent: "z"
        )
        sleepItem.target = self
        sleepItem.image = NSImage(systemSymbolName: isSleeping ? "sun.max.fill" : "moon.fill", accessibilityDescription: nil)
        menu.addItem(sleepItem)

        // Quit
        let quitItem = NSMenuItem(title: "Quit Clawdachi", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func statusDisplayLabel(for status: String) -> String {
        switch status {
        case "thinking", "tools":
            return "(thinking...)"
        case "planning":
            return "(planning...)"
        case "waiting":
            return "(waiting)"
        case "error":
            return "(error)"
        default:
            return ""
        }
    }

    private func statusIcon(for status: String) -> NSImage? {
        let symbolName: String
        switch status {
        case "thinking", "tools", "planning":
            symbolName = "circle.fill"
        case "waiting":
            symbolName = "questionmark.circle"
        case "error":
            symbolName = "exclamationmark.triangle"
        default:
            symbolName = "circle"
        }
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
    }

    // MARK: - Launch Claude Submenu

    private func buildLaunchClaudeSubmenu(_ menu: NSMenu) {
        let launcher = ClaudeLauncher.shared
        let recentDirs = launcher.recentDirectories(limit: 5)
        let availableTerminals = launcher.availableTerminals()
        let preferredTerminal = launcher.preferredTerminal

        // Recent directories
        if recentDirs.isEmpty {
            let emptyItem = NSMenuItem(
                title: "(No recent projects)",
                action: nil,
                keyEquivalent: ""
            )
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for dir in recentDirs {
                let item = NSMenuItem(
                    title: dir.displayName,
                    action: #selector(launchClaudeInDirectory(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = dir.path
                item.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Browse option
        let browseItem = NSMenuItem(
            title: "Browse...",
            action: #selector(launchClaudeBrowse),
            keyEquivalent: ""
        )
        browseItem.target = self
        browseItem.image = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: nil)
        menu.addItem(browseItem)

        menu.addItem(NSMenuItem.separator())

        // Terminal preference
        if availableTerminals.isEmpty {
            let noTerminalItem = NSMenuItem(
                title: "No supported terminal found",
                action: nil,
                keyEquivalent: ""
            )
            noTerminalItem.isEnabled = false
            menu.addItem(noTerminalItem)
        } else {
            for terminal in availableTerminals {
                let item = NSMenuItem(
                    title: terminal.displayName,
                    action: #selector(selectPreferredTerminal(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = terminal.rawValue
                item.state = (terminal == preferredTerminal) ? .on : .off
                item.image = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: nil)
                menu.addItem(item)
            }
        }
    }

    // MARK: - Actions

    @objc private func selectSession(_ sender: NSMenuItem) {
        guard let sessionId = sender.representedObject as? String else { return }
        ClaudeSessionMonitor.shared.selectionMode = .specific(sessionId)
        SettingsManager.shared.sessionSelectionMode = "specific:\(sessionId)"
        rebuildMenu()
    }

    @objc private func openSettings() {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        SettingsWindow.shared.toggle(relativeTo: appDelegate.spriteWindow)
    }

    @objc private func toggleSleep() {
        ClawdachiScene.shared?.toggleSleep()
        rebuildMenu()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func launchClaudeInDirectory(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? URL else { return }

        ClawdachiScene.shared?.showChatBubble("> let's build", duration: 2.0)

        ClaudeLauncher.shared.launch(in: path) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    break
                case .terminalNotInstalled(let terminal):
                    ClawdachiScene.shared?.showChatBubble("\(terminal.displayName) not found", duration: 3.0)
                case .directoryNotFound:
                    ClawdachiScene.shared?.showChatBubble("folder not found", duration: 3.0)
                case .appleScriptError(let message):
                    ClawdachiScene.shared?.showChatBubble("error: \(message)", duration: 3.0)
                }
            }
        }
    }

    @objc private func launchClaudeBrowse() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a directory to launch Claude Code in"
        panel.prompt = "Launch Claude"

        if panel.runModal() == .OK, let url = panel.url {
            ClawdachiScene.shared?.showChatBubble("> let's build", duration: 2.0)

            ClaudeLauncher.shared.launch(in: url) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        break
                    case .terminalNotInstalled(let terminal):
                        ClawdachiScene.shared?.showChatBubble("\(terminal.displayName) not found", duration: 3.0)
                    case .directoryNotFound:
                        ClawdachiScene.shared?.showChatBubble("folder not found", duration: 3.0)
                    case .appleScriptError(let message):
                        ClawdachiScene.shared?.showChatBubble("error: \(message)", duration: 3.0)
                    }
                }
            }
        }
    }

    @objc private func selectPreferredTerminal(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let terminal = ClaudeLauncher.Terminal(rawValue: rawValue) else { return }
        ClaudeLauncher.shared.preferredTerminal = terminal
        rebuildMenu()
    }
}
