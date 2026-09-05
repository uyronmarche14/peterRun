# PETER RUN — Character Sprite Specification

> **Companion to:** [Visual Production Master](00_Visual_Production_Master.md) · [Art Direction BRD](01_Art_Direction_BRD.md)

## 1. Deliverable

Create one original adult player character that is readable from the rear elevated **2D 2.5D** camera and can perform the four game actions without visually implying unsafe real-world movement. The character must not borrow the silhouette, outfit, pose language, or animation timing of another commercial runner.

| Field | Requirement |
| --- | --- |
| Master canvas per frame | `48 × 64 px`, transparent RGBA PNG |
| Ground anchor | Bottom-centre, x=`24`, y=`62` |
| Working sprite sheet | `384 × 64 px` maximum for eight 48 px frames |
| Outline | 1 px Ink (`#263238`) on exterior silhouette |
| Target scale | 4× nearest-neighbour in Godot |
| File prefix | `char_player_` |

## 2. Required animation set

| ID | File | Frames | FPS | Visual purpose | Godot state |
| --- | --- | ---:| ---:| --- | --- |
| C-01 | `char_player_idle_v01.png` | 4 | 4 | Gentle ready breathing; no sway that suggests instability | `idle` |
| C-02 | `char_player_run_v01.png` | 6 | 8 | Forward travel loop; modest leg movement | `run` |
| C-03 | `char_player_left_v01.png` | 4 | 8 | One short lane-shift lean/step | `move_left` |
| C-04 | `char_player_right_v01.png` | 4 | 8 | Mirrored or separate approved lane shift | `move_right` |
| C-05 | `char_player_jump_v01.png` | 5 | 8 | Symbolic upward game motion; use a soft arc | `jump` |
| C-06 | `char_player_slide_v01.png` | 5 | 8 | Symbolic lowered game pose; no harsh fall pose | `slide` |
| C-07 | `char_player_success_v01.png` | 4 | 6 | Brief upright positive acknowledgement | `success` |

`jump` and `slide` are game labels. The device/therapist defines the actual prescribed motion; the art must not teach an unsafe imitation.

## 3. Layered source file structure

Create `char_player_master_v01.pxo` in Pixelorama with these groups:

```text
FX
Hair / head
Torso / clothing
Arms
Legs / shoes
Outline
Shadow
Guides (hidden on export)
```

Keep a single base palette and edit only required action frames. Do not create five different player designs per level; visual consistency helps comprehension and reduces asset work.

## 4. Character form checklist

- [ ] Adult-proportioned, friendly, non-caricatured silhouette.
- [ ] Head, torso, feet and lane position are distinct at 192 × 256 output pixels.
- [ ] Dark outline separates character from bright and dark backgrounds.
- [ ] Feet share the same ground-anchor baseline in every frame.
- [ ] No forward hand-reaching, obstacle grabbing, tapping, or unsafe balance pose.
- [ ] No visible trademark, branded clothing, or copied character design.

## 5. Godot connection contract

| Sprite property | Godot destination | Rule |
| --- | --- | --- |
| PNG sheet | `res://art/characters/player/` | Import filtering off; mipmaps off |
| Frame layout | `SpriteFrames` resource / `AnimatedSprite2D` | Match frame count and FPS above |
| Ground anchor | `Player.tscn` marker or sprite offset | Same baseline for all states |
| Action state | `Runner.gd` / player state machine | The code changes state; art does not read input |
| Success animation | Prompt resolution event | Trigger only after a correctly resolved prompt |

## 6. Character approval form

| Field | Fill before export |
| --- | --- |
| Asset version | |
| Artist | |
| Reference concept path | |
| Palette checked | Yes / No |
| Ground anchors checked | Yes / No |
| Tested against light and dark level | Yes / No |
| Imported into Godot | Yes / No |
| Approved by | |
