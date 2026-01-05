//
//  MusicPlaybackMonitor.swift
//  Clawdachi
//
//  Monitors Apple Music and Spotify playback state via AppleScript polling
//

import Foundation

/// Monitors music playback from Apple Music and Spotify
class MusicPlaybackMonitor {

    // MARK: - Properties

    /// Whether music is currently playing
    private(set) var isPlaying = false

    /// Callback when playback state changes
    var onPlaybackStateChanged: ((Bool) -> Void)?

    /// Polling timer
    private var pollTimer: Timer?

    /// Polling interval in seconds
    private let pollInterval: TimeInterval = 2.0

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
        checkPlaybackState()

        // Then poll periodically
        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkPlaybackState()
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func checkPlaybackState() {
        // Check on background thread to avoid blocking main thread
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let spotifyPlaying = self?.isSpotifyPlaying() ?? false
            let appleMusicPlaying = self?.isAppleMusicPlaying() ?? false
            let playing = spotifyPlaying || appleMusicPlaying

            DispatchQueue.main.async {
                self?.updatePlaybackState(playing)
            }
        }
    }

    // MARK: - AppleScript Queries

    private func isSpotifyPlaying() -> Bool {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    return "playing"
                end if
            end tell
        end if
        return "stopped"
        """
        return runAppleScript(script) == "playing"
    }

    private func isAppleMusicPlaying() -> Bool {
        let script = """
        if application "Music" is running then
            tell application "Music"
                if player state is playing then
                    return "playing"
                end if
            end tell
        end if
        return "stopped"
        """
        return runAppleScript(script) == "playing"
    }

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        return result.stringValue
    }

    // MARK: - State Update

    private func updatePlaybackState(_ playing: Bool) {
        guard playing != isPlaying else { return }
        isPlaying = playing
        onPlaybackStateChanged?(isPlaying)
    }
}
