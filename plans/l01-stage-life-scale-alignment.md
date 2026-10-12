# L01 stage-life scale and visual integration blueprint

Status: PLAN ONLY, 2026-10-10. Do not treat this file as approval to alter gameplay or as evidence that revised art exists.

## Outcome and scope

Make the small animated people, laundry, plants, and signs in all five L01 Barangay Morning stages look as if they belong to their painted surroundings. Match their apparent size, perspective, palette, ground/attachment contact, and rendering finish at the native 480×270 canvas. Keep the approved buildings, road, curb, lane marks, Barangay Hall, and original stage plates unchanged. If removing a baked-in duplicate is necessary, create a versioned, local clean-plate/patch variant that preserves the seven-layer geometry and original source, or animate only part of the static subject. Do not change input, player movement, obstacle approach, prompt timing, repetitions, misses, Pause, or therapy wording.

Baseline: branch `feature/l01-scenery-motion-assets`, source HEAD `ed05953`; `code/releases/PETER_RUN_Windows_x64_v6_preview.zip` is the comparison package, not a target to overwrite. Preserve the current approved stage plates and all unrelated dirty or untracked workspace files. New final runtime art belongs under `code/art/`; raw source work belongs under `Peter_Run_Visual_Production/`.

## Observed failure

[`l01_stage_street_life.gd`](../code/scripts/l01_stage_street_life.gd) reuses v05/v06 sprite strips on v10/v11 stage plates. A stage's 0.5 scale and its `StreetLife` child's 2.0 scale cancel; the smallness comes from each sprite's `size` and its large transparent frame margins, not an accidental double downscale. Measured first-frame alpha footprints, at native size, are approximately:

| Detail | Visible size in game | Current authored scale |
| --- | ---: | ---: |
| Waving neighbour | 8–10 × 30.5 px across poses | 0.125 |
| Market neighbour, including basket | 20 × 30–31 px | 0.17 |
| Laundry | 28–29 × 16–17 px | 0.13 |
| Flowers | 17 × 19 px | 0.11 |
| Banana detail | 19 × 24 px | 0.11 |
| Hanging sign | 13 × 13 px | 0.075 |

The [Palengke capture](../test_evidence/l01_v15_stage_motion/l01_v15_palengke_gesture_1920x1080.png) makes the mismatch especially clear: the animated left-side neighbour reads smaller and more cartoon-like than nearby painted market details. The current source strips have padding and a different finish from the stage plates. Simply enlarging every sprite by one factor risks misaligned feet, duplicate painted details, softened pixels, and curb intrusion.

[`l01_visual_geometry.gd`](../code/scripts/l01_visual_geometry.gd) is the painted-curb guide; [`road_projection.gd`](../code/scripts/road_projection.gd) owns lane/prompt geometry. The stage-specific details, existing anchors, and five progress thresholds are registered in [`L01_Scenery_Motion_Asset_Tracker.md`](../Peter_Run_Visual_Production/L01_Scenery_Motion_Asset_Tracker.md). The existing [`l01_static_buildings_restore_test.gd`](../code/tests/l01_static_buildings_restore_test.gd) deliberately keeps the formerly misaligned moving-building layer hidden. Do not re-enable it as part of this work.

## Non-negotiable visual contract

1. Exactly three readable lanes and the present 480×270 forward composition remain unchanged. Every animated alpha footprint, contact shadow, and sway extent stays outside the painted curb and Peter/prompt/HUD exclusion zones on every frame.
2. Compare each moving detail with a painted object at a similar screen `y`/depth, not with Peter at a different depth. Use visible alpha bounds, not the nominal 256-pixel frame, for size decisions. A person should read as an adult of comparable apparent height to another person at the same depth; a pot, sign, or cloth must match its exact painted attachment.
3. Keep a fixed canvas and the same foot, pot-base, line-end, roof-seam, or hook origin across all frames. Enlarging a detail may not make its contact point slide. No ghost of a baked-in person or plant may remain beneath a new cutout.
4. Animation stays calm. Pause freezes the exact pose and clock; Reduced Motion shows a stable resting pose. No new motion crosses a lane or competes with the active prompt.
5. This is a presentation-only change. `Route pace` may remain a separate later issue; do not increase motion speed to conceal a scale problem.

## Dependency map

`1. Baseline and size guide` → `2. Palengke art prototype` → `3. Anchored integration` → `4. Remaining four stages` → `5. Verification and review package`.

After Step 1, test-authoring for Step 3 may proceed alongside art prototyping, but integration waits for a visually approved prototype. Art for different stages may proceed in parallel only after a single palette, scale, lighting, and anchor guide is signed off. One integrator owns the final scene geometry.

## Step 1 — Lock a same-depth scale and attachment guide

**Context for a fresh implementer:** Read `code/AGENTS.md`, this plan, the tracker, `l01_stage_street_life.gd`, `runner_level.tscn`, `l01_visual_geometry.gd`, `road_projection.gd`, and the five v15 stage screenshots/video. Preserve the dirty worktree. This step is measurement and documentation only.

**Work:** Capture or inspect each stage at native 480×270 and at 960×540. For every current `PARTS` entry, record (a) minimum and maximum visible-alpha width/height over **all** frames, (b) the painted comparator at the same screen depth and an approved target pixel-size interval or comparator ratio, (c) exact feet/pot/hook/line attachment, (d) minimum curb and HUD/prompt clearances including sway, rotation, shadow, and translucent alpha fringe, and (e) whether the stage plate already contains a duplicate. Set a per-asset range rather than a universal multiplier. Require fixed contact/attachment drift of at most 1 native pixel across all frames, at least 2 native pixels of curb clearance at the widest pose, and no overlap with Peter, the prompt card, Pause, or any active prop footprint in any of the three lanes. Record the specific bounds and exclusions for each asset, not just these global floors. Make a contact/scale guide image per stage with measured boxes, without altering runtime art. Use the existing curb profile, not a second hard-coded road estimate. Record uncertain comparators for human art review.

**Exit gate:** A per-asset size/anchor table covers all 15 wired stage details and identifies every baked duplicate. Each detail has numeric native-pixel min/max alpha dimensions, same-depth target interval or ratio, anchor-drift measurement, minimum clearance, and documented prompt/HUD exclusion envelope for all three lanes. No source or runtime asset is overwritten.

**Rollback:** None; measurement documents only. **Model tier:** strongest visual/geometry reasoning.

## Step 2 — Approve one Palengke prototype before mass production

**Context:** Palengke is the highest-contrast problem: the animated neighbour sits at native `(54,181)` and the flowers at `(426,182)` beside detailed painted market frontage. The current sprite strips come from v05/v06 while the stage plate comes from v11.

**Work:** Rework one person and one attached small detail using the Step 1 guide. Prefer stage-matched, transparent source art with the same lighting, outline/detail level, perspective, and palette as the Palengke plate. Keep an editable source and fixed-canvas frames; crop only within the strip by stable alpha bounds, never crop each animation frame independently. If a corresponding subject is baked into the original plate, either (1) create a **versioned local clean-plate/patch variant**, retaining the original plate and identical seven-layer canvas, road, curb, lane, and building geometry, or (2) leave the subject painted and animate only a small attached part. Do not stack two full figures. Export clearly named runtime candidates under `code/art/backgrounds/l01_stage_life_v16/`. Composite rest and widest-action frames against the untouched plate when there is no duplicate, or against the reviewed clean-plate variant when there is one.

**Exit gate:** At native size, the prototype person has the approved same-depth apparent size and a stable sidewalk contact in every pose. It is recognisable but quieter than Peter and the active prompt. Palette and edge treatment match the market art. No road intrusion, duplicate/ghost image, rectangular transparency edge, or blurred upscaling. If a clean plate is used, the repaired composite is explicitly reviewed alongside the untouched original before integration. Product owner reviews the composite before the other stages are produced.

**Rollback:** Keep the current v05/v06 strips and stage plate untouched; candidate remains inactive until approval. **Model tier:** strongest visual-art model or artist.

## Step 3 — Integrate by visible bounds and stable anchors

**Context:** `L01StageStreetLife` currently sets a manually chosen sprite scale and then shifts ground-anchored sprites using the first frame's used rectangle. This is the narrowest code surface for integration; gameplay controllers do not need modification.

**Work:** Add small deterministic tests before changing the runtime script. Test all-frame alpha bounds, one constant contact origin, approved per-stage size range, curb/prompt clearance for all three lanes, and unchanged animation timing. Replace only the approved Palengke detail with per-asset scale and attachment metadata from Step 1. Prefer a compact data table in the existing script over a new animation framework. Keep the 480×270 coordinate system; do not apply a second stage-parent scale. Inspect the current 1.2-second stage reveal: `l01_layered_route_motion.gd` uses a spatial wipe on stage parents while `StreetLife` children receive alpha modulation. If enlargement exposes a detail before its supporting sidewalk or over the outgoing stage, align its visibility to the existing wipe with a visual-only mask/reveal; do not alter progression timing. Preserve Pause and Reduced Motion behavior.

**Exit gate:** The Palengke prototype passes the focused tests and a rendered stage capture at rest, widest pose, Pause, and Reduced Motion. Capture stage-reveal frames at 0%, 25%, 50%, 75%, and 100%; the moving detail appears only with its supporting stage art and never doubles a person or prop from the outgoing stage. Position and perceived size remain stable on entry/exit. The active prompt remains visually dominant and unobscured.

**Rollback:** Restore the previous `PARTS` entry/texture; no changes to shared gameplay timing or stage resources. **Model tier:** default engineering, strongest review for visual geometry.

## Step 4 — Extend the approved method to Home, Waiting, Sari-sari, and Plaza

**Context:** Each stage has three current animated details, but a shared old strip is not automatically the right size or style for every stage. The tracker lists exact current anchors and intended attachment types.

**Work:** Produce stage-matched candidates for the remaining details, prioritising people, laundry/awning attachment, then plants/signs. Calibrate each asset against its own stage at the same depth. Avoid duplicated painted content; when a complete cutout cannot be made cleanly, keep the static subject and animate only a leaf, sleeve, cloth edge, or highlight. If a full cutout is approved, use a separately versioned local clean-plate variant and review its composite before activation; never overwrite the source plate. Update only the corresponding stage entries and tracker rows after visual approval. Keep shared clouds/foreground leaves if they already align; do not bring back hidden floating legacy overlays or the whole-building travel system.

**Exit gate:** All five stages have at least one readable but restrained motion cue; every current or replacement detail has a final size, anchor, all-frame safe bounds, and matching art finish recorded in the tracker. No stage is forced to use a visually wrong shared sprite merely for code reuse.

**Rollback:** Revert individual stage entries without affecting other stages or the fixed stage plates. **Model tier:** strongest art reasoning for assets; default engineering for table integration.

## Step 5 — Regression, visual QA, and release decision

**Context:** Existing checks include `l01_v13_street_life_test.gd`, `l01_v15_stage_motion_test.gd`, `l01_static_buildings_restore_test.gd`, `l01_prompt_visual_clearance_test.gd`, `pause_motion_test.gd`, and `project_setup_smoke.gd`. v6 preview and `test_evidence/l01_v15_stage_motion/` are the visual baseline.

**Work:** Run the focused tests and the full Godot suite. Capture every stage at 480×270, 960×540, 1024×768, and 1920×1080, including rest, widest motion pose, prompt approaching each of the three lanes, Pause mid-motion, Reduced Motion, and a short video showing actual movement. Inspect **every animation frame** against per-asset size, contact, and safety envelopes, not only the sampled video frames. Capture 0%, 25%, 50%, 75%, and 100% of every adjacent stage transition and check that each moving detail stays attached to its supporting plate without ghosts or duplicates. Compare against v6 preview side by side. Confirm all assets import and no white/grey backgrounds, clipping, drift, perspective jump, or pixel blur. Update the asset tracker and provenance. Only after human approval, export a new preview with a distinct version; keep v6 as rollback.

**Exit gate:** In each stage, moving details are visibly scale-matched to painted neighbours at the same depth; all 15 detail slots have an explicit accepted/replaced/disabled disposition; all relevant tests pass; screenshots and video verify alignment and immediate Pause. The package is not called clinically approved without separate therapist/hardware/UAT evidence.

**Rollback:** Retain v6 package and previous source/asset references. **Model tier:** strongest visual review plus normal release verification.

## Anti-patterns and plan mutation

- Do not multiply every `size` value by one constant. Each sprite has different alpha padding and stands at a different depth.
- Do not resize a whole sheet without checking every frame's foot or attachment location. Do not move the anchor to make one pose look right.
- Do not overlay an enlarged duplicate on top of the same painted person, plant, sign, or cloth.
- Do not shift the full stage image, road, curb, or Hall to compensate for a small sprite.
- Do not re-enable `RoadsideMotion`; its older building art was intentionally hidden for layout alignment.
- Do not change Route pace, prompt approach time, player size, repetition thresholds, or clinical wording in this scope.
- If the prototype fails visual review, revise or replace Step 2 art before modifying other stages. If a stage cannot support a clean cutout, mark that asset `STATIC + PARTIAL MOTION` in the tracker rather than forcing a mismatched full sprite. Record the decision and evidence when splitting, inserting, or dropping a step.
