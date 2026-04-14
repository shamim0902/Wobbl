import AppKit

/// Watches global mouse position and notifies PetScene when the cursor
/// enters or leaves the pet window — works even with ignoresMouseEvents = true.
/// Also enables dragging while hovered and pauses walking during drag.
final class HoverController {
    private weak var window: NSWindow?
    private weak var scene: PetScene?
    weak var idleSleepController: IdleSleepController?
    weak var walkingController: WalkingController?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var dragMonitor: Any?
    private(set) var isHovered = false
    private var isDragging = false

    func setup(window: NSWindow, scene: PetScene) {
        self.window = window
        self.scene = scene

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.evaluate()
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.evaluate()
            return event
        }
        // Pause walking on drag so the walk timer doesn't fight the window movement
        dragMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp]) { [weak self] event in
            guard let self = self else { return event }
            if event.type == .leftMouseDown {
                self.isDragging = true
                self.walkingController?.pause()
                NSCursor.closedHand.push()
            } else {
                self.isDragging = false
                self.walkingController?.resume()
                NSCursor.pop()
                self.snapToFloor()
            }
            return event
        }
    }

    private func evaluate() {
        guard let window = window, !isDragging else { return }
        let inside = window.frame.contains(NSEvent.mouseLocation)
        guard inside != isHovered else { return }
        isHovered = inside

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.window?.ignoresMouseEvents = !self.isHovered
            if self.isHovered {
                // Ensure window is floating, key, and on top so drag works
                self.window?.level = .floating
                self.window?.makeKeyAndOrderFront(nil)
                self.idleSleepController?.wakeUp()
                self.walkingController?.pause()
                NSCursor.openHand.push()
                self.scene?.startHoverReaction()
            } else {
                NSCursor.pop()
                self.scene?.endHoverReaction()
                self.walkingController?.resume()
            }
        }
    }

    /// After dropping, snap the window Y back to the screen floor so Wobbl
    /// resumes walking at the right height.
    private func snapToFloor() {
        guard let window = window else { return }
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]
        var origin = window.frame.origin
        origin.y = screen.visibleFrame.minY
        window.setFrameOrigin(origin)
    }

    func stop() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        if let m = localMonitor  { NSEvent.removeMonitor(m); localMonitor  = nil }
        if let m = dragMonitor   { NSEvent.removeMonitor(m); dragMonitor   = nil }
    }

    deinit { stop() }
}
