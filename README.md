# Sara's Mirror

A 2D top-down illusion adventure built in **Godot 4.6** for a game jam (theme: **Illusion**).

Sara is pulled into her shattered bedroom mirror and must reclaim one **mirror shard** from each of four dream-worlds — then step back through the glass to wake. The catch: nothing in the dream is quite what it looks like.

## Play / run it

1. Install [Godot 4.6+](https://godotengine.org/download) (standard build, no C#/.NET needed).
2. Open the Godot project manager → **Import** → select this folder → **Import & Edit**.
3. Press **F5** (or the Play button). The game starts at the title screen.

Everything is built in GDScript; there is no build step.

## Controls

| Action | Key |
|---|---|
| Move | WASD / Arrows |
| Strike | J / Left-click |
| True Sight (reveal real vs. illusion) | Q / Right-click |
| Dash | Shift |
| Interact (signs, levers, locks, portals, ladder) | E |
| Pause | Esc |
| Mute | M |

## The four dream-worlds

1. **The Shattered Hall** — a combination-lock gate (the dial *hums* as you near the right number) and a wall of mirror panels where only one is a passable illusion.
2. **The Cursed Forest** — a snake-filled swamp you bridge with a **ladder**, plus illusory hedges.
3. **The Mirage** — a vast belt of sinking sand crossed with the ladder; wander off and it takes you.
4. **The Mirror Throne** — a phase-gate gauntlet, an alignment-lever puzzle, and the Warden of Glass, wearing Sara's own face.

Core mechanic: **True Sight (Q)** exposes which walls, floors and paths are real. Hazards (quicksand, swamp snakes, spikes, crumbling floors, the light-sweep) hurt enemies too — lure them in.

## Project layout

```
autoload/     Global singletons: Game flow, Save, Audio (synth), FX, Illusion, Talk
systems/      Shared helpers: LevelBase, World (palettes/shaders), SpriteSheet
entities/     Player, enemies, pickups, props, hazards
levels/       The four dream-world scenes (code-built in build())
ui/           Main menu, HUD, win/wake-up cutscene
assets/       CC0 / free-license pixel art (see CREDITS.md)
```

Scenes are thin wrappers: each level's content is constructed in code (`build()`),
which makes the levels easy to read and diff. Audio and most VFX are generated
procedurally — no audio files.

## Contributing

- Use **Godot 4.6.x** to keep the `.godot` cache and class registry compatible.
- After adding a script with a new `class_name`, run the editor once (or
  `godot --headless --path . --import`) so the global class cache picks it up.
- Keep the `.godot/` cache and any `export/` output out of git (see `.gitignore`).

## Credits & license

Art assets are CC0 / free-license (CraftPix, Kenney) — see [CREDITS.md](CREDITS.md).
Game code and design are original to this project.
