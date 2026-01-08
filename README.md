# Pulse Notify

A macOS screen-edge breathing light notification effect for Claude Code hooks.

## Features

- Gaussian breathing curve with natural inhale/exhale rhythm
- Full-screen edge glow on all four sides
- Dynamic glow size that expands and contracts with breathing
- System sound playback on trigger
- Fully configurable via command-line arguments

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/neokn/claude-notification-hook/main/install.sh | bash
```

> **Requirements:** macOS 11.0+ with Apple Silicon (M1/M2/M3/M4)

## Usage

```bash
./pulse-notify [options]
```

## Parameters

### Basic

| Parameter | Short | Default | Description |
|-----------|-------|---------|-------------|
| `--color` | `-c` | `orange` | Glow color (name or hex) |
| `--duration` | `-d` | `8` | Duration in seconds |

**Supported color names:**
`white`, `green`, `blue`, `red`, `orange`, `purple`, `yellow`, `pink`, `cyan`

**Hex format:** `#FF5500` or `FF5500`

### Breathing

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--breath-cycle` | `4.0` | Full breath cycle duration (seconds) |
| `--min-brightness` | `0.15` | Minimum brightness (0-1) |
| `--max-brightness` | `1.0` | Maximum brightness (0-1) |
| `--inhale-sigma` | `0.8` | Inhale Gaussian width (smaller = faster) |
| `--exhale-sigma` | `1.2` | Exhale Gaussian width (larger = slower) |

### Glow Size

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--min-glow-height` | `80` | Min height for top/bottom glow (px) |
| `--max-glow-height` | `160` | Max height for top/bottom glow (px) |
| `--min-glow-width` | `100` | Min width for left/right glow (px) |
| `--max-glow-width` | `200` | Max width for left/right glow (px) |
| `--min-blur` | `20` | Min blur radius (px) |
| `--max-blur` | `45` | Max blur radius (px) |

### Sound

| Parameter | Short | Default | Description |
|-----------|-------|---------|-------------|
| `--sound` | `-s` | `Ping` | Sound effect name |
| `--no-sound` | - | - | Disable sound |

**Available system sounds:**
```
Basso, Blow, Bottle, Frog, Funk, Glass, Hero,
Morse, Ping, Pop, Purr, Sosumi, Submarine, Tink
```

### Speech (Text-to-Speech)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--speak` | - | Message to speak (fallback if no stdin message) |
| `--voice` | `Ralph` | macOS voice name |

**Speech priority:** stdin `message` field → `--speak` parameter → no speech

When triggered by Claude Code hooks, the program automatically reads the `message` field from stdin JSON and speaks it. Use `--speak` as a fallback for hooks without messages (like `Stop`).

**List available voices:**
```bash
say -v '?'                    # All voices
say -v '?' | grep Taiwan      # Taiwan Chinese voices
say -v '?' | grep en_US       # US English voices
```

## Examples

```bash
# Default (orange glow + Ping sound)
./pulse-notify

# Green success notification
./pulse-notify -c green -d 5 -s Glass

# Red error warning (faster breathing)
./pulse-notify -c red --breath-cycle 2 -s Basso

# Blue silent mode with large glow
./pulse-notify -c blue --max-glow-height 200 --no-sound

# Custom hex color
./pulse-notify -c "#FF6B35" -d 10

# Slow meditation mode
./pulse-notify -c purple --breath-cycle 8 --exhale-sigma 1.5

# With speech
./pulse-notify -c orange -s Glass --speak "Mission accomplished" --voice Daniel

# Test stdin message (simulating Claude hook)
echo '{"message": "Permission needed"}' | ./pulse-notify -c red
```

## Claude Code Hook Configuration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c red -s Ping"
          }
        ]
      },
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c blue -s Blow"
          }
        ]
      },
      {
        "matcher": "elicitation_dialog",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c purple -s Pop"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/claude-notification-hook/bin/pulse-notify -c orange -s Glass --speak 'Mission accomplished' --voice Meijia"
          }
        ]
      }
    ]
  }
}
```

### Event Types

| Event | Color | Sound | Speech | Purpose |
|-------|-------|-------|--------|---------|
| `permission_prompt` | Red | Ping | Auto (stdin) | Permission request, needs attention |
| `idle_prompt` | Blue | Blow | Auto (stdin) | Waiting for input |
| `elicitation_dialog` | Purple | Pop | Auto (stdin) | Interactive dialog/question |
| `Stop` | Orange | Glass | "Mission accomplished" | Task completed |

> **Note:** Notification hooks automatically speak the `message` field from Claude's stdin JSON. The `Stop` hook uses `--speak` as a fallback since it doesn't include a message.

## License

MIT
