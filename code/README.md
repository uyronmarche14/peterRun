# PETER RUN — Godot Project

This is the Godot 4 project root for the PETER RUN Windows desktop prototype.

## Current setup

- Original 2D forward-lane runner with a 2.5D parallax illusion, Compatibility renderer, and `480 × 270` base canvas.
- Development Input Map: `A` Move Left, `D` Move Right, `W` Jump, `S` Slide, `P` Pause.
- ComfyUI reference folders exist under `art/_references/`; they are not runtime game assets.
- `scenes/main.tscn` is a foundation screen only. It is not yet the final main menu or clinical build.

## Verify after opening Godot

1. Open this `code/` folder in Godot 4.
2. Run `scenes/main.tscn`; confirm the PETER RUN foundation screen appears at a crisp 16:9 scale.
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

Implement `PR-01`: pure `SessionConfig` and `SessionResult` data models with deterministic tests. Do not begin the five final levels before the L01 gameplay loop is safe and testable.
