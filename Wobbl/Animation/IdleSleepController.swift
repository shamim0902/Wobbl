import AppKit

/// Watches for mouse inactivity. After 5–10 s with no movement, Wobbl dozes off on the floor.
/// Sleep breaks when the cursor hovers over Wobbl, or automatically after 1 minute.
final class IdleSleepController {
    private weak var walkingController: WalkingController?
    private weak var scene: PetScene?

    private var monitor: Any?
    private var sleepTimer: DispatchSourceTimer?
    private var wakeTimer: DispatchSourceTimer?
    private(set) var isIdleSleeping = false

    func setup(walkingController: WalkingController, scene: PetScene) {
        self.walkingController = walkingController
        self.scene = scene

        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.onActivity() }
        }

        resetSleepTimer()
    }

    private func onActivity() {
        // Mouse movement only resets the countdown — it does NOT wake from sleep.
        // Wake happens via hover (HoverController calls wakeUp()) or after 1 minute.
        guard !isIdleSleeping else { return }
        resetSleepTimer()
    }

    private func resetSleepTimer() {
        sleepTimer?.cancel()
        let delay = TimeInterval.random(in: 25.0...50.0)
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + delay)
        timer.setEventHandler { [weak self] in self?.fallAsleep() }
        timer.resume()
        sleepTimer = timer
    }

    private func fallAsleep() {
        guard !isIdleSleeping, let scene = scene, let wc = walkingController else { return }
        // Only ~25% chance — sleeps rarely and unpredictably
        guard Int.random(in: 0..<100) < 25 else {
            resetSleepTimer()
            return
        }
        isIdleSleeping = true
        wc.pause()
        // Yawn before sleeping
        scene.eyesNode.setExpression(.squint)
        scene.mouthNode.setShape(.yawn)
        scene.limbsNode.setYawnPose { [weak self] in
            guard let self = self, self.isIdleSleeping else { return }
            self.scene?.startIdleSleep()
        }
        scheduleAutoWake()
    }

    private func scheduleAutoWake() {
        wakeTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 60.0)
        timer.setEventHandler { [weak self] in self?.wakeUp() }
        timer.resume()
        wakeTimer = timer
    }

    /// Called by HoverController when the cursor enters the pet window while sleeping.
    func wakeUp() {
        wakeTimer?.cancel()
        wakeTimer = nil
        guard isIdleSleeping, let scene = scene else { return }
        isIdleSleeping = false
        scene.endIdleSleep()
        // Short stretch on waking
        scene.eyesNode.setExpression(.squint)
        scene.mouthNode.setShape(.yawn)
        scene.limbsNode.setYawnPose { [weak self] in
            self?.scene?.eyesNode.setExpression(.normal)
            self?.scene?.eyesNode.startBlinking()
            self?.scene?.mouthNode.setShape(.smile)
            self?.walkingController?.resume()
        }
        resetSleepTimer()
    }

    func stop() {
        sleepTimer?.cancel()
        sleepTimer = nil
        wakeTimer?.cancel()
        wakeTimer = nil
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }

    deinit { stop() }
}
