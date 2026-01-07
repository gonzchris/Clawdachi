//
//  SpeechRecognizer.swift
//  Clawdachi
//
//  Protocol for speech recognition engines (native and Whisper)
//

import Foundation

/// Protocol for speech recognition implementations
protocol SpeechRecognizer {
    /// Whether the recognizer is ready to transcribe
    var isAvailable: Bool { get }

    /// Transcribe audio from a file URL
    /// - Parameters:
    ///   - audioURL: URL to the audio file (16kHz mono WAV)
    ///   - completion: Callback with transcription result
    func transcribe(audioURL: URL, completion: @escaping (Result<String, SpeechRecognitionError>) -> Void)
}

/// Errors that can occur during speech recognition
enum SpeechRecognitionError: Error, LocalizedError {
    case notAuthorized
    case unavailable
    case noSpeechDetected
    case recognitionFailed(underlying: Error?)
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized"
        case .unavailable:
            return "Speech recognition unavailable"
        case .noSpeechDetected:
            return "No speech detected in audio"
        case .recognitionFailed(let error):
            if let error = error {
                return "Recognition failed: \(error.localizedDescription)"
            }
            return "Recognition failed"
        case .modelNotLoaded:
            return "Whisper model not loaded"
        }
    }
}
