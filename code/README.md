# PETER RUN — Godot Project

This is the Godot 4 project root for the PETER RUN Windows desktop prototype.

## Current setup

- Original 2D forward-lane runner with a 2.5D parallax illusion, Compatibility renderer, and `480 × 270` base canvas.
- Input Map: keyboard `A` Move Left, `D` Move Right, `W` Jump, `S` Slide, `P` Pause; standard gamepad D-pad Left/Right, A Jump, B Slide, Start Pause. A MOVE controller is supported when its firmware sends the same debounced HID keyboard actions.
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

## Opening dashboard and menu music

F5 now opens an original code-drawn Barangay Morning welcome screen with an animated prototype character and a short panel fade-in. **Start Session** retains the existing supervised setup flow; **Tutorial** opens practice. **Settings** offers menu music, a compact keyboard/controller support guide, **Check controller**, and **Session settings**. **Quit** asks for confirmation.

The game accepts both keyboard and a compatible standard gamepad through the same named actions. Keyboard remains the reliable development fallback. A connected gamepad uses D-pad Left/Right, A to Jump, B to Slide, and Start to Pause. The MOVE controller must be validated separately: its firmware should emit debounced HID A/D/W/S/P presses and releases; the game does not parse raw sensor data. Use **Settings -> Check controller** to see whether a compatible gamepad is detected before a session.

**Music: On/Off** toggles the original 20-second synthesized instrumental, *Hakbang sa Umaga*. Settings provides a 0–100% volume slider with a bounded output gain. Music fades in on the opening and stops when leaving it; no music was added to gameplay or practice. Mute and volume persist only while the application is running, not across restarts. Adjust the operating-system/device volume for comfortable listening.

This is a plucked-string-style prototype, not a recorded rondalla ensemble, national anthem, final mastered soundtrack, or clinically approved audio asset. See [audio provenance and rebuild instructions](art/audio/README.md). The environment is original procedural geometry; final character/background art remains separate work. No additional routes, difficulty tiers or level selector were added.

```text
godot --headless --path . -s res://tests/opening_dashboard_test.gd
godot --path . --rendering-method gl_compatibility -s res://tests/support/capture_opening.gd
```

The second command captures the opening at 1920×1080, 960×540 and 1024×768, plus its settings/quit panels, then closes. It preserves the 480×270 canvas and aspect ratio; non-wide windows have letterboxing. Screenshots are saved in `../test_evidence/`.

## Compact Barangay UI pass

The opening, setup, controller check, tutorial, Ready, review and overlays now share a cream card surface (`art/ui/menu_card.tres`) and a teal/cream control theme (`art/ui/compact_theme.tres`). Primary actions use `PrimaryButton`; secondary controls stay quieter. Session screens reuse the original code-drawn barangay background, and L01 uses a warmer resource palette. No new route or final raster artwork was added.

Measured card dimensions at 1920×1080 (480×270 base canvas unchanged):

| Screen | Card size |
| --- | --- |
| Opening | 776×648 |
| Settings / Quit | 720×464 |
| Patient Setup | 976×784 |
| Controller Check | 912×576 |
| Ready | 912×600 |
| Tutorial | 1280×904; retains the readable practice area |
| Pause | 688×440 |
| End confirmation / end review | 768×440 |
| Session review | 1200×832 |

The HUD band is 120 output pixels high, down from 152. A separate quiet footer keeps keyboard/miss labels readable against the brighter route. Regular button targets are 64–80 pixels high at the 1080p output; rating targets are 72 pixels high. Smaller windows preserve the aspect ratio and proportionally scale the interface, so these are not guaranteed physical-pixel minima at every window size.

Patient Setup now uses horizontal **− / +** repetition buttons instead of tiny vertical arrows. The underlying SpinBox/Range and `value_changed` contract remain intact, with the existing 10–15 bounds. Direct text entry is replaced by mouse-operated stepping. The tutorial's action instruction remains larger than its utility buttons; all practice, demonstration, pause and skip routes remain available.

```text
godot --headless --path . -s res://tests/ui_theme_pass_test.gd
godot --path . --rendering-method gl_compatibility -s res://tests/ui_theme_pass_test.gd -- --capture
```

The test verifies card-size caps, shared surfaces, visible control bounds, button targets, pointer routing for repetition changes, and rated/resting review states at 1920×1080, 960×540 and 1024×768. The graphics variant saves `../test_evidence/ui_theme_*.png` and closes automatically. These checks do not substitute for user readability or clinical review.

## ComfyUI use

1. Generate a reference only for **L01 Barangay Morning** first.
2. Save the PNG reference to `art/_references/l01_barangay/`.
3. Save the matching prompt in `art/_references/comfyui_prompts/` and workflow JSON in `art/_references/comfyui_workflows/`.
4. Rebuild approved final pixel assets in Krita/Pixelorama before importing them into runtime folders such as `art/backgrounds/`, `art/prompts/`, or `art/tilesets/`.

Use [the project ComfyUI workflow](../Peter_Run_Visual_Production/05_ComfyUI_Concept_Workflow.md) for required prompt, licensing, and approval rules.

## Current focus — one route, clearer practice

The Tutorial is now a playable four-step practice area. Follow the displayed keyboard hint, try the highlighted movement, then choose Next. Repeat resets the current lesson; Skip bypasses practice. Pause (button or P) freezes the character. The tutorial shares `scenes/player.tscn` and the affected-side input adapter with gameplay, but does not record session repetitions or misses. Verify with `res://tests/guided_tutorial_test.gd`.

**PR-12: LevelDefinition data resources** is implemented locally. **PR-13, additional themes and the level selector are deferred by user direction (2026-09-07).** Keep Start Session → Setup → Controller Check → Tutorial → Ready → Barangay Morning. There are no difficulty tiers, unlock requirements or automatic progression.

Setup labels Barangay Morning as the **route**. Future route selection, if resumed, chooses an environment rather than a difficulty; therapist-controlled repetition settings remain separate. The data-resource architecture stays intact.

Tutorial polish: **Show me** plays one visual example of the current action, then returns the character to the starting pose. Watching never acknowledges a lesson or records repetitions. The player must still try the highlighted action before Next is enabled. Pause freezes the demonstration and its return timer; Skip/Back remain available. No automatic demonstration loop or timed practice challenge was added.

Test: `godot --headless --path . -s res://tests/tutorial_demo_test.gd`. For a quick visual check, open How to Play, select Show me, pause/resume the example, then try the movement yourself.

## Data-driven levels (PR-12)

Normal F5 play still starts L01. Its title, planned sequence, three prop-scene references, environment palette, optional background texture and existing timing values now come from [l01_barangay.tres](data/levels/l01_barangay.tres). The runner no longer selects L01-specific props in code.

To author another level:

1. Duplicate the L01 resource, give it a unique `level_id`, a short `short_name`, and a readable `title`.
2. Assign `move_prop`, `jump_prop` and `slide_prop` to original Node2D-rooted scenes. Put their visual ground contact near the local origin, matching the existing props. Left/right share the movement prop; icons and action labels stay consistent across themes.
3. Edit the `sequence`, covering all four named actions so every prescribed target remains reachable. The sequence repeats after misses until the session targets are met.
4. Set the four environment colours. An optional `background_texture` is placed at the native origin behind hills and road; use a 480×270 image. Full layered parallax/final-art work is still PR-14.
5. Retain timing at **2.5s warning / 2.0s response / 0.75s resolution**. Validation rejects changes to this baseline, missing props, non-2D roots, missing identity or incomplete/unknown actions. Themes cannot silently increase reflex demands.
6. Add the resource to `data/levels/catalog.tres`. Selecting its ID in `SessionConfig` uses the same runner, Ready and Summary. Normal setup remains Barangay Morning-only; adding routes and a selector is currently deferred.

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

Session and pause menus use compact centred cream panels and a shared teal control theme; the opening uses a left-side welcome card. The gameplay HUD band is 30 native pixels tall (previously 38). Patient Setup shows both repetitions per action and the total session target.

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
