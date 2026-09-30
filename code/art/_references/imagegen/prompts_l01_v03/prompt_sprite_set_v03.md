# L01 Prompt Sprite Set v03

- Workflow: OpenAI built-in image generation, followed by deterministic transparent-canvas resizing and derived silhouette overlays.
- Date: 2026-09-27
- Runtime folder: `res://art/prompts/l01_barangay/`
- Source folder: `res://art/_references/imagegen/prompts_l01_v03/`
- Licence status: project-original generated artwork; product-owner and supervised-readability approval remain required.
- Integration status: active sprites connected to their existing Godot prop scenes; gameplay meanings and timings unchanged.

## Final prompt set

### Active delivery crates

Create exactly two stacked, friendly Filipino neighbourhood delivery crates. Use weathered bamboo and wood, mango-orange edge rails, cream rope cross-braces, blank teal label plates, dark fasteners, warm morning light, a stable centred ground contact, restrained dark-teal outlines, and polished low-poly illustrated 2.5D game styling. Use a genuinely transparent background. Do not include scenery, text, logos, a floor, a baked shadow, hazard markings, broken boards, or duplicate objects.

### Active shallow puddle

Create one wide, low, irregular shallow-water Jump cue using two muted teal-blue tones, cream sky reflection, a dark wet-road rim, two tiny leaves, restrained ripple arcs, and a mango/cream near-edge accent. It must read as safe reflective surface water rather than a hole, pit, mud trap, or flood. Use a genuinely transparent 2:1 composition with space for Peter's jump shadow and landing dust.

### Active laundry line

Create two stable bamboo or painted-wood posts, one sagging clothesline, and exactly three cloth panels in muted teal, coral, and cream. Keep a wide, unmistakable open gap under the cloth for the Slide action. Use a front-facing orthographic 2.5D silhouette, aligned post bottoms, warm morning light, subtle mango/cream corner accents, and a genuinely transparent background. Do not make a threatening barrier or unstable structure.

### Roadside variants

Create separate low-contrast decorative versions: one small single delivery crate, one tiny muted puddle with no ripple or active accent, and one compact two-cloth household line with a potted plant. Each must be smaller, quieter, and visually distinct from its active prompt counterpart, with transparent backgrounds and no glow or action-outline treatment.

### Effect overlays

Create a ripple-only transparent layer containing three incomplete cream elliptical arcs, and a cloth-only transparent layer preserving the three active laundry panels. The highlight overlays are deterministic mango/cream dilations of each active sprite's alpha silhouette. Crate and laundry contact shadows are deterministic flattened, blurred, deep-teal alpha projections. These derived layers preserve exact runtime alignment and do not contain gameplay logic.

## Runtime canvases

| Asset | Canvas |
| --- | ---: |
| Active crates | 192 x 192 |
| Active puddle and ripple | 256 x 128 |
| Active laundry line and cloth overlay | 256 x 192 |
| Decorative crate | 128 x 128 |
| Decorative puddle | 128 x 64 |
| Decorative laundry line | 192 x 144 |
