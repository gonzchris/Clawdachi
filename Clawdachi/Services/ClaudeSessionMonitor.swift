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

    /// Priority for "any active" mode selection (higher = more important)
    var activityPriority: Int {
        switch status {
        case "thinking", "planning":
            return 4  // Highest - actively working
        case "tools":
            return 3  // Running tools
        case "waiting":
            return 2  // Waiting for input
        case "idle":
            return 1  // Lowest - not doing anything
        default:
            return 0  // Unknown status
        }
    }
}

/// How to select which session to monitor
enum SessionSelectionMode: Equatable {
    /// Monitor whichever session is most actively working (recommended default)
    case anyActive
    /// Follow the focused terminal tab (original behavior)
    case followFocusedTab
    /// Monitor a specific session by ID
    case specific(String)
}

/// Monitors Claude Code session status by watching session files
class ClaudeSessionMonitor: PollingService {

    // MARK: - Properties

    /// Whether any Claude session is currently active
    private(set) var isActive = false

    /// Current status from most recent session ("thinking", "tools", etc.)
    private(set) var currentStatus: String?

    /// All currently active sessions (non-stale)
    private(set) var activeSessions: [SessionInfo] = []

    /// Current selection mode for which session to monitor
    var selectionMode: SessionSelectionMode = .anyActive {
        didSet {
            // Re-check status immediately when mode changes
            checkSessionStatus()
        }
    }

    /// The TTY of the currently focused terminal (nil if not a terminal or unknown)
    private(set) var focusedTTY: String?

    /// For hysteresis in anyActive mode - prevents flickering between equal-priority sessions
    private var lastMonitoredSessionId: String?
    private var lastMonitoredTime: Date?
    private let stickinessInterval: TimeInterval = 5.0

    /// Update focused TTY (used when in followFocusedTab mode)
    /// - Parameter tty: The TTY device of the focused terminal (e.g., "/dev/ttys003")
    func updateFocusedTTY(_ tty: String?) {
        focusedTTY = tty

        // Only trigger re-check if we're in followFocusedTab mode
        if case .followFocusedTab = selectionMode {
            checkSessionStatus()
        }
    }

    /// Callback when session status changes (isActive, status, sessionId)
    var onStatusChanged: ((Bool, String?, String?) -> Void)?

    /// Callback when the list of active sessions changes
    var onSessionListChanged: (([SessionInfo]) -> Void)?

    // MARK: - PollingService

    var pollTimer: Timer?
    let pollInterval: TimeInterval = 2.0

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

    // MARK: - PollingService Implementation

    func poll() {
        checkSessionStatus()
    }

    private func checkSessionStatus() {
        // Check on serial queue to avoid blocking main thread and ensure thread safety
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            let result = self.readSessionFiles()

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

    /// Result of validating a session
    private enum SessionValidationResult {
        case valid(SessionInfo)
        case stale  // Should be deleted
        case invalid  // Parsing failed
    }

    private func readSessionFiles() -> (isActive: Bool, status: String?, sessionId: String?, allSessions: [SessionInfo]) {
        let fileManager = FileManager.default

        // Ensure directory exists
        guard fileManager.fileExists(atPath: sessionsPath.path) else {
            clearCache()
            return (false, nil, nil, [])
        }

        // Update directory modification tracking
        updateDirectoryModDate()

        do {
            let jsonFiles = try listSessionFiles()

            if jsonFiles.isEmpty {
                clearCache()
                return (false, nil, nil, [])
            }

            // Process all session files
            var sessions: [SessionInfo] = []
            var filesToDelete: [URL] = []
            var currentFilenames = Set<String>()

            for file in jsonFiles {
                let filename = file.lastPathComponent
                currentFilenames.insert(filename)

                let result = processSessionFile(file)
                switch result {
                case .valid(let session):
                    sessions.append(session)
                case .stale:
                    filesToDelete.append(file)
                case .invalid:
                    break  // Skip unparseable files
                }
            }

            // Clean up stale files and orphaned cache entries
            cleanupStaleFiles(filesToDelete)
            cleanupOrphanedCache(currentFilenames: currentFilenames)

            // Sort by timestamp (most recent first)
            sessions.sort { $0.timestamp > $1.timestamp }

            // Select which session to monitor
            let monitoredSession = selectMonitoredSession(from: sessions)

            return (monitoredSession != nil, monitoredSession?.status, monitoredSession?.id, sessions)

        } catch {
            return (false, nil, nil, [])
        }
    }

    // MARK: - File Operations

    private func updateDirectoryModDate() {
        let dirAttributes = try? FileManager.default.attributesOfItem(atPath: sessionsPath.path)
        let dirModDate = dirAttributes?[.modificationDate] as? Date
        if dirModDate != lastDirectoryModDate {
            lastDirectoryModDate = dirModDate
        }
    }

    private func listSessionFiles() throws -> [URL] {
        let files = try FileManager.default.contentsOfDirectory(
            at: sessionsPath,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        )
        return files.filter { $0.pathExtension == "json" }
    }

    // MARK: - Session Processing

    private func processSessionFile(_ file: URL) -> SessionValidationResult {
        let filename = file.lastPathComponent
        let fileAttributes = try? file.resourceValues(forKeys: [.contentModificationDateKey])
        let fileModDate = fileAttributes?.contentModificationDate

        // Try to use cached session if file hasn't changed
        if let session = getCachedSession(filename: filename, currentModDate: fileModDate) {
            return validateSession(session, file: file)
        }

        // Parse new or modified file
        guard let session = parseSessionFile(at: file) else {
            return .invalid
        }

        // Update cache
        cachedSessions[filename] = session
        fileModDates[filename] = fileModDate

        return validateSession(session, file: file)
    }

    private func getCachedSession(filename: String, currentModDate: Date?) -> SessionInfo? {
        guard let cachedModDate = fileModDates[filename],
              let currentModDate = currentModDate,
              cachedModDate == currentModDate,
              let cachedSession = cachedSessions[filename] else {
            return nil
        }
        return cachedSession
    }

    private func validateSession(_ session: SessionInfo, file: URL) -> SessionValidationResult {
        // Check if terminal is still open
        guard isTerminalOpen(tty: session.tty) else {
            return .stale
        }

        // Idle sessions are always valid if terminal is open
        if session.status == "idle" {
            return .valid(session)
        }

        // Active sessions must not be stale
        let age = Date().timeIntervalSince1970 - session.timestamp
        if age <= AnimationTimings.sessionStalenessThreshold {
            return .valid(session)
        }

        return .stale
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

    // MARK: - Session Selection

    private func selectMonitoredSession(from sessions: [SessionInfo]) -> SessionInfo? {
        switch selectionMode {
        case .specific(let sessionId):
            return sessions.first { $0.id == sessionId }

        case .followFocusedTab:
            guard let tty = focusedTTY else { return nil }
            return sessions.first { $0.tty == tty }

        case .anyActive:
            return selectMostActiveSession(from: sessions)
        }
    }

    private func selectMostActiveSession(from sessions: [SessionInfo]) -> SessionInfo? {
        // Sort by activity priority (desc), then timestamp (desc)
        let sortedByPriority = sessions.sorted { lhs, rhs in
            if lhs.activityPriority != rhs.activityPriority {
                return lhs.activityPriority > rhs.activityPriority
            }
            return lhs.timestamp > rhs.timestamp
        }

        guard let topSession = sortedByPriority.first else { return nil }

        // Apply hysteresis to prevent flickering between equal-priority sessions
        if let lastId = lastMonitoredSessionId,
           let currentSession = sessions.first(where: { $0.id == lastId }),
           currentSession.activityPriority >= topSession.activityPriority,
           let lastTime = lastMonitoredTime,
           Date().timeIntervalSince(lastTime) < stickinessInterval {
            return currentSession
        }

        // Switch to new top session
        lastMonitoredSessionId = topSession.id
        lastMonitoredTime = Date()
        return topSession
    }

    // MARK: - Cache Management

    private func cleanupStaleFiles(_ files: [URL]) {
        for file in files {
            try? FileManager.default.removeItem(at: file)
            let filename = file.lastPathComponent
            cachedSessions.removeValue(forKey: filename)
            fileModDates.removeValue(forKey: filename)
        }
    }

    private func cleanupOrphanedCache(currentFilenames: Set<String>) {
        let orphanedFiles = Set(cachedSessions.keys).subtracting(currentFilenames)
        for filename in orphanedFiles {
            cachedSessions.removeValue(forKey: filename)
            fileModDates.removeValue(forKey: filename)
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

            // If specific session no longer exists, fall back to anyActive mode
            if case .specific(let selectedId) = selectionMode,
               !allSessions.contains(where: { $0.id == selectedId }) {
                selectionMode = .anyActive
                // Note: This will trigger another checkSessionStatus() via didSet
                return
            }
        }

        // Only fire status callback if state actually changed
        let statusChanged = isActive != self.isActive || status != self.currentStatus || sessionId != self.currentSessionId

        guard statusChanged else { return }

        self.isActive = isActive
        self.currentStatus = status
        self.currentSessionId = sessionId
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
