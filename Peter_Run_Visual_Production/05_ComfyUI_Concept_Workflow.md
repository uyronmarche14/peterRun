# PETER RUN — ComfyUI Concept Workflow

> **ComfyUI is for original visual references, composition exploration, and texture ideas. It is not the final sprite-production tool.**  
> **Companion to:** [Visual Production Master](00_Visual_Production_Master.md)

## 1. What ComfyUI should create

| Good use | Do not use it for |
| --- | --- |
| Level moodboards and background compositions | Final pixel-perfect sprite sheets |
| Material/texture reference: bamboo, stone, woven mat, capiz | Text-heavy UI or clinical instructions |
| Character silhouette exploration | Precise animation-frame continuity |
| Prompt/prop silhouette options | Direct import into Godot without cleanup |
| Palette and lighting studies | Copying another game or artist’s assets |

## 2. Project setup

Create these local reference folders first:

```text
art/_references/
├── comfyui_prompts/
├── l01_barangay/
├── l02_palengke/
├── l03_riverside/
├── l04_rice_terrace/
└── l05_pasko/
```

Save each useful image with a paired text prompt and register it as a **reference** in the Asset Register. Do not put generated source images in the runtime art folder.

## 3. Recommended workflow

1. Fill the [Level Art Brief Form](04_Level_Art_Brief_Form.md).
2. Generate **six low-variation concepts** for one level, using the same seed/style reference where possible.
3. Pick one composition for approval; record its prompt, model, seed, workflow JSON, and licence notes.
4. Use Krita to simplify the image into clean layers and composition reference.
5. Rebuild final tiles, props, icons and frames in Pixelorama.
6. Test the simplified final asset in Godot—not the raw AI image.

## 4. Base prompt template

Replace brackets before generation.

```text
Use case: stylized-concept
Asset: original 2D forward-lane pixel-art game concept reference for PETER RUN
Scene: [LEVEL] in an original Filipino-inspired setting: [PLACE / MATERIALS]
Camera: fixed elevated 2.5D forward-lane view made from 2D layers, a clear three-lane
Filipino route centred in frame, open foreground and a large prompt horizon
Mood: calm, welcoming, adult-friendly rehabilitation game; no urgency
Style: original 16-bit-inspired pixel art, crisp large shapes, thick dark outlines,
simple tileable materials, sparse scenery
Palette: ink charcoal, deep teal, mango yellow, coral, leaf green, sky blue, cream
Props: [LANE PROP], [JUMP PROP], [SLIDE PROP], placed as clear non-threatening
game prompts with no overlap
Constraints: no logos, no copyrighted characters, no subway/train/station imagery, no guards,
coins, hoverboards, graffiti branding, copied runner UI, dense crowds, flashing lights, UI text,
watermark, photorealism, or 3D rendered look
```

### Character prompt add-on

```text
Subject: original adult game character viewed from behind, friendly sporty clothing,
clear silhouette, cream top, teal lower garment, no logo, no unsafe balance pose.
```

### Negative prompt / avoid list

```text
brand logo, named game, train, subway, station, guard, chase, coin, hoverboard, graffiti,
weapon, crash, fall, hospital scene, copied game interface, text, watermark, crowd, motion blur,
flashing lights, tiny clutter, photorealism, 3D render
```

## 5. Level-specific concept details

| Level | Add to prompt |
| --- | --- |
| L01 Barangay | sunny street, sari-sari storefront texture, capiz windows, stone path, delivery crates, laundry line |
| L02 Palengke | woven baskets, fruit stalls, bunting, market cart, warm tan lane tiles |
| L03 Riverside | bamboo rail, calm river, fishing basket, tropical plants, bridge-gap marker |
| L04 Rice Terrace | layered rice terraces, mountain sky, earthy path, stone bundle, bamboo arch |
| L05 Pasko | warm plaza, parol lanterns, gift boxes, decorative ribbon, soft steady glow |

## 6. Reference approval criteria

- [ ] A clear, fixed three-lane path is visible.
- [ ] Player and prompt zone are not blocked by scenery.
- [ ] The setting has an original Filipino visual identity.
- [ ] Props match the correct action grammar from the Prompt Spec.
- [ ] No logos, copied characters, unreadable text, or third-party art are visible.
- [ ] The image can be reduced to a 16 px tile / 48 px sprite system.
- [ ] The route, character, props and HUD direction pass the [2.5D Originality Standard](11_2_5D_Originality_Standard.md).

## 7. Concept record form

| Field | Value |
| --- | --- |
| Concept ID | |
| Level / asset | |
| Prompt file path | |
| ComfyUI workflow JSON path | |
| Model + version | |
| Seed | |
| Style/reference inputs | |
| Output path | |
| Selected / rejected | |
| Licence/use review completed | Yes / No |
| Notes for Krita/Pixelorama | |

**Licensing rule:** record the model and any input asset licence. Do not use a reference image, LoRA, sprite sheet, logo, or style request that would make the shipped art infringe another creator’s rights.
