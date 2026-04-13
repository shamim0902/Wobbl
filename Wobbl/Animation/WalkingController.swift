import AppKit
import SpriteKit

enum WalkDirection {
    case left, right, standing
}

enum PetActivity {
    case walking
    case standing
    case sitting
    case relaxedSitting
    case scratchingHead
    case lookingAround
    case waving
    case surfing
}

/// Drives all of Wobbl's idle behaviour — walking, sitting, scratching, and looking around.
/// Runs on a background GCD timer so it never freezes when the app loses focus.
final class WalkingController {
    private weak var window: NSWindow?
    private weak var scene: PetScene?
    private var displayTimer: DispatchSourceTimer?

    private(set) var direction: WalkDirection = .standing
    private var walkSpeed: CGFloat = 1.2
    private(set) var isEnabled = true

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
        } else if currentActivity == .walking || currentActivity == .surfing {
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
            scene.setWalkTilt(on: false)
        case .surfing:
            scene.limbsNode.stopSurfing()
            scene.bodyNode.removeAction(forKey: "walkBob")
            scene.setWalkTilt(on: false)
        case .waving:
            scene.limbsNode.stopWave()
        case .relaxedSitting:
            scene.eyesNode.setExpression(.normal)
            scene.mouthNode.setShape(.neutral)
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
            scene.setWalkTilt(on: true)
            startBodyBob(scene: scene)

        case .standing:
            direction = .standing
            scene.limbsNode.setStandingPose()
            // ~35% chance to show a feel-good message after settling
            if Int.random(in: 0..<100) < 35 {
                let delay = TimeInterval.random(in: 0.8...2.0)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak scene] in
                    scene?.effectsNode.showAffirmation()
                }
            }

        case .sitting:
            direction = .standing
            scene.limbsNode.setSittingPose()

        case .relaxedSitting:
            direction = .standing
            scene.setFacingDirection(.standing)
            scene.limbsNode.setRelaxedSitPose()
            // Chill face — half-closed eyes, soft smile
            scene.eyesNode.setExpression(.squint)
            scene.mouthNode.setShape(.smile)
            scene.cheeksNode.setBlushIntensity(0.25)

        case .scratchingHead:
            direction = .standing
            scene.limbsNode.startScratch()

        case .lookingAround:
            direction = .standing
            scene.limbsNode.setStandingPose()
            scene.eyesNode.startLookAround()
            // ~25% chance to drop a kind word while looking around
            if Int.random(in: 0..<100) < 25 {
                let delay = TimeInterval.random(in: 1.5...3.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak scene] in
                    scene?.effectsNode.showAffirmation()
                }
            }

        case .waving:
            direction = .standing
            scene.setFacingDirection(.standing)
            scene.limbsNode.setWavePose()
            scene.effectsNode.showGreeting()

        case .surfing:
            pickDirection(window: window)
            scene.limbsNode.startSurfing()
            scene.setFacingDirection(direction)
            scene.setWalkTilt(on: true)
            startSurfBob(scene: scene)
        }
    }

    // MARK: - Activity Selection

    private func pickNextActivity() -> PetActivity {
        // walk 15%, stand 10%, sit 10%, relaxedSit 15%, scratch 10%, look 10%, wave 10%, surf 20%
        switch Int.random(in: 0..<100) {
        case 0..<15:  return .walking
        case 15..<25: return .standing
        case 25..<35: return .sitting
        case 35..<50: return .relaxedSitting
        case 50..<60: return .scratchingHead
        case 60..<70: return .lookingAround
        case 70..<80: return .waving
        default:      return .surfing
        }
    }

    private func duration(for activity: PetActivity) -> TimeInterval {
        switch activity {
        case .walking:        return TimeInterval.random(in: 3.0...7.0)
        case .standing:       return TimeInterval.random(in: 2.0...4.0)
        case .sitting:        return TimeInterval.random(in: 7.0...14.0)
        case .relaxedSitting: return TimeInterval.random(in: 9.0...18.0)
        case .scratchingHead: return TimeInterval.random(in: 4.0...7.0)
        case .lookingAround:  return TimeInterval.random(in: 4.0...8.0)
        case .waving:         return TimeInterval.random(in: 3.0...5.0)
        case .surfing:        return TimeInterval.random(in: 5.0...10.0)
        }
    }

    // MARK: - Pause / Resume (sensor-triggered states)

    func pause() {
        guard let scene = scene else { isEnabled = false; return }
        switch currentActivity {
        case .scratchingHead:  scene.limbsNode.stopScratch()
        case .lookingAround:   scene.eyesNode.stopLookAround()
        case .waving:          scene.limbsNode.stopWave()
        case .surfing:         scene.limbsNode.stopSurfing()
        case .relaxedSitting:
            scene.eyesNode.setExpression(.normal)
            scene.mouthNode.setShape(.neutral)
        default: break
        }
        isEnabled = false
        direction = .standing
        scene.limbsNode.stopWalking()
        scene.bodyNode.removeAction(forKey: "walkBob")
        scene.setWalkTilt(on: false)
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

    private func startSurfBob(scene: PetScene) {
        scene.bodyNode.removeAction(forKey: "walkBob")
        let up   = SKAction.moveBy(x: 0, y: 7, duration: 0.5)
        let down = SKAction.moveBy(x: 0, y: -7, duration: 0.5)
        up.timingMode   = .easeInEaseOut
        down.timingMode = .easeInEaseOut
        scene.bodyNode.run(.repeatForever(.sequence([up, down])), withKey: "walkBob")
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
