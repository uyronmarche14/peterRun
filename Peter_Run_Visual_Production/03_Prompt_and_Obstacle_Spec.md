# PETER RUN — Prompt and Obstacle Specification

> **Companion to:** [Visual Production Master](00_Visual_Production_Master.md) · [Art Direction BRD](01_Art_Direction_BRD.md)

## 1. Purpose

In PETER RUN, “obstacles” are **friendly movement prompts**, not threats. They communicate exactly one requested logical action, provide enough warning, and disappear neutrally when missed.

## 2. Gameplay-to-art contract

| Logical action | Game input | Prompt placement | Prop grammar | Required icon |
| --- | --- | --- | --- | --- |
| `move_left` | `A` / HID action | One non-target lane is occupied | Side-lane block | ↔ |
| `move_right` | `D` / HID action | One non-target lane is occupied | Side-lane block | ↔ |
| `jump` | `W` / HID action | Across path at low height | Low floor cue | ↑ |
| `slide` | `S` / HID action | Across path above character | Overhead cue | ↓ |

For left-affected-leg play, the `InputAdapter` handles sensor mapping. Prompt art never changes side meaning; its request remains the logical game action named in the level data.

## 3. Prompt anatomy

```text
Rounded action sign (icon + short label)
                ↓
World prop with a clear silhouette
                ↓
Optional soft ground shadow / warning ring
```

| Element | Standard |
| --- | --- |
| Sign size | At least `32 × 32 px` native; scales to 128 × 128 output px |
| Text | 3–5 characters or clinician-approved short word; never icon only |
| Outline | 1–2 px Ink outline and cream inner border |
| Spawn | Warning appears before active response window; see `LevelDefinition.timing` |
| On success | Prop clears gently; `success` animation/effect plays |
| On miss | Prop fades/drifts away; no red flash, collision, shake or penalty |

## 4. Required prompt assets by level

| ID | Level | Lane prompt ↔ | Jump prompt ↑ | Slide prompt ↓ |
| --- | --- | --- | --- | --- |
| L01 | Barangay Morning | Delivery crates | Tiny curb or shallow puddle | Laundry line / low store awning |
| L02 | Palengke Dash | Fruit baskets or market cart | Empty crate stack | Hanging market banner |
| L03 | Riverside Walk | Bamboo planter or fishing basket | Small bridge-gap marker | Low bamboo branch |
| L04 | Rice Terrace Trail | Stones or rice-sack bundle | Path step or narrow stream marker | Hanging leaves / bamboo arch |
| L05 | Pasko Festival | Gift boxes or light stand | Raised plaza tile or ribbon line | Low parol string / festival banner |

Each level needs a minimum of **three final prop variants** (one per action) and may contain decorative variants only when they cannot be mistaken for an active prompt.

## 5. File requirements

| Type | Native size | Example name | Use |
| --- | --- | --- | --- |
| Action icon | `32 × 32 px` | `ui_icon_jump_v01.png` | Shared HUD and warning sign |
| Prompt sign | `48 × 48 px` | `prompt_sign_slide_v01.png` | Appears above active prop |
| Lane prop | Max `48 × 48 px` | `prompt_l01_delivery_crates_v01.png` | Side lane block |
| Floor prop | Max `64 × 32 px` | `prompt_l02_crate_stack_v01.png` | Jump cue |
| Overhead prop | Max `64 × 48 px` | `prompt_l05_parol_string_v01.png` | Slide cue |
| Collision guide | Not exported art | `prompt_*_guide` | Used to set `Area2D` bounds |

Collision areas must match the readable visible object, not invisible art margins. The collision/action test belongs to code; it must not create a game-over.

## 6. Prompt design review

- [ ] Player can state the requested action after viewing for two seconds.
- [ ] Icon, label, and prop all indicate the same action.
- [ ] Prompt remains visible against its intended level background.
- [ ] Decorative props cannot be confused with active prompts.
- [ ] The scene contains only one active requested action in the MVP.
- [ ] Successful, incorrect, and missed resolution are visually calm.

## 7. Prompt asset form

| Field | Fill before production |
| --- | --- |
| Asset ID | |
| Level ID | |
| Logical action | `move_left` / `move_right` / `jump` / `slide` |
| World prop | |
| Icon + wording | |
| Native dimensions | |
| Concept reference path | |
| Pixel source file | |
| Godot scene/resource | |
| Tested at 4× output | Yes / No |
| Safety/readability approval | |
