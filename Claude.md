# Clawdachi

A cute pixel art desktop pet for macOS. A friendly orange blob that lives on your screen, breathes, blinks, whistles, dances to your music, and reacts when you interact with it.

---

## What It Does

Clawdachi is a tiny pixel mascot that floats on your desktop. It has a life of its own - breathing gently, blinking randomly, occasionally whistling a tune with little music notes floating up. Play some music in Spotify or Apple Music and watch it groove along! Click on it and it'll wave or bounce happily. Drag it around and watch it sweat nervously. Put it to sleep when you need focus time.

It's a small piece of joy that makes your desktop feel a little more alive.

---

## Features

### Idle Animations
- **Breathing:** Gentle 4-frame breathing cycle
- **Blinking:** Random blinks every 2.5-6 seconds
- **Whistling:** Occasionally whistles with floating music notes (side-mouth style)
- **Eye tracking:** Eyes follow your mouse cursor
- **Looking around:** Eyes wander curiously when idle

### Music-Reactive Dancing
- **Automatic detection:** Monitors Spotify and Apple Music playback
- **Dance animation:** When music plays:
  - Body sways side to side
  - Arms wave up and down alternately
  - Legs tap in rhythm
  - Music notes (♪/♫) float up from both sides
- **Smart behavior:** Stops dancing when sleeping, resumes after waking

### Interactions
- **Click:** Triggers random reactions (wave, bounce, pixel heart)
- **Drag:** Pick up and reposition anywhere on screen
  - Sweat drops appear (it's nervous!)
  - Arms wiggle anxiously
- **Right-click menu:**
  - Sleep Mode / Wake Up
  - Quit

### Other
- **Sleep mode:** Closes eyes, spawns floating Z's
- **GIF recording:** Capture animations with Cmd+Shift+R
- **Window position:** Remembers where you left it

### Visual Effects
All floating effects feature consistent styling:
- **Orange gradient** matching sprite palette (highlight → main → shadow)
- **Black outline** for visibility
- **Smooth anti-aliased** rendering for notes and Z's
- **Pixel-art hearts** with shading

---

## Technical Details

### Platform
- macOS 14.0+ (Sonoma)
- Swift
- SpriteKit for rendering and animation

### Window
- Borderless transparent window (288x288 points)
- Floating level (stays above other windows)
- Supports all Spaces
- Draggable anywhere on screen

### Sprite
- 32x32 pixel base resolution
- 6x scale with nearest-neighbor filtering (crisp pixels)
- Programmatically generated (no external image files)
- Layered composition: limbs → body → face → effects

### Color Palette
| Color | Hex | Usage |
|-------|-----|-------|
| Primary Orange | #FF9933 | Main body |
| Shadow Orange | #CC6600 | Shading |
| Highlight Orange | #FFBB77 | Highlights |
| Eye Pupil | #222222 | Eyes |
| Mouth | #442200 | Mouth shapes |

---

## Project Structure

```
Clawdachi/
├── App/
│   └── AppDelegate.swift           # Window setup, keyboard shortcuts
├── ClawdachiApp.swift              # App entry point
├── Recording/
│   ├── AnimationRecorder.swift     # GIF frame capture
│   └── GIFExporter.swift           # GIF file creation
├── Services/
│   └── MusicPlaybackMonitor.swift  # Spotify/Apple Music detection via AppleScript
└── Sprites/
    ├── Animation/
    │   ├── ClawdachiSprite+Dancing.swift    # Music-reactive dance animations
    │   ├── ClawdachiSprite+Drag.swift       # Drag interaction
    │   ├── ClawdachiSprite+Idle.swift       # Breathing, blinking, whistling
    │   ├── ClawdachiSprite+Interaction.swift # Click reactions
    │   └── ClawdachiSprite+Sleep.swift      # Sleep mode
    ├── Constants/
    │   ├── AnimationTimings.swift  # All timing values
    │   └── SpritePositions.swift   # Position and z-order constants
    ├── Effects/
    │   └── ParticleSpawner.swift   # Music notes, hearts, sweat drops, Z's
    ├── ClawdachiBodySprites.swift  # Body texture generation
    ├── ClawdachiFaceSprites.swift  # Face/effect texture generation
    ├── ClawdachiPalette.swift      # Color definitions
    ├── ClawdachiScene.swift        # SKScene, input handling, context menu
    ├── ClawdachiSprite.swift       # Main sprite node, setup
    └── PixelArtGenerator.swift     # Pixel array → SKTexture utility
```

---

## Animation System

### Idle Loop
All idle animations run continuously and independently:
- Breathing: Body scales subtly, face bobs
- Blinking: Scheduled randomly, 5-frame sequence
- Whistling: Random trigger, shows mouth + spawns music notes
- Looking around: Eyes shift position randomly

### Animation Timings (see AnimationTimings.swift)
- Breathing cycle: 3.0s
- Blink interval: 2.5-6.0s
- Whistle interval: 12-25s
- Look around interval: 5-12s
- Dance sway: 0.6s
- Dance music note spawn: 0.8s

### Particle Effects
Reusable spawner for floating effects:
- Music notes (whistling)
- Hearts (click reaction)
- Sleep Z's (sleep mode)
- Sweat drops (dragging)

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+Shift+R | Toggle GIF recording |
| Cmd+Q | Quit (when focused) |

---

## Design Principles

### Ambient Presence
- Not demanding attention
- Rewards a glance, doesn't require focus
- Part of the workspace vibe

### Alive, Not Performing
- Mostly idle with subtle animations
- Occasional surprises (whistle, look around)
- Feels like it's *existing*, not *performing*

### Pixel Perfect
- Every pixel intentional
- Crisp rendering at any scale
- Consistent visual style

---

## Future Ideas

- More click reactions
- Time-of-day awareness (sleepy at night)
- Weather reactions
- Multiple personality modes
- Companion pets
