//
//  TerminalFocusMonitor.swift
//  Clawdachi
//
//  Monitors which terminal tab is focused to auto-select the corresponding Claude session
//

import Foundation
import AppKit

/// Monitors the focused terminal tab and reports its TTY device
class TerminalFocusMonitor {

    // MARK: - Properties

    /// Currently focused terminal's TTY (e.g., "/dev/ttys003")
    private(set) var focusedTTY: String?

    /// Callback when focused TTY changes
    var onFocusedTTYChanged: ((String?) -> Void)?

    /// Polling timer
    private var pollTimer: Timer?

    /// Polling interval in seconds
    private let pollInterval: TimeInterval = 1.5

    /// Last known focused app bundle ID
    private var lastFocusedApp: String?

    /// Supported terminal bundle identifiers
    private let supportedTerminals: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty"
    ]

    // MARK: - Initialization

    init() {
        startPolling()
    }

    deinit {
        stopPolling()
    }

    // MARK: - Polling

    private func startPolling() {
        // Check immediately
        checkFocusedTerminal()

        // Poll periodically
        pollTimer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkFocusedTerminal()
        }
        RunLoop.main.add(pollTimer!, forMode: .common)
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
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
        return runAppleScript(script)
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
        return runAppleScript(script)
    }

    // MARK: - Ghostty

    private func getGhosttyTTY() -> String? {
        // Ghostty doesn't have AppleScript support yet
        // Try using the focused window's process to find TTY
        // For now, return nil - can be enhanced later
        return nil
    }

    // MARK: - AppleScript Execution

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }

        let result = script.executeAndReturnError(&error)

        if let error = error {
            // Don't log routine errors (app not running, no windows, etc.)
            if let errorNumber = error["NSAppleScriptErrorNumber"] as? Int,
               errorNumber != -1728 { // -1728 = "Can't get" (expected when no windows)
                print("Clawdachi: AppleScript error: \(error)")
            }
            return nil
        }

        guard let tty = result.stringValue, !tty.isEmpty else { return nil }
        return tty
    }
}
