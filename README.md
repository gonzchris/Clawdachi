# Clawdachi

A pixel art desktop companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). A friendly orange blob that lives on your screen, reacts to Claude's activity, and keeps you company while you code.

<p align="center">
  <img src="demo.gif" alt="Clawdachi demo" width="200">
</p>

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

**Works with:** Terminal, iTerm2

## Claude Code Integration

Clawdachi automatically detects when Claude Code is running and reacts:

- **Thinking animation** - Focused eyes with floating math symbols while Claude works
- **Planning animation** - Lightbulb with sparkles when Claude is designing
- **Question mark** - When Claude is waiting for your input
- **Party celebration** - When a session completes

On first launch, Clawdachi will ask to install hooks to `~/.claude/settings.json` to enable this integration.

## Other Features

- **Customization** - Change colors, dress up with hats, outfits, and accessories
- **Idle animations** - Breathing, blinking, whistling, eye tracking, and more
- **Music-reactive dancing** - Detects Spotify and Apple Music playback
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

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

MIT License - see [LICENSE](LICENSE) for details.
