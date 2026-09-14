# L01_ShallowPuddle Blender source

Open `L01_ShallowPuddle_Source_v01.blend`. The opening scene is `L01_ShallowPuddle_ACTIVE_JUMP`; separate scenes hold `RIPPLE_OVERLAY` and `ROADSIDE_DECORATIVE`. The previous crate and obstacle-source scenes are retained in the new file. The earlier `.blend` files on disk were not overwritten.

All three puddle variants have centered ground-contact origins. The active puddle is a flat, approximately 2.34 m wide mesh with two muted teal-blue water tones, a dark wet-road rim, cream sky reflections, two tiny leaves, and short mango/cream edge accents. Its top surface is below 0.03 m, with transparent space around the rendered footprint for Peter's jump shadow and landing dust. The roadside puddle is only about 0.70 m wide and deliberately lacks an active edge cue.

Blender-only transparent exports are in `generated/l01_shallow_puddle/`:

- `prompt_l01_shallow_puddle_v03.png` — 256×128 active base.
- `prompt_l01_shallow_puddle_ripple_v01.png` — 256×128 isolated ripple overlay.
- `decor_l01_small_puddle_v01.png` — 128×64 quiet roadside decoration.

`build_l01_shallow_puddle_live.py` records construction in the connected Blender session. `render_l01_shallow_puddle.py` renders one PNG per background Blender process and checks native dimensions and transparent corners. No Godot scene, script, or runtime art was changed.
