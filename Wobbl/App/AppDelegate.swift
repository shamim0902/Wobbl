import AppKit
import SwiftUI
import SpriteKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var petWindow: NSWindow!
    private var petScene: PetScene!
    private var menuBarController: MenuBarController!
    private var sensorManager: SensorManager!
    private var petBrain: PetBrain!
    private var animationController: AnimationController!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock — menu bar only
        NSApp.setActivationPolicy(.accessory)

        setupPetWindow()
        setupSensors()
        setupMenuBar()
    }

    private func setupPetWindow() {
        let windowSize = CGSize(width: 200, height: 200)
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let origin = CGPoint(
            x: screenFrame.maxX - windowSize.width - 40,
            y: screenFrame.minY + 40
        )

        petWindow = NSWindow(
            contentRect: NSRect(origin: origin, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        petWindow.isOpaque = false
        petWindow.backgroundColor = .clear
        petWindow.hasShadow = false
        petWindow.level = .floating
        petWindow.collectionBehavior = [.canJoinAllSpaces, .transient]
        petWindow.isMovableByWindowBackground = true
        petWindow.ignoresMouseEvents = false

        petScene = PetScene(size: windowSize)
        petScene.scaleMode = .resizeFill
        petScene.backgroundColor = .clear

        let spriteView = SpriteView(
            scene: petScene,
            transition: nil,
            isPaused: false,
            preferredFramesPerSecond: 60,
            options: [.allowsTransparency],
            shouldRender: { _ in true }
        )

        let hostingView = NSHostingView(rootView: spriteView)
        petWindow.contentView = hostingView
        petWindow.orderFrontRegardless()
    }

    private func setupSensors() {
        sensorManager = SensorManager()
        petBrain = PetBrain()
        animationController = AnimationController(scene: petScene, brain: petBrain)

        // Wire sensors → brain
        sensorManager.$latestSnapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                self?.petBrain.process(snapshot)
            }
            .store(in: &cancellables)

        sensorManager.start()
    }

    private func setupMenuBar() {
        menuBarController = MenuBarController(brain: petBrain)
    }
}
