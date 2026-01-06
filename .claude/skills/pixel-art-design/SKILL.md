---
name: pixel-art-design
description: Create pixel-art sprites, animations, and UI elements for Clawdachi. Use this skill when designing visual elements, animations, or UI components that match the retro pixel aesthetic.
---

This skill guides creation of pixel-art visual elements for Clawdachi, ensuring consistency with the established aesthetic and technical patterns.

## Design Principles

### Pixel Art Style
- **Resolution**: 32x32 pixel base for sprites, scaled 6x with nearest-neighbor filtering
- **No anti-aliasing**: Crisp pixel edges, no smoothing
- **Limited palette**: Use established Clawdachi color palette
- **Intentional pixels**: Every pixel should serve a purpose

### Color Palette
| Color | Hex | Usage |
|-------|-----|-------|
| Primary Orange | #FF9933 | Main body, primary elements |
| Shadow Orange | #CC6600 | Shading, depth |
| Highlight Orange | #FFBB77 | Highlights, emphasis |
| Dark Outline | #222222 | Outlines, eyes, text |
| Mouth Brown | #442200 | Mouth shapes |
| White | #FFFFFF | UI backgrounds, highlights, sparks |
| Gray Shadow | #8C8C8C | Drop shadows |
| Spark Yellow | #FFF596 | Lightbulb sparks main |
| Spark Yellow Bright | #FFFFC8 | Lightbulb sparks highlight |
| Spark Yellow Dark | #FFDC50 | Lightbulb sparks shadow |

### UI Elements (Chat Bubbles, etc.)
- **Pixel-art styling**: Black outline, gray drop shadow (offset left/bottom), white fill
- **Rounded corners**: Use stepped diagonal pattern (3px corner radius in pixel units)
- **Shadows**: 2px offset, positioned on left and bottom edges
- **Rendering**: Use NSBezierPath for GPU-accelerated drawing, avoid pixel-by-pixel loops
- **Caching**: Cache generated images by size/variant to avoid redundant work

## Animation Guidelines

### Timing Principles
- **Breathing**: Slow, subtle (3.0s cycle)
- **Reactions**: Snappy but not jarring (0.15-0.25s)
- **Idle variations**: Randomized intervals to feel organic
- **Pop-in effects**: Overshoot slightly (1.1x) then settle

### Animation Patterns
- **Idle animations**: Run continuously, coordinated via idle cycle (whistle/smoke alternate every 20s)
- **State animations**: Managed by SpriteStateManager; use state-backed computed properties (e.g., `isDancing`, `isSmoking`)
- **Particle effects**: Float upward, fade out, use consistent gradient styling, return to pool on complete
- **UI animations**: Pop-in with overshoot, fade-out on dismiss

### Standard Timings
| Animation | Duration | Notes |
|-----------|----------|-------|
| Pop-in | 0.15s | Scale 0.3→1.1 with easeOut |
| Settle | 0.075s | Scale 1.1→1.0 with easeInOut |
| Fade-out | 0.2s | Alpha 1→0 with easeIn |
| Slide/move | 0.25s | Position changes with easeOut |
| Breathing | 3.0s | Full cycle |
| Blink | 0.1s per frame | 5-frame sequence |

## Technical Patterns

### Sprite Generation
Use `PixelArtGenerator` for converting pixel arrays to SKTexture:
```swift
let pixels: [[ClawdachiPalette.Color?]] = [...]
let texture = PixelArtGenerator.generateTexture(from: pixels, scale: 6)
```

### UI Elements (NSWindow-based)
For text or complex UI, use separate NSWindow + AppKit views:
```swift
// Architecture: Manager → Window → View → Textures
ChatBubbleManager.shared.showMessage("Hello!", relativeTo: spriteWindow)
```

### Performance
- Cache fonts, images, attributed strings (use NSCache for thread safety)
- Use NSBezierPath instead of pixel loops for shapes
- Use object pooling for particles (ParticlePool) and windows
- Batch animations when possible

### Floating Effects
Use ParticleSpawner for consistent particle styling (with object pooling):
- Orange gradient (highlight → main → shadow)
- Black outline for visibility
- Float upward with fade-out
- Randomized spawn positions and timing

## File Organization

New visual elements should follow this structure:
- **Sprites/**: SpriteKit-based visual elements
- **Sprites/Constants/**: Timing, positioning, color constants
- **Sprites/Effects/**: Particle spawners and effects
- **UI/**: NSWindow-based UI elements (chat bubbles, etc.)

## Quality Checklist

Before finalizing any visual element:
- [ ] Uses established color palette
- [ ] Crisp pixels (no smoothing/anti-aliasing)
- [ ] Consistent outline thickness
- [ ] Shadow offset consistent with existing elements
- [ ] Animation timing feels natural
- [ ] Caching implemented for performance
- [ ] Constants extracted to appropriate file
