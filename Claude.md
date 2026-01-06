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
- **Smoking:** Rare cigarette break animation (humorous)
  - Pixel-art cigarette with ember glow
  - Arm raises to mouth, exhales smoke
  - Cigarette shrinks with each puff
  - Subtle tip smoke wisps
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

### Claude Code Integration
- **Auto-setup:** On first launch, automatically installs hooks to `~/.claude/settings.json`
- **Thinking animation:** When Claude Code is working:
  - Focused eyes: `> <` expression with occasional blinks
  - Gentle head bob
  - Orange dots float upward and pop at the top
  - Chat bubble: "hmm, let me think...", "on it!", "brb coding...", etc.
- **Planning animation:** When Claude is in plan mode (designing implementation):
  - Focused eyes: `> <` with occasional blinks
  - Gentle head bob (same as thinking)
  - Glowing lightbulb above head with pulsing yellow glow
  - Yellow/white sparkles flicker around the lightbulb
  - No orange thinking dots (sparkles replace them)
  - Chat bubble: "planning it out...", "got an idea!", "designing...", etc.
  - Triggered by EnterPlanMode tool, ends with ExitPlanMode
- **Waiting question mark:** White pixel question mark appears when Claude is waiting for user input or permission approval (dismisses on click or when Claude starts again)
  - Chat bubble: "your turn!", "whatcha think?", "need your input!", etc.
- **Party celebration:** When Claude session ends, shows party hat on head with cycling party blower animation:
  - Purple/gold striped party hat wobbles gently
  - Party blower pops in, extends with flutter, retracts, disappears, repeats
  - Arms shoot up on each "toot"
  - Persists until clicked or new CLI activity
- **File-based hooks:** Monitors `~/.clawdachi/sessions/` for status files
  - Plan mode tracked via `~/.clawdachi/planmode/` marker files
- **Smart behavior:** Pauses dancing/idle animations during all Claude states (thinking, planning, question mark, party celebration)

### Chat Bubbles
- **RPG-style message system:** Stacking speech bubbles beside sprite
- **Positioning:** Appears at mouth level, to the right of sprite
- **Pixel-art styling:** White fill, black outline, gray drop shadow
- **Triangular tail:** Points LEFT toward sprite from left edge of bubble
- **Always on top:** Window level above sprite for visibility
- **Multi-message support:** Up to 4 bubbles stack vertically
  - Newest message appears at bottom (with tail)
  - Older messages slide up (tail removed, left-aligned)
  - Oldest auto-dismisses when 5th message arrives
  - 2px spacing between stacked messages
- **Speaking animation:** Sprite mouth animates when bubble appears
  - "-O-O" pattern with 4 random variations
  - Hollow O shape for open mouth
- **Animations:** Pop-in with overshoot, fade-out on dismiss
- **Dismissal:** Click any bubble to dismiss, or auto-dismiss after 5 seconds
- **Font:** Silkscreen pixel font (12pt) for clean retro look

### Interactions
- **Click:** Triggers random reactions (wave, bounce, pixel heart)
- **Drag:** Pick up and reposition anywhere on screen
  - Sweat drops appear (it's nervous!)
  - Arms wiggle anxiously
- **Right-click menu:**
  - Sleep Mode / Wake Up
  - Test Chat Bubble
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
- Borderless transparent window (288x384 points)
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
├── Resources/
│   ├── claude-status.sh            # Hook script (tracks thinking, planning, waiting)
│   └── Fonts/                      # Custom pixel fonts (Silkscreen, etc.)
├── Services/
│   ├── ClaudeIntegrationSetup.swift # Auto-setup hooks on first launch
│   ├── ClaudeSessionMonitor.swift   # Claude Code status via file polling
│   └── MusicPlaybackMonitor.swift   # Spotify/Apple Music detection via AppleScript
├── UI/
│   ├── ChatBubbleManager.swift     # Manages stacking bubble queue (max 4)
│   ├── ChatBubbleWindow.swift      # Individual bubble NSWindow
│   ├── ChatBubbleView.swift        # Custom NSView for bubble rendering
│   ├── ChatBubbleTextures.swift    # Pixel-art bubble image generation
│   └── PixelFontLoader.swift       # Custom font loading and caching
└── Sprites/
    ├── Animation/
    │   ├── ClawdachiSprite+Claude.swift     # Claude Code thinking/planning animations
    │   ├── ClawdachiSprite+Dancing.swift    # Music-reactive dance animations
    │   ├── ClawdachiSprite+Drag.swift       # Drag interaction
    │   ├── ClawdachiSprite+Idle.swift       # Breathing, blinking, whistling
    │   ├── ClawdachiSprite+Interaction.swift # Click reactions
    │   ├── ClawdachiSprite+Sleep.swift      # Sleep mode
    │   ├── ClawdachiSprite+Smoking.swift    # Smoking idle animation
    │   └── ClawdachiSprite+Speaking.swift   # Speaking mouth animation
    ├── Constants/
    │   ├── AnimationTimings.swift    # All timing values
    │   ├── ChatBubbleConstants.swift # Chat bubble sizing, colors, timing
    │   └── SpritePositions.swift     # Position and z-order constants
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

### Animation Timings (see AnimationTimings.swift, ChatBubbleConstants.swift)
- Breathing cycle: 3.0s
- Blink interval: 2.5-6.0s
- Whistle interval: 18-35s
- Smoking interval: 20-40s
- Smoking duration: 18s
- Smoking puff interval: 3.0s
- Look around interval: 5-12s
- Dance sway: 0.6s
- Dance music note spawn: 0.8s
- Claude thinking bob: 2.0s
- Claude thinking dot spawn: 0.6-1.0s
- Claude thinking blink: 4-7s
- Claude planning spark spawn: 0.15-0.35s
- Claude planning spark lifetime: ~0.25s
- Chat bubble pop-in: 0.15s (with 1.1x overshoot)
- Chat bubble fade-out: 0.2s
- Chat bubble auto-dismiss: 5.0s
- Chat bubble stack slide: 0.25s
- Speaking mouth pattern: ~0.6-0.8s (varies by pattern)

### Particle Effects
Reusable spawner for floating effects:
- Music notes (whistling, dancing)
- Hearts (click reaction)
- Sleep Z's (sleep mode)
- Sweat drops (dragging)
- Thinking dots (Claude working) - orange gradient
- Lightbulb sparks (Claude planning) - yellow/white
- Smoke particles (smoking animation)

### Chat Bubble System
Separate floating NSWindow system (not SpriteKit) for text rendering:
- **Architecture:** ChatBubbleManager (singleton) → ChatBubbleWindow[] → ChatBubbleView
- **Rendering:** NSBezierPath for rounded rect body + triangular left-pointing tail
- **Tail position:** Points LEFT from left edge of bubble toward sprite
- **Z-order:** Window level above sprite's floating level
- **Caching:** LRU image cache (12 entries), font caching, attributed string caching
- **Positioning:** At mouth level, right of sprite center (horizontal offset 42px)

API:
```swift
// Show a message (managed by ChatBubbleManager)
ChatBubbleWindow.show(message: "Hello!", relativeTo: spriteWindow)

// Or via scene
clawdachiScene.showChatBubble("Hello!", duration: 5.0)

// Dismiss all
ChatBubbleWindow.dismiss(animated: true)
```

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
- Chat bubble typing animation (character by character)
- Different bubble styles/colors
- Sound effects for interactions
