# PETER RUN — Godot Project

This is the Godot 4 project root for the PETER RUN Windows desktop prototype.

## Current setup

- Original 2D forward-lane runner with a 2.5D parallax illusion, Compatibility renderer, and `480 × 270` base canvas.
- Development Input Map: `A` Move Left, `D` Move Right, `W` Jump, `S` Slide, `P` Pause.
- ComfyUI reference folders exist under `art/_references/`; they are not runtime game assets.
- `scenes/main.tscn` opens the menu, followed by Patient Setup, Controller Check, Tutorial, Ready, and L01.
- PR-10B adds continuous perspective travel, lane-aware props, neutral exit fades, running/landing feedback, and animated repetition progress. The current character and environment remain prototype geometry.

## Verify after opening Godot

1. Open this `code/` folder in Godot 4.
2. Press **F5**; choose **Start Session**, configure the session, continue through Controller Check and Tutorial, then choose **Start L01 Session**. F6 runs only the selected scene.
3. Open **Project → Project Settings → Input Map** and confirm the five named actions.
4. If `godot` is available in a terminal, run:

```text
godot --headless --path . -s res://tests/project_setup_smoke.gd
```

## ComfyUI use

1. Generate a reference only for **L01 Barangay Morning** first.
2. Save the PNG reference to `art/_references/l01_barangay/`.
3. Save the matching prompt in `art/_references/comfyui_prompts/` and workflow JSON in `art/_references/comfyui_workflows/`.
4. Rebuild approved final pixel assets in Krita/Pixelorama before importing them into runtime folders such as `art/backgrounds/`, `art/prompts/`, or `art/tilesets/`.

Use [the project ComfyUI workflow](../Peter_Run_Visual_Production/05_ComfyUI_Concept_Workflow.md) for required prompt, licensing, and approval rules.

## Next build unit

The Tutorial is now a playable four-step practice area. Follow the displayed keyboard hint, try the highlighted movement, then choose Next. Repeat resets the current lesson; Skip bypasses practice. Pause (button or P) freezes the character. The tutorial shares `scenes/player.tscn` and the affected-side input adapter with gameplay, but does not record session repetitions or misses. Verify with `res://tests/guided_tutorial_test.gd`.

**PR-12: LevelDefinition data resources** is implemented locally. Next is **PR-13: L02–L05 content resources and level selection**; final art integration remains PR-14.

## Data-driven levels (PR-12)

Normal F5 play still starts L01. Its title, planned sequence, three prop-scene references, environment palette, optional background texture and existing timing values now come from [l01_barangay.tres](data/levels/l01_barangay.tres). The runner no longer selects L01-specific props in code.

To author another level:

1. Duplicate the L01 resource, give it a unique `level_id`, a short `short_name`, and a readable `title`.
2. Assign `move_prop`, `jump_prop` and `slide_prop` to original Node2D-rooted scenes. Put their visual ground contact near the local origin, matching the existing props. Left/right share the movement prop; icons and action labels stay consistent across themes.
3. Edit the `sequence`, covering all four named actions so every prescribed target remains reachable. The sequence repeats after misses until the session targets are met.
4. Set the four environment colours. An optional `background_texture` is placed at the native origin behind hills and road; use a 480×270 image. Full layered parallax/final-art work is still PR-14.
5. Retain timing at **2.5s warning / 2.0s response / 0.75s resolution**. Validation rejects changes to this baseline, missing props, non-2D roots, missing identity or incomplete/unknown actions. Themes cannot silently increase reflex demands.
6. Add the resource to `data/levels/catalog.tres`. Selecting its ID in `SessionConfig` uses the same runner, Ready and Summary. The normal setup UI remains L01-only until PR-13.

Therapist-configured repetition targets remain in `SessionConfig`; level resources do not overwrite them. The current fixed road pace and movement animation are unchanged. Each run creates its prop instances once and reuses them. Review/retry retain a snapshot of the selected definition.

`tests/fixtures/alternate_level.tres` is a developer-only Courtyard Test configuration, not an implemented L02 or a clinically approved exercise set. It changes order, colours and the jump prop and is deliberately absent from the production catalog.

```text
godot --headless --path . -s res://tests/level_definition_test.gd
godot --path . --rendering-method gl_compatibility -s res://tests/support/capture_level_resources.gd
```

The second command renders both configurations, saves screenshots under `../test_evidence/pr12_*.png`, and closes automatically. Invalid selected resources disable Start on Ready; a directly launched invalid runner freezes and retains an exit through Review → Finish.

Internal migration: the world mount is now `LevelWorld/PromptWorldAnchor/PromptProps`; capture helpers use `_show_prompt`. `l01_prompt_catalog.gd` is a compatibility facade over the L01 resource for existing tests, not a second source of level rules.

## Session review (PR-11)

Completing the configured targets opens the completion overlay. Choose **Review Summary** to see actual completed/planned counts for all four movements and neutral misses.

- Ending a level/session from Pause first asks for confirmation. **Keep paused** cancels without resuming; **End & review** retains partial results and opens the end overlay.
- Select an effort rating from **1–10** with the mouse. No rating is preselected. This is the simplified in-game scale, not a validated clinical assessment or clearance to continue.
- **Rest** stays on the summary indefinitely; there is no countdown or automatic restart.
- After a rating is recorded, **Retry L01** restores the reviewed settings and opens **Ready**. The therapist must explicitly start again; the new run has fresh counters and no inherited rating.
- **Finish** returns to Main Menu. **Finish without rating** remains available if no rating was entered; the model keeps `rpe = 0` to represent unrecorded effort.
- Only the latest completed/ended run is retained in memory, including its settings, rating and latest decision. Closing the application loses it; the next ended run replaces it. There is no database, export, history browser or patient identifier in this slice.

Quick manual test: **F5 → Start Session → setup/check/tutorial → Start L01 Session → Pause → End Session → End & review → Review Summary**. Try a rating, Rest, and Retry; confirm Retry waits at Ready. Repeat and use Finish without rating.

```text
godot --headless --path . -s res://tests/session_summary_flow_test.gd
godot --path . --rendering-method gl_compatibility -s res://tests/support/capture_session_summary.gd
```

The second command opens an auto-closing graphics preview and saves layout captures to `../test_evidence/`.

## Verify runner polish

Menus now use compact centred panels and a shared teal button theme. The gameplay HUD is 38 native pixels tall (previously 53). Patient Setup shows both repetitions per action and the total session target.

Successful responses rotate brief encouragement toasts, with recognition at ten-movement milestones. Misses show neutral feedback. Only one toast exists; it dismisses automatically, ignores mouse input, freezes/hides on Pause, resumes with its remaining time, and clears on session end. Run `res://tests/feedback_toast_test.gd` for these behavior checks.

```text
godot --headless --path . -s res://tests/runner_polish_test.gd
godot --headless --path . -s res://tests/presentation_motion_test.gd
godot --headless --path . -s res://tests/pause_motion_test.gd
godot --headless --path . -s res://tests/session_progress_test.gd
```

With a graphics display, `godot --path . -s res://tests/support/capture_runner_polish.gd` saves actual 1920x1080 and 480x270 frames in `../test_evidence/` and closes automatically. It is a developer capture utility, not a normal game entry point.

During a playtest, watch an unanswered prop approach and pass, try a matching action during MOVE NOW, and pause during a lane change or prompt fade. Confirm that all motion freezes and resumes smoothly. Repetitions measure progress toward the configured targets; there is no competitive score or endless speed escalation.

Movement tuning: the shared player now jumps 50 native pixels with a 0.24s rise, 0.06s apex hold and 0.32s descent. Lane changes use a responsive 0.22s ease-out. A short landing ring, landing compression, lane trails and paired roadside markers provide motion cues. Prompt warning/response timing is unchanged. `movement_feel_test.gd` verifies these cues and their pause behaviour; `tests/support/capture_movement_feel.gd` renders developer screenshots.
