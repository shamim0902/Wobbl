import SpriteKit

final class PetEffectsNode: SKNode {
    private var activeEmitters: [String: SKEmitterNode] = [:]
    private var activeNodes: [String: SKNode] = [:]
    private weak var greetingBubble: SKNode?     // tracked separately — survives stopAll()
    private weak var hoverBubble: SKNode?        // same: immune to stopAll()
    private weak var affirmationBubble: SKNode?  // same: immune to stopAll()
    private weak var reactionBubble: SKNode?     // same: immune to stopAll()

    func setup() {
        // Container positioned above the body center
    }

    // MARK: - Sweat Drops

    func startSweat() {
        guard activeEmitters["sweat"] == nil else { return }
        let emitter = makeSweatEmitter()
        emitter.position = CGPoint(x: 0, y: 40)
        addChild(emitter)
        activeEmitters["sweat"] = emitter
    }

    func stopSweat() {
        activeEmitters["sweat"]?.removeFromParent()
        activeEmitters["sweat"] = nil
    }

    // MARK: - Vomit Particles

    func startVomit() {
        guard activeEmitters["vomit"] == nil else { return }
        let emitter = makeVomitEmitter()
        emitter.position = CGPoint(x: 0, y: -24)
        addChild(emitter)
        activeEmitters["vomit"] = emitter
    }

    func stopVomit() {
        activeEmitters["vomit"]?.removeFromParent()
        activeEmitters["vomit"] = nil
    }

    // MARK: - ZZZ Sleep Bubbles

    func startZZZ() {
        guard activeNodes["zzz"] == nil else { return }
        let container = SKNode()
        container.position = CGPoint(x: 20, y: 28)
        addChild(container)
        activeNodes["zzz"] = container

        let emitZ = SKAction.run { [weak container] in
            guard let container = container else { return }
            let z = SKLabelNode(text: "💤")
            z.fontName = "Avenir-Heavy"
            z.fontSize = CGFloat.random(in: 12...18)
            z.fontColor = ColorPalette.zzzColor
            z.position = .zero
            z.alpha = 1.0
            container.addChild(z)

            let moveUp = SKAction.moveBy(x: CGFloat.random(in: 5...15), y: 30, duration: 2.0)
            let fadeOut = SKAction.fadeOut(withDuration: 2.0)
            let scaleUp = SKAction.scale(to: 1.5, duration: 2.0)
            let group = SKAction.group([moveUp, fadeOut, scaleUp])
            z.run(SKAction.sequence([group, .removeFromParent()]))
        }
        let wait = SKAction.wait(forDuration: 0.8, withRange: 0.4)
        container.run(.repeatForever(.sequence([emitZ, wait])))
    }

    func stopZZZ() {
        activeNodes["zzz"]?.removeAllActions()
        activeNodes["zzz"]?.removeFromParent()
        activeNodes["zzz"] = nil
    }

    // MARK: - Dizzy Stars

    func startStars() {
        guard activeNodes["stars"] == nil else { return }
        let orbit = SKNode()
        orbit.position = CGPoint(x: 0, y: 25)
        addChild(orbit)
        activeNodes["stars"] = orbit

        let starCount = 3
        for i in 0..<starCount {
            let angle = (CGFloat(i) / CGFloat(starCount)) * 2.0 * .pi
            let star = createStarShape(size: 5)
            star.position = CGPoint(x: cos(angle) * 35, y: sin(angle) * 16)
            orbit.addChild(star)
        }

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 1.2)
        orbit.run(.repeatForever(spin))
    }

    func stopStars() {
        activeNodes["stars"]?.removeAllActions()
        activeNodes["stars"]?.removeFromParent()
        activeNodes["stars"] = nil
    }

    // MARK: - Sparkle Burst (excited)

    func showSparkles() {
        for i in 0..<5 {
            let star = createStarShape(size: CGFloat.random(in: 3...6))
            let angle = CGFloat(i) / 5 * 2 * .pi + CGFloat.random(in: -0.3...0.3)
            let dist: CGFloat = CGFloat.random(in: 20...40)
            star.position = CGPoint(x: 0, y: 30)
            star.alpha = 0
            star.setScale(0.1)
            addChild(star)

            let move = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist + 15, duration: 0.6)
            let fade = SKAction.sequence([
                SKAction.fadeIn(withDuration: 0.1),
                SKAction.wait(forDuration: 0.3),
                SKAction.fadeOut(withDuration: 0.2),
            ])
            let scale = SKAction.easedScale(to: 1.0, duration: 0.35, easing: Easing.easeOutBack)
            star.run(.sequence([
                .group([move, fade, scale]),
                .removeFromParent(),
            ]))
        }
    }

    // MARK: - Sneeze Burst

    func showSneezeBurst() {
        for _ in 0..<4 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            dot.fillColor = SKColor(white: 0.9, alpha: 0.8)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: 0, y: -10)
            addChild(dot)

            let dx = CGFloat.random(in: 15...35)
            let dy = CGFloat.random(in: -8...8)
            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.4)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.35)
            dot.run(.sequence([.group([move, fade]), .removeFromParent()]))
        }
    }

    // MARK: - Question Bubble (curious)

    func showQuestionBubble() {
        let bubble = makeSpeechBubble(text: "?")
        bubble.position = CGPoint(x: 18, y: 72)
        bubble.alpha = 0
        bubble.setScale(0.1)
        addChild(bubble)

        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.14),
            SKAction.easedScale(to: 1.0, duration: 0.22, easing: Easing.easeOutBack),
        ])
        let hold = SKAction.wait(forDuration: 2.5)
        let leave = SKAction.group([
            SKAction.moveBy(x: 0, y: 12, duration: 0.5),
            SKAction.fadeOut(withDuration: 0.5),
        ])
        bubble.run(.sequence([popIn, hold, leave, .removeFromParent()]))
    }

    // MARK: - Reaction Text Bubble

    static let excitedTexts = [
        "Yay! ✨", "Woohoo!", "So happy! 💖", "Let's gooo!", "Amazing! 🎉",
        "Best day ever!", "I'm pumped! 💪", "Wheee!", "Yahoo~! 🌟", "Can't stop! 🥳",
    ]
    static let shyTexts = [
        "eep! 😳", "s-sorry~", "don't look!", "shy...", "eeek!",
        "oh no~ 🙈", "am smol...", "h-hewwo?", "hiding~", "too shy 💕",
    ]
    static let curiousTexts = [
        "hmm? 🤔", "what's that?", "ooh!", "interesting~", "tell me more!",
        "wait wait!", "lemme see!", "what if... 💭", "oooh~!", "huh? 👀",
    ]
    static let yawnTexts = [
        "*yaaawn*", "five more min~", "so tired~",
        "can't stay awake~", "big stretch!", "droopy eyes~",
        "*stretching*", "mmm~ comfy", "need a break~",
    ]
    static let sneezeTexts = [
        "ACHOO! 🤧", "achoo~!", "bless me!", "ugh~ sniffles", "ah-CHOO!",
        "*sniff sniff*", "allergies?!", "woah!", "that tickled!",
    ]
    static let sittingTexts = [
        "comfy~ 😊", "nice spot!", "just chillin~", "taking a break 🍃",
        "floor is nice~", "sit with me!", "relaxing~", "ahh, peace~",
    ]
    static let relaxedTexts = [
        "ahh~ 😌", "so chill~", "vibes ✌️", "living the life~", "bliss!",
        "this is nice~", "no worries~", "zen mode 🧘", "perfectly cozy~",
    ]
    static let scratchTexts = [
        "itchy! 😖", "hmm~", "got an itch!", "scratchy scratch~",
        "right there~", "ahh better!", "so itchy~!", "can't reach!",
    ]
    static let lookAroundTexts = [
        "what's over there? 👀", "ooh~", "looking around~", "see anything?",
        "so much to see!", "hmm! 🔍", "over here!", "exploring~",
    ]
    static let surfTexts = [
        "cowabunga! 🏄", "surf's up!", "radical~!", "catch the wave!",
        "gnarly! 🌊", "hang ten!", "wooo! 🤙", "riding waves~", "surfer dude!",
    ]
    static let walkTexts = [
        "strolling~ 🚶", "off I go!", "walking around~", "la la la~",
        "on my way!", "adventure! 🌈", "step step step~", "exploring!",
    ]

    /// Shows a text bubble for any reaction — auto-dismisses after ~2.2s.
    func showReactionText(_ text: String) {
        reactionBubble?.removeAllActions()
        reactionBubble?.removeFromParent()
        reactionBubble = nil

        let bubble = makeSpeechBubble(text: text)
        bubble.position = CGPoint(x: 10, y: 74)
        bubble.alpha = 0
        bubble.setScale(0.1)
        addChild(bubble)
        reactionBubble = bubble

        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.14),
            SKAction.scale(to: 1.0, duration: 0.2),
        ])
        let hold = SKAction.wait(forDuration: 2.2)
        let leave = SKAction.group([
            SKAction.moveBy(x: 0, y: 10, duration: 0.5),
            SKAction.fadeOut(withDuration: 0.5),
        ])
        let cleanup = SKAction.run { [weak self] in self?.reactionBubble = nil }
        bubble.run(.sequence([popIn, hold, leave, .removeFromParent(), cleanup]))
    }

    /// Shows a random text for the given activity.
    func showReactionText(for activity: PetActivity) {
        let pool: [String]
        switch activity {
        case .excited:       pool = Self.excitedTexts
        case .shy:           pool = Self.shyTexts
        case .curious:       pool = Self.curiousTexts
        case .yawning:       pool = Self.yawnTexts
        case .sneezing:      pool = Self.sneezeTexts
        case .sitting:       pool = Self.sittingTexts
        case .relaxedSitting:pool = Self.relaxedTexts
        case .scratchingHead:pool = Self.scratchTexts
        case .lookingAround: pool = Self.lookAroundTexts
        case .surfing:       pool = Self.surfTexts
        case .walking:       pool = Self.walkTexts
        default: return
        }
        if let text = pool.randomElement() {
            showReactionText(text)
        }
    }

    // MARK: - Greeting Bubble

    private static let greetings = ["Hi! 👋", "Hello!", "Hey!", "Heya!", "Howdy!", "Helloooo! 😊", "Yo! ✌️"]

    func showGreeting() {
        // Dismiss any existing bubble immediately
        greetingBubble?.removeAllActions()
        greetingBubble?.removeFromParent()
        greetingBubble = nil

        let text = PetEffectsNode.greetings.randomElement() ?? "Hi!"
        let bubble = makeSpeechBubble(text: text)
        bubble.position = CGPoint(x: 14, y: 72)
        bubble.alpha = 0
        bubble.setScale(0.1)
        addChild(bubble)
        greetingBubble = bubble   // NOT in activeNodes — immune to stopAll()

        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.14),
            SKAction.scale(to: 1.0, duration: 0.18),
        ])
        let hold = SKAction.wait(forDuration: 1.8)
        let leave = SKAction.group([
            SKAction.moveBy(x: 0, y: 12, duration: 0.55),
            SKAction.fadeOut(withDuration: 0.55),
        ])
        let cleanup = SKAction.run { [weak self] in self?.greetingBubble = nil }
        bubble.run(.sequence([popIn, hold, leave, .removeFromParent(), cleanup]))
    }

    private func makeSpeechBubble(text: String) -> SKNode {
        let container = SKNode()

        // Bubble body
        let bw: CGFloat = 74
        let bh: CGFloat = 28
        let bodyRect = CGRect(x: -bw / 2, y: 0, width: bw, height: bh)
        let bodyPath = CGPath(
            roundedRect: bodyRect,
            cornerWidth: 8, cornerHeight: 8, transform: nil
        )
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor.white
        body.strokeColor = ColorPalette.normalStroke
        body.lineWidth = 1.8

        // Tail pointing toward the body (down-left)
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -10, y: 0))
        tailPath.addLine(to: CGPoint(x: -18, y: -11))
        tailPath.addLine(to: CGPoint(x: -2, y: 0))
        tailPath.closeSubpath()
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = SKColor.white
        tail.strokeColor = ColorPalette.normalStroke
        tail.lineWidth = 1.5

        // Label — draw body first so label sits on top
        let label = SKLabelNode(text: text)
        label.fontName = "Avenir-Heavy"
        label.fontSize = 12
        label.fontColor = ColorPalette.pupil
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: bh / 2)

        container.addChild(tail)
        container.addChild(body)
        container.addChild(label)
        return container
    }

    // MARK: - Affirmation Bubble

    private static let affirmations = [
        "You're doing great! ✨",
        "Take a deep breath~",
        "You've got this! 💪",
        "You're amazing!",
        "Keep going! 🌟",
        "Be kind to yourself~",
        "You matter! 💜",
        "One step at a time~",
        "You're not alone!",
        "Today will be good 🌸",
        "Proud of you! ⭐",
        "You're enough ♡",
        "Smile~ it helps!",
        "You're doing okay!",
    ]

    func showAffirmation() {
        affirmationBubble?.removeAllActions()
        affirmationBubble?.removeFromParent()
        affirmationBubble = nil

        let text = PetEffectsNode.affirmations.randomElement() ?? "You've got this!"
        let bubble = makeAffirmationBubble(text: text)
        bubble.position = CGPoint(x: 0, y: 80)
        bubble.alpha = 0
        bubble.setScale(0.1)
        addChild(bubble)
        affirmationBubble = bubble

        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.18),
            SKAction.scale(to: 1.0, duration: 0.22),
        ])
        let hold = SKAction.wait(forDuration: 2.8)
        let leave = SKAction.group([
            SKAction.moveBy(x: 0, y: 10, duration: 0.6),
            SKAction.fadeOut(withDuration: 0.6),
        ])
        let cleanup = SKAction.run { [weak self] in self?.affirmationBubble = nil }
        bubble.run(.sequence([popIn, hold, leave, .removeFromParent(), cleanup]))
    }

    private func makeAffirmationBubble(text: String) -> SKNode {
        let container = SKNode()

        let bw: CGFloat = 116
        let bh: CGFloat = 28
        let softMint = SKColor(red: 0.82, green: 0.96, blue: 0.88, alpha: 0.95)

        let bodyPath = CGPath(
            roundedRect: CGRect(x: -bw / 2, y: 0, width: bw, height: bh),
            cornerWidth: 9, cornerHeight: 9, transform: nil
        )
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = softMint
        body.strokeColor = SKColor(red: 0.45, green: 0.75, blue: 0.60, alpha: 1.0)
        body.lineWidth = 1.6

        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -6, y: 0))
        tailPath.addLine(to: CGPoint(x: -14, y: -10))
        tailPath.addLine(to: CGPoint(x: 4, y: 0))
        tailPath.closeSubpath()
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = softMint
        tail.strokeColor = SKColor(red: 0.45, green: 0.75, blue: 0.60, alpha: 1.0)
        tail.lineWidth = 1.4

        let label = SKLabelNode(text: text)
        label.fontName = "Avenir-Heavy"
        label.fontSize = 11
        label.fontColor = SKColor(red: 0.15, green: 0.40, blue: 0.30, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: bh / 2)

        container.addChild(tail)
        container.addChild(body)
        container.addChild(label)
        return container
    }

    // MARK: - Hover Bubble

    private static let hoverTexts = [
        "uwu ♥", "hehe~", "eep!", "owo", "squish!", "hiii!", "teehee~", "✨", "so soft~", "omg hi",
        "pet me more! 💕", "yesss~ 😊", "that feels nice!", "purrrr~", "don't stop!",
        "I love pets! 💖", "right there~!", "so gentle! 🥰", "happy happy!", "more pls~",
        "best human! 💜", "cozy vibes~", "mmmm~ 💗", "love this!", "heaven~ ✨",
    ]

    // MARK: - Love Particles (hearts floating up during petting)

    func showLoveParticles() {
        for _ in 0..<3 {
            let heart = SKLabelNode(text: "♥")
            heart.fontName = "Avenir-Heavy"
            heart.fontSize = CGFloat.random(in: 10...16)
            heart.fontColor = SKColor(red: 1.0, green: 0.45, blue: 0.65, alpha: 0.9)
            heart.position = CGPoint(
                x: CGFloat.random(in: -25...25),
                y: CGFloat.random(in: 20...45)
            )
            heart.alpha = 0
            heart.setScale(0.3)
            addChild(heart)

            let floatUp = SKAction.moveBy(x: CGFloat.random(in: -12...12), y: CGFloat.random(in: 25...45), duration: 1.2)
            floatUp.timingMode = .easeOut
            let fadeIn = SKAction.fadeAlpha(to: 0.9, duration: 0.2)
            let hold = SKAction.wait(forDuration: 0.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let grow = SKAction.easedScale(to: 1.0, duration: 0.4, easing: Easing.easeOutBack)
            heart.run(.sequence([
                .group([fadeIn, grow]),
                .group([floatUp, .sequence([hold, fadeOut])]),
                .removeFromParent(),
            ]))
        }
    }

    func showHoverBubble() {
        // Dismiss any existing hover bubble without animation
        hoverBubble?.removeAllActions()
        hoverBubble?.removeFromParent()
        hoverBubble = nil

        let text = PetEffectsNode.hoverTexts.randomElement() ?? "uwu"
        let bubble = makeHoverBubble(text: text)
        bubble.position = CGPoint(x: -8, y: 72)
        bubble.alpha = 0
        bubble.setScale(0.05)
        addChild(bubble)
        hoverBubble = bubble

        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.16),
            SKAction.scale(to: 1.0, duration: 0.22),
        ])
        popIn.timingMode = .easeOut
        bubble.run(popIn)
    }

    func hideHoverBubble() {
        guard let bubble = hoverBubble else { return }
        hoverBubble = nil
        let dismiss = SKAction.group([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.scale(to: 0.3, duration: 0.2),
        ])
        bubble.run(.sequence([dismiss, .removeFromParent()]))
    }

    private func makeHoverBubble(text: String) -> SKNode {
        let container = SKNode()

        let bw: CGFloat = 82
        let bh: CGFloat = 28

        // Soft lavender fill — matches Wobbl's colour palette
        let bubbleFill = ColorPalette.normalBody.withAlphaComponent(0.92)

        let bodyPath = CGPath(
            roundedRect: CGRect(x: -bw / 2, y: 0, width: bw, height: bh),
            cornerWidth: 10, cornerHeight: 10, transform: nil
        )
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = bubbleFill
        body.strokeColor = ColorPalette.normalStroke
        body.lineWidth = 1.6

        // Tail pointing down-right (toward character body)
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: 8,  y: 0))
        tailPath.addLine(to: CGPoint(x: 16, y: -11))
        tailPath.addLine(to: CGPoint(x: 22, y: 0))
        tailPath.closeSubpath()
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = bubbleFill
        tail.strokeColor = ColorPalette.normalStroke
        tail.lineWidth = 1.4

        let label = SKLabelNode(text: text)
        label.fontName = "Avenir-Heavy"
        label.fontSize = 12
        label.fontColor = ColorPalette.pupil
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: bh / 2)

        container.addChild(tail)
        container.addChild(body)
        container.addChild(label)
        return container
    }

    // MARK: - Stop All

    func stopAll() {
        for (_, emitter) in activeEmitters { emitter.removeFromParent() }
        for (_, node) in activeNodes { node.removeAllActions(); node.removeFromParent() }
        activeEmitters.removeAll()
        activeNodes.removeAll()
    }

    // MARK: - Emitter Factories

    private func makeSweatEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 2.5
        emitter.particleLifetime = 1.2
        emitter.particleLifetimeRange = 0.3
        emitter.particleSize = CGSize(width: 4, height: 6)
        emitter.particleColor = ColorPalette.sweatDrop
        emitter.particleColorBlendFactor = 1.0
        emitter.emissionAngle = .pi * 0.6
        emitter.emissionAngleRange = .pi * 0.5
        emitter.particleSpeed = 25
        emitter.particleSpeedRange = 10
        emitter.yAcceleration = -60
        emitter.particleAlphaSpeed = -0.6
        emitter.particleScale = 0.8
        emitter.particleScaleSpeed = -0.3
        emitter.particleTexture = SKTexture(image: generateDropImage(size: 8, color: ColorPalette.sweatDrop))
        return emitter
    }

    private func makeVomitEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 8
        emitter.particleLifetime = 0.8
        emitter.particleLifetimeRange = 0.3
        emitter.particleSize = CGSize(width: 5, height: 5)
        emitter.particleColor = ColorPalette.vomitGreen
        emitter.particleColorBlendFactor = 1.0
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = .pi * 0.3
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 15
        emitter.yAcceleration = -80
        emitter.particleAlphaSpeed = -0.8
        emitter.particleScale = 1.0
        emitter.particleScaleRange = 0.4
        emitter.particleScaleSpeed = -0.5
        emitter.particleTexture = SKTexture(image: generateDropImage(size: 8, color: ColorPalette.vomitGreen))
        return emitter
    }

    // MARK: - Texture Generation

    private func generateDropImage(size: CGFloat, color: SKColor) -> NSImage {
        let imgSize = NSSize(width: size, height: size * 1.3)
        let image = NSImage(size: imgSize, flipped: false) { rect in
            let path = NSBezierPath()
            let cx = rect.midX
            path.move(to: NSPoint(x: cx, y: rect.maxY))
            path.curve(
                to: NSPoint(x: cx, y: rect.minY),
                controlPoint1: NSPoint(x: rect.maxX + 1, y: rect.midY),
                controlPoint2: NSPoint(x: rect.maxX, y: rect.minY)
            )
            path.curve(
                to: NSPoint(x: cx, y: rect.maxY),
                controlPoint1: NSPoint(x: rect.minX, y: rect.minY),
                controlPoint2: NSPoint(x: rect.minX - 1, y: rect.midY)
            )
            color.setFill()
            path.fill()
            return true
        }
        return image
    }

    private func createStarShape(size: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        let points = 5
        let innerRadius = size * 0.4
        let outerRadius = size

        for i in 0..<(points * 2) {
            let angle = (CGFloat(i) / CGFloat(points * 2)) * 2.0 * .pi - .pi / 2
            let r = i % 2 == 0 ? outerRadius : innerRadius
            let x = cos(angle) * r
            let y = sin(angle) * r
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()

        let star = SKShapeNode(path: path)
        star.fillColor = ColorPalette.starYellow
        star.strokeColor = .clear
        return star
    }
}
