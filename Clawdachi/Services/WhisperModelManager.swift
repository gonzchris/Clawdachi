//
//  WhisperModelManager.swift
//  Clawdachi
//
//  Manages Whisper model download and storage
//

import Foundation

/// Manages downloading and storing the Whisper speech recognition model
final class WhisperModelManager {
    static let shared = WhisperModelManager()

    // MARK: - Constants

    private let modelName = "ggml-small.en.bin"
    private let modelURLString = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin"
    private let expectedSizeBytes: Int64 = 244_000_000  // ~244MB

    // MARK: - Properties

    /// Directory where Whisper models are stored
    var modelDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Clawdachi/whisper", isDirectory: true)
    }

    /// Path to the downloaded model, or nil if not downloaded
    var modelPath: URL? {
        let path = modelDirectory.appendingPathComponent(modelName)
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }

    /// Whether the model has been downloaded
    var isModelDownloaded: Bool { modelPath != nil }

    /// Current download progress (0.0 to 1.0)
    private(set) var downloadProgress: Double = 0

    /// Whether a download is currently in progress
    private(set) var isDownloading = false

    // MARK: - Callbacks

    /// Called when download progress updates
    var onDownloadProgress: ((Double) -> Void)?

    /// Called when download completes (success with path, or failure with error)
    var onDownloadComplete: ((Result<URL, Error>) -> Void)?

    // MARK: - Private

    private var downloadTask: URLSessionDownloadTask?
    private var progressObservation: NSKeyValueObservation?

    // MARK: - Initialization

    private init() {}

    // MARK: - Download Management

    /// Start downloading the Whisper model
    func downloadModel() {
        guard !isDownloading else { return }
        guard !isModelDownloaded else {
            onDownloadComplete?(.success(modelPath!))
            return
        }

        guard let url = URL(string: modelURLString) else {
            onDownloadComplete?(.failure(WhisperModelError.invalidURL))
            return
        }

        // Create directory if needed
        do {
            try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
        } catch {
            onDownloadComplete?(.failure(error))
            return
        }

        isDownloading = true
        downloadProgress = 0

        let session = URLSession(configuration: .default)
        let task = session.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let self = self else { return }

            self.isDownloading = false
            self.progressObservation = nil

            if let error = error {
                DispatchQueue.main.async {
                    self.onDownloadComplete?(.failure(error))
                }
                return
            }

            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    self.onDownloadComplete?(.failure(WhisperModelError.downloadFailed))
                }
                return
            }

            // Move to final destination
            let destination = self.modelDirectory.appendingPathComponent(self.modelName)
            do {
                // Remove existing file if present
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: tempURL, to: destination)

                DispatchQueue.main.async {
                    self.downloadProgress = 1.0
                    self.onDownloadProgress?(1.0)
                    self.onDownloadComplete?(.success(destination))
                }
            } catch {
                DispatchQueue.main.async {
                    self.onDownloadComplete?(.failure(error))
                }
            }
        }

        // Observe progress
        progressObservation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgress = progress.fractionCompleted
                self?.onDownloadProgress?(progress.fractionCompleted)
            }
        }

        downloadTask = task
        task.resume()
    }

    /// Cancel an in-progress download
    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        progressObservation = nil
        isDownloading = false
        downloadProgress = 0
    }

    /// Delete the downloaded model
    func deleteModel() {
        guard let path = modelPath else { return }
        try? FileManager.default.removeItem(at: path)
    }

    /// Get model size as formatted string
    var modelSizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: expectedSizeBytes)
    }
}

// MARK: - Errors

enum WhisperModelError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case modelCorrupted

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid model URL"
        case .downloadFailed:
            return "Model download failed"
        case .modelCorrupted:
            return "Model file is corrupted"
        }
    }
}
