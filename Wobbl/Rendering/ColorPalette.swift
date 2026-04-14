import SpriteKit

enum ColorPalette {
    // Body colors
    static let normalBody = SKColor(red: 0.72, green: 0.66, blue: 0.91, alpha: 1.0)    // Soft lavender #B8A9E8
    static let normalStroke = SKColor(red: 0.60, green: 0.54, blue: 0.79, alpha: 1.0)   // Darker lavender
    static let sickBody = SKColor(red: 0.55, green: 0.78, blue: 0.52, alpha: 1.0)       // Greenish
    static let hotBody = SKColor(red: 0.93, green: 0.55, blue: 0.60, alpha: 1.0)        // Reddish pink
    static let coldBody = SKColor(red: 0.55, green: 0.70, blue: 0.90, alpha: 1.0)       // Cool blue
    static let scaredBody = SKColor(red: 0.85, green: 0.78, blue: 0.95, alpha: 1.0)     // Pale lavender

    // Eyes
    static let sclera = SKColor.white
    static let pupil = SKColor(red: 0.15, green: 0.10, blue: 0.20, alpha: 1.0)          // Dark purple-black
    static let highlight = SKColor.white

    // Cheeks
    static let blush = SKColor(red: 1.0, green: 0.60, blue: 0.70, alpha: 0.45)          // Soft pink
    static let blushHot = SKColor(red: 1.0, green: 0.35, blue: 0.40, alpha: 0.7)        // Deep red blush
    static let blushSick = SKColor(red: 0.55, green: 0.75, blue: 0.50, alpha: 0.4)      // Green blush

    // Mouth
    static let mouth = SKColor(red: 0.15, green: 0.10, blue: 0.20, alpha: 1.0)

    // Effects
    static let sweatDrop = SKColor(red: 0.50, green: 0.75, blue: 1.0, alpha: 0.8)
    static let vomitGreen = SKColor(red: 0.45, green: 0.72, blue: 0.30, alpha: 0.9)
    static let starYellow = SKColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 0.9)
    static let zzzColor = SKColor(red: 1.0, green: 0.92, blue: 0.45, alpha: 1.0)
}
