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

    // Whether the pet is currently glancing at the cursor
    private var isCursorAttentive = false
    private var cursorAttentionWorkItem: DispatchWorkItem?

    /// The whole character container (body + limbs) — used for flipping direction
    private let characterContainer = SKNode()

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        isPaused = false
        view.allowsTransparency = true
        view.isPaused = false

        let center = CGPoint(x: size.width / 2, y: size.height / 2 + 40)

        characterContainer.position = center
        addChild(characterContainer)

        bodyNode.setup()
        characterContainer.addChild(bodyNode)

        eyesNode.setup()
        bodyNode.addChild(eyesNode)

        mouthNode.setup()
        bodyNode.addChild(mouthNode)

        cheeksNode.setup()
        bodyNode.addChild(cheeksNode)

        limbsNode.setup()
        characterContainer.addChild(limbsNode)

        effectsNode.position = .zero
        effectsNode.setup()
        characterContainer.addChild(effectsNode)

        startIdleAnimations()
        scheduleCursorLook()
    }

    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval
        if lastUpdateTime == 0 {
            dt = 1.0 / 60.0
        } else {
            dt = currentTime - lastUpdateTime
        }
        lastUpdateTime = currentTime

        wobblePhase += CGFloat(dt) * 1.2
        bodyNode.updateWobble(phase: wobblePhase)

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

    // MARK: - Mouse Tracking (intermittent)

    private func updateEyeTracking() {
        // Only track when the pet is "paying attention" to the cursor
        guard isCursorAttentive, !eyesNode.isLookingAround else { return }
        guard let window = view?.window else { return }

        let screenMousePos = NSEvent.mouseLocation
        let windowRect = window.convertFromScreen(NSRect(origin: screenMousePos, size: .zero))
        guard let view = self.view else { return }
        let viewPoint = view.convert(windowRect.origin, from: nil)
        let scenePoint = convertPoint(fromView: viewPoint)

        let charLocal = characterContainer.convert(scenePoint, from: self)
        let bodyLocal = bodyNode.convert(charLocal, from: characterContainer)

        eyesNode.trackPoint(bodyLocal)
    }

    // MARK: - Cursor Attention Cycle
    // Pet glances at cursor for a few seconds, then looks away for a while

    private func scheduleCursorLook() {
        let delay = TimeInterval.random(in: 10.0...22.0)
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isCursorAttentive = true
            self.scheduleCursorLookAway()
        }
        cursorAttentionWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func scheduleCursorLookAway() {
        let duration = TimeInterval.random(in: 3.0...7.0)
        let item = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isCursorAttentive = false
            self.eyesNode.returnPupilsToCenter()
            self.scheduleCursorLook()
        }
        cursorAttentionWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item)
    }

    // MARK: - Hover Reaction

    private var hoverSettleWorkItem: DispatchWorkItem?

    func startHoverReaction() {
        hoverSettleWorkItem?.cancel()

        // Phase 1 — surprised squish
        eyesNode.stopBlinking()
        eyesNode.setExpression(.wide)
        mouthNode.setShape(.openSmall)
        cheeksNode.setBlushIntensity(1.0)

        let squish = SKAction.sequence([
            SKAction.scaleY(to: 0.78, duration: 0.07),
            SKAction.scaleY(to: 1.18, duration: 0.11),
            SKAction.scaleY(to: 1.0, duration: 0.10),
        ])
        bodyNode.run(squish)

        // Show hover bubble
        effectsNode.showHoverBubble()

        // Phase 2 — settle into cute/relaxed mode after 0.45s
        let settle = DispatchWorkItem { [weak self] in self?.settleHoverReaction() }
        hoverSettleWorkItem = settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: settle)
    }

    private func settleHoverReaction() {
        eyesNode.setExpression(.squint)
        mouthNode.setShape(.smile)
        cheeksNode.setBlushIntensity(0.75)
        eyesNode.startBlinking()

        // Gentle whole-character sway
        characterContainer.removeAction(forKey: "hoverSway")
        let sway = SKAction.sequence([
            SKAction.rotate(toAngle:  0.065, duration: 0.55),
            SKAction.rotate(toAngle: -0.065, duration: 0.55),
        ])
        sway.timingMode = .easeInEaseOut
        characterContainer.run(.repeatForever(sway), withKey: "hoverSway")
    }

    func endHoverReaction() {
        hoverSettleWorkItem?.cancel()
        hoverSettleWorkItem = nil

        characterContainer.removeAction(forKey: "hoverSway")
        let resetSway = SKAction.rotate(toAngle: 0, duration: 0.25)
        resetSway.timingMode = .easeInEaseOut
        characterContainer.run(resetSway)

        effectsNode.hideHoverBubble()
        eyesNode.setExpression(.normal)
        mouthNode.setShape(.smile)
        cheeksNode.setBlushIntensity(0.3)
        eyesNode.startBlinking()
    }

    // MARK: - Idle Animations

    private func startIdleAnimations() {
        let breatheUp = SKAction.scaleY(to: 1.03, duration: 1.25)
        breatheUp.timingMode = .easeInEaseOut
        let breatheDown = SKAction.scaleY(to: 0.97, duration: 1.25)
        breatheDown.timingMode = .easeInEaseOut
        bodyNode.run(.repeatForever(.sequence([breatheUp, breatheDown])), withKey: "breathing")
    }
}
