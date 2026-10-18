# Peter adult action in-betweens v06

This source-art pass adds distinct illustrated poses to the existing approved adult Peter animation. The eight v05 Jump and six v04 Slide key poses remain intact and in order. Godot still owns action timing, lane movement, repetition counting, and pause.

| Clip | Old poses | New poses | Duration | Runtime atlas |
| --- | ---: | ---: | ---: | --- |
| Jump | 8 | 15 | 0.92 s | `code/art/characters/peter_adult_image_v04/jump_smooth_v06.png` |
| Slide | 6 | 11 | 0.48 s source clip, fitted to controller timing | `code/art/characters/peter_adult_image_v04/slide_smooth_v06.png` |

The generated transparent source strips are in `source_strips/`. `process_peter_actions_v06.ps1` reproducibly normalizes and interleaves them into fixed 256×256 runtime cells. It does not alter the old atlases or the approved source strips. Jump in-betweens retain a centered horizontal origin and an interpolated contact/lift coordinate; Slide in-betweens retain a stable ground contact.

Built-in OpenAI image generation created the source cutouts. The selected prompt set was:

- Seven adult Peter rear-view Jump midpoints, one between each adjacent approved source pose, matching the same terracotta/teal/navy/cream costume, style, camera, and lighting, with genuine transparent alpha and isolated figures. Four clean separated poses were selected from this strip.
- Three additional high-rise/descent/landing midpoints from the same source reference, with only three widely separated figures and genuine transparent alpha.
- Five controlled lower/hold/rise Slide midpoints from the approved Slide source and character turnaround, maintaining grounded shoes and a clear, safe duck silhouette, again with genuine transparent alpha.

Generated variants that had touching cutouts or an unwanted baked background were rejected and are not part of the project. See `code/art/characters/peter_adult_image_v04/animation_manifest.json` for the exact timestamp and region contracts.

To regenerate from the project root:

```powershell
& .\Peter_Run_Visual_Production\process_peter_actions_v06.ps1
& 'C:\Users\Rhyss\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --editor --path code --import --quit
```
