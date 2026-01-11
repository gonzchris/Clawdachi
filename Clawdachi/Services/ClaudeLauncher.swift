//
//  ClaudeLauncher.swift
//  Clawdachi
//
//  Launches Claude Code in a terminal at a specified directory
//

import Foundation
import AppKit

class ClaudeLauncher {

    static let shared = ClaudeLauncher()

    // MARK: - Terminal Types

    enum Terminal: String, CaseIterable {
        case terminalApp = "Terminal"
        case iTerm = "iTerm"

        var bundleIdentifier: String {
            switch self {
            case .terminalApp: return "com.apple.Terminal"
            case .iTerm: return "com.googlecode.iterm2"
            }
        }

        var displayName: String {
            switch self {
            case .terminalApp: return "Terminal"
            case .iTerm: return "iTerm2"
            }
        }
    }

    // MARK: - Result Type

    enum LaunchResult {
        case success
        case terminalNotInstalled(Terminal)
        case directoryNotFound(URL)
        case appleScriptError(String)
    }

    // MARK: - Preferences

    private let preferredTerminalKey = "clawdachi.launch.preferredTerminal"

    var preferredTerminal: Terminal {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: preferredTerminalKey),
               let terminal = Terminal(rawValue: rawValue) {
                return terminal
            }
            // Default to first available terminal
            return availableTerminals().first ?? .terminalApp
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: preferredTerminalKey)
        }
    }

    // MARK: - Terminal Detection

    func availableTerminals() -> [Terminal] {
        Terminal.allCases.filter { isTerminalInstalled($0) }
    }

    func isTerminalInstalled(_ terminal: Terminal) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminal.bundleIdentifier) != nil
    }

    // MARK: - Launch

    func launch(in directory: URL, terminal: Terminal? = nil, completion: ((LaunchResult) -> Void)? = nil) {
        let targetTerminal = terminal ?? preferredTerminal

        // Verify terminal is installed
        guard isTerminalInstalled(targetTerminal) else {
            completion?(.terminalNotInstalled(targetTerminal))
            return
        }

        // Verify directory exists
        guard FileManager.default.fileExists(atPath: directory.path) else {
            completion?(.directoryNotFound(directory))
            return
        }

        // Generate and run AppleScript
        let script = generateAppleScript(for: targetTerminal, directory: directory)

        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            completion?(.appleScriptError("Failed to create AppleScript"))
            return
        }

        appleScript.executeAndReturnError(&error)

        if let error = error {
            let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            completion?(.appleScriptError(errorMessage))
        } else {
            completion?(.success)
        }
    }

    // MARK: - AppleScript Generation

    private func generateAppleScript(for terminal: Terminal, directory: URL) -> String {
        // Escape single quotes in path for shell
        let escapedPath = directory.path.replacingOccurrences(of: "'", with: "'\\''")

        switch terminal {
        case .terminalApp:
            return """
            tell application "Terminal"
                do script "cd '\(escapedPath)' && claude"
                activate
            end tell
            """

        case .iTerm:
            return """
            tell application "iTerm"
                create window with default profile
                tell current session of current window
                    write text "cd '\(escapedPath)' && claude"
                end tell
                activate
            end tell
            """
        }
    }

    // MARK: - Recent Directories

    /// Get recent directories from Claude session history
    /// - Parameter limit: Maximum number of directories to return (default 5)
    /// - Returns: Array of (displayName, path) tuples, most recent first
    func recentDirectories(limit: Int = 5) -> [(displayName: String, path: URL)] {
        let sessionsPath = ClawdachiPaths.sessions

        guard FileManager.default.fileExists(atPath: sessionsPath.path) else {
            return []
        }

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: sessionsPath,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )

            let jsonFiles = files.filter { $0.pathExtension == "json" }

            // Parse all session files and extract cwd
            var directoriesWithTimestamp: [(path: URL, timestamp: Double, displayName: String)] = []
            var seenPaths = Set<String>()

            for file in jsonFiles {
                guard let session = SessionDataParser.parse(from: file),
                      let cwdString = session.cwd else {
                    continue
                }

                let path = URL(fileURLWithPath: cwdString)
                let timestamp = session.timestamp

                // Skip duplicates (keep most recent)
                guard !seenPaths.contains(cwdString) else { continue }

                // Verify directory still exists
                guard FileManager.default.fileExists(atPath: cwdString) else { continue }

                seenPaths.insert(cwdString)
                let displayName = path.lastPathComponent
                directoriesWithTimestamp.append((path: path, timestamp: timestamp, displayName: displayName))
            }

            // Sort by timestamp (most recent first) and limit
            let sorted = directoriesWithTimestamp
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(limit)

            return sorted.map { (displayName: $0.displayName, path: $0.path) }

        } catch {
            return []
        }
    }
}
