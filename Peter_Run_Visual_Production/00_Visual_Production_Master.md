# PETER RUN — Visual Production Master

> **Single source of truth for visual production**  
> **Version 0.1 · 05 September 2026**

This file connects the business goal, gameplay requirements, art direction, AI concept workflow, final pixel art, and Godot implementation. Start here at the beginning of every art or level task.

## 1. Source documents and authority

| Document | Authority | Use it for |
| --- | --- | --- |
| [BRD](../Peter_Run_BRD.md) | Product purpose, supervision, safety and scope | Resolve user/safety questions first |
| [PRD](../Peter_Run_PRD.md) | Gameplay behavior, input, level data and tests | Resolve implementation questions first |
| [Art Direction BRD](01_Art_Direction_BRD.md) | Art rules, palette, accessibility and level identity | Resolve visual decisions |
| [Character Spec](02_Character_Sprite_Spec.md) | Player/NPC sprite requirements | Create the character sheet |
| [Prompt & Obstacle Spec](03_Prompt_and_Obstacle_Spec.md) | All gameplay prompt visuals | Make gameplay-readable props |
| [Level Art Brief Form](04_Level_Art_Brief_Form.md) | One reusable form per level | Plan new levels |
| [ComfyUI Workflow](05_ComfyUI_Concept_Workflow.md) | AI concept/reference generation | Generate references only |
| [Pixelorama Export Spec](06_Pixelorama_Sprite_and_Export_Spec.md) | Final sprite, tile and animation production | Produce game-ready PNGs |
| [Krita Environment Pipeline](07_Krita_Environment_Pipeline.md) | Background and texture production | Produce layered scenery |
| [Godot Art Integration Spec](08_Godot_Art_Integration_Spec.md) | Import, scenes, data and runtime connection | Put assets into the game |
| [Asset Register](09_Asset_Register_Template.md) | Ownership, readiness and file tracking | Track every asset |
| [End-to-End System Flow](10_End_to_End_System_Flow.md) | Screen navigation, systems, assets and data connection | Build and test the full prototype path |
| [2.5D Originality Standard](11_2_5D_Originality_Standard.md) | Camera, UI, route and genre boundary | Keep the 2D runner original and implementation-ready |

**Priority rule:** when documents conflict, preserve the BRD safety requirement, then the PRD gameplay requirement, then this art pack. Never make a visual effect that hides a prompt, pressures speed, or turns a missed movement into a failure.

---

## 2. The production chain

```text
Level Art Brief
  → ComfyUI concept/reference images
  → Krita composition + texture paintover
  → Pixelorama final sprites / tiles / frame animation
  → Godot import + scene hookup + LevelDefinition data
  → in-game readability test
  → Asset Register approval
```

AI generates **references**, not final game files. The final assets are deliberate pixel-art PNGs exported from Pixelorama/Krita and imported into Godot.

## 3. Non-negotiable design requirements

| Requirement | Source | Visual implementation |
| --- | --- | --- |
| Slow, predictable, non-punishing play | BR-05; PRD principles | Fixed camera and speed; no threatening art or visual rush |
| One clear planned action at a time | FR-05, FR-06 | Only one active prompt; action icon + label + distinct silhouette |
| Patient uses a walker | BRD safety guardrails | Do not imply arm swings, hand gestures, tapping, or grabbing |
| Immediate therapist pause/stop | BR-06; FR-08 | Persistent large pause control, high contrast, no busy corner art |
| No reliance on colour alone | BRD accessibility; PRD §8 | Pair colour with an icon, label and silhouette |
| Many levels without code changes | BR-10; FR-11 | Reusable level kit and data-driven `LevelDefinition` resources |
| 2.5D runner, not a copied commercial runner | Product decision | 2D sprites + parallax; original Filipino routes, props, character and UI |

## 4. Canonical production settings

| Item | Standard | Reason |
| --- | --- | --- |
| Design canvas | `480 × 270 px` | 16:9, scales cleanly 4× to 1920 × 1080 |
| Pixel grid | `16 × 16 px` terrain tiles | Consistent, fast to create and easy to reuse |
| Player frame | `48 × 64 px`, transparent PNG | Clear adult silhouette at the target scale |
| Native game scale | 4× nearest-neighbour | Crisp pixel art, no blur |
| Art format | PNG, RGBA, sRGB | Godot-ready and transparent where needed |
| File naming | `category_level_asset_variant_v01.png` | Searchable, versioned, engine-safe |
| Example | `prompt_l02_market_cart_left_v01.png` | Identifies category, level and intended action |

Do not change the native canvas, tile grid, player size, or naming pattern midway through the MVP without updating this master file and the asset register.

## 5. Folder system to create in the Godot project

```text
res://
├── art/
│   ├── _references/              # ComfyUI concepts; never loaded by runtime
│   ├── characters/
│   │   └── player/
│   ├── prompts/
│   │   ├── shared_icons/
│   │   └── l01_barangay/ ... l05_pasko/
│   ├── environments/
│   │   └── l01_barangay/ ... l05_pasko/
│   ├── tilesets/
│   ├── ui/
│   └── vfx/
├── data/
│   ├── levels/
│   ├── prompt_definitions/
│   └── palettes/
├── scenes/
│   ├── actors/
│   ├── prompts/
│   └── levels/
└── docs/
    └── asset_register.md
```

## 6. Five-level content matrix

| ID | Level | Hero palette | Lane move prop | Jump prop | Slide prop |
| --- | --- | --- | --- | --- | --- |
| L01 | Barangay Morning | Mango, teal, cream | Delivery crates | Tiny curb/puddle | Laundry line/store awning |
| L02 | Palengke Dash | Coral, fruit green, warm tan | Fruit basket/market cart | Empty crate stack | Market banner |
| L03 | Riverside Walk | River blue, bamboo green, sand | Bamboo planter/fishing basket | Bridge-gap marker | Low bamboo branch |
| L04 | Rice Terrace Trail | Leaf green, earth, sky blue | Stones/rice-sack bundle | Path step/stream marker | Low bamboo arch/leaves |
| L05 | Pasko Festival | Deep teal, parol gold, coral | Gift boxes/light stand | Raised tile/ribbon line | Low parol string/banner |

## 7. Asset readiness gates

An asset may move to the next stage only after passing its gate.

| Gate | Owner | Evidence |
| --- | --- | --- |
| Concept approved | Art lead / stakeholder | Reference image linked in register |
| Gameplay legible | Game designer | Correct action is identifiable at gameplay scale in 2 seconds |
| Pixel-final | Pixel artist | PNG follows grid, palette, size and name standard |
| Engine connected | Developer | Scene/resource loads without warnings and action mapping is correct |
| Safe to test | Therapist / product owner | Prompt does not rush, shame, distract or obscure pause control |

## 8. MVP schedule and next action

| Day | Visual work | Engine work | Exit criteria |
| --- | --- | --- | --- |
| 1 | Approve palette, player silhouette, prompt icon system; create L01 kit | Three lanes, player actions, one prompt | L01 works in greybox with temporary art |
| 2 | Create reusable UI, 15 prompt visuals and five background palettes | Menu, HUD, summary, five level definitions | All five levels load from data |
| 3 | Polish L01/L05 and reuse kits for L02–L04 | Import tuning, gamepad test, Windows build | Full supervised prototype pass |

### Start here now

1. Read [End-to-End System Flow](10_End_to_End_System_Flow.md) and create the L01 gameplay greybox before producing final art.
2. Duplicate and fill [Level Art Brief Form](04_Level_Art_Brief_Form.md) for **L01 Barangay Morning**.
3. Follow the ComfyUI workflow to create 3–6 visual references—not final sprites.
4. Create `player_base_v01.png`, `icon_move_v01.png`, `icon_jump_v01.png`, `icon_slide_v01.png`, and the L01 prompt set in Pixelorama.
5. Register those files in [Asset Register](09_Asset_Register_Template.md).
6. Integrate only L01 into Godot. Do not begin the other levels until the prompt is readable and the pause flow works.
