import AppKit
import SpriteKit

enum WalkDirection {
    case left, right, standing
}

enum PetActivity {
    case walking
    case standing
    case sitting
    case scratchingHead
    case lookingAround
}

/// Drives all of Wobbl's idle behaviour — walking, sitting, scratching, and looking around.
/// Runs on a background GCD timer so it never freezes when the app loses focus.
final class WalkingController {
    private weak var window: NSWindow?
    private weak var scene: PetScene?
    private var displayTimer: DispatchSourceTimer?

    private(set) var direction: WalkDirection = .standing
    private var walkSpeed: CGFloat = 1.2
    private var isEnabled = true

    private var currentActivity: PetActivity = .standing
    private var activityTimeRemaining: TimeInterval = 0

    private let edgeMargin: CGFloat = 10.0
    private let frameInterval: TimeInterval = 1.0 / 30.0

    func setup(window: NSWindow, scene: PetScene) {
        self.window = window
        self.scene = scene
        activityTimeRemaining = TimeInterval.random(in: 1.0...2.0)
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

        activityTimeRemaining -= frameInterval

        if activityTimeRemaining <= 0 {
            let next = pickNextActivity()
            transition(to: next, window: window, scene: scene)
            activityTimeRemaining = duration(for: next)
        } else if currentActivity == .walking {
            moveWindow(window: window, scene: scene)
        }
    }

    // MARK: - Activity Transitions

    private func transition(to next: PetActivity, window: NSWindow, scene: PetScene) {
        // Clean up outgoing activity
        switch currentActivity {
        case .scratchingHead:
            scene.limbsNode.stopScratch()
        case .lookingAround:
            scene.eyesNode.stopLookAround()
        case .walking:
            scene.limbsNode.stopWalking()
            scene.bodyNode.removeAction(forKey: "walkBob")
        default:
            break
        }

        currentActivity = next

        // Set up incoming activity
        switch next {
        case .walking:
            pickDirection(window: window)
            scene.limbsNode.startWalking(speed: max(walkSpeed / 1.2, 0.5))
            scene.setFacingDirection(direction)
            startBodyBob(scene: scene)

        case .standing:
            direction = .standing
            scene.limbsNode.setStandingPose()

        case .sitting:
            direction = .standing
            scene.limbsNode.setSittingPose()

        case .scratchingHead:
            direction = .standing
            scene.limbsNode.startScratch()

        case .lookingAround:
            direction = .standing
            scene.limbsNode.setStandingPose()
            scene.eyesNode.startLookAround()
        }
    }

    // MARK: - Activity Selection

    private func pickNextActivity() -> PetActivity {
        // Weighted random: walk 30%, stand 20%, sit 25%, scratch 15%, look 10%
        switch Int.random(in: 0..<100) {
        case 0..<30:  return .walking
        case 30..<50: return .standing
        case 50..<75: return .sitting
        case 75..<90: return .scratchingHead
        default:      return .lookingAround
        }
    }

    private func duration(for activity: PetActivity) -> TimeInterval {
        switch activity {
        case .walking:        return TimeInterval.random(in: 3.0...7.0)
        case .standing:       return TimeInterval.random(in: 2.0...4.0)
        case .sitting:        return TimeInterval.random(in: 7.0...14.0)
        case .scratchingHead: return TimeInterval.random(in: 4.0...7.0)
        case .lookingAround:  return TimeInterval.random(in: 4.0...8.0)
        }
    }

    // MARK: - Pause / Resume (sensor-triggered states)

    func pause() {
        guard let scene = scene else { isEnabled = false; return }
        switch currentActivity {
        case .scratchingHead: scene.limbsNode.stopScratch()
        case .lookingAround:  scene.eyesNode.stopLookAround()
        default: break
        }
        isEnabled = false
        direction = .standing
        scene.limbsNode.stopWalking()
        scene.bodyNode.removeAction(forKey: "walkBob")
        currentActivity = .standing
    }

    func resume() {
        guard !isEnabled else { return }
        isEnabled = true
        currentActivity = .standing
        activityTimeRemaining = TimeInterval.random(in: 0.5...1.5)
    }

    func setSpeed(_ speed: CGFloat) {
        walkSpeed = speed
    }

    // MARK: - Movement

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
        if let screen = window.screen { return screen.visibleFrame }
        if let screen = NSScreen.screens.first(where: {
            $0.frame.intersects(window.frame) || $0.frame.contains(window.frame.center)
        }) { return screen.visibleFrame }
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

    deinit { stop() }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
