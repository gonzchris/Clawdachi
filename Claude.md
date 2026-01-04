# Claudachi

A cute pixel art desktop pet for macOS. A friendly orange blob that lives on your screen, breathes, blinks, whistles, and reacts when you interact with it.

---

## What It Does

Claudachi is a tiny pixel mascot that floats on your desktop. It has a life of its own - breathing gently, blinking randomly, occasionally whistling a tune with little music notes floating up. Click on it and it'll wave or bounce happily. Drag it around and watch it sweat nervously. Put it to sleep when you need focus time.

It's a small piece of joy that makes your desktop feel a little more alive.

---

## Features

### Idle Animations
- **Breathing:** Gentle 4-frame breathing cycle
- **Blinking:** Random blinks every 2.5-6 seconds
- **Whistling:** Occasionally whistles with floating music notes
- **Looking around:** Eyes wander curiously

### Interactions
- **Click:** Triggers random reactions (wave, bounce, heart)
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
Claudachi/
├── App/
│   └── AppDelegate.swift           # Window setup, keyboard shortcuts
├── ClaudachiApp.swift              # App entry point
├── Recording/
│   ├── AnimationRecorder.swift     # GIF frame capture
│   └── GIFExporter.swift           # GIF file creation
└── Sprites/
    ├── Animation/
    │   ├── ClaudachiSprite+Drag.swift       # Drag interaction
    │   ├── ClaudachiSprite+Idle.swift       # Breathing, blinking, whistling
    │   ├── ClaudachiSprite+Interaction.swift # Click reactions
    │   └── ClaudachiSprite+Sleep.swift      # Sleep mode
    ├── Constants/
    │   ├── AnimationTimings.swift  # All timing values
    │   └── SpritePositions.swift   # Position and z-order constants
    ├── Effects/
    │   └── ParticleSpawner.swift   # Music notes, hearts, sweat drops, Z's
    ├── ClaudachiBodySprites.swift  # Body texture generation
    ├── ClaudachiFaceSprites.swift  # Face/effect texture generation
    ├── ClaudachiPalette.swift      # Color definitions
    ├── ClaudachiScene.swift        # SKScene, input handling, context menu
    ├── ClaudachiSprite.swift       # Main sprite node, setup
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
- Cursor tracking (eyes follow mouse)
- Time-of-day awareness (sleepy at night)
- Weather reactions
- Multiple personality modes
- Companion pets
