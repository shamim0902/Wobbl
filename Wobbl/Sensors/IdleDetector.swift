import Foundation
import CoreGraphics

final class IdleDetector {
    func secondsSinceLastInput() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: UInt32.max)!  // kCGAnyInputEventType
        )
    }
}
