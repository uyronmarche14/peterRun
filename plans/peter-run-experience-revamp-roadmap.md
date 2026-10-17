# PETER RUN experience revamp roadmap

Status: **roadmap with initial slices in progress**, updated 2026-10-17. This document is not clinical approval. The working branch at planning time was `fix/l01-full-lane-action-cues`; the worktree contains unrelated edits and untracked source art that must be preserved. Do not treat a passing automated test as clinical approval.

## Intended outcome

Make L01 Barangay Morning easier to read and more convincingly alive at normal game size, while keeping the supervised rehabilitation flow calm and predictable. This is a presentation and usability revamp first, not a speed, difficulty, or clinical-rules revamp. The 480 x 270 Godot 2D Compatibility canvas, exactly three lanes, named actions (`move_left`, `move_right`, `jump`, `slide`, `pause_session`), one active prompt, fixed response timing, immediate Pause, and therapist controls are invariants unless a separately approved product decision explicitly changes them. No scores, coins, chases, enemies, score penalties, countdown pressure, or copied commercial-runner art.

The scope is L01 and shared UI/audio surfaces it actually uses. L02/L03 are hidden developer routes; exposing or redesigning them is outside this roadmap. Young Peter remains future work. New final runtime art belongs under `code/art/`, source work under `Peter_Run_Visual_Production/`, and evidence under `test_evidence/`.

## Checked baseline and open decisions

| Area | Confirmed current state | Change to evaluate |
| --- | --- | --- |
| Prompt action | `runner_level_controller.gd` applies accepted movement immediately, stores the response, then resolves/counts it at contact. `input_adapter.gd` has a 0.35-second action cooldown. | Make the *accepted now* versus *counted at contact* feedback unmistakable; measure perceived delay before considering any timing change. |
| Miss/contact | `formation_collision_resolver.gd` ends the run on an unresolved occupied-lane contact; a non-contact miss is neutral. The BRD/PRD contain both broad neutral-miss language and explicit contact-end requirements. | Therapist/product owner must resolve the wording and intended behavior before any logic or clinical-copy change. Do not silently treat every miss as a collision or every collision as harmless. |
| Formations | The L01 resolver now selects full three-lane Jump/Slide gates: one active puddle/laundry cue plus two crates. Left/Right patterns can have two crates and one open safe lane by design. | Improve apparent variety and the safe lane's visual legibility without filling it with a deceptive hazard or adding reaction pressure. |
| World | Five journey landmarks already exist (Home, Waiting Shed, Sari-sari Store, Palengke Approach, Barangay Plaza). Building plates stay fixed; road seams and small clouds/plants/people animate. The old moving-building system is hidden because it misaligned. | Give a clearer sense of forward travel with grounded, authored side movement or milestone transitions; retain fixed road/Hall and a static fallback. |
| Alignment | `road_projection.gd` owns lane projection; `l01_visual_geometry.gd` represents painted curb geometry. Existing tests cover some prompt clearance and stage-life scale. | Establish one measured native-pixel composition/anchor contract for every stage and all prompt approach depths. |
| Visual finish | Current captures show detailed stage plates, but native-size prompt guidance is small and character/prop finish differs from the painted world. Some animated side details look underscaled. | Prioritize action word/icon/prop clarity; then reconcile Peter, props, shadows, residents, and scenery at their actual on-screen depth. |
| Settings | `GameSettings.visual_pace` is 0.85/1.0/1.15 for scenery/road motion only; prompt timing is unchanged. Reduced Motion and effect intensity exist. Setup currently applies one target count to all four actions. | Clarify the label as visual/scenery motion, offer predictable comfort controls, and consider per-action targets only after therapist workflow approval. |
| Audio | Original gameplay ambience and distinct Jump/Slide cues were added after the local v9 ZIP. Automated routing/mute/Pause tests pass; target-speaker listening is unverified. | Mix and accessibility review, then build a new package rather than assuming v9 contains these sounds. |
| Release/docs | `code/export_presets.cfg` uses `all_resources` and does not exclude `art/_references/`; `code/README.md` still says gameplay has no music and describes older art. Last recorded full test sweep was 71/71 after the audio change, with non-failing shutdown warnings. | Audit packaged resources, update documentation, verify a clean-machine Windows build and real hardware before any release-readiness claim. |

Reference evidence: `test_evidence/l01_full_lane_action_cues/verification.md`, `test_evidence/l01_v15_stage_motion/`, and `test_evidence/gameplay_audio_v10/verification.md`. These are previous captures, not a fresh complete playthrough. The existing [stage-life scale plan](l01-stage-life-scale-alignment.md) and [roadside travel proposal](l01-roadside-travel-without-layout-loss.md) remain detailed design inputs; neither is already implemented merely because it is documented.

## Decisions required before changing behavior

1. **Contact and neutral misses:** reconcile the BRD/PRD prose, their explicit physical-contact requirement, the current implementation, and `Peter_Run_Project_Kit/docs/TEST_STRATEGY.md`. The strategy currently expects wrong/no-response continuation in UT-06/UT-07, E2E-02, its safety blocker, and its daily sweep, even when an occupied lane would cause contact in the current formation system. Write separate approved expectations for **non-contact miss** and **occupied-lane contact** (including preservation of completed repetitions), identify which old assertions/checklists are superseded, and update the strategy before using it as a release gate. Until then, retain existing behavior and do not claim that these contradictory checks pass.
2. **Repetition acknowledgment:** approve a visual distinction between immediate accepted movement and later recorded repetition. Do not count early, count twice, or shorten the prescribed response window to make the interface feel snappier.
3. **Therapist setup:** decide whether per-action repetition targets are wanted. This is a workflow/clinical choice, not merely a new control. Preserve current equal-target setup until approved.
4. **Comfort preferences:** decide whether audio/Reduced Motion/effect choices should persist between application launches. Do not persist patient/session details by accident.
5. **Visual acceptance:** approve one native-size reference composition and same-depth scale guide before producing a full new scenery set.

## Dependency map and delivery slices

`1 Baseline/decisions -> 2 Geometry contract -> {3 Prompt clarity, 4 Formation presentation, 5 Stage travel, 6 Art cohesion} -> 10 Integration QA`. Step 7 (whole-flow UI) follows the prompt hierarchy from Step 3; Steps 8 (settings) and 9 (audio/export configuration) can proceed after Step 1 in parallel with visual work, each with its own focused tests. Step 10 is the release gate. Each numbered step is a small reviewable implementation slice; do not bundle them into one giant art-and-code change. One integrator owns final L01 scene geometry.

### 1. Lock baseline, success measures, and clinical decision log — P0

**Fresh-implementer context:** Read `code/AGENTS.md`, `Peter_Run_BRD.md`, `Peter_Run_PRD.md`, `Peter_Run_Visual_Production/10_End_to_End_System_Flow.md`, `Peter_Run_Visual_Production/11_2_5D_Originality_Standard.md`, this plan, `runner_level_controller.gd`, `formation_collision_resolver.gd`, and the three evidence folders above. Do not overwrite the dirty worktree.

**Work:** Capture current L01 at 480 x 270, 960 x 540, 1024 x 768, and 1920 x 1080: all five stages, each action/formation, accepted-but-not-yet-counted state, non-contact miss, physical contact, Pause mid-action, and Reduced Motion. Record exact branch/commit, Godot version, test counts, capture paths, and known limitations. Ask the therapist/product owner to settle the five decisions above; mark unapproved items blocked, not tacitly approved. Reconcile the affected `TEST_STRATEGY.md` unit, E2E, blocker, and daily-sweep assertions with the approved contact policy; preserve completed repetitions for review after a contact. Define measurable prompt legibility, curb clearance, anchor drift, side-occupancy, and pause criteria.

**Verification/exit:** A baseline evidence index and signed decision log exist. The approved test strategy distinguishes non-contact misses from occupied-lane contacts and names every superseded assertion; if no decision is available, the conflict is clearly marked unresolved and release/UAT remains gated. A reviewer can identify what changes visually, what behavior is frozen, and what remains undecided. No gameplay behavior is changed.

**Rollback/model:** Documentation only; default engineering with product/therapist review.

### 2. Establish a single L01 composition and anchor contract — P0

**Context:** Read `road_projection.gd`, `l01_visual_geometry.gd`, `world_motion_controller.gd`, `runner_level.tscn`, `l01_stage_street_life.gd`, and both existing visual plans. The previously hidden `RoadsideMotion` must stay hidden unless a new aligned system passes review.

**Work:** Measure the active painted road/curb at several y/depth positions across all five stage plates. Record three lane centres, visible curb edges, prompt centre and width envelopes from distant spawn through contact, Peter's feet/shadow, HUD/Pause exclusions, and roadside contact/attachment origins in native pixels. Compare painted and projected coordinates instead of assuming they match. Give every candidate side sprite visible-alpha bounds over *all* frames, a same-depth scale target, and a parent/contact anchor. Create a guide overlay and deterministic geometry/clearance tests; do not move gameplay lanes to fit art. Accept at most 1 native pixel of attachment drift and at least 2 native pixels of curb clearance for decorative art unless the measured guide requires a larger safety margin.

**Verification/exit:** Native-pixel guide and tests cover every stage, three lanes, and far/mid/contact prop depths at all requested output sizes. Any painted/projected mismatch is resolved explicitly or recorded as a blocker before new art integration. Existing `l01_prompt_visual_clearance_test.gd`, `l01_stage_life_scale_test.gd`, and `motion_perspective_upgrade_test.gd` still pass.

**Rollback/model:** Keep existing stage plates and projection constants as fallback; strongest visual/geometry review.

### 3. Make active prompts and response feedback instantly legible — P0

**Context:** Read `runner_level_controller.gd`, `prompt_director.gd`, prompt scenes/art, `code/scenes/player.tscn`, and the 480 x 270 formation captures. The active prompt must remain the visual priority over the Hall, market, HUD, and decorative residents.

**Work:** Enlarge/simplify the action word, icon, and hint hierarchy at native size, and quiet the immediate background only where needed. Make warning, response, accepted movement, and contact resolution visually distinct without changing the timers or adding countdown pressure. Keep one active prompt, visible Pause, and action-specific world silhouettes. Check that early Jump/Slide movement begins immediately while its later repetition acknowledgment is understandable. Measure the 0.35-second input cooldown and press/release handling with keyboard and supported controller signals before proposing any input-timing change. Keep neutral feedback gentle; any miss/contact wording change waits on Step 1 approval.

**Verification/exit:** Focused tests such as `prompt_visual_contact_timing_test.gd`, `l01_prompt_test.gd`, `formation_response_integrity_test.gd`, `input_adapter_test.gd`, and `pause_motion_test.gd` pass. Native-size captures show readable action, icon, and keyboard/controller hint before contact; one accepted action never yields an extra rep. Pause freezes the same visual state.

**Rollback/model:** Version prompt art/theme and retain current UI resources; default engineering plus native-size visual review.

### 4. Polish formation variety and depth presentation — P1

**Context:** Read `pattern_library_resolver.gd`, `code/data/levels/l01_barangay.tres`, `world_motion_controller.gd`, formation collision rules, and the six full-lane captures. Full-lane Jump/Slide gates are already implemented; do not reintroduce sparse fallback.

**Work:** Audit the actual generated sequence for all four targets, reachability from each lane, balanced repetition opportunities, and how often the same arrangement repeats. Refine art/projection so puddle, laundry opening, and crates grow smoothly from small to contact size with stable ground shadows and no left/right roadside overlap. If the lateral safe lane looks empty, use a clearly non-obstacle surface/route cue only; do not place a fake active puddle/crate there. Keep dynamic combinations readable, one requested action at a time, and the established response windows. No new collision rules without the Step 1 decision.

**Verification/exit:** Seeded pattern tests (`l01_formation_expansion_test.gd`, `l01_new_formation_integration_test.gd`, `formation_collision_resolver_test.gd`, `formation_response_integrity_test.gd`) cover every lane and target-exhaustion case. Captures at far/mid/contact depths show no curb, sidewalk, or active-prop overlap. One valid action maps to only its intended repetition.

**Rollback/model:** Keep current v9 formation data and prop sprites selectable; normal engineering and art review.

### 5. Add grounded travel and stage life without sliding the whole street — P1

**Context:** Read `l01_layered_route_motion.gd`, `l01_stage_street_life.gd`, `world_motion_controller.gd`, and the two existing visual plans. The current five fixed stage plates already change with repetition progress; only road marks and small ambient details move continuously.

**Work:** First prototype one stage with an authored, perspective-matched roadside pass-by or short milestone transition outside the curbs. Keep the road, lane geometry, Hall, sun, player, props, and HUD anchored. Preserve dense, inhabited side occupancy; no duplicate baked people/buildings or broad empty verges. Attach cloth, signs, window glints, leaves, and shadows to their correct frontage; calibrate their visible size against same-depth painted neighbours. Use the existing world-motion clock for decorative travel, with calm staggered timing. Pause freezes every clock and tween immediately; Reduced Motion holds a complete, aligned still scene. Expand to other stages only after the one-stage first-frame/loop/transition composite is approved.

**Verification/exit:** Tests for attachment, stage reveal, no curb intrusion, Pause/Resume, and Reduced Motion pass (`l01_v15_stage_motion_test.gd`, `l01_stage_life_scale_test.gd`, `l01_static_buildings_restore_test.gd` plus new focused tests). Record a full motion/recycle cycle and all five stage transitions at native size; no pop, floating foot, ghost, clipping, or detached building. If the clean plate/side art is not convincing, keep the static fallback and stop this slice.

**Rollback/model:** Preserve existing plates and hidden travel fallback; strongest art/geometry review, default motion integration.

### 6. Unify Peter, prop, and environment finish — P1

**Context:** Read current Peter runtime scene/art, prompt art, contact effects, and the stage-life scale plan. Review at the actual native-canvas character size, not only enlarged source images.

**Work:** Establish one palette, directional light, edge/outline, texture density, and contact-shadow guide. Correct underscaled/mismatched residents and animated props by visible alpha footprint and depth, not a universal multiplier. Keep Peter's adult, respectful back-facing design and existing action timing; refine landing ring/dust, lane trail, slide dust, and jump shadow only where they improve contact clarity. No new gameplay hitbox or exaggerated/fail pose. Keep versioned source and runtime exports separate, and inspect every animation frame for anchor drift and haloing.

**Verification/exit:** Rest, run, left/right, Jump, Slide, Pause, and stage-detail captures show coherent lighting and stable contact at 480 x 270. Existing player, movement, prompt art, and visual-clearance tests pass; no active cue is obscured. Full-frame contact sheets and provenance are stored with the art work.

**Rollback/model:** Retain previous Peter/prop textures and scene references; strongest visual review.

### 7. Make the full session UI coherent and readable — P1

**Context:** Read opening dashboard, patient setup, controller check, tutorial, Ready, Pause, end/review, and summary scenes/controllers, plus the current compact theme. This is a visual/usability slice, not a new therapy flow. Step 3 owns the active in-game prompt hierarchy.

**Work:** Inspect every screen at 960 x 540, 1024 x 768, and 1920 x 1080. Bring typography, button hierarchy, focus states, spacing, and image/card finish into one calm system. Keep the dashboard inviting, setup choices explicit, tutorial instructions easier to scan than decoration, Pause and End immediately visible, and summary informative without score-like emphasis. Check keyboard/controller hints against actual mappings and inspect long labels/letterboxing. Use original image-backed UI art only where it improves clarity; do not replace a readable control with a decorative raster. Do not alter session navigation, clinical copy, or repetition meaning without the Step 1 decision.

**Verification/exit:** Existing `setup_screens_layout_test.gd`, `ui_theme_pass_test.gd`, tutorial, summary, and Pause tests pass, with new layout assertions only where needed. A human can follow the complete flow at the three output sizes without clipped text, obscured actions, or competing calls to action. The gameplay prompt remains more prominent than the HUD.

**Rollback/model:** Keep existing theme and scene resources as fallback; visual/UI design review plus default engineering.

### 8. Clarify comfort settings and therapist setup — P1, partly decision-gated

**Context:** Read `main_dashboard.gd`, `game_settings.gd`, `menu_audio_settings.gd`, `patient_setup_controller.gd`, `session_setup_store.gd`, setup/pause scenes, and `SessionConfig`. Route pace currently changes visual motion only, not prompt cadence.

**Work:** Rename/explain the visual-only pace control as scenery motion and give a restrained live preview, if this helps users understand it. Check Reduced Motion against every ambient layer and transition. Consider an in-Pause audio mute/volume control while retaining immediately responsive Resume/End. Persist only comfort preferences if Step 1 approves; keep patient/session data session-local. Design optional per-action targets as a separate therapist-reviewed slice; preserve equal-target default and existing setup until approved. Ensure there is no new urgency or misleading difficulty control.

**Verification/exit:** `game_route_settings_test.gd`, `controls_settings_test.gd`, `session_setup_flow_test.gd`, `pause_motion_test.gd`, and new persistence/per-action tests where applicable pass. Visual pace changes only scenery/road motion, not prompt windows, repetition count, collisions, or action acceptance. All settings remain legible in setup and Pause at 960 x 540 and 1024 x 768.

**Rollback/model:** Keep current session-local settings and equal-target setup as fallback; default engineering, therapist review for target workflow.

### 9. Finish audio, documentation, and export configuration — P1

**Context:** The source after commit `9ee665f` has Jump/Slide cues; the existing v9 ZIP predates them. Read `code/art/audio/README.md`, `gameplay_audio_test.gd`, `export_presets.cfg`, `code/README.md`, and release scripts before packaging.

**Work:** Listen on available target speakers to ambience, action cues, Pause/Resume, and menu-to-game transitions; adjust mix only with original/licensed sound sources. Verify shared mute/volume in a local graphical run. Audit resource references and the current PCK manifest, especially `art/_references/`, tests, tools, and source-only assets; tighten export configuration without breaking imported runtime resources. Update the stale README to distinguish current implemented L01, hidden developer routes, sound behavior, and unverified claims. Do **not** create the final candidate here: this slice prepares a verified export configuration for Step 10.

**Verification/exit:** `gameplay_audio_test.gd` and project smoke pass; the resource audit documents which files are required, excluded, and why, with an export-config dry run or manifest check where practical. Human listening results and limitations are recorded. The clean-folder package test is intentionally deferred to Step 10; no claims about MOVE hardware, therapist acceptance, or clinical suitability without direct evidence.

**Rollback/model:** Keep existing audio files and v9 ZIP; default engineering plus human audio review.

### 10. Full integration, usability, and release gate — P0 final gate

**Context:** This step starts only when selected earlier slices have passed their own gates. Read the current project test strategy and all slice evidence. Run the full flow: dashboard -> setup -> optional controller check/tutorial -> ready -> gameplay -> Pause/Resume -> end/review -> summary -> retry.

**Work:** First run all top-level Godot tests, affected graphical capture helpers, and a human playthrough with each formation and five journey stages. Capture 480 x 270, 960 x 540, 1024 x 768, and 1920 x 1080, plus brief motion evidence. Test accepted-before-contact feedback, both lane directions, Jump/Slide, neutral non-contact miss, occupied-lane physical contact under the approved rule, Pause mid-transition, Reduced Motion, restart, and session end. Check against the **reconciled** test strategy, not contradictory legacy assertions. Inspect prompt legibility, stage alignment, no clipping/white backgrounds, steady frame time, audio comfort, and no visual movement during Pause. **Then** create a distinctly named candidate package from the integrated source; launch that package from a clean folder, inspect its contents and hash, and repeat the critical flow on the exported build. Test the target Windows device, real controller, and speakers separately; clearly mark anything not exercised. Update `test_evidence/` and the release notes with exact commands/results and known defects. Never overwrite v9.

**Verification/exit:** Source checks pass before export; the newly created candidate then passes clean-folder launch/resource/audio checks and a critical-flow replay. All relevant automated checks pass or have explicit, reviewed exceptions against the approved policy; actual captures and playthrough support the visual claims; clinician/UAT sign-off is recorded separately if performed. A new preview is labeled a prototype until the target-device and therapist gates pass. The previous package remains recoverable.

**Rollback/model:** Revert individual versioned scene/asset references or ship the prior preview; strongest integration and human visual review.

## Execution and change control

- Do not modify repetition logic, input mapping, response timing, collision policy, or clinical wording as a side effect of art work. Logic changes require the smallest failing deterministic test first, then implementation and an affected-scene check per `code/AGENTS.md`.
- Run focused tests from `code/` with `godot --headless --path . -s res://tests/<test_name>.gd`; also run `res://tests/project_setup_smoke.gd`. Record the exact executable/version and exit code. A full top-level test sweep must be rerun after integration; the previous 71/71 result is only a baseline.
- For visual work, compare native 480 x 270 captures first. Then inspect 960 x 540, 1024 x 768 letterboxing, and 1920 x 1080. Include far/mid/contact prop depths, every stage, widest animation pose, Pause, and Reduced Motion. Pixel tests are not a substitute for human legibility review.
- Use a separate branch/review for each implementation slice if the team wants PRs; this document itself creates no branch, commit, PR, or release. Preserve existing uncommitted and untracked work. Do not delete or overwrite source art or old packages to make a new build fit.
- If an exit gate fails, return to the responsible art/geometry/logic slice rather than relaxing the three-lane, prompt, pause, or clinical constraints. Record any split/merged/dropped step and why in this file before proceeding.

## Priority summary

First: resolve clinical wording/acceptance and measure the composition (Steps 1-2). Next: make prompt action and prop approach unmistakable (Steps 3-4). Then: add grounded life/travel and unify visual finish (Steps 5-6). Whole-flow UI follows prompt hierarchy (Step 7); settings and audio/export cleanup can progress after the baseline (Steps 8-9). Only then perform the integrated release gate (Step 10).

## Progress record — 2026-10-17

- **Step 1 partial:** A fresh three-size screen-flow baseline and focused test record are in `test_evidence/experience_revamp_baseline/verification.md`. The contact/miss policy and test-strategy conflict remain unapproved; no clinical behavior or wording was changed.
- **Step 2 baseline:** The first capture recorded the painted/projected curb gap and separate prompt/Peter ground anchors; the measured five-stage guide below now supersedes that preliminary note.
- **Step 2 measured guide (2026-10-18):** `plans/l01-five-stage-composition-contract.md`, `l01_composition_contract_test.gd`, and 20 stage/size guide overlays now record the five road masks, painted/projected mismatch, three lanes, HUD exclusions, Peter/prompt anchor separation, and far/mid/contact active-prop envelopes. The y=112 PNG-transparent far-zone exception is explicit. This does not approve moving buildings; candidate art must still pass native-size alpha/attachment and full-cycle review.
- **Step 5 art gate not passed (2026-10-18):** An exact Home clean plate can be composited from existing layers, but it has empty side fields. An image-generated full clean-plate edit changed the Hall/road geometry and was rejected. One transparent left-side frontage was previewed at three curb-anchored depths; it leaves a blank verge as it exits. Both candidates remain source/evidence only. The fixed stage stays active; no motion or gameplay code was enabled.
- **Step 3 partial:** The native action word increased from 8 to 11 px and state/control text moved to a non-overlapping second row within the original card height. A failing regression test preceded the scene edit; final 480 x 270 formation captures exist. Other warning/accepted/resolution feedback refinements remain open.
- **Step 8 partial:** Settings now names the visual-only control `Scenery motion` and visibly says prompt timing is unchanged. The reviewed settings card is 187 native pixels high with original control spacing; no visual pace, prompt, or repetition values changed. Other comfort/setup decisions remain open.
- **Integration check, not release gate:** 73/73 top-level Godot scripts passed after the edits, with 38 non-failing shutdown warning/error lines. Final UI/formation screenshots and details are in `test_evidence/experience_revamp_final/verification.md`. No Windows export, hardware, target-speaker, therapist, or UAT verification was done.
