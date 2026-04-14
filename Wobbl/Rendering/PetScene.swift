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

    /// Spring-driven body squish — replaces hardcoded squish keyframes
    var bodySquishSpring = SpringState(value: 1.0, target: 1.0)

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

        let center = CGPoint(x: size.width / 2, y: 120)

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

        // Per-frame spring physics for body squish.
        // While active, the spring owns yScale — breathing is paused to avoid fights.
        if !bodySquishSpring.isSettled {
            bodySquishSpring.step(dt: CGFloat(dt))
            bodyNode.removeAction(forKey: "breathing")
            bodyNode.yScale = bodySquishSpring.value
        } else if bodyNode.action(forKey: "breathing") == nil
                    && bodyNode.action(forKey: "stateAnim") == nil {
            // Spring settled and no breathing running — restart idle breathing
            bodyNode.yScale = 1.0
            startIdleAnimations()
        }

        if isMouseTrackingEnabled {
            updateEyeTracking()
        }
    }

    // MARK: - Walk Tilt + Eye Direction

    /// Tilts the body forward in the walking direction with a 3D perspective lean.
    /// Rotation + x-compression + face shift simulate a rectangle tilting toward the camera.
    func setWalkTilt(on: Bool) {
        bodyNode.removeAction(forKey: "walkTilt")
        bodyNode.removeAction(forKey: "walkCompress")

        if on {
            // Stronger forward tilt for 3D lean
            bodyNode.run(
                SKAction.easedRotate(toAngle: -0.20, duration: 0.28, easing: Easing.easeOutBack),
                withKey: "walkTilt"
            )
            // Slight x-compression — foreshortening like a rectangle turning
            let compress = SKAction.scaleX(to: 0.91, duration: 0.28)
            compress.timingMode = .easeInEaseOut
            bodyNode.run(compress, withKey: "walkCompress")

            // Face features shift forward (+x) — head leads the body
            let shift = SKAction.moveTo(x: 4, duration: 0.25)
            shift.timingMode = .easeInEaseOut
            eyesNode.run(shift, withKey: "walkShift")
            mouthNode.run(shift, withKey: "walkShift")
            cheeksNode.run(shift, withKey: "walkShift")

            // Pupils drift forward
            eyesNode.driftPupils(to: CGPoint(x: 3.2, y: 0.8), duration: 0.35)
        } else {
            let tilt = SKAction.easedRotate(toAngle: 0, duration: 0.38, easing: { Easing.spring($0, damping: 0.5) })
            bodyNode.run(tilt, withKey: "walkTilt")

            let decompress = SKAction.scaleX(to: 1.0, duration: 0.35)
            decompress.timingMode = .easeInEaseOut
            bodyNode.run(decompress, withKey: "walkCompress")

            // Face returns to center
            let reset = SKAction.moveTo(x: 0, duration: 0.35)
            reset.timingMode = .easeInEaseOut
            eyesNode.run(reset, withKey: "walkShift")
            mouthNode.run(reset, withKey: "walkShift")
            cheeksNode.run(reset, withKey: "walkShift")

            eyesNode.returnPupilsToCenter()
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

    // MARK: - Hover Reaction (Petting)

    private var hoverSettleWorkItem: DispatchWorkItem?
    private var hoverJoyTimer: DispatchSourceTimer?

    func startHoverReaction() {
        hoverSettleWorkItem?.cancel()
        stopHoverJoyLoop()

        // Phase 1 — initial surprise
        eyesNode.stopBlinking()
        eyesNode.setExpression(.wide)
        mouthNode.setShape(.openSmall)
        cheeksNode.setBlushIntensity(1.0)

        // Spring-driven squish
        bodySquishSpring.value = 0.78
        bodySquishSpring.velocity = 4.0
        bodySquishSpring.target = 1.0

        // Sparkle burst on first touch
        effectsNode.showSparkles()
        effectsNode.showHoverBubble()

        // Lean into the petting — head tilts to one side
        let tiltDir: CGFloat = Bool.random() ? 1 : -1
        bodyNode.run(
            SKAction.easedRotate(toAngle: 0.14 * tiltDir, duration: 0.35, easing: Easing.easeOutBack),
            withKey: "hoverTilt"
        )

        // Phase 2 — settle into joy after initial surprise
        let settle = DispatchWorkItem { [weak self] in self?.settleHoverReaction() }
        hoverSettleWorkItem = settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: settle)
    }

    private func settleHoverReaction() {
        eyesNode.setExpression(.squint)
        mouthNode.setShape(.bigSmile)
        cheeksNode.setBlushIntensity(0.85)
        eyesNode.startBlinking()

        // Gentle whole-character sway
        characterContainer.removeAction(forKey: "hoverSway")
        let sway = SKAction.sequence([
            SKAction.rotate(toAngle:  0.075, duration: 0.6),
            SKAction.rotate(toAngle: -0.075, duration: 0.6),
        ])
        sway.timingMode = .easeInEaseOut
        characterContainer.run(.repeatForever(sway), withKey: "hoverSway")

        // Head nuzzle — alternating tilt like leaning into pets
        bodyNode.removeAction(forKey: "hoverTilt")
        let nuzzle = SKAction.sequence([
            SKAction.easedRotate(toAngle:  0.16, duration: 0.8, easing: Easing.easeInOutCubic),
            SKAction.easedRotate(toAngle: -0.12, duration: 0.8, easing: Easing.easeInOutCubic),
        ])
        bodyNode.run(.repeatForever(nuzzle), withKey: "hoverTilt")

        // Periodic joy effects — hearts, sparkles, and text cycling
        startHoverJoyLoop()
    }

    private func startHoverJoyLoop() {
        stopHoverJoyLoop()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 2.0, repeating: 2.5)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            // Alternate between hearts and sparkles
            if Bool.random() {
                self.effectsNode.showLoveParticles()
            } else {
                self.effectsNode.showSparkles()
            }
            // Cycle hover text
            self.effectsNode.showHoverBubble()
            // Occasional extra-happy squish
            if Int.random(in: 0..<100) < 30 {
                self.bodySquishSpring.value = 0.90
                self.bodySquishSpring.velocity = 2.5
                self.bodySquishSpring.target = 1.0
            }
            // ~40% chance: close eyes briefly in bliss then reopen happy
            if Int.random(in: 0..<100) < 40 {
                self.eyesNode.stopBlinking()
                self.eyesNode.setExpression(.closed)
                self.mouthNode.setShape(.bigSmile)
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval.random(in: 1.2...2.0)) { [weak self] in
                    guard let self = self else { return }
                    self.eyesNode.setExpression(.squint)
                    self.eyesNode.startBlinking()
                }
            }
        }
        timer.resume()
        hoverJoyTimer = timer
    }

    private func stopHoverJoyLoop() {
        hoverJoyTimer?.cancel()
        hoverJoyTimer = nil
    }

    func endHoverReaction() {
        hoverSettleWorkItem?.cancel()
        hoverSettleWorkItem = nil
        stopHoverJoyLoop()

        characterContainer.removeAction(forKey: "hoverSway")
        let resetSway = SKAction.rotate(toAngle: 0, duration: 0.3)
        resetSway.timingMode = .easeInEaseOut
        characterContainer.run(resetSway)

        // Head returns to center
        bodyNode.removeAction(forKey: "hoverTilt")
        bodyNode.run(SKAction.easedRotate(toAngle: 0, duration: 0.35, easing: { Easing.spring($0, damping: 0.5) }), withKey: "hoverTilt")

        effectsNode.hideHoverBubble()
        eyesNode.setExpression(.normal)
        mouthNode.setShape(.smile)
        cheeksNode.setBlushIntensity(0.3)
        eyesNode.startBlinking()
    }

    // MARK: - Idle Sleep

    func startIdleSleep() {
        isMouseTrackingEnabled = false
        eyesNode.stopBlinking()
        eyesNode.setExpression(.closed)
        mouthNode.setShape(.neutral)
        cheeksNode.setBlushIntensity(0.0)
        limbsNode.setSleepPose()
        effectsNode.startZZZ()
    }

    func endIdleSleep() {
        effectsNode.stopZZZ()
        limbsNode.setStandingPose()
        eyesNode.setExpression(.normal)
        eyesNode.startBlinking()
        mouthNode.setShape(.smile)
        cheeksNode.setBlushIntensity(0.3)
        isMouseTrackingEnabled = true
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
