import AppKit
import SpriteKit

/// Drives Wobbl's occasional peekaboo — slides in from the right edge on top of other apps,
/// peeks for a few seconds with wide eyes, then retreats back to the desktop.
final class PeekabooController {
    private weak var window: NSWindow?
    private weak var scene: PetScene?
    private weak var walkingController: WalkingController?
    private weak var brain: PetBrain?

    private var peekTimer: DispatchSourceTimer?
    private var isPeeking = false

    func setup(window: NSWindow, scene: PetScene, walkingController: WalkingController, brain: PetBrain) {
        self.window = window
        self.scene = scene
        self.walkingController = walkingController
        self.brain = brain
        scheduleNextPeek()
    }

    // MARK: - Scheduling

    private func scheduleNextPeek() {
        peekTimer?.cancel()
        let delay = TimeInterval.random(in: 60.0...180.0)
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + delay)
        timer.setEventHandler { [weak self] in self?.attemptPeekaboo() }
        timer.resume()
        peekTimer = timer
    }

    private func attemptPeekaboo() {
        // Only peek when calm — skip if in a reactive state
        if let state = brain?.currentState {
            switch state {
            case .vomit, .dizzy, .scared, .sleep:
                scheduleNextPeek()
                return
            default:
                break
            }
        }
        startPeekaboo()
    }

    // MARK: - Peekaboo

    private func startPeekaboo() {
        guard !isPeeking, let window = window, let scene = scene else {
            scheduleNextPeek()
            return
        }
        isPeeking = true

        let wasWalking = walkingController?.isEnabled ?? false
        walkingController?.pause()

        // Raise above all other apps
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)))

        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let sf = screen.frame  // use full frame so we can slide off-screen edge

        // Vertical: upper-middle of screen (eye level feels natural for peeking)
        let peekY = sf.minY + sf.height * 0.55

        // Slide in far enough so the face (centered at x=100 in the 200px window) is ~25px from right edge
        let peekX = sf.maxX - 125

        // Start fully off-screen to the right
        window.setFrameOrigin(CGPoint(x: sf.maxX + 10, y: peekY))

        // Face left — looking into the screen
        scene.setFacingDirection(.left)
        scene.eyesNode.setExpression(.wide)
        scene.limbsNode.setStandingPose()

        // Slide in
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.55
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrameOrigin(CGPoint(x: peekX, y: peekY))
        }, completionHandler: { [weak self] in
            let holdDuration = TimeInterval.random(in: 3.0...6.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
                self?.endPeekaboo(wasWalking: wasWalking, peekY: peekY, screenFrame: sf)
            }
        })
    }

    private func endPeekaboo(wasWalking: Bool, peekY: CGFloat, screenFrame: CGRect) {
        guard let window = window, let scene = scene else {
            isPeeking = false
            scheduleNextPeek()
            return
        }

        // Slide back off-screen to the right
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.45
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().setFrameOrigin(CGPoint(x: screenFrame.maxX + 10, y: peekY))
        }, completionHandler: { [weak self] in
            guard let self = self, let window = self.window else { return }

            // Restore to floating (on top within current desktop)
            window.level = .floating

            // Return to desktop floor
            let screen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]
            let visibleFrame = screen.visibleFrame
            let restOrigin = CGPoint(
                x: visibleFrame.maxX - window.frame.width - 40,
                y: visibleFrame.minY
            )
            window.setFrameOrigin(restOrigin)

            // Reset scene state
            scene.eyesNode.setExpression(.normal)
            scene.eyesNode.startBlinking()
            scene.setFacingDirection(.right)

            if wasWalking {
                self.walkingController?.resume()
            }
            self.isPeeking = false
            self.scheduleNextPeek()
        })
    }

    func stop() {
        peekTimer?.cancel()
        peekTimer = nil
    }

    deinit { stop() }
}
