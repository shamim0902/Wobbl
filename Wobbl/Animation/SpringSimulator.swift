import CoreGraphics

/// Lightweight damped spring for per-frame simulation.
/// Call `step(dt:)` every frame in PetScene.update() — produces natural
/// overshoot, oscillation, and settling without keyframes.
struct SpringState {
    var value: CGFloat
    var velocity: CGFloat = 0
    var target: CGFloat

    /// Advance the spring by `dt` seconds.
    /// - Parameters:
    ///   - stiffness: How snappy the spring is (higher = faster). ~180 is punchy, ~80 is gentle.
    ///   - damping: How quickly oscillation dies out (higher = fewer bounces). ~12 is natural.
    mutating func step(dt: CGFloat, stiffness: CGFloat = 180, damping: CGFloat = 12) {
        let force = -stiffness * (value - target)
        let dampForce = -damping * velocity
        velocity += (force + dampForce) * dt
        value += velocity * dt
    }

    /// True when the spring has essentially settled (for optional cleanup).
    var isSettled: Bool {
        abs(value - target) < 0.001 && abs(velocity) < 0.01
    }
}
