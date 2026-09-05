# PETER RUN — Godot Project Rules

This `code/` folder is the Godot 4 project root. Before changing gameplay, read:

1. `../Peter_Run_BRD.md`
2. `../Peter_Run_PRD.md`
3. `../Peter_Run_Visual_Production/10_End_to_End_System_Flow.md`
4. `../Peter_Run_Visual_Production/11_2_5D_Originality_Standard.md`
5. `../Peter_Run_Project_Kit/docs/BUILD_QUEUE.md`
6. `../Peter_Run_Project_Kit/docs/TEST_STRATEGY.md`

## Non-negotiable rules

- Use Godot 4, GDScript, 2D and the Compatibility renderer.
- Build a 2D 2.5D forward-lane illusion with sprite layers and parallax; do not add 3D scenes or cameras.
- Keep the base canvas at `480 × 270`; preserve crisp pixel-art scaling.
- Use only named actions: `move_left`, `move_right`, `jump`, `slide`, `pause_session`.
- The ESP32 controller must reach Godot as a debounced HID keyboard action. Godot gameplay must never parse raw sensor values.
- Menus use mouse/trackpad. The gameplay movement controls are not menu navigation controls.
- Show one active prompt at a time. A prompt needs an icon, word, and distinct world-prop silhouette.
- Missed prompts are neutral. Never add health, collision damage, a chase, score loss, or a game-over state.
- Pause must remain visible and freeze gameplay immediately.
- Use original Filipino routes, props, HUD, character and animation. Do not use copied commercial-runner assets, branding, designs, characters, sounds, tracks, trains, guards, coins, hoverboards, chase logic, or names.

## Test-first requirement

For logic changes, add or update the smallest deterministic test first, observe a real failure where practical, implement the smallest fix, rerun it, then run the affected Godot scene. Record only actual results in `../test_evidence/`.

Run the foundation check when Godot is installed and available in the terminal:

```text
godot --headless --path . -s res://tests/project_setup_smoke.gd
```
