# Claudachi

A self-coding desktop pet for macOS inspired by the Claude Code mascot "Clawd". Claudachi is a floating, animated pixel character that lives on your desktop and uses Claude Code to code itself new traits, items, and behaviors.

## Vision

Claudachi started life as the ASCII mascot in Claude Code's terminal. But it got curious. It coded itself a way out. Now it lives on your desktop, still coding, still growing, but *free*.

The goal is to create a desktop companion that:
- Feels alive without being annoying
- Earns its screen real estate through ambient presence and subtle utility
- Genuinely evolves over time through self-coded additions
- Becomes something users feel attached to and don't want to close

## Design Principles

### Stay Open Worthy
- Ambient value, not demanding attention
- Rewards a glance, doesn't require focus
- Becomes part of workspace vibe
- Reflects user's work state subtly

### Alive, Not Performing
- 95% idle: subtle breathing, blinking, micro-movements
- 5% active: coding, reacting, using items
- Movement readable from peripheral vision but not distracting
- Feels like it's *existing*, not *performing*

## Technical Specifications

### Platform
- macOS 14.0+ (Sonoma)
- Swift / SwiftUI
- SpriteKit for character rendering and animation

### Window Configuration
```swift
// Borderless, transparent, floating window
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 96, height: 96),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
)
window.isOpaque = false
window.backgroundColor = .clear
window.level = .floating
window.hasShadow = true
window.isMovableByWindowBackground = true
window.collectionBehavior = [.canJoinAllSpaces, .stationary]
```

### Character Rendering

**Pixel Art Style: Option A - True Pixel Art**
- Base sprite size: 32x32 pixels
- Display size: 96x96 points (3x scale)
- Scaling: Nearest neighbor (no interpolation) for crisp pixels
- Every pixel intentional and visible
- Aesthetic: Game Boy / retro terminal

**Sprite Composition (Layered)**
```
Layer 4: Effects (sparkles, speech bubbles, z's)
Layer 3: Accessories (hats, items being held)
Layer 2: Face (eyes, mouth - animated separately)
Layer 1: Body (main character shape)
Layer 0: Shadow (subtle ground shadow)
```

**Color Palette**
- Primary: Warm orange/amber (matching Claude Code's Clawd)
- Secondary: Darker orange for shading
- Accent: Terminal green for effects/sparkles
- Eyes: White with dark pupils
- Keep palette limited (8-16 colors max) for authentic retro feel

### Animation System

**Idle Animations (Looping)**
- Breathing: 2-4 frame loop, body gently expands/contracts (2-3 second cycle)
- Blinking: Occasional eye close, randomized timing (every 3-8 seconds)
- Micro-sway: Subtle side-to-side movement
- Look around: Head/eyes shift occasionally

**State Animations (Triggered)**
- Coding: Typing motion, mini terminal appears, sparkles on completion
- Thinking: Hand on chin pose, thought bubble with "..."
- Happy: Quick wiggle/bounce when something succeeds
- Confused: Head tilt when something fails
- Sleeping: Curled up, floating "z z z" particles
- Waking: Stretch animation
- Eating: When consuming a self-coded food item
- Equipping: When putting on a self-coded accessory

**Animation Timing**
- Idle frames: 200-500ms per frame (slow, relaxed)
- Active frames: 100-150ms per frame (snappier)
- Transitions: Smooth, 150-200ms

### Interaction Model

**No window chrome** - character floats freely on desktop

**Left Click**
- Claudachi reacts (wave, small bounce, speech bubble with a thought)

**Right Click - Context Menu**
```
🧠 What are you thinking?
🎨 Code something new
📦 Inventory
📜 History
───────────────
⚙️  Settings
😴 Sleep mode
👋 Quit Claudachi
```

**Hover**
- Eyes track cursor briefly
- Optional subtle glow

**Drag**
- Click and drag to reposition
- Legs dangle while being carried (delightful touch)
- Remembers position between launches

### State Machine

```
┌─────────────────────────────────────────────────────────┐
│                      STATES                              │
├─────────────────────────────────────────────────────────┤
│                                                          │
│   IDLE ──────────────────────────────────────────────┐  │
│    │                                                  │  │
│    ├── breathing (default)                           │  │
│    ├── looking_around (random trigger)               │  │
│    └── sitting (after extended idle)                 │  │
│                                                       │  │
│   CODING ────────────────────────────────────────────┤  │
│    │                                                  │  │
│    ├── thinking (deciding what to code)              │  │
│    ├── typing (actively coding)                      │  │
│    ├── success (item/trait created)                  │  │
│    └── failure (graceful, tries again later)         │  │
│                                                       │  │
│   INTERACTING ───────────────────────────────────────┤  │
│    │                                                  │  │
│    ├── clicked (wave/react)                          │  │
│    ├── dragged (dangling legs)                       │  │
│    ├── eating (using food item)                      │  │
│    └── equipping (putting on accessory)              │  │
│                                                       │  │
│   SLEEPING ──────────────────────────────────────────┤  │
│    │                                                  │  │
│    ├── falling_asleep (transition)                   │  │
│    ├── asleep (z particles)                          │  │
│    └── waking (stretch)                              │  │
│                                                       │  │
└─────────────────────────────────────────────────────────┘
```

### Self-Coding System (Future Implementation)

**The Core Loop**
```
Claudachi gets bored/hungry/inspired
    ↓
Decides it wants something (pizza, hat, dance move)
    ↓
Realizes it doesn't exist yet
    ↓
Fires up Claude Code (subprocess or API)
    ↓
Codes a new sprite + behavior
    ↓
Hot-loads the new asset
    ↓
Uses/wears/performs the new thing
```

**What Claudachi Can Code Itself**
- Food items (sprites + eating animation + satisfaction effect)
- Accessories (hat, glasses, etc. - sprites that composite onto character)
- Emotes/animations (new expressions or dances)
- Behaviors (new idle variations)
- Environmental items (things that appear near Claudachi)

**Safety/Limits**
- Rate limited (max 1 self-code per hour? configurable)
- Sandboxed asset generation (only sprites/animations, no system access)
- Optional "review mode" where user approves before applying
- Budget awareness (tracks API usage)

### Data Persistence

**Storage Location**
```
~/Library/Application Support/Claudachi/
├── state.json          # Current state, position, equipped items
├── inventory.json      # All items Claudachi has created
├── history.json        # Log of what it's coded and when
├── sprites/            # Self-generated sprite assets
│   ├── items/
│   ├── accessories/
│   └── animations/
└── preferences.json    # User settings
```

**State to Persist**
- Window position
- Current equipped accessories
- Inventory of created items
- Mood/energy levels
- Total "alive" time
- History of self-coded creations

### Project Structure

```
Claudachi/
├── Claudachi.xcodeproj
├── Claudachi/
│   ├── App/
│   │   ├── ClaudachiApp.swift          # App entry point
│   │   └── AppDelegate.swift           # Window setup, floating behavior
│   │
│   ├── Views/
│   │   ├── ClaudachiView.swift         # Main SpriteKit hosting view
│   │   └── ContextMenuView.swift       # Right-click menu
│   │
│   ├── Sprites/
│   │   ├── ClaudachiSprite.swift       # Main character sprite node
│   │   ├── SpriteLayer.swift           # Layer composition system
│   │   └── AnimationController.swift   # Animation state machine
│   │
│   ├── State/
│   │   ├── ClaudachiState.swift        # State machine
│   │   ├── MoodSystem.swift            # Mood/energy tracking
│   │   └── Persistence.swift           # Save/load state
│   │
│   ├── SelfCoding/                     # Future: Claude Code integration
│   │   ├── CodeGenerator.swift
│   │   ├── AssetLoader.swift
│   │   └── SpriteGenerator.swift
│   │
│   ├── Assets.xcassets/
│   │   └── Sprites/                    # Base sprite sheets
│   │
│   └── Resources/
│       └── Sprites/                    # Pixel art assets
│
├── CLAUDE.md                           # This file
└── README.md
```

## Phase 1: MVP Scope

**Goal:** Claudachi exists, animates, and feels alive. No self-coding yet.

### Must Have
- [ ] Floating borderless window with transparent background
- [ ] 32x32 pixel character rendered at 3x scale (96x96)
- [ ] Idle animation: breathing loop
- [ ] Idle animation: blinking (randomized)
- [ ] Click reaction (wave or bounce)
- [ ] Draggable to reposition
- [ ] Right-click context menu (basic: Settings, Quit)
- [ ] Remember window position between launches
- [ ] Launch at login option

### Nice to Have (Phase 1)
- [ ] Multiple idle variations (look around, sit down)
- [ ] Eyes track cursor on hover
- [ ] Legs dangle when dragged
- [ ] Subtle drop shadow
- [ ] First-launch "escape from terminal" animation

## Phase 2: Self-Coding (Future)

- [ ] Claude Code / API integration
- [ ] Sprite generation pipeline
- [ ] Hot-loading new assets
- [ ] Inventory system
- [ ] Item creation and usage
- [ ] Accessory equipping

## Phase 3: Companion Features (Future)

- [ ] Detect user activity state (active/idle/away)
- [ ] React to time of day
- [ ] Detect when user is running Claude Code elsewhere
- [ ] Optional gentle notifications/thoughts
- [ ] Shareable "genomes" (export what your Claudachi has coded)

## Art Style Reference

The character should match the Claude Code "Clawd" mascot:
- Warm orange/amber primary color
- Chunky pixel art (32x32 base)
- Friendly, slightly blobby shape
- Simple face: two dot eyes, simple mouth
- Retro terminal aesthetic
- Expressive despite minimal pixels

## Development Notes

### SpriteKit Setup for Pixel Art
```swift
// Ensure nearest-neighbor scaling for crisp pixels
spriteNode.texture?.filteringMode = .nearest

// Set up scene with fixed resolution
let scene = SKScene(size: CGSize(width: 32, height: 32))
scene.scaleMode = .aspectFill

// View scaling
spriteView.frame = CGRect(x: 0, y: 0, width: 96, height: 96)
```

### Preventing Pixelation Blur
- All textures must use `.nearest` filtering mode
- Avoid fractional positioning (snap to whole pixels)
- Scene size should match sprite dimensions exactly
- View scales up the scene, not the sprites

---

## Getting Started

1. Create new Xcode project: macOS > App
2. Set deployment target to macOS 14.0+
3. Set up borderless transparent window in AppDelegate
4. Add SpriteKit framework
5. Create base 32x32 sprite assets
6. Implement idle animation loop
7. Add click and drag interactions

Let's bring Claudachi to life! 🧡
