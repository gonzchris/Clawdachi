# Clawdachi

A pixel art desktop pet for macOS. A friendly orange blob that lives on your screen, breathes, blinks, whistles, dances to your music, and reacts when you interact with it.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Idle animations** - Breathing, blinking, whistling, eye tracking, and more
- **Music-reactive dancing** - Detects Spotify and Apple Music playback
- **Claude Code integration** - Shows thinking animation when Claude is working, celebrates when done
- **Click interactions** - Waves, bounces, shows hearts
- **Drag anywhere** - Pick it up and move it around your screen (it gets nervous!)
- **Sleep mode** - Put it to bed when you need to focus

## Installation

### Download

Download the latest `.dmg` from the [Releases](https://github.com/gonzchris/Clawdachi/releases) page.

### Build from Source

Requires Xcode 15+ and macOS 14.0+.

```bash
git clone https://github.com/gonzchris/Clawdachi.git
cd Clawdachi
open Clawdachi.xcodeproj
```

Build and run with `Cmd+R`.

## Claude Code Integration

Clawdachi automatically detects when [Claude Code](https://claude.ai/claude-code) is running and shows:

- **Thinking animation** - Focused eyes with floating math symbols
- **Planning animation** - Lightbulb with sparkles when designing
- **Question mark** - When Claude is waiting for your input
- **Party celebration** - When a session completes

On first launch, Clawdachi will ask to install hooks to `~/.claude/settings.json` to enable this integration.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+R` | Toggle GIF recording |
| `Cmd+,` | Open settings |

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

MIT License - see [LICENSE](LICENSE) for details.
