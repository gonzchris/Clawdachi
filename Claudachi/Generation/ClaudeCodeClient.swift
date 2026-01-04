//
//  ClaudeCodeClient.swift
//  Claudachi
//

import Foundation

/// Error types for Claude Code CLI operations
enum ClaudeCodeError: Error, LocalizedError {
    case notInstalled
    case executionFailed(String)
    case timeout
    case invalidOutput(String)

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Claude Code CLI not found"
        case .executionFailed(let message):
            return "Claude Code execution failed: \(message)"
        case .timeout:
            return "Claude Code request timed out"
        case .invalidOutput(let message):
            return "Invalid output from Claude Code: \(message)"
        }
    }
}

/// Client for interacting with Claude Code CLI
class ClaudeCodeClient {

    // MARK: - Configuration

    /// Timeout for CLI execution in seconds
    static let timeout: TimeInterval = 60

    /// Common installation paths for Claude Code CLI
    private static let searchPaths: [String] = [
        "\(FileManager.default.homeDirectoryForCurrentUser.path)/.local/bin/claude",
        "/usr/local/bin/claude",
        "/opt/homebrew/bin/claude"
    ]

    // MARK: - CLI Detection

    /// Check if Claude Code CLI is available on this system
    static func isAvailable() -> Bool {
        return locateCLI() != nil
    }

    /// Find the Claude Code CLI executable
    /// - Returns: URL to the claude executable, or nil if not found
    static func locateCLI() -> URL? {
        // Check known paths first
        for path in searchPaths {
            let url = URL(fileURLWithPath: path)

            // Try resolving symlinks first (Claude CLI is typically a symlink)
            let resolved = url.resolvingSymlinksInPath()
            if FileManager.default.isExecutableFile(atPath: resolved.path) {
                print("[ClaudeCodeClient] Found CLI at: \(resolved.path)")
                return resolved
            }

            // Try direct path check as fallback
            if FileManager.default.isExecutableFile(atPath: path) {
                print("[ClaudeCodeClient] Found CLI at: \(path)")
                return url
            }
        }

        // Fallback: try `which claude`
        if let found = findUsingWhich() {
            print("[ClaudeCodeClient] Found CLI via which: \(found.path)")
            return found
        }

        print("[ClaudeCodeClient] CLI not found in any of: \(searchPaths)")
        return nil
    }

    private static func findUsingWhich() -> URL? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["claude"]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty {
                    return URL(fileURLWithPath: path)
                }
            }
        } catch {
            // Silently fail - CLI not found
        }

        return nil
    }

    // MARK: - Generation

    /// Run a prompt through Claude Code CLI
    /// - Parameter prompt: The prompt to send to Claude
    /// - Returns: The response text from Claude
    /// - Throws: ClaudeCodeError if execution fails
    static func generate(prompt: String) async throws -> String {
        guard let cliPath = locateCLI() else {
            throw ClaudeCodeError.notInstalled
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try executeClaudeCLI(at: cliPath, prompt: prompt)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func executeClaudeCLI(at cliPath: URL, prompt: String) throws -> String {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = cliPath
        process.arguments = [
            "--print",                    // Non-interactive mode
            "--output-format", "text",    // Get plain text response
            prompt
        ]
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        print("[ClaudeCodeClient] Executing: \(cliPath.path) --print --output-format text '<prompt>'")

        // Set up timeout
        var timedOut = false
        let timeoutWorkItem = DispatchWorkItem {
            timedOut = true
            process.terminate()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        do {
            try process.run()
            print("[ClaudeCodeClient] Process started, waiting...")
            process.waitUntilExit()
            timeoutWorkItem.cancel()
            print("[ClaudeCodeClient] Process exited with status: \(process.terminationStatus)")

            if timedOut {
                print("[ClaudeCodeClient] Process timed out")
                throw ClaudeCodeError.timeout
            }

            let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

            let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
            let stderr = String(data: stderrData, encoding: .utf8) ?? ""

            print("[ClaudeCodeClient] stdout: \(stdout.count) bytes, stderr: \(stderr.count) bytes")

            if process.terminationStatus != 0 {
                let errorMessage = stderr.isEmpty ? "Exit code \(process.terminationStatus)" : stderr
                print("[ClaudeCodeClient] Execution failed: \(errorMessage)")
                throw ClaudeCodeError.executionFailed(errorMessage)
            }

            if stdout.isEmpty {
                print("[ClaudeCodeClient] Empty stdout, stderr: \(stderr)")
                throw ClaudeCodeError.invalidOutput("Empty response")
            }

            print("[ClaudeCodeClient] Response length: \(stdout.count) chars")
            return stdout.trimmingCharacters(in: .whitespacesAndNewlines)

        } catch let error as ClaudeCodeError {
            throw error
        } catch {
            throw ClaudeCodeError.executionFailed(error.localizedDescription)
        }
    }
}
