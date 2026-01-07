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
    let tty: String?  // Terminal TTY device (e.g., /dev/ttys003)

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

    /// Whether to auto-select session based on focused terminal TTY
    var autoSelectByTTY: Bool = true

    /// Update selected session based on focused terminal TTY
    /// - Parameter tty: The TTY device of the focused terminal (e.g., "/dev/ttys003")
    func selectSessionByTTY(_ tty: String?) {
        guard autoSelectByTTY, let tty = tty else { return }

        // Find session with matching TTY
        if let matchingSession = activeSessions.first(where: { $0.tty == tty }) {
            // Only update if different from current selection
            if selectedSessionId != matchingSession.id {
                selectedSessionId = matchingSession.id
            }
        }
    }

    /// Callback when session status changes (isActive, status, sessionId)
    var onStatusChanged: ((Bool, String?, String?) -> Void)?

    /// Callback when the list of active sessions changes
    var onSessionListChanged: (([SessionInfo]) -> Void)?

    /// Polling timer
    private var pollTimer: Timer?

    /// Polling interval in seconds (2.0s balances responsiveness with resource usage)
    private let pollInterval: TimeInterval = 2.0

    /// Sessions directory path
    private let sessionsPath: URL

    /// Last known directory modification date (for change detection)
    private var lastDirectoryModDate: Date?

    /// Cached file modification dates (filename -> modDate)
    private var fileModDates: [String: Date] = [:]

    /// Cached parsed sessions (filename -> SessionInfo)
    private var cachedSessions: [String: SessionInfo] = [:]

    /// Serial queue for thread-safe cache access
    private let cacheQueue = DispatchQueue(label: "com.clawdachi.sessioncache")

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
        // Check on serial queue to avoid blocking main thread and ensure thread safety
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            let result = self.readSessionFiles()
            print("Clawdachi: Poll result - isActive: \(result.isActive), status: \(result.status ?? "nil"), sessionId: \(result.sessionId ?? "nil")")

            DispatchQueue.main.async {
                self.updateStatus(
                    isActive: result.isActive,
                    status: result.status,
                    sessionId: result.sessionId,
                    allSessions: result.allSessions
                )
            }
        }
    }

    // MARK: - Session File Reading

    private func readSessionFiles() -> (isActive: Bool, status: String?, sessionId: String?, allSessions: [SessionInfo]) {
        let fileManager = FileManager.default

        // Ensure directory exists
        guard fileManager.fileExists(atPath: sessionsPath.path) else {
            clearCache()
            return (false, nil, nil, [])
        }

        // Check directory modification date to skip unnecessary file reads
        let dirAttributes = try? fileManager.attributesOfItem(atPath: sessionsPath.path)
        let dirModDate = dirAttributes?[.modificationDate] as? Date

        // If directory hasn't changed and we have cached data, use cache
        // (but still need to check timestamps for staleness)
        let dirChanged = dirModDate != lastDirectoryModDate
        if dirChanged {
            lastDirectoryModDate = dirModDate
        }

        do {
            let files = try fileManager.contentsOfDirectory(
                at: sessionsPath,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )

            let jsonFiles = files.filter { $0.pathExtension == "json" }

            if jsonFiles.isEmpty {
                clearCache()
                return (false, nil, nil, [])
            }

            // Track which files still exist (for cache cleanup)
            var currentFiles = Set<String>()

            // Collect all valid sessions
            var sessions: [SessionInfo] = []
            var sessionsToDelete: [URL] = []
            let now = Date().timeIntervalSince1970

            for file in jsonFiles {
                let filename = file.lastPathComponent
                currentFiles.insert(filename)

                // Check file modification date
                let fileAttributes = try? file.resourceValues(forKeys: [.contentModificationDateKey])
                let fileModDate = fileAttributes?.contentModificationDate

                // Use cached session if file hasn't changed
                if let cachedModDate = fileModDates[filename],
                   let currentModDate = fileModDate,
                   cachedModDate == currentModDate,
                   let cachedSession = cachedSessions[filename] {
                    // For idle sessions, check if terminal is still open
                    if cachedSession.status == "idle" {
                        if isTerminalOpen(tty: cachedSession.tty) {
                            sessions.append(cachedSession)
                        } else {
                            // Terminal closed - mark for cleanup
                            sessionsToDelete.append(file)
                        }
                    } else {
                        // For active sessions, apply staleness threshold
                        let age = now - cachedSession.timestamp
                        if age <= AnimationTimings.sessionStalenessThreshold {
                            sessions.append(cachedSession)
                        }
                    }
                    continue
                }

                // File is new or modified - parse it
                if let session = parseSessionFile(at: file) {
                    // Update cache
                    cachedSessions[filename] = session
                    fileModDates[filename] = fileModDate

                    // For idle sessions, check if terminal is still open
                    if session.status == "idle" {
                        if isTerminalOpen(tty: session.tty) {
                            sessions.append(session)
                        } else {
                            // Terminal closed - mark for cleanup
                            sessionsToDelete.append(file)
                        }
                    } else {
                        // For active sessions, apply staleness threshold
                        let age = now - session.timestamp
                        if age <= AnimationTimings.sessionStalenessThreshold {
                            sessions.append(session)
                        }
                    }
                }
            }

            // Clean up session files for closed terminals
            for file in sessionsToDelete {
                try? fileManager.removeItem(at: file)
                let filename = file.lastPathComponent
                cachedSessions.removeValue(forKey: filename)
                fileModDates.removeValue(forKey: filename)
                currentFiles.remove(filename)
            }

            // Clean up cache for deleted files
            let deletedFiles = Set(cachedSessions.keys).subtracting(currentFiles)
            for filename in deletedFiles {
                cachedSessions.removeValue(forKey: filename)
                fileModDates.removeValue(forKey: filename)
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
            return (hasActiveSession, monitoredSession?.status, monitoredSession?.id, sessions)

        } catch {
            return (false, nil, nil, [])
        }
    }

    /// Check if a terminal is still open by verifying the TTY device exists
    private func isTerminalOpen(tty: String?) -> Bool {
        guard let tty = tty, !tty.isEmpty else {
            // No TTY info - assume still open (will be cleaned up by staleness)
            return true
        }
        return FileManager.default.fileExists(atPath: tty)
    }

    private func parseSessionFile(at url: URL) -> SessionInfo? {
        do {
            let data = try Data(contentsOf: url)
            let session = try JSONDecoder().decode(SessionData.self, from: data)
            return SessionInfo(
                id: session.session_id ?? url.deletingPathExtension().lastPathComponent,
                status: session.status,
                timestamp: session.timestamp,
                cwd: session.cwd,
                tty: session.tty
            )
        } catch {
            return nil
        }
    }

    private func clearCache() {
        lastDirectoryModDate = nil
        fileModDates.removeAll()
        cachedSessions.removeAll()
    }

    // MARK: - State Update

    /// Currently monitored session ID
    private(set) var currentSessionId: String?

    private func updateStatus(isActive: Bool, status: String?, sessionId: String?, allSessions: [SessionInfo]) {
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
        let statusChanged = isActive != self.isActive || status != self.currentStatus || sessionId != self.currentSessionId
        print("Clawdachi: updateStatus check - new(\(isActive), \(status ?? "nil"), \(sessionId ?? "nil")) vs current(\(self.isActive), \(self.currentStatus ?? "nil"), \(self.currentSessionId ?? "nil")) -> changed: \(statusChanged)")

        guard statusChanged else { return }

        self.isActive = isActive
        self.currentStatus = status
        self.currentSessionId = sessionId
        print("Clawdachi: Firing onStatusChanged callback")
        onStatusChanged?(isActive, status, sessionId)
    }
}

// MARK: - Session Data Model (internal JSON parsing)

private struct SessionData: Codable {
    let status: String
    let timestamp: Double
    let session_id: String?
    let tool_name: String?
    let cwd: String?
    let tty: String?
}
