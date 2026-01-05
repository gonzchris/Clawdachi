//
//  AnimationRecorder.swift
//  Claudachi
//

import SpriteKit
import AppKit
import UserNotifications
import QuartzCore

class AnimationRecorder {

    // MARK: - Properties

    private var frames: [CGImage] = []
    private(set) var isRecording = false
    private weak var scene: SKScene?
    private weak var view: SKView?
    private var displayLink: CVDisplayLink?
    private var recordingIndicator: SKShapeNode?

    // Recording configuration
    private let targetFrameRate: Double = 24.0  // 24fps for smoother GIFs
    private let maxRecordingDuration: Double = 20.0
    private var recordingStartTime: Date?
    private var lastCaptureTime: CFTimeInterval = 0
    private var frameInterval: CFTimeInterval { 1.0 / targetFrameRate }

    // Output at full view resolution for crisp pixels
    private var outputSize: CGSize {
        view?.bounds.size ?? CGSize(width: 288, height: 288)
    }

    // Callback for UI updates
    var onRecordingStateChanged: ((Bool) -> Void)?

    // MARK: - Initialization

    init(scene: SKScene, view: SKView) {
        self.scene = scene
        self.view = view
        setupRecordingIndicator()
        setupDisplayLink()
    }

    // MARK: - Display Link Setup

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let displayLink = link else { return }

        let callback: CVDisplayLinkOutputCallback = { _, inNow, _, _, _, userInfo -> CVReturn in
            guard let userInfo = userInfo else { return kCVReturnSuccess }
            let recorder = Unmanaged<AnimationRecorder>.fromOpaque(userInfo).takeUnretainedValue()
            recorder.displayLinkFired(timestamp: inNow.pointee)
            return kCVReturnSuccess
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink, callback, userInfo)
        self.displayLink = displayLink
    }

    private func displayLinkFired(timestamp: CVTimeStamp) {
        guard isRecording else { return }

        let currentTime = CFAbsoluteTimeGetCurrent()

        // Throttle to target frame rate
        if currentTime - lastCaptureTime < frameInterval {
            return
        }

        lastCaptureTime = currentTime

        // Capture must happen on main thread since SKView isn't thread-safe
        DispatchQueue.main.async { [weak self] in
            self?.captureFrame()
        }
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
        frames.reserveCapacity(Int(maxRecordingDuration * targetFrameRate))
        recordingStartTime = Date()
        lastCaptureTime = 0

        showRecordingIndicator()
        onRecordingStateChanged?(true)

        print("AnimationRecorder: Started recording at \(Int(targetFrameRate))fps, output size: \(outputSize)")

        // Start the display link
        if let displayLink = displayLink {
            CVDisplayLinkStart(displayLink)
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        isRecording = false

        // Stop the display link
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }

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

        // Force a render pass before capturing
        view.isPaused = false

        // Capture at full view resolution for maximum quality
        let captureRect = CGRect(origin: .zero, size: view.bounds.size)
        if let texture = view.texture(from: scene, crop: captureRect) {
            let cgImage = texture.cgImage()
            frames.append(cgImage)
        }

        // Restore indicator
        if indicatorWasVisible {
            recordingIndicator?.alpha = 1
        }
    }

    // MARK: - Export

    private func exportGIF() {
        guard !frames.isEmpty else {
            print("AnimationRecorder: No frames to export")
            sendNotification(title: "Recording Failed", body: "No frames captured")
            return
        }

        let outputURL = GIFExporter.generateOutputURL()
        let frameDelay = 1.0 / targetFrameRate
        let capturedFrames = frames
        frames = []  // Clear immediately to free memory

        DispatchQueue.global(qos: .userInitiated).async {
            let success = GIFExporter.createGIF(
                from: capturedFrames,
                frameDelay: frameDelay,
                outputURL: outputURL
            )

            DispatchQueue.main.async {
                if success {
                    self.sendNotification(
                        title: "Recording Saved",
                        body: "GIF saved to Desktop (\(capturedFrames.count) frames)"
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
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        recordingIndicator?.removeFromParent()
    }
}
