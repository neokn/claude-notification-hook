# Development Guide

Technical documentation for Pulse Notify development.

## Project Structure

```
claude-notification-hook/
├── src/
│   └── PulseNotify.swift    # Source code
├── bin/                      # Compiled binary (git ignored)
│   └── pulse-notify
├── .github/
│   └── workflows/
│       └── release.yml       # CI/CD (Apple Silicon only)
├── install.sh                # One-line installer
├── README.md                 # English documentation
├── README_zh.md              # Chinese documentation
├── DEVELOPMENT.md            # This file
└── LICENSE
```

**Repository:** https://github.com/neokn/claude-notification-hook

## Architecture Overview

```
src/PulseNotify.swift
├── NotifyConfig        # Configuration struct with CLI parsing
├── NSColor.fromHex()   # Hex color parsing extension
├── PulseOverlayView    # SwiftUI view with breathing animation
└── AppDelegate         # NSWindow setup and lifecycle
```

## Gaussian Breathing Algorithm

The breathing effect uses an asymmetric Gaussian function to simulate natural breathing:

```swift
brightness = exp(-x² / 2σ²)
```

### Inhale Phase (first half of cycle)
- **σ = 0.8** (narrower curve)
- Faster rise to peak brightness
- Simulates quick inhalation

### Exhale Phase (second half of cycle)
- **σ = 1.2** (wider curve)
- Slower descent with longer tail
- Simulates gradual exhalation

### Implementation

```swift
private func calculateGaussianBreathing(elapsed: Double) -> (Double, Double) {
    let t = elapsed.truncatingRemainder(dividingBy: config.breathCycle)
    let halfCycle = config.breathCycle / 2.0
    var gaussian: Double
    
    if t < halfCycle {
        // Inhale: narrow Gaussian
        let x = (t / halfCycle) * 2.0 - 1.0  // Map to -1 ~ 1
        gaussian = exp(-x * x / (2.0 * config.inhaleSigma * config.inhaleSigma))
    } else {
        // Exhale: wide Gaussian
        let x = ((t - halfCycle) / halfCycle) * 2.0 - 1.0
        gaussian = exp(-x * x / (2.0 * config.exhaleSigma * config.exhaleSigma))
    }
    
    let brightness = minBrightness + (maxBrightness - minBrightness) * gaussian
    return (brightness, gaussian)  // gaussian also used for glow scale
}
```

## Animation System

### Timer-Based Updates
- **Interval:** 16ms (~60fps)
- **Method:** `Timer.scheduledTimer`
- Ensures smooth, continuous animation without discrete steps

### Synchronized Properties
Both brightness and glow size use the same Gaussian value:
- `opacity` = brightness (with min/max bounds)
- `glowScale` = raw gaussian (0-1 range)

### Computed Glow Dimensions
```swift
private var currentGlowHeight: CGFloat {
    config.minGlowHeight + CGFloat(glowScale) * (config.maxGlowHeight - config.minGlowHeight)
}
```

## Window Configuration

### Level and Behavior
```swift
window.level = .screenSaver          // Above all windows
window.ignoresMouseEvents = true     // Click-through
window.collectionBehavior = [
    .canJoinAllSpaces,               // Visible on all spaces
    .fullScreenAuxiliary             // Works with fullscreen apps
]
NSApp.setActivationPolicy(.accessory) // Hidden from Dock
```

### Transparency
```swift
window.backgroundColor = .clear
window.isOpaque = false
window.hasShadow = false
```

## Sound System

Uses `NSSound` for non-blocking audio playback:

```swift
func playSound() {
    guard let name = soundName else { return }
    if let sound = NSSound(contentsOfFile: "/System/Library/Sounds/\(name).aiff", byReference: true) {
        sound.play()  // Non-blocking
    }
}
```

### System Sound Location
All macOS system sounds are located at:
```
/System/Library/Sounds/*.aiff
```

## CLI Argument Parsing

Simple index-based parsing without external dependencies:

```swift
for (index, arg) in args.enumerated() {
    switch arg {
    case "--color", "-c":
        if index + 1 < args.count { 
            // Parse next argument as value
        }
    // ...
    }
}
```

## Build & Distribution

### Compile with Optimization
```bash
swiftc -O -o bin/pulse-notify src/PulseNotify.swift
```

### Requirements
- macOS 11.0+ (SwiftUI)
- Apple Silicon (M1/M2/M3/M4)
- No external packages required

### File Size
- Source: ~11 KB
- Binary: ~120 KB

## Customization Ideas

### Adding New Colors
Add to the switch statement in `NotifyConfig.from()`:
```swift
case "coral": color = NSColor(red: 1.0, green: 0.5, blue: 0.31, alpha: 1.0)
```

### Custom Sound Paths
Modify `playSound()` to accept full paths:
```swift
let path = name.hasPrefix("/") ? name : "/System/Library/Sounds/\(name).aiff"
```

### Multiple Monitors
Current implementation uses `NSScreen.main`. For multi-monitor support:
```swift
for screen in NSScreen.screens {
    // Create window for each screen
}
```

## Debugging

### Test Animation Parameters
```bash
# Fast breathing for quick iteration
./bin/pulse-notify --breath-cycle 1 -d 3

# Large glow for visibility testing
./bin/pulse-notify --max-glow-height 300 --max-blur 80
```

### Check Available Sounds
```bash
ls /System/Library/Sounds/
```

## License

MIT
