# L01 Home roadside-travel source experiment

These files are **source candidates only**. Neither is referenced by a Godot runtime scene or packaged as approved art.

## Files and provenance

- `home_clean_plate_candidate_rejected_v01.png`: built-in image-generation edit of `test_evidence/experience_revamp_geometry/l01_home_stage_composite_960x540.png`. Prompt intent: remove near/mid side buildings while preserving the road, Hall, sunrise and camera. **Rejected** because the model altered the Hall scale, curb/road geometry and landscape proportions. Do not use it as a fixed plate.
- `home_left_frontage_source_v01.png`: built-in image-generation transparent source, with the Home composite as style/perspective reference. Prompt intent: one original left-side Filipino home, veranda, short fence, bench, plants, narrow sidewalk and contact shadow, with no road/sky/Hall/UI/person. Alpha is present; it is not an approved runtime sprite.

The exact existing clean plate is derived by compositing the active Home `Sky`, `Far`, `Landmark`, `Road`, and `Foreground` layers while omitting `LeftStreet`/`RightStreet`. It is shown in `test_evidence/experience_revamp_geometry/l01_home_without_streets_960x540.png`. This preserves the existing road and destination but reveals a broad, rural-looking empty side. It needs continuous, varied architecture before it can replace the current fixed street.

`code/tests/support/preview_l01_home_left_passby.gd` creates three **test-only** composites using this frontage. It anchors the source point `(1475, 750)` to the painted left curb minus 2 native px at y=150/185/220, scales it 0.22/0.32/0.45, and clips visible pixels to the outside of the curb. The far frame is plausible but less substantial than the approved street; at middle/near depths the single section exits and a wide blank verge reappears. The sidewalk/fence footprint also needs a depth-matched continuation. A lone cutout is not enough to enable travel.

## Required before runtime integration

1. Author at least two more distinct, compatible left sections and continuous frontage/yard behind them; then inspect the complete loop at native 480 x 270 for no blank side or repeated-house rhythm.
2. Match the fixed road's sidewalk and planted edge. Keep a documented visible-alpha union, ground-contact point and attachment origin for each section and all animation frames. Avoid moving painted sidewalk pixels independently of their building if that produces sliding seams.
3. Produce a non-mirrored right-side set and check both sides together against prompt envelopes and the static Home baseline.
4. Treat the current fixed streets as the runtime fallback. Enable no moving building until a whole cycle, recycle boundary, Pause, and Reduced Motion pass the project visual gate.

The image-generation prompts used here were: (a) a precise-object edit to remove both side street structures from the full Home composite while preserving road/Hall/sun, and (b) a transparent left-frontage source with one two-storey Filipino home, veranda, fence, bench and plants facing the road. Both requests prohibited UI, road-lane objects, copied commercial-runner imagery and watermark. The built-in image tool produced the PNGs; no CLI model or API key was used.
