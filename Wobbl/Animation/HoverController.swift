import AppKit

/// Watches global mouse position and notifies PetScene when the cursor
/// enters or leaves the pet window — works even with ignoresMouseEvents = true.
final class HoverController {
    private weak var window: NSWindow?
    private weak var scene: PetScene?

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private(set) var isHovered = false

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
    }

    private func evaluate() {
        guard let window = window else { return }
        let inside = window.frame.contains(NSEvent.mouseLocation)
        guard inside != isHovered else { return }
        isHovered = inside

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.isHovered {
                self.scene?.startHoverReaction()
            } else {
                self.scene?.endHoverReaction()
            }
        }
    }

    func stop() {
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        if let m = localMonitor  { NSEvent.removeMonitor(m); localMonitor  = nil }
    }

    deinit { stop() }
}
