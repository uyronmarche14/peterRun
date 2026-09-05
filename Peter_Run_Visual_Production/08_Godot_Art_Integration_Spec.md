# PETER RUN — Godot Art Integration Specification

> **This file defines how final art becomes gameplay.**  
> **Companion to:** [Visual Production Master](00_Visual_Production_Master.md) · [PRD](../Peter_Run_PRD.md)

## 1. Import rules

For all pixel-art PNGs in Godot:

- Use nearest-neighbour texture filtering.
- Disable mipmaps for pixel sprites and UI.
- Keep `480 × 270` as the internal viewport; scale by an integer 4× for `1920 × 1080` target output.
- Preserve native PNG dimensions. Do not rescale assets individually in an image editor after approval.
- Keep ComfyUI/reference art in `res://art/_references/` and exclude it from runtime scenes.

## 2. Visual-to-game connection map

| Art deliverable | Godot object | Data connection | Runtime behavior |
| --- | --- | --- | --- |
| Player sprite sheet | `Player.tscn` → `AnimatedSprite2D` | `SpriteFrames` resource | `Runner.gd` selects animation state |
| Prompt icon/sign | `Prompt.tscn` → `Sprite2D` | `PromptDefinition.icon` | Appears in warning/active state |
| Lane block / floor / overhead prop | `Prompt.tscn` → `Sprite2D` + `Area2D` | `PromptDefinition.visual_scene` | Calls action-resolution logic only |
| Background PNG layers | `Level.tscn` → `Parallax2D` | `LevelDefinition.theme` | Gentle decorative movement |
| Tileset | `TileMapLayer` | Level scene/layout | Creates fixed readable path |
| HUD card / buttons | `CanvasLayer` → Control scenes | `GameState`, `SessionConfig` | Shows next action/progress/pause |
| Success VFX | `SuccessVfx.tscn` | Prompt success event | Brief positive effect only |

## 3. Required scenes

```text
scenes/
├── actors/Player.tscn
├── prompts/Prompt.tscn
├── prompts/PromptWarning.tscn
├── ui/ActionCue.tscn
├── ui/HUD.tscn
├── ui/PauseMenu.tscn
├── vfx/SuccessVfx.tscn
└── levels/LevelBase.tscn
```

`LevelBase.tscn` is duplicated/configured through level data—not rewritten per visual theme. Its child order should be:

```text
LevelBase
├── Parallax2D
├── TileMapLayer_Path
├── PromptDirector
├── Player
├── PromptLayer
├── SuccessVfxLayer
└── CanvasLayer_HUD
```

## 4. Prompt connection requirement

Every prompt resource must have one authoritative `logical_action` value:

```text
move_left | move_right | jump | slide
```

The visual scene, warning sign, sound, and collision/response window are all selected from that value. Do **not** insert `A`, `D`, `W`, `S`, sensor angles, or affected-leg logic into visual assets. Input mapping belongs only to `InputAdapter.gd`, as defined by PRD FR-01–FR-04.

Example resource fields:

```yaml
id: l02_market_cart_right
logical_action: move_right
visual_scene: res://scenes/prompts/MarketCartPrompt.tscn
icon: res://art/prompts/shared_icons/ui_icon_move_v01.png
warning_seconds: 2.5
response_seconds: 2.0
success_vfx: res://scenes/vfx/SuccessVfx.tscn
```

## 5. Animation implementation

| Need | Godot implementation |
| --- | --- |
| Player frame animation | `AnimatedSprite2D` and `SpriteFrames` |
| Lane transition | Tween/move between three fixed x positions; never drift outside lanes |
| Jump/slide state | Animation + controlled state timer, with configurable duration |
| Prompt entry/exit | `AnimationPlayer` or Tween; constant, gentle speed |
| Background movement | `Parallax2D`; slow multiplier only |
| Pause | `get_tree().paused = true` plus pause-process UI; freeze art, timers and prompt state |

Use the original 2D 2.5D route order from [2.5D Originality Standard](11_2_5D_Originality_Standard.md): fixed player, road/prompt movement, and slow parallax. No 3D camera, camera shake, fast zoom, motion blur, random lane wobble, or unbounded particle effects.

## 6. Integration checklist

- [ ] Import filter/mipmap settings produce crisp pixels at 4× scale.
- [ ] All Player animation states use the same ground anchor.
- [ ] Every prompt visual resolves to one logical action.
- [ ] Prompt sign/icon appears before the prop’s response window.
- [ ] The prompt scene can be swapped without editing `PromptDirector.gd`.
- [ ] Pausing freezes prompt/background/player animation immediately.
- [ ] Missing or late action produces neutral fade-out, not collision/failure art.
- [ ] The level loads from a `LevelDefinition` without hard-coded level-specific code.

## 7. First implementation milestone

Build only this before expanding visuals:

1. `Player.tscn` using placeholder blocks or L01 character sprites.
2. One `Prompt.tscn` with all three visual modes.
3. L01 background with one lane prop, one floor prop, one overhead prop.
4. HUD action cue and visible Pause button.
5. One data resource that schedules exactly three repetitions per logical action.

Once this is readable and testable, duplicate the level data and swap visual references to build L02–L05.
