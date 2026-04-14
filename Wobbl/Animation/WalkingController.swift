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
    case excited
    case shy
    case curious
    case yawning
    case sneezing
    case eating
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
        case .excited:
            scene.limbsNode.stopExcited()
            scene.eyesNode.setExpression(.normal)
            scene.mouthNode.setShape(.smile)
        case .shy:
            scene.limbsNode.stopShy()
            scene.eyesNode.setExpression(.normal)
            scene.cheeksNode.setBlushIntensity(0.3)
        case .curious:
            scene.bodyNode.run(SKAction.easedRotate(toAngle: 0, duration: 0.3, easing: Easing.easeOutBack))
            scene.eyesNode.setExpression(.normal)
            scene.eyesNode.returnPupilsToCenter()
        case .sneezing:
            scene.bodyNode.run(SKAction.rotate(toAngle: 0, duration: 0.2))
            scene.eyesNode.setExpression(.normal)
            scene.eyesNode.startBlinking()
        case .yawning:
            scene.limbsNode.removeAction(forKey: "yawnSequence")
            scene.eyesNode.setExpression(.normal)
            scene.eyesNode.startBlinking()
            scene.mouthNode.setShape(.smile)
        case .eating:
            scene.bodyNode.removeAction(forKey: "chewing")
            scene.effectsNode.removeBurger()
            scene.eyesNode.setExpression(.normal)
            scene.eyesNode.startBlinking()
            scene.cheeksNode.setBlushIntensity(0.3)
        default:
            break
        }

        currentActivity = next

        // Show reaction text for most activities (~60% chance, with delay)
        if next != .standing && next != .waving {
            if Int.random(in: 0..<100) < 60 {
                let delay = TimeInterval.random(in: 0.4...1.2)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak scene, next] in
                    scene?.effectsNode.showReactionText(for: next)
                }
            }
        }

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

        case .excited:
            direction = .standing
            scene.setFacingDirection(.standing)
            scene.limbsNode.setExcitedPose()
            scene.eyesNode.setExpression(.wide)
            scene.mouthNode.setShape(.bigSmile)
            scene.cheeksNode.setBlushIntensity(0.7)
            scene.effectsNode.showSparkles()
            scene.bodySquishSpring.value = 0.85
            scene.bodySquishSpring.velocity = 5.0
            scene.bodySquishSpring.target = 1.0

        case .shy:
            direction = .standing
            scene.setFacingDirection(.standing)
            scene.limbsNode.setShyPose()
            scene.eyesNode.setExpression(.squint)
            scene.mouthNode.setShape(.openSmall)
            scene.cheeksNode.setBlushIntensity(0.9)

        case .curious:
            direction = .standing
            scene.setFacingDirection(.standing)
            scene.limbsNode.setCuriousPose()
            scene.eyesNode.setExpression(.wide)
            scene.mouthNode.setShape(.openSmall)
            scene.eyesNode.driftPupils(to: CGPoint(x: 3, y: 1), duration: 0.5)
            scene.bodyNode.run(SKAction.easedRotate(toAngle: 0.18, duration: 0.5, easing: { Easing.spring($0, damping: 0.5) }))
            scene.effectsNode.showQuestionBubble()

        case .yawning:
            direction = .standing
            scene.setFacingDirection(.standing)
            scene.eyesNode.setExpression(.squint)
            scene.mouthNode.setShape(.yawn)
            scene.limbsNode.setYawnPose { [weak scene] in
                scene?.eyesNode.setExpression(.normal)
                scene?.eyesNode.startBlinking()
                scene?.mouthNode.setShape(.smile)
            }

        case .sneezing:
            direction = .standing
            scene.setFacingDirection(.standing)
            scene.limbsNode.setSneezePose()
            scene.eyesNode.setExpression(.squint)
            scene.mouthNode.setShape(.neutral)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak scene] in
                guard let scene = scene else { return }
                scene.bodyNode.run(SKAction.easedRotate(toAngle: 0.15, duration: 0.1, easing: Easing.easeOutElastic))
                scene.bodySquishSpring.value = 0.85
                scene.bodySquishSpring.velocity = 6.0
                scene.bodySquishSpring.target = 1.0
                scene.eyesNode.setExpression(.closed)
                scene.mouthNode.setShape(.openWide)
                scene.effectsNode.showSneezeBurst()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak scene] in
                    scene?.bodyNode.run(SKAction.easedRotate(toAngle: 0, duration: 0.4, easing: { Easing.spring($0, damping: 0.5) }))
                    scene?.eyesNode.setExpression(.normal)
                    scene?.eyesNode.startBlinking()
                    scene?.mouthNode.setShape(.smile)
                }
            }

        case .eating:
            direction = .standing
            scene.setFacingDirection(.standing)
            scene.limbsNode.setEatingPose()
            scene.eyesNode.setExpression(.wide)
            scene.mouthNode.setShape(.chomp)
            scene.effectsNode.showBurger()
            // Show eating text
            if let text = PetEffectsNode.eatingTexts.randomElement() {
                scene.effectsNode.showReactionText(text)
            }
            // Start chomping after arms reach mouth
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak scene] in
                guard let scene = scene else { return }
                // Chewing face — mouth opens and closes
                let chew = SKAction.sequence([
                    SKAction.run { scene.mouthNode.setShape(.chomp, animated: false) },
                    SKAction.wait(forDuration: 0.22),
                    SKAction.run { scene.mouthNode.setShape(.openSmall, animated: false) },
                    SKAction.wait(forDuration: 0.15),
                ])
                scene.bodyNode.run(.repeatForever(chew), withKey: "chewing")
                // Eyes go squinty — enjoying the food
                scene.eyesNode.setExpression(.squint)
                scene.cheeksNode.setBlushIntensity(0.5)

                // Animate bite-by-bite burger shrink
                scene.effectsNode.animateEatingBites(biteCount: 4) {
                    // Eating done — fluffy full expression
                    scene.bodyNode.removeAction(forKey: "chewing")
                    scene.mouthNode.setShape(.bigSmile)
                    scene.eyesNode.setExpression(.closed)
                    scene.cheeksNode.setBlushIntensity(0.8)
                    scene.limbsNode.setFullPose()
                    // Satisfied body puff — spring expands then settles
                    scene.bodySquishSpring.value = 1.12
                    scene.bodySquishSpring.velocity = -1.0
                    scene.bodySquishSpring.target = 1.0
                    // Show full text
                    if let text = PetEffectsNode.fullTexts.randomElement() {
                        scene.effectsNode.showReactionText(text)
                    }
                    // Reopen eyes after a happy moment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak scene] in
                        scene?.eyesNode.setExpression(.squint)
                        scene?.eyesNode.startBlinking()
                    }
                }
            }
        }
    }

    // MARK: - Activity Selection

    private func pickNextActivity() -> PetActivity {
        // walk 12%, stand 7%, sit 7%, relaxedSit 9%, scratch 7%, look 7%,
        // wave 7%, surf 13%, excited 5%, shy 4%, curious 5%, yawn 3%, sneeze 4%, eating 10%
        switch Int.random(in: 0..<100) {
        case 0..<12:  return .walking
        case 12..<19: return .standing
        case 19..<26: return .sitting
        case 26..<35: return .relaxedSitting
        case 35..<42: return .scratchingHead
        case 42..<49: return .lookingAround
        case 49..<56: return .waving
        case 56..<69: return .surfing
        case 69..<74: return .excited
        case 74..<78: return .shy
        case 78..<83: return .curious
        case 83..<86: return .yawning
        case 86..<90: return .sneezing
        default:      return .eating
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
        case .excited:        return TimeInterval.random(in: 3.0...5.0)
        case .shy:            return TimeInterval.random(in: 4.0...7.0)
        case .curious:        return TimeInterval.random(in: 3.0...6.0)
        case .yawning:        return TimeInterval.random(in: 4.0...5.5)
        case .sneezing:       return TimeInterval.random(in: 2.0...3.0)
        case .eating:         return TimeInterval.random(in: 7.0...10.0)
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
        case .excited:         scene.limbsNode.stopExcited()
        case .shy:             scene.limbsNode.stopShy()
        case .curious:
            scene.bodyNode.run(SKAction.rotate(toAngle: 0, duration: 0.2))
            scene.eyesNode.returnPupilsToCenter()
        case .yawning:
            scene.limbsNode.removeAction(forKey: "yawnSequence")
        case .sneezing:
            scene.bodyNode.run(SKAction.rotate(toAngle: 0, duration: 0.2))
        case .eating:
            scene.bodyNode.removeAction(forKey: "chewing")
            scene.effectsNode.removeBurger()
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
