//
//  SoundManager.swift
//  Clawdachi
//
//  Plays notification sounds for Claude Code hook events
//

import AppKit

final class SoundManager {
    static let shared = SoundManager()

    private var questionSound: NSSound?
    private var completeSound: NSSound?
    private var startupSound: NSSound?

    private init() {
        // Load sounds from bundle
        if let url = Bundle.main.url(forResource: "Question_Notification", withExtension: "wav") {
            questionSound = NSSound(contentsOf: url, byReference: true)
        }
        if let url = Bundle.main.url(forResource: "Complete_Notification", withExtension: "wav") {
            completeSound = NSSound(contentsOf: url, byReference: true)
        }
        if let url = Bundle.main.url(forResource: "Startup", withExtension: "wav") {
            startupSound = NSSound(contentsOf: url, byReference: true)
            startupSound?.volume = 0.5
        }
    }

    /// Play sound when Claude is waiting for user input
    func playQuestionSound() {
        questionSound?.stop()  // Reset if already playing
        questionSound?.play()
    }

    /// Play sound when Claude completes a task
    func playCompleteSound() {
        completeSound?.stop()
        completeSound?.play()
    }

    /// Play startup sound during onboarding
    func playStartupSound() {
        startupSound?.stop()
        startupSound?.play()
    }
}
