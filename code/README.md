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

Next is **PR-11: Summary, RPE and therapist decision**. PR-10B is the intermediate motion/HUD polish slice; final art integration remains PR-14.

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
