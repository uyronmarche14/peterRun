# PETER RUN — Level Art Brief Form

> **Duplicate this file once for every level.**  
> **Companion to:** [Visual Production Master](00_Visual_Production_Master.md)

## Level identity

| Field | Fill in |
| --- | --- |
| Level ID | `L__` |
| Working title | |
| One-sentence emotional goal | |
| Filipino place/material inspiration | |
| PRD target per action | |
| Therapist-approved action wording | |
| Art owner | |
| Implementation owner | |
| Status | Brief / Concept / Pixel final / Integrated / Approved |

## 1. Visual story

**What does the player see first?**  

**Why does this place feel distinct from prior levels?**  

**What calm completion image/reward appears at the end?**  

## 2. Palette and composition

| Field | Decision |
| --- | --- |
| Hero colours | |
| Supporting colours | |
| Sky/time of day | |
| Path material | |
| Lane-edge treatment | |
| Distant background | |
| Midground scenery | |
| Foreground/side props | |
| Safe empty play area | |
| Prompt horizon / placement zone | |

Attach or link 3–6 approved concept references here. They are a guide—not final game art.

## 3. Prompt plan

| Logical action | World prop | Icon / label | First asset filename | Readability notes |
| --- | --- | --- | --- | --- |
| `move_left` | | ↔ / | | |
| `move_right` | | ↔ / | | |
| `jump` | | ↑ / | | |
| `slide` | | ↓ / | | |

## 4. Asset list

| Category | Asset name | Size | Source app | Status |
| --- | --- | ---:| --- | --- |
| Background sky | | 480 × 270 | Krita | |
| Distant layer | | 480 × 270 | Krita | |
| Midground layer | | 480 × 270 | Krita/Pixelorama | |
| Path tileset | | 16 × 16 tiles | Pixelorama | |
| Lane prompt prop | | | Pixelorama | |
| Jump prompt prop | | | Pixelorama | |
| Slide prompt prop | | | Pixelorama | |
| Decorative props | | | Pixelorama | |
| Completion art | | | Krita/Pixelorama | |
| Ambient VFX | | | Pixelorama | |

## 5. Godot hookup

| Godot item | Required connection |
| --- | --- |
| Folder | `res://art/environments/l__/` and `res://art/prompts/l__/` |
| Level resource | `res://data/levels/l__.tres` |
| Scene | `res://scenes/levels/Level__.tscn` |
| Prompt definitions | Link each prop to a logical action; no hard-coded key values |
| Parallax | Slow layers only; keep lane/prompt area clear |
| Completion | Summary scene reads level title, palette and completion image |

## 6. Approval checklist

- [ ] The theme is original and culturally specific without relying on a stereotype.
- [ ] The player, all lanes, and pause button remain clear at target size.
- [ ] Prompt props remain more visible than decoration.
- [ ] No moving scenery crosses or hides the active prompt path.
- [ ] Asset file names and paths match the master file.
- [ ] Level still has one active prompt at a time.
- [ ] Visual setup was tested in Godot at 480 × 270 and 1920 × 1080.

## 7. Sign-off

| Role | Name | Date | Notes |
| --- | --- | --- | --- |
| Art lead | | | |
| Developer | | | |
| Product owner | | | |
| Therapist/safety reviewer | | | |
