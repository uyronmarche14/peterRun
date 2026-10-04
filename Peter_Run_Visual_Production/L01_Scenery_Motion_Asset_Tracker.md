# L01 Barangay Morning — scenery motion asset tracker

Last audited: 2026-10-04. Scope: the five L01 journey scenes only. This is a production tracker, not a claim that the proposed art or motion has been implemented.

## How to use this tracker

- Give every moving detail its own sprite/overlay and ground or attachment anchor. Do not animate a complete building, road, curb, or full-screen stage plate.
- Move an item through `PLANNED` → `ART READY` → `WIRED` → `VISUAL QA` → `RELEASED`. `WIRED` means the node exists and code updates it; it does **not** mean its movement is noticeable or correctly aligned in a packaged game.
- For each item, record the final file path, native-screen anchor, animation loop/event, and screenshot or test evidence before changing its status.
- Update this tracker whenever art, placement, visibility, timing, or release packaging changes. Preserve the source art and do not silently replace approved stage plates.

The current stage-specific assets are `WIRED / VISUAL QA PENDING`: they are present in [`l01_stage_street_life.gd`](../code/scripts/l01_stage_street_life.gd) and the scene. The 2026-10-04 motion pass starts gestures soon after entry and gives every stage at least three independent animated details; product-owner visual approval is still pending. The `PETER_RUN_v4` package was built on 2026-09-30, before these changes; do not mark them `RELEASED` in that package.

## Fixed scenery and journey contract

Each stage uses seven registered, full-canvas 960×540 layers at 0.5 scale on the 480×270 game canvas. These are composition plates, **not** individually moving objects.

| Journey scene | Progress threshold | Layer folder and basename prefix | Fixed layers | Stage-specific moving details now |
| --- | --- | --- | --- | --- |
| Home | 0% | `code/art/backgrounds/l01_home_v10_layers/l01_v10_home_` | `sky`, `far`, `landmark`, `left_street`, `right_street`, `road`, `foreground` | 3 |
| Waiting Shed | 25% | `code/art/backgrounds/l01_journey_v11_layers/l01_v11_waiting_` | Same seven suffixes | 3 |
| Sari-sari Store | 50% | `code/art/backgrounds/l01_journey_v11_layers/l01_v11_sari_sari_` | Same seven suffixes | 3 |
| Palengke Approach | 75% | `code/art/backgrounds/l01_journey_v11_layers/l01_v11_palengke_` | Same seven suffixes | 3 |
| Barangay Plaza | 90% | `code/art/backgrounds/l01_journey_v11_layers/l01_v11_plaza_` | Same seven suffixes | 3 |

The thresholds are fractions of the configured repetition target, not fixed repetition counts; see [`route_journey.gd`](../code/scripts/route_journey.gd). The exact stage resources and draw order are in [`runner_level.tscn`](../code/scenes/levels/runner_level.tscn). The Hall/landmark, road, sidewalks, curb, and buildings remain stable through ambient animation. Stage-to-stage reveal is a separate, brief transition.

## Per-stage moving-asset register

All coordinates below are **native 480×270 canvas coordinates**, not source-image pixels. Existing anchors are from the current `PARTS` register. Proposed anchors are `TBD` until measured against that stage's painted sidewalk. A new cutout must not duplicate a person or prop already painted into the plate; revise/cover the plate region only after visual review.

### Home — doorstep and morning garden

| ID / moving asset | Existing anchor; attachment | Motion or intended motion | Art source | Status |
| --- | --- | --- | --- | --- |
| `home_neighbour_wave` | Right sidewalk `(429,186)`; feet | Short wave in a 13-second cycle | `l01_v05_resident_wave_strip.png` | WIRED / VISUAL QA PENDING |
| `home_laundry` | Left house `(78,119)`; line attachment | Slow cloth-frame change | `l01_v05_laundry_strip.png` | WIRED / VISUAL QA PENDING |
| `home_flowers` | Left verge `(56,187)`; pot base | Slow flowering-plant frames | `l01_v06_flowering_plants_strip.png` | WIRED / VISUAL QA PENDING |
| `home_banana_leaf` | TBD; left garden stem | One clear, gentle leaf sway | New transparent cutout | PLANNED |
| `home_veranda_curtain` | TBD; left veranda rail | Soft breeze; attachment points fixed | New transparent cutout | PLANNED |

### Waiting Shed — pause along the route

| ID / moving asset | Existing anchor; attachment | Motion or intended motion | Art source | Status |
| --- | --- | --- | --- | --- |
| `waiting_laundry` | Left side `(84,106)`; line attachment | Slow cloth-frame change | `l01_v05_laundry_strip.png` | WIRED / VISUAL QA PENDING |
| `waiting_flowers` | Left verge `(56,183)`; pot base | Slow flowering-plant frames | `l01_v06_flowering_plants_strip.png` | WIRED / VISUAL QA PENDING |
| `waiting_banana` | Left garden `(30,177)`; pot base | Independent banana-leaf frames | `l01_v06_banana_left_strip.png` | WIRED / VISUAL QA PENDING |
| `waiting_resident_greeting` | TBD; shed floor contact | Occasional small hand greeting, no lane entry | New transparent character strip | PLANNED |
| `waiting_shed_awning_edge` | TBD; shed roof attachment | Short, low-amplitude fabric movement | New transparent overlay | PLANNED |
| `waiting_notice_corner` | TBD; notice-board pin | Subtle paper-corner lift, no text flicker | New transparent overlay | PLANNED |

### Sari-sari Store — shopfront life

| ID / moving asset | Existing anchor; attachment | Motion or intended motion | Art source | Status |
| --- | --- | --- | --- | --- |
| `sari_balcony_laundry` | Left balcony `(92,95)`; line attachment | Slow cloth-frame change | `l01_v05_laundry_strip.png` | WIRED / VISUAL QA PENDING |
| `sari_shop_sign` | Right shop `(403,102)`; hook | Small rotational sway | `l01_v06_hanging_sign.png` | WIRED / VISUAL QA PENDING |
| `sari_shop_flowers` | Left verge `(56,189)`; pot base | Slow flowering-plant frames | `l01_v06_flowering_plants_strip.png` | WIRED / VISUAL QA PENDING |
| `sari_awning_valance` | TBD; right awning edge | Light fabric wave; roof edge fixed | New transparent overlay | PLANNED |
| `sari_shopkeeper_greeting` | TBD; shop-floor contact | Occasional calm gesture from behind counter | New transparent character strip | PLANNED |
| `sari_hanging_packets` | TBD; shop beam | Small delayed sway, no flashing product marks | New transparent overlay | PLANNED |

### Palengke Approach — market frontage

| ID / moving asset | Existing anchor; attachment | Motion or intended motion | Art source | Status |
| --- | --- | --- | --- | --- |
| `palengke_neighbour` | Left sidewalk `(54,181)`; feet | Short vendor gesture in a 13-second cycle | `l01_v06_resident_vendor_strip.png` | WIRED / VISUAL QA PENDING |
| `palengke_sign` | Right frontage `(414,105)`; hook | Small rotational sway | `l01_v06_hanging_sign.png` | WIRED / VISUAL QA PENDING |
| `palengke_flowers` | Right verge `(426,182)`; pot base | Slow flowering-plant frames | `l01_v06_flowering_plants_strip.png` | WIRED / VISUAL QA PENDING |
| `palengke_canopy_edge` | TBD; market roof attachment | Separate cloth frames with fixed roof seam | New transparent overlay | PLANNED |
| `palengke_basket_tend` | TBD; stall/table contact | Small hands/basket gesture outside lanes | New transparent strip | PLANNED |
| `palengke_warm_window` | TBD; stall interior | Very restrained warm-light variation | New transparent overlay | PLANNED |

### Barangay Plaza — calm arrival

| ID / moving asset | Existing anchor; attachment | Motion or intended motion | Art source | Status |
| --- | --- | --- | --- | --- |
| `plaza_neighbour_wave` | Right sidewalk `(423,185)`; feet | Short wave in a 13-second cycle | `l01_v05_resident_wave_strip.png` | WIRED / VISUAL QA PENDING |
| `plaza_garden_sign` | Left side `(72,109)`; hook | Small rotational sway | `l01_v06_hanging_sign.png` | WIRED / VISUAL QA PENDING |
| `plaza_garden_flowers` | Left verge `(56,188)`; pot base | Slow flowering-plant frames | `l01_v06_flowering_plants_strip.png` | WIRED / VISUAL QA PENDING |
| `plaza_garden_leaf_cluster` | TBD; planting bed | Gentle independent leaf movement | New transparent cutout | PLANNED |
| `plaza_welcome_banner_edge` | TBD; plaza-side mount | Small fabric wave, never over Hall text | New transparent overlay | PLANNED |
| `plaza_hall_window_highlight` | TBD; exact Hall-window mask | Brief, soft glint gated to Plaza | New or re-aligned transparent overlay | PLANNED |

Existing shared texture paths are under `code/art/backgrounds/l01_barangay_v05_layers/` and `code/art/backgrounds/l01_barangay_v06_layers/`. New runtime textures should live under a clearly named `code/art/backgrounds/` subfolder; keep raw source art separately under `Peter_Run_Visual_Production/`.

## Shared motion and inactive legacy assets

| Asset / node | Current behavior | Tracker action |
| --- | --- | --- |
| `CloudsA` | Shared slow drift over every stage; 7 native-pixel amplitude at 0.30 alpha | VISUAL QA: confirm drift is readable without covering the Hall or prompt. |
| `BananaLeavesLeft/Right`, `ForegroundLeavesLeft/Right` | Shared frame changes and approximately 1–1.35 native-pixel sway at screen edges | VISUAL QA: keep within edge masks; confirm calm motion at normal game size. |
| `Birds`, `HallWindowGlints` | Event-driven; birds/glints become visible only during scheduled events | VISUAL QA: check stage-specific placement and avoid glints over mismatched Hall windows. |
| `MarketGlow` | Shared slow opacity variation | SCOPE QA: verify it belongs only where the market appears; do not leave a floating light in other stages. |
| `Laundry`, `ResidentWave`, `FloweringPlants`, `MarketAwning`, `ResidentGardener`, `ResidentVendor`, `HangingSign` at the route root | Legacy shared nodes start hidden; code may change frames without making most of them visible | INACTIVE: do not count them as delivered animation. Reuse only after stage-specific placement and visibility are approved. |
| `RoadsideMotion` whole-building travel | Hidden for L01 by the level controller | INACTIVE by design: do not re-enable to create movement. It previously broke visual alignment. |
| `RoadMotionDashes` | Subtle projected road seams, disabled in Reduced Motion | VISUAL QA: preserve three-lane readability and match painted road geometry. |

The current motion owner is [`l01_layered_route_motion.gd`](../code/scripts/l01_layered_route_motion.gd). `GameSettings.reduced_motion` holds ambient motion; Pause must freeze the timeline and the current pose immediately.

## Asset card template — copy once per new sprite

| Field | Record |
| --- | --- |
| Asset ID / stage | `l01_<stage>_<asset>_v01` / Home, Waiting, Sari-sari, Palengke, or Plaza |
| Source and runtime file | Editable source path; transparent final PNG/strip path |
| Frame data | Canvas size; frame size/count; fps or phase timing; loop/event; no duplicate endpoint frame |
| Attachment | Native `(x,y)`; left/right side; feet, pot base, roof seam, hook, or line endpoints |
| Geometry | All-frame alpha bounds; painted curb clearance at lowest visible pixel; HUD/prompt exclusion |
| Behavior | Normal-motion range; Reduced Motion resting frame; Pause/resume exact-pose behavior |
| Evidence | Test name; 960×540, 1024×768, and 1920×1080 screenshots or short capture; package version |
| Status and owner | PLANNED / ART READY / WIRED / VISUAL QA / RELEASED; responsible person; date |

## Acceptance checklist

- [ ] Each of the five stages shows at least one recognizable, calm movement within 3–5 seconds of normal play, without relying on the shared clouds or global leaves.
- [ ] Every moving detail is a separate transparent asset or overlay with a stable attachment point. Baked-in duplicates/ghosts are removed or masked cleanly.
- [ ] All frames remain outside the painted road edge using [`l01_visual_geometry.gd`](../code/scripts/l01_visual_geometry.gd); no asset reaches active props, Peter, the prompt card, or Pause.
- [ ] Stage change reveals the new stage's details cleanly; the previous stage's details leave with it. The road, curb, lane markings, Hall, and houses do not slide.
- [ ] Pause holds every frame, position, rotation, event timer, and stage transition; Resume continues from the held pose. Reduced Motion shows a stable, pleasant resting pose.
- [ ] Existing alignment and pause tests pass, including [`l01_v13_street_life_test.gd`](../code/tests/l01_v13_street_life_test.gd) and [`l01_v09_scenery_test.gd`](../code/tests/l01_v09_scenery_test.gd); add per-frame bounds tests for new assets.
- [ ] Review actual gameplay at 960×540, 1024×768, and 1920×1080, plus a short motion capture for **each** stage. Still screenshots alone cannot prove movement.
- [ ] Rebuild and identify the package containing these changes before marking any item `RELEASED`.

## Current verification evidence

- Godot 4.7.2 Compatibility renderer: [`l01_v15_stage_motion_test.gd`](../code/tests/l01_v15_stage_motion_test.gd) passes for all five stages, stage-entry timing, 0–15 second sampled curb clearance, Pause, Reduced Motion, and fixed building position.
- Nine other affected tests passed: `l01_v13_street_life_test`, `l01_prompt_visual_clearance_test`, `l01_v09_scenery_test`, `l01_barangay_layered_route_test`, `l01_static_buildings_restore_test`, `pause_motion_test`, `presentation_motion_test`, `route_journey_test`, and `project_setup_smoke`.
- The [capture utility](../code/tests/support/capture_l01_v15_stage_motion.gd) produced 25 local stage/pose screenshots in `test_evidence/l01_v15_stage_motion/`, including all five stages at 960×540, 1024×768, and 1920×1080. Its `captures.json` reports Pause and Reduced Motion checks as true. This evidence folder is local/ignored, not a packaged release or clinical approval.

## Update log

| Date | Change | Evidence / next action |
| --- | --- | --- |
| 2026-10-04 | Initial audit and tracker created; 14 stage-specific sprites are wired, most visually subtle; proposed additional details remain unmade. | Scene/script inspection only. No new art, code, tests, or release created by this document. |
| 2026-10-04 | Five-stage motion integration: Waiting Shed gained a separately anchored banana sprite; gestures and cloth/sign frames now begin and read sooner; stage clocks restart on entry; shared clouds/leaves move more clearly. Current count: 15 stage-specific sprites. | Godot tests and 25 visual captures pass. Remaining planned concept assets are still unmade; product-owner visual review and new package are pending. |
