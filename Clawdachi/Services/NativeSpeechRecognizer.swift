//
//  NativeSpeechRecognizer.swift
//  Clawdachi
//
//  Wrapper around macOS SFSpeechRecognizer for native speech-to-text
//

import Foundation
import Speech

/// Native macOS speech recognition using SFSpeechRecognizer
final class NativeSpeechRecognizer: SpeechRecognizer {

    // MARK: - Properties

    private let recognizer: SFSpeechRecognizer?
    private var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    var isAvailable: Bool {
        guard authorizationStatus == .authorized else { return false }
        return recognizer?.isAvailable == true
    }

    // MARK: - Initialization

    init(locale: Locale = Locale(identifier: "en-US")) {
        recognizer = SFSpeechRecognizer(locale: locale)

        // Check current authorization status
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }

    // MARK: - Authorization

    /// Request speech recognition authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            self?.authorizationStatus = status
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    // MARK: - Transcription

    func transcribe(audioURL: URL, completion: @escaping (Result<String, SpeechRecognitionError>) -> Void) {
        // Check authorization
        guard authorizationStatus == .authorized else {
            // Try to request authorization first
            requestAuthorization { [weak self] authorized in
                if authorized {
                    self?.performTranscription(audioURL: audioURL, completion: completion)
                } else {
                    completion(.failure(.notAuthorized))
                }
            }
            return
        }

        performTranscription(audioURL: audioURL, completion: completion)
    }

    // MARK: - Private

    private func performTranscription(audioURL: URL, completion: @escaping (Result<String, SpeechRecognitionError>) -> Void) {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("[Speech] Recognizer not available")
            completion(.failure(.unavailable))
            return
        }

        // Verify file exists
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            print("[Speech] Audio file not found: \(audioURL.path)")
            completion(.failure(.recognitionFailed(underlying: nil)))
            return
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.requiresOnDeviceRecognition = false  // Allow network for better results

        print("[Speech] Starting transcription of: \(audioURL.lastPathComponent)")

        recognizer.recognitionTask(with: request) { result, error in
            // Handle completion
            if let error = error {
                print("[Speech] Error: \(error.localizedDescription)")
                // Check if it's a "no speech" error
                let nsError = error as NSError
                print("[Speech] Error domain: \(nsError.domain), code: \(nsError.code)")
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                    completion(.failure(.noSpeechDetected))
                } else {
                    completion(.failure(.recognitionFailed(underlying: error)))
                }
                return
            }

            guard let result = result else {
                print("[Speech] No result returned")
                completion(.failure(.recognitionFailed(underlying: nil)))
                return
            }

            if result.isFinal {
                let text = result.bestTranscription.formattedString
                print("[Speech] Transcription result: '\(text)'")
                if text.isEmpty {
                    completion(.failure(.noSpeechDetected))
                } else {
                    completion(.success(text))
                }
            }
        }
    }
}
