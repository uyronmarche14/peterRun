# L01 five-stage composition and anchor contract

Status: measured visual guide, 2026-10-18. This is **not** approval to enable moving buildings. The current five fixed streets, road, Hall, sun, prompt projection, movement timing, and gameplay lanes remain unchanged.

## Source and coordinate system

- Godot 2D Compatibility canvas: **480 x 270** native pixels. Each active stage uses separately aligned **960 x 540** PNGs displayed at **0.5** scale from screen origin `(0, 0)`.
- Active stage order: Home, Waiting Shed, Sari-sari Store, Palengke Approach, Barangay Plaza. Their `Road` sprites are the v10 Home and v11 journey assets in `code/scenes/levels/runner_level.tscn`; the V05 all-in-one environment and old V08 `RoadsideMotion` remain hidden.
- The painted road/sidewalk *outer alpha silhouette* is identical at every sampled row across all five active road layers. The **painted curb** is an inner line within this silhouette, not the alpha edge. Side scenery must attach outside the painted curb and must not be placed at the outer alpha line as though it were the lane boundary.
- `RoadProjection` owns three lane centres and prompt contact at y=218. `L01VisualGeometry` owns the visual painted curb. Do not move gameplay lanes to close the visible gap between them.
- The route PNG is transparent at y=112, the logical far spawn line. The guide curb there is an extrapolation, **not** a measured road-paint edge. New passing art should enter from a depth where a real sidewalk/curb is visible, approximately y>=128; review any entrance nearer the horizon against the Hall/plaza composite.

## Measured native-pixel profile

Values are approximate to 0.5 px from source alpha and the existing painted-curb guide. Left/right pairs are x coordinates. The projected-edge gap is measured inward from the painted curb, so it is **not** a call to change collision or prompt lanes.

| Native y | Outer opaque road/sidewalk | Painted curb | Projected L01 road edge | Lane centres L/C/R | Projected edge inward gap L/R |
| ---: | --- | --- | --- | --- | --- |
| 120 | 187 / 314.5 | 180 / 300 (extrapolated, outside left alpha) | 198 / 282 | 213 / 240 / 267 | 18 / 18 |
| 150 | 130 / 350.5 | 151 / 329 | 159 / 321 | 181 / 240 / 299 | 8 / 8 |
| 190 | 47 / 433 | 101 / 381 | 108 / 372 | 138 / 240 / 342 | 7 / 9 |
| 210 | 20.5 / 462 | 66 / 416 | 82 / 398 | 117 / 240 / 363 | 16 / 18 |
| 218 | 8 / 472 | 52 / 429 | 72 / 408 | 108 / 240 / 372 | 20 / 21 |
| 241 | 1 / 479 | 18 / 463 | n/a: past prompt contact | Peter's centre x=240 | n/a |

The profile at y=112 in `l01_visual_geometry.gd` is an extrapolated anchor `(188, 292)`. At y=120 it lies left of the road PNG's opaque left edge; that is a known far-zone art/projection exception, not an area where new roadside sections should be grounded.

## Anchors, exclusions, and clearances

- Peter's scene root is `(240, 226)` and his road shadow origin is `(240, 241)`. Prompt ground contact ends at y=218. These are deliberately different depth anchors; a moving roadside sprite must use its own ground-contact y rather than either one by default.
- The three player lane x positions are `108 / 240 / 372`; active prompts use depth-dependent centres and the current L01 curb-fitting path. Their contact visible-alpha bounds are listed below.
- The top HUD is x=8..166, y=4..33; active prompt card x=170..310, y=4..32; Pause button x=414..472, y=7..27; footer x=8..472, y=249..266. These are exclusion rectangles, not scenery targets. Side leaves must not conceal these controls.
- For a new side object's **nearest visible ground edge** at depth y, use `L01VisualGeometry.roadside_contact_x(-1 or 1, y, clearance)`. The helper defaults to 2 px outward from the painted curb and clamps negative clearance to zero. Its result is an edge/contact constraint, **not** the object's centre: artwork must extend away from the lane. A candidate's union of visible alpha across *all* frames must keep at least 2 px of curb clearance and attachment drift <=1 native pixel. Wider art, prompt shadows, and any animated sway need more clearance based on their actual bounds.
- The existing street-life parts have stage-local native anchors in `l01_stage_street_life.gd`; their pots/residents are ground anchored, while laundry/sign/canopy/glint use attachment points. These anchors are current static references, not approved parent anchors for a moving facade. Recheck all frames before reparenting any of them.

## Active prompt envelopes

These are visible-alpha unions of each active prop's currently visible Sprite2D children, after enabling the L01 road-presentation fit. Each cell gives x bounds for left / centre / right lanes. y is the approximate vertical range (side and centre sometimes differ by a few pixels). Depth `0` is the y=112 far spawn, `0.5` is y≈141, and `1` is the y=218 contact line. They are the same across stages because the prompt projection is shared.

| Prop | Depth | Left x | Centre x | Right x | Approximate y |
| --- | ---: | --- | --- | --- | --- |
| Crates | 0 | 215..229 | 232..248 | 251..265 | 91..113 |
| Crates | 0.5 | 178..211 | 224..256 | 270..302 | 99..143 |
| Crates | 1 | 81..135 | 213..267 | 345..399 | 147..221 |
| Puddle | 0 | 215..229 | 232..248 | 251..265 | 109..112 |
| Puddle | 0.5 | 178..213 | 219..262 | 267..302 | 133..142 |
| Puddle | 1 | 71..162 | 183..297 | 318..411 | 195..220 |
| Laundry | 0 | 215..229 | 233..247 | 251..265 | 102..112 |
| Laundry | 0.5 | 178..213 | 221..259 | 267..302 | 114..143 |
| Laundry | 1 | 71..162 | 191..289 | 318..411 | 144..221 |

At contact, the outer active side-lane prop boundaries remain about 18.5 px inside their corresponding painted curbs; decorative side art needs to stay outside the curb, not merely outside a lane centre. Validate composite full-lane formations in `l01_prompt_visual_clearance_test.gd`, including active highlights/shadows and every animation frame.

## Guide overlays and how to read them

Run `code/tests/support/render_l01_composition_guide.gd` to rebuild the evidence images in `test_evidence/experience_revamp_geometry/`. It composites the current fixed stage layers, without gameplay HUD, Peter or ambient street-life sprites, then draws:

- **White dots:** outer alpha edge of the road/sidewalk PNG, not the curb.
- **Mango:** painted curb and prompt ground at y=218.
- **Blue:** projected L01 road edge (ends at prompt contact).
- **Teal:** three projected lane centres.
- **Lime:** 2 px curb-safe nearest roadside edge from y=150 downward.
- **Violet:** y=112 far spawn/horizon guide and Peter's shadow line at y=241.
- **Outlined top/bottom boxes:** actual HUD, prompt card, Pause, and footer footprints. Dark top/bottom strips represent conservative no-scenery bands.

Each of the five stages has a `480x270`, `960x540`, `1024x768`, and `1920x1080` guide PNG. The `1024x768` guide represents a centred 1024x576 16:9 play image with 96 px top and bottom bars. These are **measurement overlays**, not proposed runtime sprites or actual gameplay screenshots.

## Next visual gate

The clean-plate/side-section art gate is still open. The current left/right stage PNGs contain the static buildings and planters; overlaying passing buildings would duplicate them. Omitting those two layers produces an exact, aligned Home clean plate from the existing sky/far/Hall/road/foreground layers, but reveals broad empty side fields. A generated clean-plate edit was rejected because it altered the road and Hall geometry. A transparent left-frontage source was previewed at three curb-anchored depths; one section exits quickly and does not preserve street density. See `Peter_Run_Visual_Production/imagegen_sources/l01_home_passby_v01/README.md` and the `l01_home_left_passby_candidate_*` evidence images. Make varied, overlapping Home sections, with contact shadows, continuous frontage and attached animated details. Compare the first composite and whole pass-by cycle against the current Home stage at **480 x 270**. Keep the static stage active unless there is no blank verge, duplicate building, curb intrusion, parent/cloth detachment, or visible recycle pop. Only then make the right side and other four stages.

The new contract test checks road dimensions/origin, identical sampled alpha edges, three lane centres, and a curb-safe anchor. It does not prove that any future moving sprite is ready. Existing prompt-clearance and stage-life tests remain separate gates. The unresolved contact-versus-neutral-miss requirement is unrelated to this visual measurement and remains pending therapist/product-owner review.
