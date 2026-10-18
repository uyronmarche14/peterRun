# L01 shallow puddle v04

This is a separate, editable vector source for the game-readable puddle. The earlier Blender source and v03 PNG are preserved. Blender was not available in the current environment, so this pass does not claim a Blender model update.

- Source: `prompt_l01_shallow_puddle_v04.svg` (256×128, transparent)
- Runtime: `../../code/art/prompts/l01_barangay/prompt_l01_shallow_puddle_v04.png`
- Export: run `godot --headless --path code -s res://tools/export_l01_puddle_v04.gd` from the repository root, substituting the installed Godot executable as needed.
- Ground contact: centered at SVG coordinate `(128, 88)`; the Godot sprite keeps its existing `(0, -9.75)` offset, `0.375` scale, separate highlight/ripple, and projection footprint `(89.25, 17.625)`.

The broad cream reflection, two teal water tones, dark wet rim, small leaves, and short mango/cream near edge are intentional. This is a shallow jump cue, not a hole or failure state.
