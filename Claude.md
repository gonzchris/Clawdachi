# Claudachi

A self-evolving desktop pet that uses Claude to code itself new things. Leave it running, come back to surprises.

## The Pitch

> "I left my Claudachi running overnight and it coded itself a cowboy hat and a pizza."

Claudachi is a tiny pixel mascot that lives on your desktop. Every so often, it gets curious, fires up a mini terminal, and *codes itself something new* — a hat, a snack, a dance move, a tiny friend. You watch it happen. You screenshot it. You share it.

It's Tamagotchi meets AI, and every Claudachi evolves differently.

---

## Why This Could Go Viral

| Factor | How Claudachi Delivers |
|--------|------------------------|
| **Visual hook** | Cute pixel mascot floating on desktop — instant "what is that?" |
| **10-second explainer** | "Desktop pet that codes itself new things using AI" |
| **Shareworthy moments** | "My Claudachi just invented rollerskates" + screen recording |
| **Each one is unique** | "Look what MINE made" — personalized flex |
| **Timely** | AI hype + nostalgia (Tamagotchi) + Claude brand recognition |
| **Easy to demo** | Screen recordings look great, GIFs are perfect for X |

---

## The Core Loop

```
Claudachi vibes on desktop (idle animations)
            ↓
Every N minutes, it "gets an idea"
            ↓
Thinking animation → mini terminal appears → "coding" animation
            ↓
Claude API generates a new sprite/animation
            ↓
New thing appears! Claudachi uses/wears/eats it
            ↓
Item saved to inventory
            ↓
User screenshots, posts to X
```

---

## What Claudachi Creates

The things it invents need to be **visually delightful** and **shareworthy**:

### Accessories (wearable)
- Hats: cowboy, top hat, beanie, crown, propeller cap, chef hat
- Glasses: sunglasses, monocle, 3D glasses, heart-shaped
- Props: coffee cup, tiny laptop, sword, magic wand, balloon

### Food (consumable)
- Pizza slice, burger, sushi, ice cream cone, cookie, ramen bowl
- Eating animation plays when consumed
- Food disappears, Claudachi looks satisfied

### Actions/Emotes (performable)
- Dances: moonwalk, spin, little jig, robot dance
- Tricks: juggling, tiny backflip, magic sparkles
- Expressions: excited bounce, sleepy yawn, confused head-scratch

### Weird/Surprising (the viral bait)
- "It made itself a tiny friend to talk to"
- "It built a small house and went inside"
- "It invented a skateboard and immediately fell off"
- "It coded a window and is looking out at me"
- "It's wearing sunglasses indoors now. Won't take them off."

The **unexpected** stuff is what gets screenshotted.

---

## Technical Specifications

### Platform
- macOS 14.0+ (Sonoma)
- Swift / SwiftUI
- SpriteKit for character rendering and animation
- Anthropic API for sprite generation

### Current Implementation Status

**Window Setup** (DONE)
- Borderless transparent window (192x192 points, 6x scale)
- Floating level (stays above all windows)
- Supports all spaces + stationary behavior
- Draggable by window background

**Sprite System** (DONE)
- Programmatic pixel art generation (no external PNG files)
- Layered composition: body, arms, feet, eyes, mouth, accessories, effects
- Nearest-neighbor filtering for crisp pixels
- 32x32 base resolution
- Separate arm/foot nodes for independent animation

**Idle Animations** (DONE)
- Breathing: 4-frame loop, 2.5s cycle
- Blinking: random 3-8s intervals, 5-frame sequence
- Whistling: random 8-15s intervals, spawns music notes
- Click triggers blink

**Drag Interaction** (DONE)
- Sweat drop appears when dragged
- Arms wiggle during drag
- Smooth return animations on drop

**Chef Mode / Coding Animation** (DONE)
- Chef hat (toque) drops onto head with bounce animation
- Chef apron appears on body (lower portion, hangs below body)
- Frying pan held in right hand with shake animation
- Steam rises from pan
- Success/failure exit animations

### Window Configuration
```swift
// Current implementation in AppDelegate.swift
let window = NSWindow(
    contentRect: NSRect(x: 100, y: 100, width: 192, height: 192),
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

**Sprite Specs**
- Base size: 32x32 pixels
- Display size: 192x192 points (6x scale with nearest-neighbor)
- Generated programmatically from pixel arrays
- Every pixel intentional and visible

**Layer Composition (Current)**
```
Layer 10+: Accessories in front (frying pan, held items)
Layer 5: Hat (chef hat, other headwear)
Layer 3: Effects (music notes, sparkles, sweat drops)
Layer 2: Face (eyes, mouth — animated separately)
Layer 1: Body (main character shape)
Layer 0: Arms and feet (separate nodes for animation)
Layer -10: Accessories behind (chef mode effects)
```

**Color Palette** (Implemented in ClaudachiPalette.swift)
- Primary: #FF9933 (warm orange)
- Shadow: #CC6600 (dark orange)
- Highlight: #FFBB77 (light orange)
- Eyes: #FFFFFF white, #222222 pupils
- Mouth: #442200 (dark brown)
- Effects: #00FF88 (terminal green)

---

## Animation System

### Current Idle Animations
- **Breathing:** 4 textures cycling (contracted → neutral → expanded → neutral)
- **Blinking:** 5-frame sequence (open → half → closed → half → open)
- **Whistling:** Mouth shape + floating music notes

### Current Active Animations
- **Dragging:** Sweat drop appears, arms wiggle
- **Chef Mode (Coding):** Hat drops on head, apron appears, frying pan shakes with steam

### Future Active Animations
- **Getting idea:** Perk up, "!" or lightbulb appears
- **Success:** Item appears, happy wiggle/celebration
- **Equipping:** Puts on accessory with flourish
- **Eating:** Nom nom animation, satisfied expression

### Animation Timing
- Idle frames: 200-500ms (slow, relaxed)
- Active frames: 100-150ms (snappy, energetic)
- Transitions: 150ms ease

---

## State Machine

```
┌─────────────────────────────────────────────────────────────┐
│                      STATES                                  │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   IDLE (current default)                                     │
│    ├── breathing (continuous)                                │
│    ├── blinking (random trigger)                             │
│    └── whistling (random trigger)                            │
│                                                              │
│   CODING (future)                                            │
│    ├── getting_idea (transition into coding)                 │
│    ├── typing (terminal visible, typing animation)           │
│    ├── success (item appears, celebration)                   │
│    └── failure (shrug, try again later)                      │
│                                                              │
│   INTERACTING (future)                                       │
│    ├── clicked (wave/react)                                  │
│    ├── eating (using food item)                              │
│    └── equipping (putting on accessory)                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Self-Coding System Architecture

### The "Coding" Illusion
The coding is visual theater. Under the hood:
1. Timer fires → Claudachi "gets idea"
2. Show coding animation (purely visual)
3. Call Claude API to generate sprite
4. Load sprite, composite onto character
5. Save to inventory

### Idea Generator
```swift
class IdeaGenerator {
    let hats = ["cowboy", "top", "chef", "wizard", "party", "pirate", "crown", "beanie"]
    let glasses = ["sunglasses", "monocle", "3D", "heart-shaped", "nerd", "round"]
    let foods = ["pizza", "burger", "sushi", "ice cream", "cookie", "ramen", "taco", "donut"]
    let props = ["coffee cup", "tiny laptop", "sword", "balloon", "book", "umbrella"]

    func generateIdea(avoiding inventory: [Item]) -> ItemIdea {
        // Weight toward things Claudachi doesn't have yet
        // Occasionally pick something wild/random
    }
}
```

### Timing
- **Default:** Every 15-30 minutes (randomized)
- **Configurable:** User can adjust frequency
- **Rate limited:** Max N items per day (API cost control)

### Sprite Generation Prompt
```
Generate a 32x32 pixel art sprite of a [ITEM].

Requirements:
- Exactly 32x32 pixels
- Transparent background (alpha channel)
- Limited color palette (max 8 colors)
- Style: chunky retro pixel art, like Game Boy or early Mac
- Colors should complement orange/amber (the character's color)
- Clear silhouette, readable at small size

Return as base64-encoded PNG.
```

---

## Data Persistence

### Storage Location
```
~/Library/Application Support/Claudachi/
├── state.json              # Window position, equipped items, stats
├── inventory.json          # All created items
└── sprites/
    ├── hats/
    ├── glasses/
    ├── food/
    └── props/
```

### State to Persist
- Window position
- Current equipped accessories
- Inventory of created items
- Total "alive" time
- Generation count (for rate limiting)

---

## Project Structure

### Current Structure
```
Claudachi/
├── Claudachi.xcodeproj
├── Claudachi/
│   ├── App/
│   │   └── AppDelegate.swift           # Window setup
│   ├── Models/
│   │   ├── ItemCategory.swift          # Item category enum
│   │   └── GeneratedSprite.swift       # Generated sprite model
│   ├── Sprites/
│   │   ├── ClaudachiSprite.swift       # Main character (~1300 lines)
│   │   ├── ClaudachiBodySprites.swift  # Body textures + chef apron
│   │   ├── ClaudachiFaceSprites.swift  # Face textures + chef hat
│   │   ├── ClaudachiPalette.swift      # Colors
│   │   ├── ClaudachiScene.swift        # SKScene setup
│   │   ├── ChefModeSprite.swift        # Frying pan + steam effects
│   │   ├── PixelArtGenerator.swift     # Pixel→texture utility
│   │   ├── Constants/
│   │   │   ├── AnimationTimings.swift  # Timing constants
│   │   │   └── SpritePositions.swift   # Position/layer constants
│   │   └── Effects/
│   │       └── ParticleSpawner.swift   # Reusable particle effects
│   ├── Generation/
│   │   ├── SpriteGenerator.swift       # Claude CLI sprite generation
│   │   ├── SpriteStyles.swift          # Size/style presets + palette enforcement
│   │   └── ClaudeCodeClient.swift      # Claude Code CLI wrapper
│   ├── Recording/
│   │   ├── AnimationRecorder.swift     # Frame capture for GIFs
│   │   └── GIFExporter.swift           # GIF creation utility
│   ├── State/
│   │   └── ClaudachiStateMachine.swift # State management
│   ├── ClaudachiApp.swift              # App entry
│   └── Assets.xcassets/
├── CLAUDE.md
└── README.md
```

### Target Structure (after expansion)
```
Claudachi/
├── Claudachi/
│   ├── App/
│   │   ├── ClaudachiApp.swift
│   │   └── AppDelegate.swift
│   │
│   ├── Models/
│   │   ├── ItemCategory.swift          # Item category enum
│   │   └── GeneratedSprite.swift       # Generated sprite model
│   │
│   ├── Views/
│   │   ├── ContextMenuView.swift       # Right-click menu
│   │   └── InventoryView.swift         # Item gallery
│   │
│   ├── Sprites/
│   │   ├── ClaudachiSprite.swift       # Main character
│   │   ├── ClaudachiScene.swift        # Scene management
│   │   ├── AccessoryLayer.swift        # Item compositing
│   │   ├── Constants/
│   │   │   ├── AnimationTimings.swift  # Timing constants
│   │   │   └── SpritePositions.swift   # Position constants
│   │   ├── Effects/
│   │   │   ├── ChefModeSprite.swift    # Frying pan + steam
│   │   │   └── ParticleSpawner.swift   # Reusable particle effects
│   │   └── Generation/
│   │       ├── PixelArtGenerator.swift
│   │       ├── ClaudachiBodySprites.swift
│   │       ├── ClaudachiFaceSprites.swift
│   │       └── ClaudachiPalette.swift
│   │
│   ├── State/
│   │   ├── ClaudachiStateMachine.swift # Formal state machine
│   │   ├── Inventory.swift             # Item storage
│   │   └── Persistence.swift           # Save/load
│   │
│   ├── Generation/
│   │   ├── IdeaGenerator.swift         # What to make next
│   │   ├── SpriteGenerator.swift       # Claude API calls
│   │   └── ItemLoader.swift            # Load generated sprites
│   │
│   └── API/
│       └── ClaudeClient.swift          # Anthropic API wrapper
```

---

## Development Roadmap

### Phase 1: Living Character (DONE)
- [x] Floating borderless transparent window
- [x] 32x32 pixel character at 6x scale
- [x] Idle animation: breathing loop
- [x] Idle animation: blinking (randomized)
- [x] Idle animation: whistling with effects
- [x] Click detection (triggers blink)
- [x] Draggable to reposition with sweat drop + arm wiggle
- [ ] Persist window position between launches
- [ ] Right-click context menu (basic: Quit)
- [ ] Additional click reactions (wave, bounce)

### Phase 2: Self-Coding Foundation (IN PROGRESS)
- [x] Chef mode animation (hat, apron, frying pan with steam)
- [x] Enter/exit chef mode with smooth transitions
- [ ] Formal state machine (idle, coding, interacting)
- [ ] "Getting idea" animation (perk up, "!" bubble)
- [ ] Success celebration animation
- [ ] Timer-based idea triggers (configurable interval)

### Phase 3: Claude API Integration (IN PROGRESS)
- [x] ClaudeCodeClient wrapper for Claude Code CLI
- [x] SpriteGenerator with category-specific prompts
- [x] Multiple sprite sizes (8x8, 12x12, 16x16, 24x24)
- [x] Style presets (claudachi, gameboy, nes, monochrome, pastel)
- [x] Palette enforcement post-processing
- [ ] Generated sprite persistence to disk
- [ ] Rate limiting and error handling

### Phase 4: Inventory & Accessories
- [ ] Inventory data model and persistence
- [x] Accessory positioning system (hats on head, items in hand)
- [ ] Food consumption animation
- [ ] Right-click menu with inventory submenu
- [ ] Equip/unequip functionality

### Phase 5: Polish & Virality
- [ ] Built-in screenshot tool
- [ ] Shareable stats ("Invented 47 items")
- [ ] Launch at login option
- [ ] Settings panel (generation frequency, API key)
- [ ] First-launch "escape from terminal" animation

---

## Interaction Model

### Click
- Currently: triggers immediate blink
- Future: wave, bounce, happy expression

### Right-Click (future)
- Context menu: Inventory, Settings, Screenshot, Quit

### Drag (DONE)
- Pick up and reposition
- Sweat drop appears above head
- Arms wiggle anxiously during drag
- Smooth return to idle on drop

### Hover (future)
- Eyes briefly track cursor

---

## Key Design Principles

### Stay Open Worthy
- Ambient value, not demanding attention
- Rewards a glance, doesn't require focus
- Becomes part of workspace vibe

### Alive, Not Performing
- 95% idle: subtle breathing, blinking, micro-movements
- 5% active: coding, reacting, using items
- Feels like it's *existing*, not *performing*

### Shareworthy
Every feature should serve one question:
> "Would someone screenshot this and share it?"

If yes, build it. If no, skip it.

---

## Success Metrics

- Screenshots/recordings shared on X
- "Look what mine made" posts
- Retention: Do people leave it running?
- Unique inventories across users

---

Let's make something people can't stop talking about.
