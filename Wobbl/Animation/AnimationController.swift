import SpriteKit
import Combine

final class AnimationController {
    private let scene: PetScene
    private let brain: PetBrain
    private var currentState: PetState?
    private var cancellables = Set<AnyCancellable>()

    init(scene: PetScene, brain: PetBrain) {
        self.scene = scene
        self.brain = brain

        brain.$currentState
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] newState in
                self?.transitionTo(newState)
            }
            .store(in: &cancellables)
    }

    private func transitionTo(_ state: PetState) {
        let oldState = currentState
        currentState = state

        // Stop old state-specific animations
        if let oldState = oldState {
            stopAnimations(for: oldState)
        }

        // Run transition
        runTransition(from: oldState, to: state)

        // Start new state animations
        startAnimations(for: state)
    }

    // MARK: - Stop Animations

    private func stopAnimations(for state: PetState) {
        scene.effectsNode.stopAll()
        scene.bodyNode.removeAction(forKey: "stateAnim")
        scene.bodyNode.removeAction(forKey: "breathing")
        scene.bodyNode.removeAction(forKey: "walkBob")
        scene.bodyNode.run(SKAction.rotate(toAngle: 0, duration: 0.3))
        scene.bodyNode.run(SKAction.move(to: .zero, duration: 0.2))
        // Reset scale so breathing/spring can restart cleanly
        scene.bodyNode.yScale = 1.0
        scene.bodyNode.xScale = 1.0
    }

    // MARK: - Transitions

    private func runTransition(from: PetState?, to: PetState) {
        // Body color transition
        let targetColor: SKColor
        switch to {
        case .vomit:
            targetColor = ColorPalette.sickBody
        case .sweat:
            targetColor = ColorPalette.hotBody
        case .shiver:
            targetColor = ColorPalette.coldBody
        case .scared:
            targetColor = ColorPalette.scaredBody
        default:
            targetColor = ColorPalette.normalBody
        }
        scene.bodyNode.transitionColor(to: targetColor, duration: 0.4)

        // Reset expression and re-enable mouse tracking
        scene.eyesNode.setExpression(.normal)
        scene.mouthNode.setShape(.smile)
        scene.cheeksNode.setBlushIntensity(0.3)
        scene.eyesNode.startBlinking()
        scene.isMouseTrackingEnabled = true
    }

    // MARK: - Start Animations

    private func startAnimations(for state: PetState) {
        switch state {
        case .idle:
            animateIdle()
        case .happy:
            animateHappy()
        case .vomit(let intensity):
            animateVomit(intensity: intensity)
        case .sweat(let temp):
            animateSweat(temperature: temp)
        case .dizzy(let angle):
            animateDizzy(angle: angle)
        case .sleep(let duration):
            animateSleep(duration: duration)
        case .shiver:
            animateShiver()
        case .scared:
            animateScared()
        }
    }

    // MARK: - State Animations

    private func animateIdle() {
        scene.eyesNode.setExpression(.normal)
        scene.mouthNode.setShape(.neutral)
        scene.cheeksNode.setBlushIntensity(0.2)
        scene.limbsNode.setStandingPose()
    }

    private func animateHappy() {
        scene.eyesNode.setExpression(.normal)
        scene.mouthNode.setShape(.smile)
        scene.cheeksNode.setBlushIntensity(0.5)
        // Limbs managed by WalkingController (walking or standing)
    }

    private func animateVomit(intensity: Double) {
        scene.isMouseTrackingEnabled = false
        scene.eyesNode.stopBlinking()
        scene.eyesNode.setExpression(.spiral)
        scene.mouthNode.setShape(.openWide)
        scene.cheeksNode.setBlushIntensity(0.8, color: ColorPalette.blushSick)

        scene.effectsNode.startVomit()
        scene.limbsNode.setSickPose()

        // Wobble body more aggressively
        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.05, duration: 0.1),
            SKAction.rotate(byAngle: -0.10, duration: 0.1),
            SKAction.rotate(byAngle: 0.05, duration: 0.1),
        ])
        scene.bodyNode.run(.repeatForever(wobble), withKey: "stateAnim")
    }

    private func animateSweat(temperature: Double) {
        scene.eyesNode.setExpression(.squint)
        scene.cheeksNode.setBlushIntensity(1.0, color: ColorPalette.blushHot)

        scene.effectsNode.startSweat()

        // Panting mouth
        let open = SKAction.run { [weak self] in
            self?.scene.mouthNode.setShape(.pant, animated: false)
        }
        let close = SKAction.run { [weak self] in
            self?.scene.mouthNode.setShape(.openSmall, animated: false)
        }
        let pant = SKAction.sequence([
            open, SKAction.wait(forDuration: 0.2),
            close, SKAction.wait(forDuration: 0.15),
        ])
        scene.bodyNode.run(.repeatForever(pant), withKey: "stateAnim")
    }

    private func animateDizzy(angle: Double) {
        scene.isMouseTrackingEnabled = false
        scene.eyesNode.stopBlinking()
        scene.eyesNode.setExpression(.spiral)
        scene.mouthNode.setShape(.wavy)
        scene.cheeksNode.setBlushIntensity(0.4)

        scene.effectsNode.startStars()
        scene.limbsNode.setStandingPose()

        // Tilt body toward the physical tilt
        let tiltAction = SKAction.rotate(toAngle: CGFloat(angle) * 0.3, duration: 0.5)
        tiltAction.timingMode = .easeInEaseOut
        scene.bodyNode.run(tiltAction)

        // Sway
        let sway = SKAction.sequence([
            SKAction.moveBy(x: 3, y: 0, duration: 0.4),
            SKAction.moveBy(x: -6, y: 0, duration: 0.8),
            SKAction.moveBy(x: 3, y: 0, duration: 0.4),
        ])
        sway.timingMode = .easeInEaseOut
        scene.bodyNode.run(.repeatForever(sway), withKey: "stateAnim")
    }

    private func animateSleep(duration: TimeInterval) {
        scene.isMouseTrackingEnabled = false
        scene.eyesNode.stopBlinking()
        scene.eyesNode.setExpression(.closed)
        scene.mouthNode.setShape(.neutral)
        scene.cheeksNode.setBlushIntensity(0.15)

        scene.effectsNode.startZZZ()
        scene.limbsNode.setSleepPose()

        // Slower, deeper breathing
        scene.bodyNode.removeAction(forKey: "breathing")
        let deepBreathe = SKAction.sequence([
            SKAction.scaleY(to: 1.05, duration: 1.75),
            SKAction.scaleY(to: 0.95, duration: 1.75),
        ])
        deepBreathe.timingMode = .easeInEaseOut
        scene.bodyNode.run(.repeatForever(deepBreathe), withKey: "stateAnim")
    }

    private func animateShiver() {
        scene.eyesNode.setExpression(.squint)
        scene.mouthNode.setShape(.wavy)
        scene.cheeksNode.setBlushIntensity(0.2, color: SKColor(red: 0.5, green: 0.6, blue: 0.9, alpha: 0.4))

        // Rapid small vibration
        let shiver = SKAction.sequence([
            SKAction.moveBy(x: 1.5, y: 0, duration: 0.04),
            SKAction.moveBy(x: -3, y: 0, duration: 0.04),
            SKAction.moveBy(x: 1.5, y: 0, duration: 0.04),
        ])
        scene.bodyNode.run(.repeatForever(shiver), withKey: "stateAnim")
    }

    private func animateScared() {
        scene.eyesNode.stopBlinking()
        scene.eyesNode.setExpression(.wide)
        scene.mouthNode.setShape(.openSmall)
        scene.cheeksNode.setBlushIntensity(0.6)

        scene.limbsNode.setScaredPose()

        // Spring-driven squish — punchy compression with natural bounce-back
        scene.bodySquishSpring.value = 0.7
        scene.bodySquishSpring.velocity = 5.0
        scene.bodySquishSpring.target = 1.0

        // Trembling
        let tremble = SKAction.sequence([
            SKAction.moveBy(x: 1, y: 0.5, duration: 0.03),
            SKAction.moveBy(x: -2, y: -1, duration: 0.03),
            SKAction.moveBy(x: 1, y: 0.5, duration: 0.03),
        ])
        scene.bodyNode.run(.repeatForever(tremble), withKey: "stateAnim")
    }
}
