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
        "> finished",
        "> shipped",
        "> yep",
        "> ok"
    ]

    // MARK: - Sleep Messages

    static let sleepMessage = "> zzz so sleepy"

    // MARK: - Time-of-Day Greetings

    static let greetingMorning = "> good morning"
    static let greetingAfternoon = "> good afternoon"
    static let greetingEvening = "> good evening"
    static let greetingLateNight = "> late night session?"

    static func greetingForCurrentTime() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<4:   return greetingLateNight
        case 4..<12:  return greetingMorning
        case 12..<18: return greetingAfternoon
        default:      return greetingEvening  // 18-23
        }
    }

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
