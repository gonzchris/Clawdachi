//
//  VoiceInputService.swift
//  Clawdachi
//
//  Main orchestrator for voice-to-text input functionality
//

import Foundation

/// Orchestrates voice input: captures audio, transcribes, and types into last-focused window
final class VoiceInputService {
    static let shared = VoiceInputService()

    // MARK: - Components

    private let windowTracker = WindowTracker.shared
    private let audioRecorder = AudioRecorder()
    private let textInjector = TextInjector()

    private var nativeRecognizer: NativeSpeechRecognizer?
    private var whisperRecognizer: WhisperRecognizer?

    // MARK: - State

    /// Whether voice recording is currently active
    private(set) var isRecording = false

    /// Callback when recording state changes (for sprite animation)
    var onRecordingStateChanged: ((Bool) -> Void)?

    /// Callback when transcription completes (text result or nil on failure)
    var onTranscriptionComplete: ((String?) -> Void)?

    /// Callback for error messages (for chat bubble display)
    var onError: ((String) -> Void)?

    // MARK: - Settings

    /// User preference: use Whisper if available
    static var useWhisper: Bool {
        get { UserDefaults.standard.bool(forKey: "clawdachi.voice.useWhisper") }
        set { UserDefaults.standard.set(newValue, forKey: "clawdachi.voice.useWhisper") }
    }

    // MARK: - Initialization

    private init() {
        nativeRecognizer = NativeSpeechRecognizer()

        // Initialize Whisper if model is downloaded
        if WhisperModelManager.shared.isModelDownloaded {
            whisperRecognizer = WhisperRecognizer()
        }
    }

    // MARK: - Recording Control

    /// Start voice recording
    func startRecording() {
        guard !isRecording else { return }

        // 1. Capture the currently focused window BEFORE we do anything
        windowTracker.captureCurrentWindow()

        // 2. Check/request microphone permission
        if !AudioRecorder.hasMicrophonePermission {
            AudioRecorder.requestMicrophonePermission { [weak self] granted in
                if granted {
                    self?.beginRecording()
                } else {
                    self?.onError?("need mic access!")
                }
            }
            return
        }

        beginRecording()
    }

    /// Actually start the audio recording (after permission check)
    private func beginRecording() {
        // Start audio capture
        do {
            try audioRecorder.startRecording()
            isRecording = true
            DispatchQueue.main.async {
                self.onRecordingStateChanged?(true)
            }
        } catch let error as RecordingError {
            DispatchQueue.main.async {
                switch error {
                case .permissionDenied:
                    self.onError?("need mic access!")
                case .noInputDevice:
                    self.onError?("no microphone!")
                default:
                    self.onError?("recording failed")
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.onError?("recording failed")
            }
        }
    }

    /// Stop recording and transcribe
    func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        DispatchQueue.main.async {
            self.onRecordingStateChanged?(false)
        }

        // 1. Stop audio capture and get the file URL
        let audioURL = audioRecorder.stopRecording()

        // 2. Check if recording was too short
        if audioRecorder.lastRecordingDuration < 0.5 {
            // Too short, ignore
            cleanup(audioURL: audioURL)
            return
        }

        // 3. Choose recognizer
        let recognizer: SpeechRecognizer
        if Self.useWhisper, let whisper = whisperRecognizer, whisper.isAvailable {
            print("[Voice] Using Whisper recognizer")
            recognizer = whisper
        } else if let native = nativeRecognizer {
            print("[Voice] Using native recognizer (available: \(native.isAvailable))")
            recognizer = native
        } else {
            print("[Voice] No recognizer available")
            DispatchQueue.main.async {
                self.onError?("no speech engine")
            }
            cleanup(audioURL: audioURL)
            return
        }

        // 4. Transcribe
        recognizer.transcribe(audioURL: audioURL) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let text):
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    DispatchQueue.main.async {
                        self.onError?("didn't catch that")
                        self.onTranscriptionComplete?(nil)
                    }
                    self.cleanup(audioURL: audioURL)
                    return
                }

                // 5. Restore focus and type
                DispatchQueue.main.async {
                    self.windowTracker.restoreFocus()

                    // Small delay for focus restoration
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self.textInjector.typeText(trimmed)
                        self.onTranscriptionComplete?(trimmed)
                    }
                }

            case .failure:
                DispatchQueue.main.async {
                    self.onError?("transcription failed")
                    self.onTranscriptionComplete?(nil)
                }
            }

            self.cleanup(audioURL: audioURL)
        }
    }

    /// Cancel recording without transcribing
    func cancelRecording() {
        guard isRecording else { return }
        isRecording = false

        let audioURL = audioRecorder.stopRecording()
        cleanup(audioURL: audioURL)

        DispatchQueue.main.async {
            self.onRecordingStateChanged?(false)
        }
    }

    // MARK: - Whisper Management

    /// Reload Whisper recognizer after model download
    func reloadWhisperRecognizer() {
        if WhisperModelManager.shared.isModelDownloaded {
            whisperRecognizer = WhisperRecognizer()
        }
    }

    // MARK: - Permission Requests

    /// Request speech recognition permission
    func requestSpeechPermission(completion: @escaping (Bool) -> Void) {
        nativeRecognizer?.requestAuthorization(completion: completion)
    }

    // MARK: - Private

    private func cleanup(audioURL: URL) {
        // Remove temporary audio file
        try? FileManager.default.removeItem(at: audioURL)
    }
}
