import AppKit
import Combine

final class MenuBarController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let brain: PetBrain
    private var cancellables = Set<AnyCancellable>()
    private var moodMenuItem: NSMenuItem!

    init(brain: PetBrain) {
        self.brain = brain
        super.init()
        setup()
        // Perform initial positioning and animation after setup
        initialPositionAndAnimation()
    }

    private func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "Wobbl")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.delegate = self

        moodMenuItem = NSMenuItem(title: "Wobbl is happy 😊", action: nil, keyEquivalent: "")
        moodMenuItem.isEnabled = false
        menu.addItem(moodMenuItem)

        menu.addItem(NSMenuItem.separator())

        let resetItem = NSMenuItem(title: "Reset Position", action: #selector(resetPosition), keyEquivalent: "r")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Wobbl", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu

        // Update mood display
        brain.$currentState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.moodMenuItem.title = "Wobbl is \(state.displayName.lowercased()) \(state.emoji)"
            }
            .store(in: &cancellables)
    }

    private func initialPositionAndAnimation() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        if let window = NSApp.windows.first(where: { $0.level == .floating }) {
            let windowWidth = window.frame.width
            let _ = window.frame.height

            // Initial position: top-right, off-screen
            let initialOrigin = CGPoint(
                x: frame.maxX - windowWidth - 40, // 40 points from the right edge
                y: frame.maxY // Just above the top of the screen
            )
            window.setFrameOrigin(initialOrigin)

            // Final position: bottom-right, same as resetPosition
            let finalOrigin = CGPoint(
                x: frame.maxX - windowWidth - 40,
                y: frame.minY
            )

            // Animate the fall
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 1.0 // Duration of the fall animation
                context.timingFunction = CAMediaTimingFunction(name: .easeIn) // Accelerate downwards
                window.animator().setFrameOrigin(finalOrigin)
            }, completionHandler: nil)
        }
    }

    @objc private func resetPosition() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        if let window = NSApp.windows.first(where: { $0.level == .floating }) {
            let origin = CGPoint(
                x: frame.maxX - window.frame.width - 40,
                y: frame.minY
            )
            window.setFrameOrigin(origin)
        }
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        // Refresh mood text right before menu opens
        moodMenuItem.title = "Wobbl is \(brain.currentState.displayName.lowercased()) \(brain.currentState.emoji)"
    }
}
