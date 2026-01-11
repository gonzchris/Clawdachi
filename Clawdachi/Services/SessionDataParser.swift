//
//  SessionDataParser.swift
//  Clawdachi
//
//  Shared session data model and parsing utilities
//

import Foundation

/// Raw session data from Claude session files
struct SessionData: Codable {
    let status: String
    let timestamp: Double
    let session_id: String?
    let tool_name: String?
    let cwd: String?
    let tty: String?
}

/// Utilities for parsing session data files
enum SessionDataParser {

    /// Parse session data from a file URL
    /// - Parameter url: Path to the session JSON file
    /// - Returns: Parsed SessionData or nil if parsing fails
    static func parse(from url: URL) -> SessionData? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return parse(from: data)
    }

    /// Parse session data from raw Data
    /// - Parameter data: Raw JSON data
    /// - Returns: Parsed SessionData or nil if parsing fails
    static func parse(from data: Data) -> SessionData? {
        try? JSONDecoder().decode(SessionData.self, from: data)
    }
}
