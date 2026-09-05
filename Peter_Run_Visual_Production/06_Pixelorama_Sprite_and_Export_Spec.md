# PETER RUN — Pixelorama Sprite and Export Specification

> **Pixelorama produces final game-ready pixel art.**  
> **Companion to:** [Visual Production Master](00_Visual_Production_Master.md)

## 1. New-project settings

| Asset class | Canvas | Grid | Export |
| --- | --- | --- | --- |
| Terrain tile | `16 × 16 px` | 16 px base, 1 px detail | Transparent PNG |
| Small prop | `32 × 32 px` | 16 px base | Transparent PNG |
| Prompt sign/icon | `32 × 32 px` / `48 × 48 px` | 1 px detail | Transparent PNG |
| Player frame | `48 × 64 px` | 1 px detail | Sprite sheet PNG |
| Wide prompt | `64 × 32 px` | 16 px base | Transparent PNG |
| VFX frame | `32 × 32 px` | 1 px detail | Sprite sheet PNG |

Use the master palette from [Art Direction BRD](01_Art_Direction_BRD.md). Add level colours only after confirming contrast against Ink and Cream.

## 2. Pixel-art rules

- Draw at native pixel resolution; do not shrink a painted AI image to fake pixel art.
- Use hard-edged brushes. Disable anti-aliasing for final sprite edges.
- Keep an external outline in Ink where an asset meets varied scenery.
- Prefer 2–4 shades per material, not noisy gradients.
- Align edges and repeated details to the pixel grid.
- Make the action silhouette visible before adding cultural decoration.
- Use a hidden `GUIDES` layer for collision, anchor, and frame boundary notes; never export it.

## 3. Required Pixelorama source files

```text
pixel_source/
├── character/char_player_master_v01.pxo
├── ui/ui_prompt_icons_master_v01.pxo
├── shared/shared_vfx_master_v01.pxo
├── l01_barangay/l01_tiles_master_v01.pxo
├── l01_barangay/l01_prompts_master_v01.pxo
└── ... repeat for L02–L05
```

## 4. Sprite-sheet method

1. Set frame count before drawing animation.
2. Add a `GUIDES` layer with the 48 × 64 frame boundary and ground-anchor line.
3. Draw base pose once, duplicate frames, then change only moving parts.
4. Use onion skinning to keep proportions and feet consistent.
5. Export an RGBA PNG sheet with frames arranged horizontally.
6. Record frame size, count and FPS in the Asset Register.

## 5. Export checklist

- [ ] Native dimensions correct; no accidental 2×/4× export.
- [ ] Transparent background retained where required.
- [ ] No guide, sketch, hidden reference or copyrighted source layer appears.
- [ ] File name follows `category_level_asset_variant_v01.png`.
- [ ] Export opened once at 4× nearest-neighbour to inspect stray pixels.
- [ ] Godot import settings prepared: nearest filtering, no mipmaps.

## 6. Pixelorama production form

| Field | Fill in |
| --- | --- |
| Asset ID | |
| `.pxo` source path | |
| PNG export path | |
| Native size | |
| Frames / FPS | |
| Palette name | |
| Action/level association | |
| Godot import checked | Yes / No |
| Reviewer | |
