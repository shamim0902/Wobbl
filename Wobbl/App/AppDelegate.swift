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
    private var walkingController: WalkingController!
    private var peekabooController: PeekabooController!
    private var hoverController: HoverController!
    private var idleSleepController: IdleSleepController!
    private var cancellables = Set<AnyCancellable>()
    private var scenePauseWatchdog: DispatchSourceTimer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupPetWindow()
        setupSensors()
        setupWalking()
        setupPeekaboo()
        setupHover()
        setupIdleSleep()
        setupMenuBar()
        preventScenePause()
    }

    private func preventScenePause() {
        // SpriteKit pauses the scene when the app loses focus — fight that
        NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.unpauseSpriteKit()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didHideNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.unpauseSpriteKit()
            }
            .store(in: &cancellables)

        // Watchdog: force-unpause every 0.5s from a background thread
        let watchdog = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        watchdog.schedule(deadline: .now() + 0.5, repeating: 0.5)
        watchdog.setEventHandler { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.unpauseSpriteKit()
            }
        }
        watchdog.resume()
        scenePauseWatchdog = watchdog
    }

    private func unpauseSpriteKit() {
        petScene.isPaused = false
        petScene.view?.isPaused = false
    }

    private func setupPetWindow() {
        let windowSize = CGSize(width: 200, height: 280)
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero

        // Initial position: top-right, off-screen, to be animated by MenuBarController
        let origin = CGPoint(
            x: screenFrame.maxX - windowSize.width - 40, // 40 points from the right edge
            y: screenFrame.maxY // Just above the top of the screen
        )

        petWindow = PetWindow(
            contentRect: NSRect(origin: origin, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        petWindow.isOpaque = false
        petWindow.backgroundColor = .clear
        petWindow.hasShadow = false
        petWindow.level = .floating
        petWindow.collectionBehavior = [.managed, .fullScreenAuxiliary]
        petWindow.isMovableByWindowBackground = true
        petWindow.ignoresMouseEvents = true   // HoverController toggles this on hover

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

        sensorManager.$latestSnapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] snapshot in
                self?.petBrain.process(snapshot)
            }
            .store(in: &cancellables)

        sensorManager.start()
    }

    private func setupWalking() {
        walkingController = WalkingController()
        walkingController.setup(window: petWindow, scene: petScene)

        // Adjust walking based on mood
        petBrain.$currentState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .happy, .idle:
                    self.walkingController.resume()
                    self.walkingController.setSpeed(1.2)
                case .scared:
                    self.walkingController.resume()
                    self.walkingController.setSpeed(2.5)
                case .sweat:
                    self.walkingController.resume()
                    self.walkingController.setSpeed(0.6)
                case .shiver:
                    self.walkingController.resume()
                    self.walkingController.setSpeed(0.5)
                case .sleep, .vomit, .dizzy:
                    self.walkingController.pause()
                }
            }
            .store(in: &cancellables)
    }

    private func setupPeekaboo() {
        peekabooController = PeekabooController()
        peekabooController.setup(
            window: petWindow,
            scene: petScene,
            walkingController: walkingController,
            brain: petBrain
        )
    }

    private func setupHover() {
        hoverController = HoverController()
        hoverController.setup(window: petWindow, scene: petScene)
        hoverController.walkingController = walkingController
    }

    private func setupIdleSleep() {
        idleSleepController = IdleSleepController()
        idleSleepController.setup(walkingController: walkingController, scene: petScene)
        hoverController.idleSleepController = idleSleepController
    }

    private func setupMenuBar() {
        menuBarController = MenuBarController(brain: petBrain)
    }
}
