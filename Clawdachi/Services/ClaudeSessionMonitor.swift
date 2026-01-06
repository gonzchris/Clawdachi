//
//  ClaudeSessionMonitor.swift
//  Clawdachi
//
//  Monitors Claude Code sessions by polling ~/.clawdachi/sessions/ for status files
//

import Foundation

/// Public session info for UI display
struct SessionInfo: Equatable {
    let id: String
    let status: String
    let timestamp: Double
    let cwd: String?

    /// Display name for the session (project folder name or truncated ID)
    var displayName: String {
        if let cwd = cwd {
            return (cwd as NSString).lastPathComponent
        }
        // Fallback to truncated session ID
        let idWithoutPrefix = id.hasPrefix("claude-session-")
            ? String(id.dropFirst("claude-session-".count))
            : id
        return String(idWithoutPrefix.prefix(8))
    }
}

/// Monitors Claude Code session status by watching session files
class ClaudeSessionMonitor {

    // MARK: - Properties

    /// Whether any Claude session is currently active
    private(set) var isActive = false

    /// Current status from most recent session ("thinking", "tools", etc.)
    private(set) var currentStatus: String?

    /// All currently active sessions (non-stale)
    private(set) var activeSessions: [SessionInfo] = []

    /// User-selected session ID to monitor (nil = auto/most recent)
    var selectedSessionId: String? {
        didSet {
            // Re-check status immediately when selection changes
            checkSessionStatus()
        }
    }

    /// Callback when session status changes
    var onStatusChanged: ((Bool, String?) -> Void)?

    /// Callback when the list of active sessions changes
    var onSessionListChanged: (([SessionInfo]) -> Void)?

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
                self.updateStatus(
                    isActive: result.isActive,
                    status: result.status,
                    allSessions: result.allSessions
                )
            }
        }
    }

    // MARK: - Session File Reading

    private func readSessionFiles() -> (isActive: Bool, status: String?, allSessions: [SessionInfo]) {
        let fileManager = FileManager.default

        // Ensure directory exists
        guard fileManager.fileExists(atPath: sessionsPath.path) else {
            return (false, nil, [])
        }

        do {
            let files = try fileManager.contentsOfDirectory(
                at: sessionsPath,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

            let jsonFiles = files.filter { $0.pathExtension == "json" }

            if jsonFiles.isEmpty {
                return (false, nil, [])
            }

            // Collect all non-stale sessions
            var sessions: [SessionInfo] = []
            let now = Date().timeIntervalSince1970

            for file in jsonFiles {
                if let session = parseSessionFile(at: file) {
                    // Skip stale sessions (older than threshold)
                    let age = now - session.timestamp
                    if age > AnimationTimings.sessionStalenessThreshold {
                        continue
                    }
                    sessions.append(session)
                }
            }

            // Sort by timestamp (most recent first)
            sessions.sort { $0.timestamp > $1.timestamp }

            // Determine which session to monitor
            let monitoredSession: SessionInfo?
            if let selectedId = selectedSessionId {
                // User selected a specific session
                monitoredSession = sessions.first { $0.id == selectedId }
                // If selected session is gone, fall back to nil (will trigger callback)
            } else {
                // Auto mode: use most recent session
                monitoredSession = sessions.first
            }

            let hasActiveSession = monitoredSession != nil
            return (hasActiveSession, monitoredSession?.status, sessions)

        } catch {
            return (false, nil, [])
        }
    }

    private func parseSessionFile(at url: URL) -> SessionInfo? {
        do {
            let data = try Data(contentsOf: url)
            let session = try JSONDecoder().decode(SessionData.self, from: data)
            return SessionInfo(
                id: session.session_id ?? url.deletingPathExtension().lastPathComponent,
                status: session.status,
                timestamp: session.timestamp,
                cwd: session.cwd
            )
        } catch {
            return nil
        }
    }

    // MARK: - State Update

    private func updateStatus(isActive: Bool, status: String?, allSessions: [SessionInfo]) {
        // Check if session list changed
        let sessionsChanged = activeSessions != allSessions
        if sessionsChanged {
            activeSessions = allSessions
            onSessionListChanged?(allSessions)

            // If selected session no longer exists, clear selection (auto mode)
            if let selectedId = selectedSessionId,
               !allSessions.contains(where: { $0.id == selectedId }) {
                selectedSessionId = nil
            }
        }

        // Only fire status callback if state actually changed
        guard isActive != self.isActive || status != self.currentStatus else { return }

        self.isActive = isActive
        self.currentStatus = status
        onStatusChanged?(isActive, status)
    }
}

// MARK: - Session Data Model (internal JSON parsing)

private struct SessionData: Codable {
    let status: String
    let timestamp: Double
    let session_id: String?
    let tool_name: String?
    let cwd: String?
}
