import Foundation

enum PetState: Equatable {
    case idle
    case happy
    case vomit(intensity: Double)
    case sweat(temperature: Double)
    case dizzy(tiltAngle: Double)
    case sleep(duration: TimeInterval)
    case shiver
    case scared

    var displayName: String {
        switch self {
        case .idle: return "Chilling"
        case .happy: return "Happy"
        case .vomit: return "Nauseous"
        case .sweat: return "Overheating"
        case .dizzy: return "Dizzy"
        case .sleep: return "Sleeping"
        case .shiver: return "Cold"
        case .scared: return "Scared"
        }
    }

    var emoji: String {
        switch self {
        case .idle: return "😌"
        case .happy: return "😊"
        case .vomit: return "🤮"
        case .sweat: return "🥵"
        case .dizzy: return "😵‍💫"
        case .sleep: return "😴"
        case .shiver: return "🥶"
        case .scared: return "😱"
        }
    }

    // Priority for state override (higher = more urgent)
    var priority: Int {
        switch self {
        case .scared: return 8
        case .vomit: return 7
        case .dizzy: return 6
        case .sweat: return 5
        case .shiver: return 4
        case .sleep: return 3
        case .happy: return 2
        case .idle: return 1
        }
    }
}
