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

    /// Result of an AppleScript execution
    enum ExecutionResult {
        case success(String?)
        case failure(String)
    }

    /// Execute an AppleScript and return the string result
    /// - Parameters:
    ///   - source: The AppleScript source code to execute
    ///   - logErrors: Whether to log non-routine errors (default: true)
    /// - Returns: The string result of the script, or nil if execution failed
    static func run(_ source: String, logErrors: Bool = true) -> String? {
        switch runWithResult(source, logErrors: logErrors) {
        case .success(let result):
            return result
        case .failure:
            return nil
        }
    }

    /// Execute an AppleScript and return detailed result with error info
    /// - Parameters:
    ///   - source: The AppleScript source code to execute
    ///   - logErrors: Whether to log non-routine errors (default: true)
    /// - Returns: ExecutionResult with either the string result or error message
    static func runWithResult(_ source: String, logErrors: Bool = true) -> ExecutionResult {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            return .failure("Failed to create AppleScript")
        }

        let result = script.executeAndReturnError(&error)

        if let error = error {
            let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            // Don't log routine errors (app not running, no windows, etc.)
            if logErrors,
               let errorNumber = error["NSAppleScriptErrorNumber"] as? Int,
               errorNumber != AppleScriptError.cantGet.rawValue {
                print("Clawdachi: AppleScript error: \(error)")
            }
            return .failure(errorMessage)
        }

        let stringValue = result.stringValue
        return .success(stringValue?.isEmpty == true ? nil : stringValue)
    }
}
