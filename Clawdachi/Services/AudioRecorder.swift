//
//  AudioRecorder.swift
//  Clawdachi
//
//  Captures audio from microphone using AVAudioEngine
//

import AVFoundation

/// Captures audio from the microphone and saves to a temporary file
final class AudioRecorder {

    // MARK: - Properties

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingStartTime: Date?
    private let audioQueue = DispatchQueue(label: "com.clawdachi.audiorecorder")

    /// Duration of the last recording in seconds
    private(set) var lastRecordingDuration: TimeInterval = 0

    /// Whether currently recording
    var isRecording: Bool { audioEngine?.isRunning ?? false }

    /// URL to the temporary recording file
    var recordingURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("clawdachi_voice_recording.wav")
    }

    // MARK: - Permission

    /// Check if microphone permission is granted
    static var hasMicrophonePermission: Bool {
        AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    /// Request microphone permission
    static func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    // MARK: - Recording Control

    /// Start recording audio from the microphone
    func startRecording() throws {
        // Check permission first
        guard Self.hasMicrophonePermission else {
            throw RecordingError.permissionDenied
        }

        // Remove any existing recording file
        try? FileManager.default.removeItem(at: recordingURL)

        // Create a fresh audio engine for each recording session
        let engine = AVAudioEngine()
        self.audioEngine = engine

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Validate input format
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
            throw RecordingError.noInputDevice
        }

        // Create output file in native format (speech recognizer can handle any format)
        let file = try AVAudioFile(
            forWriting: recordingURL,
            settings: inputFormat.settings
        )

        audioQueue.sync {
            self.audioFile = file
        }

        // Install tap on input node - write directly in native format
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.writeBuffer(buffer)
        }

        engine.prepare()
        try engine.start()

        recordingStartTime = Date()
        lastRecordingDuration = 0
    }

    /// Stop recording and return the URL to the audio file
    @discardableResult
    func stopRecording() -> URL {
        if let startTime = recordingStartTime {
            lastRecordingDuration = Date().timeIntervalSince(startTime)
        }

        if let engine = audioEngine, engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }

        audioEngine = nil
        recordingStartTime = nil

        // Synchronize clearing audioFile to avoid race with buffer processing
        audioQueue.sync {
            audioFile = nil
        }

        return recordingURL
    }

    // MARK: - Private

    private func writeBuffer(_ buffer: AVAudioPCMBuffer) {
        audioQueue.async { [weak self] in
            guard let file = self?.audioFile else { return }
            do {
                try file.write(from: buffer)
            } catch {
                // Silently ignore write errors - recording will just be shorter
            }
        }
    }
}

// MARK: - Errors

enum RecordingError: Error, LocalizedError {
    case formatCreationFailed
    case fileCreationFailed
    case permissionDenied
    case noInputDevice

    var errorDescription: String? {
        switch self {
        case .formatCreationFailed:
            return "Failed to create audio format"
        case .fileCreationFailed:
            return "Failed to create audio file"
        case .permissionDenied:
            return "Microphone permission denied"
        case .noInputDevice:
            return "No audio input device available"
        }
    }
}
