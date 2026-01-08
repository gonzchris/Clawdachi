//
//  ClawdachiMessages.swift
//  Clawdachi
//

import Foundation

/// Centralized message repository for all Clawdachi speech bubbles
enum ClawdachiMessages {

    // MARK: - Claude State Messages

    static let thinkingMessages = [
        "> thinking",
        "> doing the thing",
        "> hmm",
        "> working",
        "> one sec",
        "> processing"
    ]

    static let planningMessages = [
        "> planning",
        "> lining this up",
        "> mapping it out",
        "> this might work",
        "> figuring a path",
        "> preparing"
    ]

    static let waitingMessages = [
        "> your move",
        "> awaiting input",
        "> thoughts?",
        "> over to you",
        "> ready when you are",
        "> yes / no ?"
    ]

    static let completionMessages = [
        "> done",
        "> that's done",
        "> finished",
        "> shipped",
        "> yep",
        "> ok"
    ]

    // MARK: - Random Message Getters

    static func randomThinkingMessage() -> String {
        thinkingMessages.randomElement() ?? "> thinking"
    }

    static func randomPlanningMessage() -> String {
        planningMessages.randomElement() ?? "> planning"
    }

    static func randomWaitingMessage() -> String {
        waitingMessages.randomElement() ?? "> your move"
    }

    static func randomCompletionMessage() -> String {
        completionMessages.randomElement() ?? "> done"
    }
}
