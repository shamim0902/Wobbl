import AppKit
import SpriteKit

enum WalkDirection {
    case left, right, standing
}

/// Drives Wobbl's walking using a GCD timer that never pauses,
/// even when the app loses focus.
final class WalkingController {
    private weak var window: NSWindow?
    private weak var scene: PetScene?
    private var displayTimer: DispatchSourceTimer?

    private(set) var direction: WalkDirection = .standing
    private var walkSpeed: CGFloat = 1.2
    private var isEnabled = true

    private var walkTimeRemaining: TimeInterval = 0
    private var pauseTimeRemaining: TimeInterval = 0
    private var isInPause = true

    private let walkDurationRange: ClosedRange<TimeInterval> = 3.0...8.0
    private let pauseDurationRange: ClosedRange<TimeInterval> = 1.5...4.0
    private let edgeMargin: CGFloat = 10.0
    private let frameInterval: TimeInterval = 1.0 / 30.0  // 30fps for walking is plenty

    func setup(window: NSWindow, scene: PetScene) {
        self.window = window
        self.scene = scene
        pauseTimeRemaining = TimeInterval.random(in: 1.0...2.0)
        isInPause = true
        startTimer()
    }

    private func startTimer() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: frameInterval)
        timer.setEventHandler { [weak self] in
            DispatchQueue.main.async { self?.tick() }
        }
        timer.resume()
        displayTimer = timer
    }

    private func tick() {
        guard isEnabled, let window = window, let scene = scene else { return }
        let dt = frameInterval

        if isInPause {
            pauseTimeRemaining -= dt
            if pauseTimeRemaining <= 0 {
                isInPause = false
                walkTimeRemaining = TimeInterval.random(in: walkDurationRange)
                pickDirection(window: window)
                scene.limbsNode.startWalking(speed: max(walkSpeed / 1.2, 0.5))
                scene.setFacingDirection(direction)
                startBodyBob(scene: scene)
            }
        } else {
            walkTimeRemaining -= dt
            if walkTimeRemaining <= 0 {
                isInPause = true
                pauseTimeRemaining = TimeInterval.random(in: pauseDurationRange)
                direction = .standing
                scene.limbsNode.stopWalking()
                scene.bodyNode.removeAction(forKey: "walkBob")
            } else {
                moveWindow(window: window, scene: scene)
            }
        }
    }

    func pause() {
        isEnabled = false
        direction = .standing
        scene?.limbsNode.stopWalking()
        scene?.bodyNode.removeAction(forKey: "walkBob")
    }

    func resume() {
        guard !isEnabled else { return }
        isEnabled = true
        isInPause = true
        pauseTimeRemaining = TimeInterval.random(in: 0.5...1.5)
    }

    func setSpeed(_ speed: CGFloat) {
        walkSpeed = speed
    }

    private func pickDirection(window: NSWindow) {
        let screen = visibleFrame(for: window)
        let x = window.frame.origin.x
        guard screen.width > 0 else {
            direction = Bool.random() ? .left : .right
            return
        }

        if x < screen.minX + 100 {
            direction = .right
        } else if x > screen.maxX - window.frame.width - 100 {
            direction = .left
        } else {
            direction = Bool.random() ? .left : .right
        }
    }

    private func moveWindow(window: NSWindow, scene: PetScene) {
        let screen = visibleFrame(for: window)
        guard screen.width > 0 else { return }

        var origin = window.frame.origin
        let dx: CGFloat = direction == .right ? walkSpeed : -walkSpeed
        origin.x += dx
        origin.y = screen.minY

        if origin.x < screen.minX + edgeMargin {
            origin.x = screen.minX + edgeMargin
            direction = .right
            scene.setFacingDirection(.right)
        } else if origin.x + window.frame.width > screen.maxX - edgeMargin {
            origin.x = screen.maxX - window.frame.width - edgeMargin
            direction = .left
            scene.setFacingDirection(.left)
        }

        window.setFrameOrigin(origin)
    }

    private func visibleFrame(for window: NSWindow) -> CGRect {
        if let screen = window.screen {
            return screen.visibleFrame
        }

        if let screen = NSScreen.screens.first(where: {
            $0.frame.intersects(window.frame) || $0.frame.contains(window.frame.center)
        }) {
            return screen.visibleFrame
        }

        return NSScreen.main?.visibleFrame ?? NSScreen.screens.first?.visibleFrame ?? .zero
    }

    private func startBodyBob(scene: PetScene) {
        scene.bodyNode.removeAction(forKey: "walkBob")
        let speed = max(walkSpeed / 1.2, 0.5)
        let bobDur = 0.175 / Double(speed)
        let up = SKAction.moveBy(x: 0, y: 2, duration: bobDur)
        let down = SKAction.moveBy(x: 0, y: -2, duration: bobDur)
        up.timingMode = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        scene.bodyNode.run(.repeatForever(.sequence([up, down])), withKey: "walkBob")
    }

    func stop() {
        displayTimer?.cancel()
        displayTimer = nil
    }

    deinit {
        stop()
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
