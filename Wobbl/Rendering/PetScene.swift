import SpriteKit
import AppKit

final class PetScene: SKScene {
    let bodyNode = PetBodyNode()
    let eyesNode = PetEyesNode()
    let mouthNode = PetMouthNode()
    let cheeksNode = PetCheeksNode()
    let effectsNode = PetEffectsNode()
    let limbsNode = PetLimbsNode()

    private var wobblePhase: CGFloat = 0.0
    private var lastUpdateTime: TimeInterval = 0
    var isMouseTrackingEnabled = true

    /// The whole character container (body + limbs) — used for flipping direction
    private let characterContainer = SKNode()

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        isPaused = false
        view.allowsTransparency = true
        // Prevent SpriteKit from auto-pausing when the accessory app loses focus
        view.isPaused = false

        let center = CGPoint(x: size.width / 2, y: size.height / 2 + 40)

        // Character container holds everything — flip its xScale for direction
        characterContainer.position = center
        addChild(characterContainer)

        // Body
        bodyNode.setup()
        characterContainer.addChild(bodyNode)

        // Face features are children of body
        eyesNode.setup()
        bodyNode.addChild(eyesNode)

        mouthNode.setup()
        bodyNode.addChild(mouthNode)

        cheeksNode.setup()
        bodyNode.addChild(cheeksNode)

        // Limbs attached to character container (not body, so they don't scale with breathing)
        limbsNode.setup()
        characterContainer.addChild(limbsNode)

        // Effects float above
        effectsNode.position = .zero
        effectsNode.setup()
        characterContainer.addChild(effectsNode)

        startIdleAnimations()
    }

    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 1.0 / 60.0
        } else {
            dt = currentTime - lastUpdateTime
        }
        lastUpdateTime = currentTime

        // Animate wobble phase
        wobblePhase += CGFloat(dt) * 1.2
        bodyNode.updateWobble(phase: wobblePhase)

        // Track mouse with eyes
        if isMouseTrackingEnabled {
            updateEyeTracking()
        }
    }

    // MARK: - Direction

    func setFacingDirection(_ direction: WalkDirection) {
        let targetXScale: CGFloat
        switch direction {
        case .left: targetXScale = -1.0
        case .right, .standing: targetXScale = 1.0
        }

        if characterContainer.xScale != targetXScale {
            let flip = SKAction.scaleX(to: targetXScale, duration: 0.15)
            flip.timingMode = .easeInEaseOut
            characterContainer.run(flip)
        }
    }

    // MARK: - Mouse Tracking

    private func updateEyeTracking() {
        guard let window = view?.window else { return }

        let screenMousePos = NSEvent.mouseLocation
        let windowRect = window.convertFromScreen(NSRect(origin: screenMousePos, size: .zero))
        guard let view = self.view else { return }
        let viewPoint = view.convert(windowRect.origin, from: nil)
        let scenePoint = convertPoint(fromView: viewPoint)

        // Convert to body-node local coords (accounting for character container flip)
        let charLocal = characterContainer.convert(scenePoint, from: self)
        let bodyLocal = bodyNode.convert(charLocal, from: characterContainer)

        eyesNode.trackPoint(bodyLocal)
    }

    // MARK: - Idle Animations

    private func startIdleAnimations() {
        // Gentle breathing
        let breatheUp = SKAction.scaleY(to: 1.03, duration: 1.25)
        breatheUp.timingMode = .easeInEaseOut
        let breatheDown = SKAction.scaleY(to: 0.97, duration: 1.25)
        breatheDown.timingMode = .easeInEaseOut
        let breathe = SKAction.sequence([breatheUp, breatheDown])
        bodyNode.run(.repeatForever(breathe), withKey: "breathing")
    }
}
