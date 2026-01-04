//
//  ClaudachiScene.swift
//  Claudachi
//

import SpriteKit
import AppKit

class ClaudachiScene: SKScene {

    // MARK: - Properties

    private var claudachi: ClaudachiSprite!
    private let stateMachine = ClaudachiStateMachine()

    private var currentItem: String?
    private var currentCategory: ItemCategory?

    // Generation state
    private var lastGeneratedSprite: GeneratedSprite?
    private var generationFailed: Bool = false
    private var generationTask: Task<Void, Never>?

    // MARK: - Initialization

    override init() {
        super.init(size: CGSize(width: 48, height: 48))
        scaleMode = .aspectFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        setupCharacter()
        setupStateMachine()
    }

    private func setupCharacter() {
        claudachi = ClaudachiSprite()
        claudachi.position = CGPoint(x: 20, y: 20)  // Slightly offset to leave room for terminal
        addChild(claudachi)
    }

    private func setupStateMachine() {
        // Handle state changes
        stateMachine.onStateChange = { [weak self] oldState, newState in
            self?.handleStateChange(from: oldState, to: newState)
        }

        // Handle idea triggers
        stateMachine.onIdeaTriggered = { [weak self] item, category in
            self?.currentItem = item
            self?.currentCategory = category
        }

        // Disable automatic idea generation - right-click only for now
        stateMachine.autoIdeaEnabled = false
    }

    // MARK: - State Handling

    private func handleStateChange(from oldState: ClaudachiState, to newState: ClaudachiState) {
        switch newState {
        case .idle:
            break  // Idle animations handled by sprite

        case .gettingIdea:
            startCodingSequence()

        case .coding(let item, _):
            // Coding animation is already running from startCodingSequence
            print("Claudachi is coding: \(item)")

        case .celebrating(let item):
            print("Claudachi created: \(item)!")

        case .failed:
            print("Claudachi's coding failed")

        case .sleeping:
            claudachi.startSleeping()
        }
    }

    private func startCodingSequence() {
        guard let item = currentItem, let category = currentCategory else { return }

        // Reset generation state
        generationFailed = false
        lastGeneratedSprite = nil

        // Transition to coding state
        stateMachine.beginCoding(item: item, category: category)

        // Start the coding animation (loops until we stop it)
        claudachi.startCodingAnimation(item: item)

        // Start async sprite generation
        generationTask = Task { [weak self] in
            do {
                print("Starting sprite generation for: \(item)")
                let sprite = try await SpriteGenerator.generate(item: item, category: category)

                await MainActor.run {
                    guard let self = self else { return }
                    self.lastGeneratedSprite = sprite
                    print("Successfully generated sprite for: \(item)")

                    // Stop coding animation and show success
                    self.claudachi.stopCodingAnimation(success: true) {
                        self.stateMachine.codingSucceeded(item: item)
                        print("Created \(sprite.category.displayName): \(sprite.item)")

                        // Show the generated sprite!
                        self.showGeneratedSprite(sprite)

                        self.finishCodingSequence()
                    }
                }
            } catch {
                await MainActor.run {
                    guard let self = self else { return }
                    self.generationFailed = true
                    print("Sprite generation failed: \(error.localizedDescription)")

                    // Stop coding animation and show failure
                    self.claudachi.stopCodingAnimation(success: false) {
                        self.stateMachine.codingFailed()
                        self.finishCodingSequence()
                    }
                }
            }
        }
    }

    private func finishCodingSequence() {
        stateMachine.returnToIdle()
        currentItem = nil
        currentCategory = nil
        generationTask = nil
    }

    // MARK: - Display Generated Sprite

    private func showGeneratedSprite(_ sprite: GeneratedSprite) {
        // Create sprite node from generated texture
        let node = SKSpriteNode(texture: sprite.texture)
        node.texture?.filteringMode = .nearest  // Crisp pixels
        node.setScale(2.0)  // Scale up for visibility (16x16 → 32x32)

        // Position to the right of Claudachi
        node.position = CGPoint(x: 38, y: 24)
        node.alpha = 0
        node.zPosition = 100

        addChild(node)

        // Animate in with a pop and float
        node.setScale(0.5)
        let scaleUp = SKAction.scale(to: 2.0, duration: 0.3)
        scaleUp.timingMode = .easeOut
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            scaleUp
        ])

        // Gentle float
        let floatUp = SKAction.moveBy(x: 0, y: 2, duration: 0.8)
        let floatDown = SKAction.moveBy(x: 0, y: -2, duration: 0.8)
        floatUp.timingMode = .easeInEaseOut
        floatDown.timingMode = .easeInEaseOut
        let float = SKAction.repeatForever(SKAction.sequence([floatUp, floatDown]))

        // After a few seconds, fade out
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 5.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])

        node.run(SKAction.sequence([
            popIn,
            SKAction.group([float, fadeOut])
        ]))
    }

    // MARK: - Interaction

    private var isDragging = false
    private var dragStartLocation: CGPoint = .zero

    override func mouseDown(with event: NSEvent) {
        dragStartLocation = event.locationInWindow
        isDragging = false

        // Start drag wiggle immediately on mouse down (will be dragged)
        claudachi.startDragWiggle()
    }

    override func mouseDragged(with event: NSEvent) {
        isDragging = true
    }

    override func mouseUp(with event: NSEvent) {
        // Stop drag wiggle
        claudachi.stopDragWiggle()

        // If it was a click (not a drag), trigger reaction
        if !isDragging {
            if case .idle = stateMachine.currentState {
                claudachi.triggerClickReaction()
            }
        }

        isDragging = false
    }

    override func rightMouseDown(with event: NSEvent) {
        showContextMenu(with: event)
    }

    // MARK: - Context Menu

    private func showContextMenu(with event: NSEvent) {
        guard let view = self.view else { return }

        let menu = NSMenu(title: "Claudachi")

        // Header
        let headerItem = NSMenuItem(title: "Claudachi", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        // Code something (manual trigger)
        let codeItem = NSMenuItem(
            title: "Code Something New",
            action: #selector(triggerCoding),
            keyEquivalent: ""
        )
        codeItem.target = self
        codeItem.isEnabled = (stateMachine.currentState == .idle)
        menu.addItem(codeItem)

        // Inventory (disabled for now - Phase 4)
        let inventoryItem = NSMenuItem(title: "Inventory", action: nil, keyEquivalent: "")
        inventoryItem.isEnabled = false
        menu.addItem(inventoryItem)

        // Settings (disabled for now - Phase 5)
        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsItem.isEnabled = false
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Sleep mode toggle
        let isSleeping = (stateMachine.currentState == .sleeping)
        let sleepItem = NSMenuItem(
            title: isSleeping ? "Wake Up" : "Sleep Mode",
            action: #selector(toggleSleep),
            keyEquivalent: ""
        )
        sleepItem.target = self
        sleepItem.isEnabled = (stateMachine.currentState == .idle || isSleeping)
        menu.addItem(sleepItem)

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Claudachi",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // Show menu at click location
        let locationInView = event.locationInWindow
        menu.popUp(positioning: nil, at: locationInView, in: view)
    }

    @objc private func triggerCoding() {
        stateMachine.triggerIdea()
    }

    @objc private func toggleSleep() {
        if case .sleeping = stateMachine.currentState {
            stateMachine.wake()
            claudachi.wakeUp()
        } else {
            stateMachine.sleep()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
