//
//  MusicPlaybackMonitor.swift
//  Clawdachi
//
//  Monitors Apple Music and Spotify playback state via AppleScript polling
//

import Foundation

/// Monitors music playback from Apple Music and Spotify
class MusicPlaybackMonitor: PollingService {

    // MARK: - Properties

    /// Whether music is currently playing
    private(set) var isPlaying = false

    /// Callback when playback state changes
    var onPlaybackStateChanged: ((Bool) -> Void)?

    // MARK: - PollingService

    var pollTimer: Timer?
    let pollInterval: TimeInterval = 3.5

    // MARK: - Initialization

    init() {
        startPolling()
    }

    deinit {
        stopPolling()
    }

    // MARK: - Polling

    func poll() {
        // NSAppleScript must run on main thread - these checks are fast (~20ms each)
        let spotifyPlaying = isSpotifyPlaying()
        let appleMusicPlaying = isAppleMusicPlaying()
        let playing = spotifyPlaying || appleMusicPlaying
        updatePlaybackState(playing)
    }

    // MARK: - AppleScript Queries

    /// Supported music applications
    private enum MusicApp: String, CaseIterable {
        case spotify = "Spotify"
        case appleMusic = "Music"
    }

    /// Check if a specific music app is currently playing
    private func isAppPlaying(_ app: MusicApp) -> Bool {
        let script = """
        if application "\(app.rawValue)" is running then
            tell application "\(app.rawValue)"
                if player state is playing then
                    return "playing"
                end if
            end tell
        end if
        return "stopped"
        """
        return AppleScriptExecutor.run(script, logErrors: false) == "playing"
    }

    /// Check if Spotify is playing
    private func isSpotifyPlaying() -> Bool {
        isAppPlaying(.spotify)
    }

    /// Check if Apple Music is playing
    private func isAppleMusicPlaying() -> Bool {
        isAppPlaying(.appleMusic)
    }

    // MARK: - State Update

    private func updatePlaybackState(_ playing: Bool) {
        guard playing != isPlaying else { return }
        isPlaying = playing
        onPlaybackStateChanged?(isPlaying)
    }
}
