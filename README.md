# Wobbl

A native macOS desktop pet that lives as a transparent floating overlay on your screen. Wobbl is a stick-figure character that walks autonomously across the bottom of your screen, follows your mouse with its eyes, and reacts to real system conditions — CPU heat, mouse agitation, and idle time — with distinct moods and animations.

No dock icon. No cursor interference. Always running.

---

## Features

- **Always-on-top, click-through overlay** — transparent borderless window that never blocks your cursor or other apps
- **Autonomous walking** — walks left and right across the screen, bounces off edges, pauses and resumes naturally
- **Mouse-tracking eyes** — pupils follow the cursor in real time, accounting for window position and character flip direction
- **Live CPU temperature** — reads real PMU sensor data via IOKit on Apple Silicon; triggers sweat when hot, shiver when cold
- **Mouse agitation detection** — rapid or erratic mouse movement triggers scared and vomit reactions
- **Idle detection** — falls asleep after 5 minutes of system inactivity
- **Menu bar integration** — shows current mood, option to reset position, quit

---

## Pet States

Priority-ordered — higher states override lower ones when triggered simultaneously.

| Priority | State | Trigger | Animation |
|----------|-------|---------|-----------|
| 1 | **Scared** | Sudden fast mouse jerk | Wide eyes, body squish + tremble, arms raised |
| 2 | **Vomit** | Sustained rapid mouse shaking | Green tint, spiral eyes, vomit particles, sick pose |
| 3 | **Dizzy** | Erratic mouse patterns | Spiral eyes, orbiting stars, body sway |
| 4 | **Sweat** | CPU temp > 50°C | Red tint, sweat drops, panting mouth, slow walk |
| 5 | **Shiver** | CPU temp < 35°C | Blue tint, rapid vibration, slow walk |
| 6 | **Sleep** | System idle > 5 min | Closed eyes, ZZZ bubbles, deep breathing, stops walking |
| 7 | **Happy** | Normal active conditions | Blush cheeks, smile, normal walk speed |
| 8 | **Idle** | 30s in happy with no stimulus | Subtle breathing only |

All transitions use hysteresis — entry thresholds are stricter than exit thresholds to prevent flickering between states.

---

## Architecture

Wobbl uses a unidirectional data flow pipeline:

```
┌─────────────────────────────────────────────────────────────────┐
│                         Sensors Layer                           │
│  AccelerometerReader    TemperatureReader    IdleDetector        │
│  (NSEvent mouse proxy)  (IOHIDEventSystem)   (CGEventSource)     │
└──────────────────────────────┬──────────────────────────────────┘
                               │ SensorSnapshot (Combine publisher)
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                          SensorManager                          │
│  Coordinates all readers, publishes unified SensorSnapshot      │
└──────────────────────────────┬──────────────────────────────────┘
                               │ $latestSnapshot
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                           PetBrain                              │
│  Priority-ordered state machine with hysteresis                 │
│  SensorSnapshot → PetState (idle/happy/vomit/sweat/…)           │
└──────────────┬────────────────────────────┬─────────────────────┘
               │ $currentState              │ $currentState
               ▼                            ▼
┌──────────────────────────┐   ┌────────────────────────────────┐
│   AnimationController    │   │       WalkingController        │
│  Drives SpriteKit scene  │   │  Moves NSWindow across screen  │
│  expressions, particles, │   │  Background GCD timer (never   │
│  body color, poses       │   │  pauses when app loses focus)  │
└──────────────┬───────────┘   └────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────────┐
│                         PetScene (SKScene)                      │
│  characterContainer (xScale flip for direction)                 │
│    ├── PetBodyNode      — blob shape, breathing, wobble phase   │
│    │     ├── PetEyesNode   — sclera + pupils + expressions      │
│    │     ├── PetMouthNode  — bezier mouth shapes                │
│    │     └── PetCheeksNode — blush circles                      │
│    ├── PetLimbsNode     — stick arms + legs, walk cycle         │
│    └── PetEffectsNode   — sweat/ZZZ/star/vomit particles        │
└──────────────────────────────┬──────────────────────────────────┘
                               │ hosted inside
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Floating NSWindow                            │
│  Borderless, transparent, .floating level                       │
│  ignoresMouseEvents = true  (click-through)                     │
│  canJoinAllSpaces  (visible on every Space/fullscreen app)      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Key Technical Decisions

### Rendering — no image assets
Everything is drawn programmatically with `CGPath` and `SKShapeNode`. The blob body uses sinusoidal path deformation for organic wobble. Eyes, mouth, cheeks, and particle effects are all constructed in code. This means no artist needed, resolution-independent output, and a tiny binary.

### Temperature — private IOKit API
CoreMotion is unavailable on macOS. Temperature is read using the private `IOHIDEventSystemClient` API (Monitor type), which enumerates all PMU thermal sensors on Apple Silicon and returns the maximum reading. Polling interval: every 5 seconds.

### Shake detection — mouse agitation proxy
The accelerometer is not accessible on macOS via public APIs. Instead, `AccelerometerReader` monitors global `NSEvent` mouse-moved events, computes speed and direction-change rate over a 0.5s sliding window, and outputs a synthetic magnitude value that approximates physical shaking intensity.

### Walking — background GCD timer
`WalkingController` runs on `DispatchQueue.global(qos: .userInteractive)` — a background thread — and dispatches all UI work (window position, SKAction calls) back to the main thread. This means walking never freezes when the app loses focus or when the main run loop enters a non-default mode (which would pause a `.main`-queue timer or the SpriteKit update loop).

### Scene pause prevention
SpriteKit automatically pauses scenes when an `.accessory` policy app loses focus. This is countered with three layers:
1. `NSApplication.didResignActiveNotification` observer immediately unpauses
2. `view.isPaused = false` set in `didMove(to:)`
3. A background watchdog timer force-unpauses the scene every 0.5s

---

## Project Structure

```
Wobbl/
├── App/
│   ├── WobblApp.swift              # @main, NSApplicationDelegateAdaptor
│   └── AppDelegate.swift           # Composition root — wires all layers together
├── Sensors/
│   ├── SensorManager.swift         # Coordinates readers, publishes SensorSnapshot
│   ├── AccelerometerReader.swift   # Mouse agitation → synthetic accel magnitude
│   ├── TemperatureReader.swift     # PMU temps via IOHIDEventSystemClient
│   ├── IdleDetector.swift          # CGEventSource idle time
│   └── SensorData.swift            # AccelReading, ThermalReading, SensorSnapshot types
├── Brain/
│   ├── PetBrain.swift              # State machine, publishes PetState via Combine
│   ├── PetState.swift              # Enum: idle/happy/vomit/sweat/dizzy/sleep/shiver/scared
│   └── MoodTransitionRules.swift   # Thresholds and hysteresis constants
├── Rendering/
│   ├── PetScene.swift              # SKScene — wobble phase, eye tracking, direction flip
│   ├── PetBodyNode.swift           # Blob body shape node
│   ├── PetEyesNode.swift           # Eyes with expressions and blink animation
│   ├── PetMouthNode.swift          # Bezier mouth morphing between shapes
│   ├── PetCheeksNode.swift         # Blush with variable color and intensity
│   ├── PetEffectsNode.swift        # Particle effect emitters
│   ├── PetLimbsNode.swift          # Stick arms + legs with joint hierarchy and walk cycle
│   ├── BlobShapeGenerator.swift    # CGPath factory for organic blob deformation
│   └── ColorPalette.swift          # Mood-to-color mapping
├── Animation/
│   ├── AnimationController.swift   # Observes PetBrain, drives scene per state
│   ├── IdleAnimations.swift        # Breathing, blinking, pupil drift
│   ├── ReactionAnimations.swift    # Vomit, sweat, dizzy, scared, shiver
│   └── TransitionAnimations.swift  # Cross-fade helpers between states
├── MenuBar/
│   └── MenuBarController.swift     # NSStatusItem with mood display and actions
└── Utilities/
    ├── IOKitHelpers.swift          # Swift wrappers around C IOKit calls
    └── RingBuffer.swift            # Fixed-size circular buffer for sensor history
```

---

## Requirements

- macOS 14+ (Sonoma)
- Apple Silicon (M1/M2/M3/M4) — temperature reading is chip-specific
- App Sandbox: **OFF** (required for IOKit HID and SMC access)
- No external dependencies — only Apple system frameworks: SpriteKit, IOKit, CoreGraphics, Combine

---

## Build & Run

```bash
swift build && .build/debug/Wobbl
```

Or open in Xcode:

```bash
open Package.swift
```

---

## License

MIT
