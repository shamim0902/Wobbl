import AppKit

/// Borderless floating window that can receive mouse events for dragging.
/// Default NSWindow with `.borderless` style returns false from canBecomeKey,
/// which blocks mouse event delivery when another app is active.
final class PetWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
