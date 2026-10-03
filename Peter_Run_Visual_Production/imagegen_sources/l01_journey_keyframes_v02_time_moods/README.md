# L01 journey keyframes v02 — daylight moods

Status: **whole-scene art sources for the L01 v09 scenery pass**. These five 1672 x 941 PNGs are not loaded directly by Godot. `../../process_l01_v09_journey.ps1` produces the 960 x 540 runtime copies in `code/art/backgrounds/l01_barangay_v09_journey/`. The v01 keyframes and obstacle art remain unchanged.

The built-in image-generation tool edited each corresponding v01 keyframe. Every prompt treated the v01 scene as the edit target and constrained camera, three-lane road, painted dashes, curbs, vanishing point, buildings, people, and roadside objects. The prior edited stage was supplied only as a lighting-progression reference for stages 02–05.

| Stage | File | Mood / image-edit prompt |
| --- | --- | --- |
| 01 Home Street | `l01_stage_01_home_street_dawn.png` | Soft Filipino dawn: pale peach and mint horizon, lavender-blue upper sky, cream-gold façade light, cooler teal shadows, restrained flowers; keep the road bright and clear. |
| 02 Waiting Shed & Garden | `l01_stage_02_waiting_shed_early_morning.png` | Fresh early morning, one step later than dawn: pale-blue sky, cream horizon, slightly higher/clearer sun, fresh garden greens, soft teal shadows. |
| 03 Sari-sari Corner | `l01_stage_03_sari_sari_late_morning.png` | Soft late morning: cleaner pale-blue sky, smaller pale sun glow, more neutral-warm daylight, crisp teal and coral shop accents, less orange cast. |
| 04 Palengke Approach | `l01_stage_04_palengke_early_afternoon.png` | Bright early afternoon: azure sky, honey-cream horizon, inviting produce and woven-market colors, somewhat deeper canopy shadows, no harsh glare. |
| 05 Barangay Hall Plaza | `l01_stage_05_hall_plaza_golden_afternoon.png` | Calm golden-afternoon arrival: honey-gold sky, apricot clouds, low mellow sun, warm Hall/plaza edges and existing lamps, richer teal shadows; still daylight, not night. |

Common prompt constraints: edit **lighting, sky, and environmental color only**; preserve the exact image aspect ratio, camera, road geometry, lane dashes, curb edges, safe player zone, Hall silhouette, stage-specific buildings, people, plants, and furniture. Do not add or remove objects. Keep exactly three empty lanes and readable cream markings on a warm-gray road. No Peter, HUD, prompt props, traffic, extra text, or watermark. The result is illustrated 2.5D game scenery meant to remain legible at 480 x 270.

## Read-only spot checks

- All five files are 1672 x 941, the same as their v01 targets.
- At native-canvas y=210, sampled centers of the two painted lane dashes match each corresponding v01 source within approximately 0.2 native pixels.
- At native-canvas y=190, 210, and 218, sampled curb-edge positions match each corresponding v01 source within one native pixel. This checks selected rows, not every contour or runtime alignment.
- At y=210, sampled lane-line luminance is 226–239 while sampled center-road luminance is 117–132 (8-bit scale), retaining visible line/road separation in all five moods.

The sun and sky intentionally evolve between keyframes. The runtime pass uses five aligned 960 x 540 exports, each displayed at 0.5 scale on the 480 x 270 composition. A paused, reduced-motion-aware masked reveal changes stages without superimposing semi-transparent buildings. Compatible cloud, leaf, bird, and light accents remain separate; the location-specific old laundry and resident-wave overlays are hidden because their attachment points do not exist in every new scene.

Known limitation: these are still flattened whole-scene plates, not fully independent sky, house, and road layers. The sun changes at chapter boundaries rather than travelling continuously. The previously measured painted-road versus Godot projection mismatch is not fixed by this scenery pass. Gameplay captures are under `test_evidence/l01_v09_scenery/`.
