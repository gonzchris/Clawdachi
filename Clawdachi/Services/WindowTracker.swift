//
//  WindowTracker.swift
//  Clawdachi
//
//  Tracks the last-focused window using Accessibility APIs
//  Used to restore focus after voice input transcription
//

import AppKit
import ApplicationServices

/// Tracks and restores focus to the last-focused window
final class WindowTracker {
    static let shared = WindowTracker()

    // MARK: - Properties

    /// The window that was focused before voice input activation
    private var lastFocusedWindow: AXUIElement?

    /// The PID of the app that owned the focused window
    private var lastFocusedPID: pid_t?

    /// The app reference for activation
    private var lastFocusedApp: NSRunningApplication?

    // MARK: - Initialization

    private init() {}

    // MARK: - Window Tracking

    /// Capture the currently focused window (call before starting voice input)
    func captureCurrentWindow() {
        // Get the frontmost application (excluding Clawdachi)
        let clawdachiPID = ProcessInfo.processInfo.processIdentifier

        // Try to get the focused application via Accessibility API
        let systemWide = AXUIElementCreateSystemWide()

        var focusedAppElement: AnyObject?
        let appResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedAppElement
        )

        guard appResult == .success, let appElement = focusedAppElement else {
            // Fallback: use frontmost app from NSWorkspace
            if let frontApp = NSWorkspace.shared.frontmostApplication,
               frontApp.processIdentifier != clawdachiPID {
                lastFocusedApp = frontApp
                lastFocusedPID = frontApp.processIdentifier
                lastFocusedWindow = nil
            }
            return
        }

        // Get the PID of the focused app
        var pid: pid_t = 0
        AXUIElementGetPid(appElement as! AXUIElement, &pid)

        // Skip if it's Clawdachi itself
        if pid == clawdachiPID {
            // Try to get the previously active app
            let apps = NSWorkspace.shared.runningApplications.filter {
                $0.activationPolicy == .regular && $0.processIdentifier != clawdachiPID
            }
            // Find the most recently activated app that isn't Clawdachi
            if let recentApp = apps.first(where: { $0.isActive }) ?? apps.first {
                lastFocusedApp = recentApp
                lastFocusedPID = recentApp.processIdentifier
                lastFocusedWindow = getMainWindow(for: recentApp.processIdentifier)
            }
            return
        }

        lastFocusedPID = pid
        lastFocusedApp = NSRunningApplication(processIdentifier: pid)

        // Get the focused window
        var focusedWindowElement: AnyObject?
        let windowResult = AXUIElementCopyAttributeValue(
            appElement as! AXUIElement,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindowElement
        )

        if windowResult == .success {
            lastFocusedWindow = (focusedWindowElement as! AXUIElement)
        } else {
            // Fallback: try to get main window
            lastFocusedWindow = getMainWindow(for: pid)
        }
    }

    /// Restore focus to the previously captured window
    func restoreFocus() {
        // First, activate the app
        if let app = lastFocusedApp {
            app.activate()
        } else if let pid = lastFocusedPID,
                  let app = NSRunningApplication(processIdentifier: pid) {
            app.activate()
        }

        // Then, raise the specific window if we have it
        if let window = lastFocusedWindow {
            AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        }
    }

    /// Clear tracked window (call when voice input is cancelled)
    func clearTrackedWindow() {
        lastFocusedWindow = nil
        lastFocusedPID = nil
        lastFocusedApp = nil
    }

    // MARK: - Private

    private func getMainWindow(for pid: pid_t) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)

        var mainWindow: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXMainWindowAttribute as CFString,
            &mainWindow
        )

        if result == .success {
            return (mainWindow as! AXUIElement)
        }

        // Fallback: get first window from windows array
        var windows: AnyObject?
        let windowsResult = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windows
        )

        if windowsResult == .success,
           let windowArray = windows as? [AXUIElement],
           let firstWindow = windowArray.first {
            return firstWindow
        }

        return nil
    }
}
