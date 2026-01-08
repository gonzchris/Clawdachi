//
//  TerminalFocusMonitor.swift
//  Clawdachi
//
//  Monitors which terminal tab is focused to auto-select the corresponding Claude session
//

import Foundation
import AppKit

/// Monitors the focused terminal tab and reports its TTY device
class TerminalFocusMonitor: PollingService {

    // MARK: - Properties

    /// Currently focused terminal's TTY (e.g., "/dev/ttys003")
    private(set) var focusedTTY: String?

    /// Callback when focused TTY changes
    var onFocusedTTYChanged: ((String?) -> Void)?

    /// Last known focused app bundle ID
    private var lastFocusedApp: String?

    /// Supported terminal bundle identifiers
    private let supportedTerminals: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty"
    ]

    // MARK: - PollingService

    var pollTimer: Timer?
    let pollInterval: TimeInterval = 1.5

    // MARK: - Initialization

    init() {
        startPolling()
    }

    deinit {
        stopPolling()
    }

    // MARK: - Polling

    func poll() {
        checkFocusedTerminal()
    }

    private func checkFocusedTerminal() {
        // Get the frontmost application
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontApp.bundleIdentifier else {
            updateFocusedTTY(nil)
            return
        }

        // Only process if it's a supported terminal
        guard supportedTerminals.contains(bundleId) else {
            // Not a terminal - clear focused TTY but don't spam callbacks
            if focusedTTY != nil {
                updateFocusedTTY(nil)
            }
            lastFocusedApp = bundleId
            return
        }

        // Get TTY from the appropriate terminal
        let tty: String?
        switch bundleId {
        case "com.apple.Terminal":
            tty = getTerminalAppTTY()
        case "com.googlecode.iterm2":
            tty = getITerm2TTY()
        case "com.mitchellh.ghostty":
            tty = getGhosttyTTY()
        default:
            tty = nil
        }

        lastFocusedApp = bundleId
        updateFocusedTTY(tty)
    }

    private func updateFocusedTTY(_ tty: String?) {
        guard tty != focusedTTY else { return }
        focusedTTY = tty
        onFocusedTTYChanged?(tty)
    }

    // MARK: - Terminal.app

    private func getTerminalAppTTY() -> String? {
        let script = """
        tell application "Terminal"
            if (count of windows) > 0 then
                return tty of selected tab of front window
            end if
        end tell
        return ""
        """
        return AppleScriptExecutor.run(script)
    }

    // MARK: - iTerm2

    private func getITerm2TTY() -> String? {
        let script = """
        tell application "iTerm2"
            if (count of windows) > 0 then
                return tty of current session of current tab of current window
            end if
        end tell
        return ""
        """
        return AppleScriptExecutor.run(script)
    }

    // MARK: - Ghostty

    private func getGhosttyTTY() -> String? {
        // Ghostty doesn't have AppleScript support yet
        // Try using the focused window's process to find TTY
        // For now, return nil - can be enhanced later
        return nil
    }
}
