# Wobbl

A sensor-aware desktop pet for macOS. Wobbl is a transparent, wobbly rectangle that lives on your screen and reacts to your Mac's physical state — overheating, mouse agitation, and idle time.

## Features

- **Transparent floating pet** — always-on-top, draggable, see-through rectangle with organic wobble animation
- **Mouse tracking eyes** — pupils follow your cursor in real-time
- **Temperature sensing** — reads real CPU die temperatures via IOKit HID Event System (Apple Silicon)
- **Shake detection** — rapid mouse movements trigger nausea and scare reactions
- **Idle detection** — falls asleep after 5 minutes of inactivity
- **Menu bar integration** — shows current mood, reset position, quit

## Pet States

| State | Trigger | Animation |
|-------|---------|-----------|
| Happy | Normal activity | Gentle bounce, blinking, smile |
| Idle | 30s calm | Subtle breathing |
| Scared | Sudden fast mouse movement | Wide eyes, trembling |
| Vomit | Sustained rapid mouse shaking | Green tint, spiral eyes, particles |
| Sweat | CPU temp > 50°C | Red tint, sweat drops, panting |
| Dizzy | Erratic mouse patterns | Spiral eyes, orbiting stars |
| Sleep | Mac idle > 5 min | Closed eyes, ZZZ bubbles |
| Shiver | CPU temp < 28°C | Blue tint, vibrating |

## Requirements

- macOS 14+ (Sonoma)
- Apple Silicon (M1/M2/M3/M4) for temperature sensing
- No external dependencies — uses only Apple system frameworks

## Build & Run

```bash
swift build && .build/debug/Wobbl
```

Or open in Xcode:

```bash
open Package.swift
```

## Architecture

```
Sensors (IOKit/NSEvent) -> SensorManager -> PetBrain (state machine) -> AnimationController -> PetScene (SpriteKit)
                                                                                                   |
                                                                              Floating NSWindow (transparent, borderless)
```

- **Sensors**: Mouse agitation via `NSEvent` global monitor, temperature via `IOHIDEventSystemClient` private API, idle via `CGEventSource`
- **Brain**: Priority-ordered state machine with hysteresis to prevent flickering
- **Rendering**: Programmatic SpriteKit — all shapes drawn with `CGPath`, no image assets needed
- **Window**: Borderless, transparent `NSWindow` at floating level with `SpriteView` hosting

## Project Structure

```
Wobbl/
├── App/           # Entry point, AppDelegate, window setup
├── Sensors/       # Accelerometer (mouse), temperature, idle detection
├── Brain/         # State machine, mood rules, thresholds
├── Rendering/     # SpriteKit scene, body/eyes/mouth/cheeks/effects nodes
├── Animation/     # Animation controller, idle/reaction animation factories
├── MenuBar/       # NSStatusItem menu bar integration
└── Utilities/     # Ring buffer, IOKit helpers
```

## License

MIT
