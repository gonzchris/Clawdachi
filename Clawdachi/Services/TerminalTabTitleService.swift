//
//  TerminalTabTitleService.swift
//  Clawdachi
//
//  Queries terminal tab titles for better session naming
//

import Foundation
import AppKit

/// Service to fetch terminal tab titles by TTY
class TerminalTabTitleService {

    // MARK: - Shared Instance

    static let shared = TerminalTabTitleService()

    // MARK: - Cache

    private var titleCache: [String: String] = [:]  // tty -> title
    private var lastFetchTime: [String: Date] = [:]
    private let cacheDuration: TimeInterval = 2.0  // Refresh every 2 seconds

    // MARK: - Public API

    /// Get the tab title for a given TTY, using cache when fresh
    func tabTitle(for tty: String?) -> String? {
        guard let tty = tty, !tty.isEmpty else { return nil }

        // Check cache freshness
        if let cached = titleCache[tty],
           let lastFetch = lastFetchTime[tty],
           Date().timeIntervalSince(lastFetch) < cacheDuration {
            return cached.isEmpty ? nil : cached
        }

        // Fetch fresh title
        let title = fetchTabTitle(for: tty)
        titleCache[tty] = title ?? ""
        lastFetchTime[tty] = Date()

        return title
    }

    /// Fetch titles for multiple TTYs at once (more efficient)
    func fetchAllTabTitles(for ttys: [String]) -> [String: String] {
        var results: [String: String] = [:]

        // Only query terminals that are actually running
        let runningApps = NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier }

        // Batch fetch from Terminal.app if running
        if runningApps.contains("com.apple.Terminal") {
            let terminalTitles = fetchAllTerminalAppTitles()
            for (tty, title) in terminalTitles {
                results[tty] = title
                titleCache[tty] = title
                lastFetchTime[tty] = Date()
            }
        }

        // Batch fetch from iTerm2 if running
        if runningApps.contains("com.googlecode.iterm2") {
            let iterm2Titles = fetchAllITerm2Titles()
            for (tty, title) in iterm2Titles {
                results[tty] = title
                titleCache[tty] = title
                lastFetchTime[tty] = Date()
            }
        }

        // Batch fetch from Ghostty if running
        if runningApps.contains("com.mitchellh.ghostty") {
            let ghosttyTitles = fetchAllGhosttyTitles()
            for (tty, title) in ghosttyTitles {
                results[tty] = title
                titleCache[tty] = title
                lastFetchTime[tty] = Date()
            }
        }

        return results
    }

    // MARK: - Private Fetching

    private func fetchTabTitle(for tty: String) -> String? {
        let runningApps = NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier }

        // Try Terminal.app if running
        if runningApps.contains("com.apple.Terminal") {
            if let title = fetchTerminalAppTitle(for: tty), !title.isEmpty {
                return title
            }
        }

        // Try iTerm2 if running
        if runningApps.contains("com.googlecode.iterm2") {
            if let title = fetchITerm2Title(for: tty), !title.isEmpty {
                return title
            }
        }

        // Try Ghostty if running
        if runningApps.contains("com.mitchellh.ghostty") {
            if let title = fetchGhosttyTitle(for: tty), !title.isEmpty {
                return title
            }
        }

        return nil
    }

    // MARK: - Terminal.app

    private func fetchTerminalAppTitle(for tty: String) -> String? {
        let script = """
        tell application "Terminal"
            repeat with w in windows
                set winName to name of w
                repeat with t in tabs of w
                    if tty of t is "\(tty)" then
                        return winName
                    end if
                end repeat
            end repeat
        end tell
        return ""
        """
        guard let result = AppleScriptExecutor.run(script) else { return nil }
        return parseTerminalWindowTitle(result)
    }

    private func fetchAllTerminalAppTitles() -> [String: String] {
        let script = """
        set output to ""
        tell application "Terminal"
            repeat with w in windows
                set winName to name of w
                repeat with t in tabs of w
                    set tabTTY to tty of t
                    set output to output & tabTTY & "|||" & winName & "\\n"
                end repeat
            end repeat
        end tell
        return output
        """

        guard let result = AppleScriptExecutor.run(script) else { return [:] }
        return parseTTYTitlePairs(result, parseTitle: true)
    }

    /// Parse Terminal.app window title to extract the Claude task name
    /// Format: "user — ✳ Task Name — other stuff — dimensions"
    private func parseTerminalWindowTitle(_ title: String) -> String? {
        // Look for the ✳ marker which indicates Claude is active
        if let starRange = title.range(of: "✳ ") {
            let afterStar = title[starRange.upperBound...]
            // Find the next " — " to get just the task name
            if let dashRange = afterStar.range(of: " — ") {
                let taskName = String(afterStar[..<dashRange.lowerBound])
                return taskName.trimmingCharacters(in: .whitespaces)
            }
            // No dash after, take the rest but trim dimensions
            let remaining = String(afterStar)
            // Remove trailing dimensions like "— 107×30"
            if let lastDash = remaining.range(of: " — ", options: .backwards) {
                return String(remaining[..<lastDash.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
            return remaining.trimmingCharacters(in: .whitespaces)
        }
        return nil
    }

    // MARK: - iTerm2

    private func fetchITerm2Title(for tty: String) -> String? {
        let script = """
        tell application "iTerm2"
            repeat with w in windows
                repeat with t in tabs of w
                    repeat with s in sessions of t
                        if tty of s is "\(tty)" then
                            return name of s
                        end if
                    end repeat
                end repeat
            end repeat
        end tell
        return ""
        """
        return AppleScriptExecutor.run(script)
    }

    private func fetchAllITerm2Titles() -> [String: String] {
        let script = """
        set output to ""
        tell application "iTerm2"
            repeat with w in windows
                repeat with t in tabs of w
                    repeat with s in sessions of t
                        set sessionTTY to tty of s
                        set sessionName to name of s
                        set output to output & sessionTTY & "|||" & sessionName & "\\n"
                    end repeat
                end repeat
            end repeat
        end tell
        return output
        """

        guard let result = AppleScriptExecutor.run(script) else { return [:] }
        return parseTTYTitlePairs(result)
    }

    // MARK: - Ghostty

    private func fetchGhosttyTitle(for tty: String) -> String? {
        // Ghostty doesn't expose TTY via AppleScript, so we use window titles
        // and try to match based on the Claude task marker (✳)
        let script = """
        tell application "System Events"
            tell process "Ghostty"
                set windowNames to name of every window
                return windowNames as text
            end tell
        end tell
        """
        guard let result = AppleScriptExecutor.run(script) else { return nil }
        return parseGhosttyWindowTitle(result)
    }

    private func fetchAllGhosttyTitles() -> [String: String] {
        // For Ghostty, we can't match by TTY, so we return titles keyed by a synthetic ID
        // The caller will need to handle this specially
        let script = """
        set output to ""
        tell application "System Events"
            tell process "Ghostty"
                repeat with w in windows
                    set winName to name of w
                    set output to output & winName & "\\n"
                end repeat
            end tell
        end tell
        return output
        """

        guard let result = AppleScriptExecutor.run(script) else { return [:] }

        // Parse window titles and look for Claude markers
        var results: [String: String] = [:]
        for line in result.components(separatedBy: "\n") {
            let title = line.trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }

            // Try to parse Claude task from window title
            if let parsed = parseGhosttyWindowTitle(title), !parsed.isEmpty {
                // Use the full title as a synthetic key since we don't have TTY
                // Sessions will be matched by content similarity
                results["ghostty:\(title)"] = parsed
            }
        }

        return results
    }

    /// Parse Ghostty window title to extract Claude task name
    /// Ghostty window titles typically show: "command — directory" or custom title
    private func parseGhosttyWindowTitle(_ title: String) -> String? {
        // Look for the ✳ marker which indicates Claude is active
        if let starRange = title.range(of: "✳ ") {
            let afterStar = title[starRange.upperBound...]
            // Find the next " — " to get just the task name
            if let dashRange = afterStar.range(of: " — ") {
                let taskName = String(afterStar[..<dashRange.lowerBound])
                return taskName.trimmingCharacters(in: .whitespaces)
            }
            return String(afterStar).trimmingCharacters(in: .whitespaces)
        }

        // No ✳ marker - check if it looks like a Claude session
        // Ghostty often shows "claude — /path/to/dir" or similar
        if title.lowercased().contains("claude") {
            return nil  // Has Claude but no active task
        }

        return nil
    }

    // MARK: - Parsing

    private func parseTTYTitlePairs(_ output: String, parseTitle: Bool = false) -> [String: String] {
        var results: [String: String] = [:]

        for line in output.components(separatedBy: "\n") {
            let parts = line.components(separatedBy: "|||")
            if parts.count == 2 {
                let tty = parts[0].trimmingCharacters(in: .whitespaces)
                let rawTitle = parts[1].trimmingCharacters(in: .whitespaces)

                guard !tty.isEmpty else { continue }

                // For Terminal.app, parse the window title to extract task name
                // Only include if we found a valid task (has ✳ marker)
                if parseTitle {
                    if let parsed = parseTerminalWindowTitle(rawTitle), !parsed.isEmpty {
                        results[tty] = parsed
                    }
                    // If no ✳ marker, don't add - will fall back to "Project — Claude Code"
                } else if !rawTitle.isEmpty {
                    results[tty] = rawTitle
                }
            }
        }

        return results
    }
}
