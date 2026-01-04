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

    // MARK: - Initialization

    override init() {
        super.init(size: CGSize(width: 32, height: 32))
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
        claudachi.position = CGPoint(x: 16, y: 16)
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

        // Configure for testing (faster intervals)
        #if DEBUG
        stateMachine.ideaMinInterval = 30   // 30 seconds for testing
        stateMachine.ideaMaxInterval = 60   // 1 minute for testing
        #endif

        // Start the idea timer
        stateMachine.startIdeaTimer()
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

        claudachi.performCodingSequence(
            item: item,
            codingDuration: 3.0,
            onCodingStart: { [weak self] in
                // Transition to coding state
                self?.stateMachine.beginCoding(item: item, category: category)
            },
            onSuccess: { [weak self] in
                // TODO: In Phase 3, this is where we'd add the item to inventory
                self?.stateMachine.codingSucceeded(item: item)
            },
            onComplete: { [weak self] in
                self?.stateMachine.returnToIdle()
                self?.currentItem = nil
                self?.currentCategory = nil
            }
        )
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
