//
//  OnboardingConstants.swift
//  Clawdachi
//
//  Constants for the Onboarding window - terminal boot sequence style
//

import Foundation
import AppKit

/// Constants for the Onboarding window styling and layout
enum OnboardingConstants {

    // MARK: - Window Sizing

    /// Total window width (matches Settings)
    static let windowWidth: CGFloat = 850

    /// Total window height (matches Settings)
    static let windowHeight: CGFloat = 575

    /// Title bar height
    static let titleBarHeight: CGFloat = 28

    /// Bottom navigation bar height
    static let bottomBarHeight: CGFloat = 52

    /// Content height (between title and bottom bar)
    static let contentHeight: CGFloat = windowHeight - titleBarHeight - bottomBarHeight

    /// Border thickness (pixel art style)
    static let borderSize: CGFloat = 4

    /// Inner padding
    static let panelPadding: CGFloat = 20

    // MARK: - Steps

    enum Step: Int, CaseIterable {
        case boot = 0
        case hooks = 1
        case customize = 2

        var title: String {
            return ""
        }

        var next: Step? {
            Step(rawValue: rawValue + 1)
        }

        var previous: Step? {
            Step(rawValue: rawValue - 1)
        }
    }

    // MARK: - Boot Sequence Animation

    enum BootAnimation {
        /// Delay per line for logo reveal
        static let logoLineDelay: TimeInterval = 0.12
    }

    // MARK: - Progress Bar Animation

    enum ProgressAnimation {
        /// Total duration for progress bar fill
        static let duration: TimeInterval = 2.0

        /// Number of segments in the progress bar
        static let segments: Int = 40

        /// Delay per segment
        static let segmentDelay: TimeInterval = duration / Double(segments)
    }

    // MARK: - Jump Animation

    enum JumpAnimation {
        /// Anticipation phase (crouch)
        static let anticipationDuration: TimeInterval = 0.1

        /// Launch phase (arc trajectory)
        static let launchDuration: TimeInterval = 0.35

        /// Land phase (squash and settle)
        static let landDuration: TimeInterval = 0.15

        /// Total jump animation duration
        static let totalDuration: TimeInterval = anticipationDuration + launchDuration + landDuration

        /// Squash amount during anticipation
        static let anticipationSquash: CGFloat = 0.85

        /// Stretch amount during launch
        static let launchStretch: CGFloat = 1.15

        /// Squash amount on landing
        static let landSquash: CGFloat = 0.8
    }

    // MARK: - Navigation

    /// Step dot size
    static let dotSize: CGFloat = 8

    /// Spacing between step dots
    static let dotSpacing: CGFloat = 12

    /// Button width
    static let buttonWidth: CGFloat = 100

    /// Button height
    static let buttonHeight: CGFloat = 28

    // MARK: - Fonts

    /// Title font size
    static let titleFontSize: CGFloat = 12

    /// Section header font size
    static let sectionFontSize: CGFloat = 13

    /// Terminal text font size
    static let terminalFontSize: CGFloat = 11

    /// Logo font size (smaller for ASCII art)
    static let logoFontSize: CGFloat = 5

    // MARK: - Animation

    /// Window fade in duration
    static let fadeInDuration: TimeInterval = 0.2

    /// Window scale in duration
    static let scaleInDuration: TimeInterval = 0.2

    /// Initial scale for pop-in animation
    static let initialScale: CGFloat = 0.95

    /// Step transition duration
    static let stepTransitionDuration: TimeInterval = 0.25

    // MARK: - Colors (reuse from SettingsConstants)

    /// Main background - deep black
    static var backgroundColor: NSColor { SettingsConstants.backgroundColor }

    /// Panel/cell background - slightly lighter
    static var panelColor: NSColor { SettingsConstants.panelColor }

    /// Frame/border color - subtle green tint
    static var frameColor: NSColor { SettingsConstants.frameColor }

    /// Frame highlight (top/left edges)
    static var frameHighlight: NSColor { SettingsConstants.frameHighlight }

    /// Frame shadow (bottom/right edges)
    static var frameShadow: NSColor { SettingsConstants.frameShadow }

    /// Primary text color - terminal green/white
    static var textColor: NSColor { SettingsConstants.textColor }

    /// Dimmed text color
    static var textDimColor: NSColor { SettingsConstants.textDimColor }

    /// Accent color (Clawdachi orange)
    static var accentColor: NSColor { SettingsConstants.accentColor }

    /// Accent glow (softer)
    static var accentGlow: NSColor { SettingsConstants.accentGlow }

    // MARK: - ASCII Art

    /// The CLAWDACHI ASCII logo
    static let asciiLogo = """
   ██████╗██╗      █████╗ ██╗    ██╗██████╗  █████╗  ██████╗██╗  ██╗██╗
  ██╔════╝██║     ██╔══██╗██║    ██║██╔══██╗██╔══██╗██╔════╝██║  ██║██║
  ██║     ██║     ███████║██║ █╗ ██║██║  ██║███████║██║     ███████║██║
  ██║     ██║     ██╔══██║██║███╗██║██║  ██║██╔══██║██║     ██╔══██║██║
  ╚██████╗███████╗██║  ██║╚███╔███╔╝██████╔╝██║  ██║╚██████╗██║  ██║██║
   ╚═════╝╚══════╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝
"""

    // MARK: - ASCII Box Characters

    enum ASCII {
        static let topLeft = "┌"
        static let topRight = "┐"
        static let bottomLeft = "└"
        static let bottomRight = "┘"
        static let horizontal = "─"
        static let vertical = "│"
        static let teeRight = "├"
        static let teeLeft = "┤"
        static let teeDown = "┬"
        static let teeUp = "┴"
        static let cross = "┼"
    }
}
