//
//  ClaudeSessionMonitor.swift
//  Clawdachi
//
//  Monitors Claude Code sessions by polling ~/.clawdachi/sessions/ for status files
//

import Foundation

/// Monitors Claude Code session status by watching session files
class ClaudeSessionMonitor {

    // MARK: - Properties

    /// Whether any Claude session is currently active
    private(set) var isActive = false

    /// Current status from most recent session ("thinking", "tools", etc.)
    private(set) var currentStatus: String?

    /// Callback when session status changes
    var onStatusChanged: ((Bool, String?) -> Void)?

    /// Polling timer
    private var pollTimer: Timer?

    /// Polling interval in seconds
    private let pollInterval: TimeInterval = 1.0

    /// Sessions directory path
    private let sessionsPath: URL

    // MARK: - Initialization

    init() {
        sessionsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".clawdachi/sessions")
        startPolling()
    }

    deinit {
        stopPolling()
    }

    // MARK: - Polling

    private func startPolling() {
        // Check immediately
        checkSessionStatus()

        // Then poll periodically - ensure timer runs on main run loop in common mode
        // so it fires even during UI tracking (like dragging)
        pollTimer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkSessionStatus()
        }
        RunLoop.main.add(pollTimer!, forMode: .common)
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func checkSessionStatus() {
        // Check on background thread to avoid blocking main thread
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            let result = self.readSessionFiles()

            DispatchQueue.main.async {
                self.updateStatus(isActive: result.isActive, status: result.status)
            }
        }
    }

    // MARK: - Session File Reading

    private func readSessionFiles() -> (isActive: Bool, status: String?) {
        let fileManager = FileManager.default

        // Ensure directory exists
        guard fileManager.fileExists(atPath: sessionsPath.path) else {
            return (false, nil)
        }

        do {
            let files = try fileManager.contentsOfDirectory(
                at: sessionsPath,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

            let jsonFiles = files.filter { $0.pathExtension == "json" }

            if jsonFiles.isEmpty {
                return (false, nil)
            }

            // Find most recent session by timestamp in file contents
            var mostRecentStatus: String?
            var mostRecentTimestamp: Double = 0
            let now = Date().timeIntervalSince1970

            for file in jsonFiles {
                if let session = parseSessionFile(at: file) {
                    // Skip stale sessions (older than threshold)
                    let age = now - session.timestamp
                    if age > AnimationTimings.sessionStalenessThreshold {
                        continue
                    }

                    if session.timestamp > mostRecentTimestamp {
                        mostRecentTimestamp = session.timestamp
                        mostRecentStatus = session.status
                    }
                }
            }

            // Only active if we found a non-stale session
            let hasActiveSession = mostRecentTimestamp > 0
            return (hasActiveSession, mostRecentStatus)

        } catch {
            return (false, nil)
        }
    }

    private func parseSessionFile(at url: URL) -> SessionData? {
        do {
            let data = try Data(contentsOf: url)
            let session = try JSONDecoder().decode(SessionData.self, from: data)
            return session
        } catch {
            return nil
        }
    }

    // MARK: - State Update

    private func updateStatus(isActive: Bool, status: String?) {
        // Only fire callback if state actually changed
        guard isActive != self.isActive || status != self.currentStatus else { return }

        self.isActive = isActive
        self.currentStatus = status
        onStatusChanged?(isActive, status)
    }
}

// MARK: - Session Data Model

private struct SessionData: Codable {
    let status: String
    let timestamp: Double
    let session_id: String?
    let tool_name: String?
    let cwd: String?
}
