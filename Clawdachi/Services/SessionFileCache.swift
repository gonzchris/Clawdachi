//
//  SessionFileCache.swift
//  Clawdachi
//
//  Caches parsed session data to avoid re-parsing unchanged files
//

import Foundation

/// Caches session data based on file modification dates
class SessionFileCache {

    // MARK: - Cache Storage

    /// Cached file modification dates (filename -> modDate)
    private var fileModDates: [String: Date] = [:]

    /// Cached parsed sessions (filename -> SessionInfo)
    private var cachedSessions: [String: SessionInfo] = [:]

    /// Last known directory modification date
    private var lastDirectoryModDate: Date?

    // MARK: - Public API

    /// Get a cached session if the file hasn't changed
    /// - Parameters:
    ///   - filename: The session file name
    ///   - currentModDate: Current modification date of the file
    /// - Returns: Cached SessionInfo if valid, nil if cache miss
    func get(filename: String, modDate currentModDate: Date?) -> SessionInfo? {
        guard let cachedModDate = fileModDates[filename],
              let currentModDate = currentModDate,
              cachedModDate == currentModDate,
              let cachedSession = cachedSessions[filename] else {
            return nil
        }
        return cachedSession
    }

    /// Store a session in the cache
    /// - Parameters:
    ///   - session: The parsed session info
    ///   - filename: The session file name
    ///   - modDate: File modification date
    func set(_ session: SessionInfo, filename: String, modDate: Date?) {
        cachedSessions[filename] = session
        if let modDate = modDate {
            fileModDates[filename] = modDate
        }
    }

    /// Remove a specific entry from the cache
    /// - Parameter filename: The session file name to remove
    func remove(filename: String) {
        cachedSessions.removeValue(forKey: filename)
        fileModDates.removeValue(forKey: filename)
    }

    /// Remove cache entries for files that no longer exist
    /// - Parameter currentFilenames: Set of currently existing file names
    func cleanupOrphaned(currentFilenames: Set<String>) {
        let orphanedFiles = Set(cachedSessions.keys).subtracting(currentFilenames)
        for filename in orphanedFiles {
            remove(filename: filename)
        }
    }

    /// Clear all cached data
    func clear() {
        lastDirectoryModDate = nil
        fileModDates.removeAll()
        cachedSessions.removeAll()
    }

    // MARK: - Directory Tracking

    /// Update tracked directory modification date
    /// - Parameter date: New modification date
    func updateDirectoryModDate(_ date: Date?) {
        lastDirectoryModDate = date
    }

    /// Get the last known directory modification date
    var directoryModDate: Date? {
        lastDirectoryModDate
    }
}
