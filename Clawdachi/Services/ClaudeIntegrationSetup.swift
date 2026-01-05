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
    private static let currentSetupVersion = 1  // Increment to force re-setup on updates

    private static let hookScriptName = "claude-status.sh"
    private static let clawdachiDir = ".clawdachi"
    private static let hooksDir = "hooks"
    private static let sessionsDir = "sessions"
    private static let claudeDir = ".claude"
    private static let settingsFile = "settings.json"

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
        let homeDir = fileManager.homeDirectoryForCurrentUser

        // Create ~/.clawdachi/hooks/ directory
        let hooksPath = homeDir
            .appendingPathComponent(clawdachiDir)
            .appendingPathComponent(hooksDir)

        try fileManager.createDirectory(at: hooksPath, withIntermediateDirectories: true)

        // Create ~/.clawdachi/sessions/ directory
        let sessionsPath = homeDir
            .appendingPathComponent(clawdachiDir)
            .appendingPathComponent(sessionsDir)

        try fileManager.createDirectory(at: sessionsPath, withIntermediateDirectories: true)

        // Get script from app bundle
        guard let bundledScript = Bundle.main.url(forResource: "claude-status", withExtension: "sh") else {
            throw SetupError.scriptNotInBundle
        }

        // Copy to hooks directory (overwrite if exists)
        let destinationPath = hooksPath.appendingPathComponent(hookScriptName)

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
        let homeDir = fileManager.homeDirectoryForCurrentUser

        // Check if ~/.claude/ exists (Claude Code installed)
        let claudePath = homeDir.appendingPathComponent(claudeDir)

        if !fileManager.fileExists(atPath: claudePath.path) {
            // Claude Code not installed - create the directory
            try fileManager.createDirectory(at: claudePath, withIntermediateDirectories: true)
        }

        let settingsPath = claudePath.appendingPathComponent(settingsFile)

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

        // Our hook configurations
        let clawdachiHooks: [String: [[String: Any]]] = [
            "UserPromptSubmit": [
                [
                    "matcher": "",
                    "hooks": [
                        ["type": "command", "command": "~/.clawdachi/hooks/claude-status.sh thinking"]
                    ]
                ]
            ],
            "PreToolUse": [
                [
                    "matcher": "",
                    "hooks": [
                        ["type": "command", "command": "~/.clawdachi/hooks/claude-status.sh tool_start"]
                    ]
                ]
            ],
            "PostToolUse": [
                [
                    "matcher": "",
                    "hooks": [
                        ["type": "command", "command": "~/.clawdachi/hooks/claude-status.sh tool_end"]
                    ]
                ]
            ],
            "Stop": [
                [
                    "matcher": "",
                    "hooks": [
                        ["type": "command", "command": "~/.clawdachi/hooks/claude-status.sh stop"]
                    ]
                ]
            ]
        ]

        // For each hook type, check if our hook already exists
        for (hookType, ourHookConfig) in clawdachiHooks {
            var existingHooks = (hooks[hookType] as? [[String: Any]]) ?? []

            // Check if we already have a clawdachi hook installed
            let hasClawdachiHook = existingHooks.contains { hookEntry in
                guard let hooksList = hookEntry["hooks"] as? [[String: Any]] else { return false }
                return hooksList.contains { hook in
                    guard let command = hook["command"] as? String else { return false }
                    return command.contains(".clawdachi/hooks/claude-status.sh")
                }
            }

            if !hasClawdachiHook {
                // Add our hooks
                existingHooks.append(contentsOf: ourHookConfig)
            }

            hooks[hookType] = existingHooks
        }

        result["hooks"] = hooks
        return result
    }

    // MARK: - Errors

    enum SetupError: Error {
        case scriptNotInBundle
    }
}
