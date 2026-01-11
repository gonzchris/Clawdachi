//
//  ClawdachiPaths.swift
//  Clawdachi
//
//  Centralized file path definitions for Clawdachi
//

import Foundation

/// Centralized path definitions for all Clawdachi file locations
enum ClawdachiPaths {

    // MARK: - Base Directories

    /// User's home directory
    static let home = FileManager.default.homeDirectoryForCurrentUser

    /// ~/.clawdachi/ - Root directory for all Clawdachi data
    static let root = home.appendingPathComponent(".clawdachi")

    // MARK: - Clawdachi Subdirectories

    /// ~/.clawdachi/sessions/ - Claude session status files
    static let sessions = root.appendingPathComponent("sessions")

    /// ~/.clawdachi/hooks/ - Hook scripts for Claude integration
    static let hooks = root.appendingPathComponent("hooks")

    /// ~/.clawdachi/planmode/ - Plan mode marker files
    static let planMode = root.appendingPathComponent("planmode")

    // MARK: - Claude Code Paths

    /// ~/.claude/ - Claude Code configuration directory
    static let claudeDir = home.appendingPathComponent(".claude")

    /// ~/.claude/settings.json - Claude Code settings file
    static let claudeSettings = claudeDir.appendingPathComponent("settings.json")

    // MARK: - Hook Script

    /// Hook script filename
    static let hookScriptName = "claude-status.sh"

    /// Full path to hook script: ~/.clawdachi/hooks/claude-status.sh
    static let hookScript = hooks.appendingPathComponent(hookScriptName)
}
