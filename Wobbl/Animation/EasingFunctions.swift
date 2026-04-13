import SpriteKit

// MARK: - Easing Curves

/// Pure easing functions: take normalized t (0…1), return curved t.
enum Easing {

    /// Slight overshoot then settle — great for pose transitions, pop-ins.
    static func easeOutBack(_ t: CGFloat) -> CGFloat {
        let c1: CGFloat = 1.70158
        let c3 = c1 + 1
        let t1 = t - 1
        return 1 + c3 * t1 * t1 * t1 + c1 * t1 * t1
    }

    /// Springy oscillation — squish reactions, bouncy settles.
    static func easeOutElastic(_ t: CGFloat) -> CGFloat {
        guard t > 0 && t < 1 else { return t }
        let c4 = (2 * CGFloat.pi) / 3
        return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1
    }

    /// Bouncing ball — landing after drag-drop, surfboard pop-in.
    static func easeOutBounce(_ t: CGFloat) -> CGFloat {
        let n1: CGFloat = 7.5625
        let d1: CGFloat = 2.75
        var t = t
        if t < 1 / d1 {
            return n1 * t * t
        } else if t < 2 / d1 {
            t -= 1.5 / d1
            return n1 * t * t + 0.75
        } else if t < 2.5 / d1 {
            t -= 2.25 / d1
            return n1 * t * t + 0.9375
        } else {
            t -= 2.625 / d1
            return n1 * t * t + 0.984375
        }
    }

    /// Critically-damped spring — general "settle" with configurable damping.
    static func spring(_ t: CGFloat, damping: CGFloat = 0.6) -> CGFloat {
        let freq: CGFloat = 4.0
        return 1 - exp(-damping * 10 * t) * cos(freq * CGFloat.pi * t)
    }

    /// Smoother cubic ease in-out — subtler than SpriteKit's built-in.
    static func easeInOutCubic(_ t: CGFloat) -> CGFloat {
        t < 0.5
            ? 4 * t * t * t
            : 1 - pow(-2 * t + 2, 3) / 2
    }
}

// MARK: - SKAction Helpers

extension SKAction {

    /// Rotate a node using a custom easing curve.
    static func easedRotate(
        toAngle angle: CGFloat,
        duration: TimeInterval,
        easing: @escaping (CGFloat) -> CGFloat = Easing.easeOutBack
    ) -> SKAction {
        var startAngle: CGFloat?
        return .customAction(withDuration: duration) { node, elapsed in
            if startAngle == nil { startAngle = node.zRotation }
            guard let from = startAngle else { return }
            let t = min(CGFloat(elapsed) / CGFloat(duration), 1.0)
            node.zRotation = from + (angle - from) * easing(t)
        }
    }

    /// Scale Y using a custom easing curve.
    static func easedScaleY(
        to target: CGFloat,
        duration: TimeInterval,
        easing: @escaping (CGFloat) -> CGFloat = Easing.easeOutElastic
    ) -> SKAction {
        var startScale: CGFloat?
        return .customAction(withDuration: duration) { node, elapsed in
            if startScale == nil { startScale = node.yScale }
            guard let from = startScale else { return }
            let t = min(CGFloat(elapsed) / CGFloat(duration), 1.0)
            node.yScale = from + (target - from) * easing(t)
        }
    }

    /// Scale uniformly using a custom easing curve.
    static func easedScale(
        to target: CGFloat,
        duration: TimeInterval,
        easing: @escaping (CGFloat) -> CGFloat = Easing.easeOutBack
    ) -> SKAction {
        var startX: CGFloat?
        var startY: CGFloat?
        return .customAction(withDuration: duration) { node, elapsed in
            if startX == nil { startX = node.xScale; startY = node.yScale }
            guard let fromX = startX, let fromY = startY else { return }
            let t = min(CGFloat(elapsed) / CGFloat(duration), 1.0)
            let curved = easing(t)
            node.xScale = fromX + (target - fromX) * curved
            node.yScale = fromY + (target - fromY) * curved
        }
    }
}
