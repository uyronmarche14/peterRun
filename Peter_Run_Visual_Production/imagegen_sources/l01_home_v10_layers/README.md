# L01 Home at Dawn — v10 layered source

The two PNGs here are editable visual sources generated with the built-in image-generation tool. `home_underpaint_source.png` fills the space behind independently exported street edges; `home_sky_source.png` supplies the dawn sky. The existing reviewed `code/art/backgrounds/l01_barangay_v09_journey/l01_v09_home_dawn.png` supplies the exact road, sidewalk and street-edge pixels. The rejected landmark extraction was **not** shipped because it changed the building's size and position.

Rebuild the seven 960×540 runtime layers with:

```powershell
& 'C:\Users\Rhyss\Downloads\Godot_v4.7.2-stable_win64_console.exe' --headless --path code -s res://tools/export_l01_v10_home_layers.gd
```

The exporter also writes a local review composite to `test_evidence/l01_v10_home_layers/`. Do not use either source PNG directly as the runtime scene.

## Image-generation prompts

**Underpaint:** “Create a clean background plate from the exact Home at Dawn game image by removing only the large left and right roadside houses, fences, plants, waiting shed, utility poles, people, benches, and foreground corner leaves, replacing their regions with coherent distant barangay rooftops, open sky, mountains, and quiet paved verges. Preserve the camera, sunrise, central Barangay Hall and market wing, vanishing point, three-lane road, dashed lane markings, curb edges, and lower-screen road geometry. Warm Filipino barangay dawn style. No Peter, HUD, prompts, obstacles, text, watermark, grey background, or blur. Full-frame 16:9 opaque image.”

**Sky:** “Generate a clean full-frame 16:9 Filipino barangay dawn sky only, using the reviewed Home image as a position and palette reference: warm sun near 73% of width and 17% of height, soft pink clouds, calm gradient extending to the bottom. No mountains, land, roads, buildings, trees, people, poles, foreground objects, text, watermark, UI, grey or white background.”

The shipped result is an aligned export of these paintings and the reviewed Home street, not a claim that the source generator maintained exact pixel geometry. The road layer deliberately copies the reviewed road pixels to maintain that geometry.
