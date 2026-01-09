//
//  SettingsManager.swift
//  Clawdachi
//
//  Manages user preferences for General and Sound settings
//

import Foundation

/// Singleton manager for app settings (General and Sound)
class SettingsManager {

    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let launchAtLogin = "clawdachi.settings.launchAtLogin"
        static let rememberPosition = "clawdachi.settings.rememberPosition"
        static let questionSoundEnabled = "clawdachi.settings.questionSound"
        static let completionSoundEnabled = "clawdachi.settings.completionSound"
        static let savedWindowX = "clawdachi.settings.windowX"
        static let savedWindowY = "clawdachi.settings.windowY"
    }

    // MARK: - Initialization

    private init() {
        // Register defaults
        defaults.register(defaults: [
            Keys.launchAtLogin: false,
            Keys.rememberPosition: true,
            Keys.questionSoundEnabled: true,
            Keys.completionSoundEnabled: true
        ])
    }

    // MARK: - General Settings

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin(newValue)
        }
    }

    var rememberPosition: Bool {
        get { defaults.bool(forKey: Keys.rememberPosition) }
        set { defaults.set(newValue, forKey: Keys.rememberPosition) }
    }

    // MARK: - Sound Settings

    var questionSoundEnabled: Bool {
        get { defaults.bool(forKey: Keys.questionSoundEnabled) }
        set { defaults.set(newValue, forKey: Keys.questionSoundEnabled) }
    }

    var completionSoundEnabled: Bool {
        get { defaults.bool(forKey: Keys.completionSoundEnabled) }
        set { defaults.set(newValue, forKey: Keys.completionSoundEnabled) }
    }

    // MARK: - Window Position

    var savedWindowPosition: NSPoint? {
        get {
            guard rememberPosition else { return nil }
            // Check if values were actually saved
            guard defaults.object(forKey: Keys.savedWindowX) != nil else { return nil }
            let x = defaults.double(forKey: Keys.savedWindowX)
            let y = defaults.double(forKey: Keys.savedWindowY)
            return NSPoint(x: x, y: y)
        }
        set {
            if let point = newValue {
                defaults.set(point.x, forKey: Keys.savedWindowX)
                defaults.set(point.y, forKey: Keys.savedWindowY)
            } else {
                defaults.removeObject(forKey: Keys.savedWindowX)
                defaults.removeObject(forKey: Keys.savedWindowY)
            }
        }
    }

    // MARK: - Launch at Login

    private func updateLaunchAtLogin(_ enabled: Bool) {
        // Note: Implementing launch at login requires ServiceManagement framework
        // and a helper app. For now, this is a placeholder.
        // TODO: Implement SMAppService for macOS 13+ or SMLoginItemSetEnabled for older versions
    }
}
