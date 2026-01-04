//
//  AnimationRecorder.swift
//  Claudachi
//

import SpriteKit
import AppKit
import UserNotifications

class AnimationRecorder {

    // MARK: - Properties

    private var frames: [CGImage] = []
    private(set) var isRecording = false
    private weak var scene: SKScene?
    private weak var view: SKView?
    private var recordingTimer: Timer?
    private var recordingIndicator: SKShapeNode?

    // Configuration
    private let frameRate: Double = 60  // 60 FPS for smooth animation
    private let maxRecordingDuration: Double = 10.0  // 10 second limit
    private let outputSize: CGSize = CGSize(width: 192, height: 192)  // 6x scale
    private var recordingStartTime: Date?

    // Callback for UI updates
    var onRecordingStateChanged: ((Bool) -> Void)?

    // MARK: - Initialization

    init(scene: SKScene, view: SKView) {
        self.scene = scene
        self.view = view
        setupRecordingIndicator()
    }

    // MARK: - Recording Indicator

    private func setupRecordingIndicator() {
        guard let scene = scene else { return }

        // Red dot in the top-right corner
        let indicator = SKShapeNode(circleOfRadius: 2)
        indicator.fillColor = .red
        indicator.strokeColor = .clear
        indicator.position = CGPoint(x: scene.size.width - 4, y: scene.size.height - 4)
        indicator.zPosition = 1000
        indicator.alpha = 0
        indicator.name = "recordingIndicator"

        scene.addChild(indicator)
        recordingIndicator = indicator
    }

    private func showRecordingIndicator() {
        guard let indicator = recordingIndicator else { return }

        indicator.alpha = 1

        // Pulsing animation
        let pulseOut = SKAction.fadeAlpha(to: 0.3, duration: 0.5)
        let pulseIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        let pulse = SKAction.repeatForever(SKAction.sequence([pulseOut, pulseIn]))
        indicator.run(pulse, withKey: "pulse")
    }

    private func hideRecordingIndicator() {
        guard let indicator = recordingIndicator else { return }
        indicator.removeAction(forKey: "pulse")
        indicator.alpha = 0
    }

    // MARK: - Recording Control

    func startRecording() {
        guard !isRecording, view != nil, scene != nil else { return }

        isRecording = true
        frames = []
        recordingStartTime = Date()

        showRecordingIndicator()
        onRecordingStateChanged?(true)

        print("AnimationRecorder: Started recording")

        // Start frame capture timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / frameRate, repeats: true) { [weak self] _ in
            self?.captureFrame()
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil

        hideRecordingIndicator()
        onRecordingStateChanged?(false)

        print("AnimationRecorder: Stopped recording with \(frames.count) frames")

        // Export the GIF
        exportGIF()
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    // MARK: - Frame Capture

    private func captureFrame() {
        guard isRecording, let view = view, let scene = scene else { return }

        // Check max duration
        if let startTime = recordingStartTime,
           Date().timeIntervalSince(startTime) >= maxRecordingDuration {
            print("AnimationRecorder: Max duration reached, stopping")
            stopRecording()
            return
        }

        // Temporarily hide recording indicator for clean capture
        let indicatorWasVisible = recordingIndicator?.alpha ?? 0 > 0
        recordingIndicator?.alpha = 0

        // Capture the scene and scale up to output size
        if let texture = view.texture(from: scene) {
            let cgImage = texture.cgImage()
            if let scaledImage = scaleImage(cgImage, to: outputSize) {
                frames.append(scaledImage)
            }
        }

        // Restore indicator
        if indicatorWasVisible {
            recordingIndicator?.alpha = 1
        }
    }

    // MARK: - Image Scaling

    /// Scales a CGImage to the target size using nearest-neighbor interpolation (crisp pixels)
    private func scaleImage(_ image: CGImage, to size: CGSize) -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        // Use nearest-neighbor interpolation for crisp pixel art
        context.interpolationQuality = .none

        // Draw the image scaled up
        context.draw(image, in: CGRect(origin: .zero, size: size))

        return context.makeImage()
    }

    // MARK: - Export

    private func exportGIF() {
        guard !frames.isEmpty else {
            print("AnimationRecorder: No frames to export")
            sendNotification(title: "Recording Failed", body: "No frames captured")
            return
        }

        let outputURL = GIFExporter.generateOutputURL()
        let frameDelay = 1.0 / frameRate

        DispatchQueue.global(qos: .userInitiated).async { [frames] in
            let success = GIFExporter.createGIF(
                from: frames,
                frameDelay: frameDelay,
                outputURL: outputURL
            )

            DispatchQueue.main.async {
                if success {
                    self.sendNotification(
                        title: "Recording Saved",
                        body: "GIF saved to Desktop"
                    )
                    // Open in Finder
                    NSWorkspace.shared.selectFile(outputURL.path, inFileViewerRootedAtPath: "")
                } else {
                    self.sendNotification(
                        title: "Recording Failed",
                        body: "Could not save GIF"
                    )
                }
            }
        }
    }

    // MARK: - Notifications

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("AnimationRecorder: Failed to send notification - \(error)")
            }
        }
    }

    // MARK: - Cleanup

    deinit {
        recordingTimer?.invalidate()
        recordingIndicator?.removeFromParent()
    }
}
