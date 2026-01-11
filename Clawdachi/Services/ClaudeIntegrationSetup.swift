//
//  ClaudeIntegrationSetup.swift
//  Clawdachi
//
//  Sets up Claude Code integration on first launch by installing hooks
//

import Foundation

/// Handles automatic setup of Claude Code integration
class ClaudeIntegrationSetup {

    // MARK: - Constants

    private static let setupVersionKey = "clawdachi.claude.setupVersion"
    private static let currentSetupVersion = 4  // Increment to force re-setup on updates

    // MARK: - Public API

    /// Sets up Claude Code integration if not already done
    static func setupIfNeeded() {
        let defaults = UserDefaults.standard

        // Check if already set up with current version
        if defaults.integer(forKey: setupVersionKey) >= currentSetupVersion {
            return
        }

        // Perform setup
        do {
            try installHookScript()
            try configureClaudeHooks()

            // Mark setup complete
            defaults.set(currentSetupVersion, forKey: setupVersionKey)
        } catch {
            // Setup failed - will retry on next launch
            print("Clawdachi: Claude integration setup failed: \(error)")
        }
    }

    // MARK: - Hook Script Installation

    private static func installHookScript() throws {
        let fileManager = FileManager.default

        // Create ~/.clawdachi/hooks/ directory
        try fileManager.createDirectory(at: ClawdachiPaths.hooks, withIntermediateDirectories: true)

        // Create ~/.clawdachi/sessions/ directory
        try fileManager.createDirectory(at: ClawdachiPaths.sessions, withIntermediateDirectories: true)

        // Get script from app bundle
        guard let bundledScript = Bundle.main.url(forResource: "claude-status", withExtension: "sh") else {
            throw SetupError.scriptNotInBundle
        }

        // Copy to hooks directory (overwrite if exists)
        let destinationPath = ClawdachiPaths.hookScript

        if fileManager.fileExists(atPath: destinationPath.path) {
            try fileManager.removeItem(at: destinationPath)
        }

        try fileManager.copyItem(at: bundledScript, to: destinationPath)

        // Make executable (chmod +x)
        try fileManager.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: destinationPath.path
        )
    }

    // MARK: - Claude Hooks Configuration

    private static func configureClaudeHooks() throws {
        let fileManager = FileManager.default

        // Check if ~/.claude/ exists (Claude Code installed)
        if !fileManager.fileExists(atPath: ClawdachiPaths.claudeDir.path) {
            // Claude Code not installed - create the directory
            try fileManager.createDirectory(at: ClawdachiPaths.claudeDir, withIntermediateDirectories: true)
        }

        let settingsPath = ClawdachiPaths.claudeSettings

        // Read existing settings or create empty
        var settings: [String: Any] = [:]

        if fileManager.fileExists(atPath: settingsPath.path) {
            let data = try Data(contentsOf: settingsPath)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                settings = json
            }
        }

        // Merge our hooks
        settings = mergeHooks(into: settings)

        // Write back
        let jsonData = try JSONSerialization.data(
            withJSONObject: settings,
            options: [.prettyPrinted, .sortedKeys]
        )
        try jsonData.write(to: settingsPath)
    }

    private static func mergeHooks(into settings: [String: Any]) -> [String: Any] {
        var result = settings

        // Get or create hooks dictionary
        var hooks = (settings["hooks"] as? [String: Any]) ?? [:]

        // Hook configurations: (Claude hook event, our script argument)
        let hookConfigs: [(event: String, action: String)] = [
            ("SessionStart", "session_start"),
            ("UserPromptSubmit", "thinking"),
            ("PreToolUse", "tool_start"),
            ("PostToolUse", "tool_end"),
            ("Notification", "notification"),  // Heartbeat during long operations
            ("Stop", "stop"),
            ("PermissionRequest", "permission_request"),
            ("SessionEnd", "session_end")
        ]

        // For each hook type, check if our hook already exists and add if needed
        for config in hookConfigs {
            var existingHooks = (hooks[config.event] as? [[String: Any]]) ?? []

            // Check if we already have a clawdachi hook installed
            let hasClawdachiHook = existingHooks.contains { hookEntry in
                guard let hooksList = hookEntry["hooks"] as? [[String: Any]] else { return false }
                return hooksList.contains { hook in
                    guard let command = hook["command"] as? String else { return false }
                    return command.contains(".clawdachi/hooks/claude-status.sh")
                }
            }

            if !hasClawdachiHook {
                // Add our hook using builder helper
                existingHooks.append(buildHookEntry(action: config.action))
            }

            hooks[config.event] = existingHooks
        }

        result["hooks"] = hooks
        return result
    }

    /// Builds a standard hook entry dictionary for our status script
    private static func buildHookEntry(action: String) -> [String: Any] {
        [
            "matcher": "",
            "hooks": [
                ["type": "command", "command": "~/.clawdachi/hooks/claude-status.sh \(action)"]
            ]
        ]
    }

    // MARK: - Errors

    enum SetupError: Error {
        case scriptNotInBundle
    }
}
