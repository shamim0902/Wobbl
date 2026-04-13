import SpriteKit
import AppKit

final class PetScene: SKScene {
    let bodyNode = PetBodyNode()
    let eyesNode = PetEyesNode()
    let mouthNode = PetMouthNode()
    let cheeksNode = PetCheeksNode()
    let effectsNode = PetEffectsNode()

    private var wobblePhase: CGFloat = 0.0
    private var lastUpdateTime: TimeInterval = 0
    var isMouseTrackingEnabled = true

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.allowsTransparency = true

        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        // Body at center
        bodyNode.position = center
        bodyNode.setup()
        addChild(bodyNode)

        // Eyes, mouth, cheeks are children of body (move with it)
        eyesNode.setup()
        bodyNode.addChild(eyesNode)

        mouthNode.setup()
        bodyNode.addChild(mouthNode)

        cheeksNode.setup()
        bodyNode.addChild(cheeksNode)

        // Effects float above body
        effectsNode.position = center
        effectsNode.setup()
        addChild(effectsNode)

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

        // Animate wobble phase for living-membrane effect
        wobblePhase += CGFloat(dt) * 1.2
        bodyNode.updateWobble(phase: wobblePhase)

        // Track mouse pointer with eyes
        if isMouseTrackingEnabled {
            updateEyeTracking()
        }
    }

    private func updateEyeTracking() {
        guard let window = view?.window else { return }

        // Get mouse position in screen coordinates
        let screenMousePos = NSEvent.mouseLocation

        // Convert screen coords → window coords → view coords → scene coords
        let windowRect = window.convertFromScreen(NSRect(origin: screenMousePos, size: .zero))
        guard let view = self.view else { return }
        let viewPoint = view.convert(windowRect.origin, from: nil)
        let scenePoint = convertPoint(fromView: viewPoint)

        // Convert scene coords to body-node local coords (where the eyes live)
        let bodyLocal = bodyNode.convert(scenePoint, from: self)

        eyesNode.trackPoint(bodyLocal)
    }

    // MARK: - Idle Animations

    private func startIdleAnimations() {
        // Gentle breathing — Y scale oscillation
        let breatheUp = SKAction.scaleY(to: 1.03, duration: 1.25)
        breatheUp.timingMode = .easeInEaseOut
        let breatheDown = SKAction.scaleY(to: 0.97, duration: 1.25)
        breatheDown.timingMode = .easeInEaseOut
        let breathe = SKAction.sequence([breatheUp, breatheDown])
        bodyNode.run(.repeatForever(breathe), withKey: "breathing")

        // Gentle bob — slight Y position oscillation
        let bobUp = SKAction.moveBy(x: 0, y: 1.5, duration: 1.25)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = SKAction.moveBy(x: 0, y: -1.5, duration: 1.25)
        bobDown.timingMode = .easeInEaseOut
        let bob = SKAction.sequence([bobUp, bobDown])
        bodyNode.run(.repeatForever(bob), withKey: "bobbing")

    }
}
