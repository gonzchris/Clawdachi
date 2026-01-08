//
//  AppleScriptExecutor.swift
//  Clawdachi
//
//  Shared utility for executing AppleScript commands
//

import Foundation

/// Error codes returned by AppleScript
enum AppleScriptError: Int {
    /// "Can't get" - expected when app not running or no windows open
    case cantGet = -1728
}

/// Utility for executing AppleScript commands
enum AppleScriptExecutor {

    /// Execute an AppleScript and return the string result
    /// - Parameters:
    ///   - source: The AppleScript source code to execute
    ///   - logErrors: Whether to log non-routine errors (default: true)
    /// - Returns: The string result of the script, or nil if execution failed
    static func run(_ source: String, logErrors: Bool = true) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }

        let result = script.executeAndReturnError(&error)

        if let error = error {
            // Don't log routine errors (app not running, no windows, etc.)
            if logErrors,
               let errorNumber = error["NSAppleScriptErrorNumber"] as? Int,
               errorNumber != AppleScriptError.cantGet.rawValue {
                print("Clawdachi: AppleScript error: \(error)")
            }
            return nil
        }

        guard let stringValue = result.stringValue, !stringValue.isEmpty else { return nil }
        return stringValue
    }
}
