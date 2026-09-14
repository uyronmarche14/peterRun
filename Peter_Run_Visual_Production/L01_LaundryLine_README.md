# L01_LaundryLine Blender source

Open `L01_LaundryLine_Source_v01.blend`. The opening `L01_LaundryLine_ACTIVE_SLIDE` scene shows two stable bamboo posts, a gently sagging cream line, and three route-facing cloth panels in teal, coral, cream order. The lowest hem leaves about 1.54 m of visible space below it. Shadows, coloured cloth, and frame are separate collections with centred ground origins.

`L01_LaundryLine_CLOTH_SWAY_OVERLAY` contains only the cloth panels, pins, and hems. The source has a very slow ±0.025 m breeze keyframe study, returning to centre on frames 1 and 121. The overlay PNG is aligned to the base at rest; if layered over the full base PNG in a 2D engine, use low overlay opacity for a subtle shimmer/sway or render a frame-only base from the separate Blender collections. No runtime animation is implemented here.

`L01_LaundryLine_ROADSIDE_DECORATIVE` is a smaller, lower-contrast variant with metadata marking it roadside-only. It is not an active road-crossing prompt.

Transparent Blender exports are in `generated/l01_laundry_line/`:

- `prompt_l01_laundry_line_v03.png` — 256×192 active prompt.
- `prompt_l01_laundry_cloth_sway_v01.png` — 256×192 isolated cloth overlay.
- `decor_l01_laundry_line_v01.png` — 128×96 roadside decoration.

`build_l01_laundry_line_live.py` records creation in the connected Blender session. `render_l01_laundry_line.py` renders one PNG per background Blender process and checks dimensions and transparency. No Godot file or runtime art was changed.
