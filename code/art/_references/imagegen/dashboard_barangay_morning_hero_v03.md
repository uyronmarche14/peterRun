# Dashboard Barangay Morning Hero v03

- Runtime asset: `res://art/backgrounds/dashboard_barangay_morning_hero_v03.png`
- Raw source: `dashboard_barangay_morning_hero_v03_source.png`
- Workflow: OpenAI built-in image generation followed by deterministic 960 x 540 centre-crop/downscale
- Date: 2026-09-27
- Licence status: project-original generated artwork; release approval still required by the project owner
- Runtime status: integrated for dashboard visual review

## Final prompt

Create an original warm cinematic 2.5D Filipino Barangay Morning avenue for the opening dashboard. Use a broad quiet road leading toward a tall welcoming community Barangay Hall and substantial public-market wing. Reserve the left 47 percent as low-detail negative space for the live cream dashboard panel, keep the lower centre-right road open for the live player sprite, and keep the top-right quiet for live controls. Use polished low-poly illustrated game art, crisp silhouettes, restrained outlines, warm golden morning light, cool teal shadows, and a muted teal, cream, mango, coral, leaf-green, warm-grey, and earth palette. Include Filipino neighbourhood details without crowds or traffic. The civic destination must not resemble a religious building. Background only: no UI, text, labels, player, people, obstacle props, score elements, or watermark.

## Integration notes

- The artwork contains scenery only. Dashboard labels, controls, route information, and the opening Peter remain live Godot nodes.
- The previous `OpeningLife` procedural drawing node was removed from `main.tscn`; all visible environmental scenery now comes from the image asset.
- The original v01 and v02 dashboard images remain preserved.
