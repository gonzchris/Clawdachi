//
//  ClaudachiSprite+EyeTracking.swift
//  Claudachi
//
//  Eyes follow the mouse cursor with smooth interpolation
//

import SpriteKit
import AppKit

extension ClaudachiSprite {

    // MARK: - Eye Tracking Update

    /// Called from scene's update() to update eye positions
    func updateEyeTracking(globalMouse: CGPoint, currentTime: TimeInterval) {
        let deltaTime = lastEyeUpdateTime == 0 ? 0 : currentTime - lastEyeUpdateTime
        lastEyeUpdateTime = currentTime

        // Calculate target offset from mouse position (unless tracking is disabled)
        // Skip recalculation if mouse hasn't moved enough (performance optimization)
        let mouseDelta = hypot(globalMouse.x - lastMousePosition.x, globalMouse.y - lastMousePosition.y)
        if isMouseTrackingEnabled && !isDragging && !isLookingAround && mouseDelta > 2 {
            lastMousePosition = globalMouse
            targetEyeOffset = calculateEyeOffset(from: globalMouse)
        }

        // Update eye positions with breathing + tracking
        updateEyePositions(deltaTime: deltaTime)
    }

    // MARK: - Offset Calculation

    private func calculateEyeOffset(from globalMouse: CGPoint) -> CGPoint {
        guard let window = scene?.view?.window else { return .zero }

        // Window center in screen coordinates
        let windowFrame = window.frame
        let windowCenter = CGPoint(
            x: windowFrame.midX,
            y: windowFrame.midY
        )

        // Direction vector from sprite to mouse
        let dx = globalMouse.x - windowCenter.x
        let dy = globalMouse.y - windowCenter.y
        let distance = hypot(dx, dy)

        // Dead zone - eyes stay centered when mouse is very close
        let deadZone: CGFloat = 15
        guard distance > deadZone else { return .zero }

        // Normalize and scale to max offset (1.0 point, matching look-around)
        let maxOffset: CGFloat = 1.0
        return CGPoint(
            x: (dx / distance) * maxOffset,
            y: (dy / distance) * maxOffset * 0.5  // Reduce vertical movement
        )
    }

    // MARK: - Position Update

    private func updateEyePositions(deltaTime: TimeInterval) {
        // Update breathing phase (synced with body breathing duration)
        eyeBreathPhase += CGFloat(deltaTime) * (2 * .pi / CGFloat(breathingDuration))
        if eyeBreathPhase > 2 * .pi { eyeBreathPhase -= 2 * .pi }

        // Calculate breathing bob (0.4 points amplitude, slightly delayed from body)
        // Using sin with phase offset to approximate the original easeInEaseOut timing
        let breathOffset = sin(eyeBreathPhase - 0.2) * 0.4

        // Smooth interpolation toward target (lerp factor 0.1 for smooth following)
        let lerpFactor: CGFloat = 0.1
        let snapThreshold: CGFloat = 0.05

        let dx = targetEyeOffset.x - currentEyeOffset.x
        let dy = targetEyeOffset.y - currentEyeOffset.y

        // Snap to target when very close, otherwise lerp
        if abs(dx) < snapThreshold && abs(dy) < snapThreshold {
            currentEyeOffset = targetEyeOffset
        } else {
            currentEyeOffset.x += dx * lerpFactor
            currentEyeOffset.y += dy * lerpFactor
        }

        // Apply combined offset to both eyes
        leftEyeNode.position = CGPoint(
            x: leftEyeBasePos.x + currentEyeOffset.x,
            y: leftEyeBasePos.y + currentEyeOffset.y + breathOffset
        )
        rightEyeNode.position = CGPoint(
            x: rightEyeBasePos.x + currentEyeOffset.x,
            y: rightEyeBasePos.y + currentEyeOffset.y + breathOffset
        )
    }

    // MARK: - Tracking Control

    func disableMouseTracking() {
        isMouseTrackingEnabled = false
        targetEyeOffset = .zero
    }

    func enableMouseTracking() {
        isMouseTrackingEnabled = true
    }
}
