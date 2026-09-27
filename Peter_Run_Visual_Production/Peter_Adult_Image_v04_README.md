# Peter adult image animation v04

This version uses the approved adult Peter turnaround as the visual master instead of the earlier Blender-rendered character. It preserves the original gameplay controller: Godot remains the sole owner of lane position, action timing, repetition completion, and pause/resume state.

## Approved reference

`character_concepts/peter_character_v03/peter_character_turnaround_v03.png`

The generated images retain Peter's mature Filipino adult identity, swept dark hair, terracotta shirt, teal-and-cream woven back trim, cuffed navy trousers, and cream/teal walking shoes.

## Source and runtime assets

- Original generated transparent strips: `generated/peter_adult_image_v04/source_strips/`
- Normalized review frames: `generated/peter_adult_image_v04/normalized_frames/`
- Godot atlases and manifest: `../code/art/characters/peter_adult_image_v04/`
- Deterministic strip preparation: `prepare_peter_adult_image_v04.ps1`
- Graphical verification: `../code/tests/support/capture_peter_adult_image_v04.gd`

The preparation script detects each complete transparent character figure as a connected component, removes accidental cross-cell fragments, normalizes it to a 256x256 frame, and maintains the existing `(128, 216)` ground pivot. It creates one padded atlas per clip plus a separate soft ground shadow.

The integrated presentation uses a restrained `0.32` display scale. Jump frames add a controlled visual lift of up to 18 source pixels at the apex, while the middle slide frames compress vertically around the fixed foot anchor to make the duck clearly lower. Gameplay timing and action acceptance windows remain unchanged.

## Animation set

| Clip | Key poses | Duration | Loop |
|---|---:|---:|---|
| `idle_ready` | 6 | 2.00 s | yes |
| `walk_forward` | 6 | 1.20 s | yes |
| `move_left` | 6 | 0.22 s | no |
| `move_right` | 6 | 0.22 s | no |
| `jump_low` | 6 | 0.62 s | no |
| `slide_duck` | 6 | 0.48 s | no |
| `rest` | 6 | 2.00 s | yes |
| `success_settle` | 4 | 0.50 s | no |
| `neutral_clear` | 4 | 0.25 s | no |
| `paused` | 1 | 1/24 s | no |

## Generation prompt set

All strips used the approved turnaround and the adult action-pose sheet as strict identity references. Shared constraints required the same rear gameplay camera, body scale, clothing, warm morning key/cool teal fill, full-body transparent RGBA output, no props or text, and calm rehabilitation-safe motion.

Action-specific prompts requested:

- gentle breathing phases for idle and rest;
- six in-place alternating contact/passing/lift phases for forward locomotion;
- anticipation, active foot transfer, and recovery for each lane direction;
- preparation, takeoff, modest apex, landing, and recovery for jump;
- controlled entry, compact low hold, and balanced exit for slide/duck;
- a small approving acknowledgement for success;
- calm shoulder release and recovery for neutral feedback;
- one balanced, completely still rear-view pose for pause.

No Blender-rendered character is used by this version.

## Regeneration

From the project root in PowerShell:

```powershell
& .\Peter_Run_Visual_Production\prepare_peter_adult_image_v04.ps1
```

Then import the project in Godot so the atlas textures are refreshed.
