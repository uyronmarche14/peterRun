# L01 v8 visual candidate — image-generation record

The following project-bound resident cutouts were made with the built-in `image_gen` tool on 2026-10-14. They are original generated art for visual review, not product-owner-approved assets. Their final runtime copies are under `code/art/backgrounds/l01_stage_details_v08/`. The source prompts are recorded here; no CLI/API fallback was used.

## Home neighbour wave

Runtime file: `home_neighbour_wave_v08.png` (1024x1536 RGBA).

> Use case: stylized-concept. Asset type: transparent 2D game sprite cutout for PETER RUN, a calm Filipino barangay rehabilitation game. Create one original Filipino adult neighbour, full body visible, standing on a sunlit sidewalk, friendly subtle wave with one hand, viewed from a slight rear/side three-quarter angle as if facing a person running up a road. Everyday teal-green short-sleeved blouse and warm brown trousers, simple sandals, natural adult proportions. Render as polished semi-realistic illustrated game art with crisp silhouette, warm golden morning highlights, gentle teal shadows, carefully defined shoes and feet, no harsh black outline. The surrounding game scenery is richly painted Filipino houses, banana leaves and warm concrete sidewalk; make the figure harmonious with that detailed but readable environment. Keep both feet on one clean horizontal ground line and leave transparent padding around the full silhouette for a fixed-origin sprite. One character only, no background, no sidewalk, no shadow plane, no props, no text, no watermark. Genuine transparent alpha background.

## Home neighbour rest

Runtime file: `home_neighbour_rest_v08.png` (1024x1536 RGBA). Edit target: the generated Home wave cutout above.

> Use case: precise-object-edit. Input image: the illustrated transparent-background Filipino adult neighbour. Change only her raised waving arm into a relaxed lowered arm beside her body, keeping her face, hair, clothes, torso, legs, feet, size, camera angle, lighting, palette, and exact full-body placement consistent with the source. Maintain a genuinely transparent alpha background and the same ground line. No new objects, no environment, no text, no watermark.

## Palengke vendor

Runtime file: `palengke_vendor_v08.png` (1024x1536 RGBA).

> Use case: stylized-concept. Asset type: transparent 2D game sprite cutout for PETER RUN's Palengke afternoon sidewalk. One original Filipino adult market neighbour, full body visible, standing naturally beside a compact woven produce basket held at waist level; friendly slight turn toward the road. Practical muted coral blouse, earth-brown trousers, simple sandals, contemporary everyday attire, natural adult proportions. Polished semi-realistic illustrated game art harmonizing with a richly painted Filipino public market, warm afternoon sunlight and cooler teal shadows, crisp readable silhouette at small game scale. Fixed full-body canvas with feet aligned on a clean horizontal ground line and transparent padding around silhouette. One person only; no background, no road, no stalls, no shadow plane, no logos, no text, no watermark. Genuine transparent alpha background.

The four SVG stage accents and the narrower laundry-line SVG were authored directly as editable vector assets; they did not use image generation. Godot imports the SVGs to textures for the 2D Compatibility renderer. The original v7 PNGs and seven-layer stage plates remain unchanged.
