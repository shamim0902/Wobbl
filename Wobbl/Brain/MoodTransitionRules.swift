import Foundation

struct Threshold {
    let enter: Double
    let exit: Double
    let holdTime: TimeInterval  // Must sustain for this long to transition
}

enum MoodTransitionRules {
    // Mouse agitation-based (magnitude from AccelerometerReader)
    // Agitation scale: 0=calm, 1.0=moderate, 2.0+=very agitated
    static let vomit = Threshold(enter: 1.5, exit: 0.8, holdTime: 0.5)      // sustained fast shaking
    static let dizzy = Threshold(enter: 0.15, exit: 0.08, holdTime: 1.5)    // tilt angle (radians)
    static let scared = Threshold(enter: 2.2, exit: 0.0, holdTime: 0.0)     // sudden spike

    // Temperature-based (from IOHIDEventSystem, real °C)
    // Apple Silicon idles at ~47°C and rarely exceeds 70°C
    static let sweat = Threshold(enter: 50.0, exit: 46.0, holdTime: 3.0)    // °C - triggers on any real load
    static let shiver = Threshold(enter: 28.0, exit: 33.0, holdTime: 10.0)  // °C (cold room/just booted)

    // Idle-based
    static let sleep = Threshold(enter: 300.0, exit: 1.0, holdTime: 0.0)    // seconds

    // Duration for auto-exiting states
    static let scaredDuration: TimeInterval = 3.0
    static let recoveryDelay: TimeInterval = 2.0

    // Idle threshold to transition from happy → idle
    static let happyToIdleTime: TimeInterval = 30.0
}
