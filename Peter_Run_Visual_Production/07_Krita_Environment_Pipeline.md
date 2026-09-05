# PETER RUN — Krita Environment and Texture Pipeline

> **Krita is used for composition, layered backgrounds, texture studies, and paintovers. Pixelorama remains the final authority for grid-bound gameplay sprites.**  
> **Companion to:** [Visual Production Master](00_Visual_Production_Master.md)

## 1. What Krita owns

| Krita work | Pixelorama work |
| --- | --- |
| Scenery composition and concept paintovers | Final lane tiles and gameplay props |
| Layered skies, mountains, rivers and distant buildings | Prompt icons, prompt signs and sprite animation |
| Texture studies for woven bamboo, capiz and stone | Grid-aligned repeatable 16 × 16 terrain tiles |
| Summary/completion illustration, if pixel-processed | Player animation frames |

Krita may generate a clean visual plan at 480 × 270, but all art that interacts with gameplay must be verified at native pixels in Pixelorama.

## 2. Environment source-file structure

For each level, create `env_l##_name_master_v01.kra` with this mandatory layer order:

```text
00_GUIDES (hidden: 480 × 270 frame, lane safe zone, prompt zone)
01_SKY
02_DISTANT_SCENERY
03_MIDGROUND_SCENERY
04_PATH_BASE
05_PATH_ACCENTS
06_SIDE_PROPS_STATIC
07_ATMOSPHERE (optional, very subtle)
08_REFERENCE (hidden; never export)
```

Keep active prompts, player sprites and HUD out of the Krita environment export. They are separate Godot nodes.

## 3. Background delivery plan

| Layer | Native size | Godot use | Movement rule |
| --- | ---:| --- | --- |
| Sky | 480 × 270 | `Parallax2D` far layer | Static or extremely slow |
| Distant scenery | 480 × 270 | Far layer | 0.05–0.10 relative speed |
| Midground | 480 × 270 | Mid layer | 0.10–0.20 relative speed |
| Path | 480 × 270 or tilemap | Base play view | Fixed readable lane alignment |
| Side props | Individual PNGs | Decorative side nodes | Never overlap prompt zone |

If the 2–3 day deadline is firm, produce one path base and palette-swapped/prop-swapped background kits. Do not paint five fully unique landscapes at high detail before L01 is playable.

## 4. Texture procedure

1. Generate or gather an original reference concept through the ComfyUI workflow.
2. In Krita, identify the **three largest shapes** first: sky, route, place landmark.
3. Reduce texture to 2–4 colours per material and remove random visual noise.
4. Test as a small thumbnail; if the path/prompt zone is not clear, simplify.
5. Export compositional background layers as PNG.
6. Rebuild any repeated gameplay-facing detail (path tile, bamboo rail, market tile) in Pixelorama on the 16 px grid.

## 5. Level texture cues

| Level | Keep | Simplify or remove |
| --- | --- | --- |
| Barangay | stone tiles, capiz highlights, painted storefront blocks | small product labels, wires crossing lane view |
| Palengke | basket weave, canopy stripes, produce colour blocks | hundreds of tiny fruits, dense signs |
| Riverside | horizontal water ripples, bamboo segments, riverbank greens | fast water patterns or narrow visual lanes |
| Rice Terrace | broad stepped green bands, mountain silhouette, earth path | tiny terrace texture lines and cliff edges |
| Pasko | warm parol glow, plaza stone, gentle string lights | flashing, glitter overload, detailed crowds |

## 6. Krita handoff form

| Field | Fill in |
| --- | --- |
| Environment ID | |
| `.kra` source path | |
| Reference concept paths | |
| Export layers | |
| Export PNG paths | |
| Target level | |
| Pixelorama rebuild required? | Yes / No; list assets |
| Prompt-safe zone checked | Yes / No |
| Parallax speed agreed | |
| Godot integrated | Yes / No |
