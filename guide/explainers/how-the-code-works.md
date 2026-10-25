# How the Code Works

For a developer opening the project for the first time. Read [How the Game Works](how-the-game-works.md) first for the flow and rules, then use this page to find your way around the code.

## Ground rules (from `code/AGENTS.md`)

- Godot 4, GDScript, 2D, **Compatibility** renderer. No 3D scenes or cameras.
- Base canvas **480 × 270**, crisp pixel scaling.
- Only the named actions `move_left`, `move_right`, `jump`, `slide`, `pause_session`.
- The controller reaches Godot as HID keyboard actions. Gameplay **never** parses raw sensor values.
- Left and Right stay literal. Affected side is no longer collected in the UI.
- One prompt on screen at a time.
- Obstacle contact ends the run. Never add health, lives, score loss, a chase, or shaming language.
- Logic changes are **test-first**: add the smallest deterministic test, see it fail, fix, rerun.

## Project map

```text
peter_run/
├─ code/                  ← the Godot project (open this folder in Godot)
│  ├─ project.godot       input map, 480×270 canvas, main scene = scenes/main.tscn
│  ├─ scenes/             main · patient_setup · ready · tutorial · controller_check
│  │                      · session_summary · levels/runner_level · player · props · ui
│  ├─ scripts/            all GDScript (one script per scene or model)
│  ├─ data/levels/        catalog.tres + l01/l02/l03 level resources
│  ├─ art/                audio · backgrounds · characters · fonts · prompts · tilesets · ui · vfx
│  ├─ tests/              ~73 test scripts + support/ (screenshot capture helpers)
│  ├─ plans/              implementation trackers (PR-14, PR-16, pattern library)
│  └─ releases/           packaged Windows builds
├─ guide/                 ← this documentation
├─ Peter_Run_Visual_Production/   art specs, prompts, Blender sources
├─ Peter_Run_Project_Kit/docs/    build queue, status, test strategy
├─ electron-peterrun/     separate Electron wrapper
├─ controller_firmware/   ESP32 controller firmware (currently empty)
└─ test_evidence/         recorded real test output per PR
```

## Scenes and the scripts behind them

| Scene | Controller script | Role |
| --- | --- | --- |
| `main.tscn` | `main_dashboard.gd` | Opening, settings, music, quit |
| `patient_setup.tscn` | `patient_setup_controller.gd` | Side, reps, route |
| `controller_check.tscn` | `controller_check_controller.gd` | "Test your controls" |
| `tutorial.tscn` | `tutorial_controller.gd` | Guided practice |
| `ready.tscn` | `ready_screen_controller.gd` | Plan recap, Start |
| `levels/runner_level.tscn` | **`runner_level_controller.gd`** | **The game loop** |
| `session_summary.tscn` | `session_summary_controller.gd` | Review, game-speed choice, Retry/Rest/Finish |

Scenes switch with `get_tree().change_scene_to_file(...)`. Data crosses scenes through two small static stores:

- `session_setup_store.gd` → holds the current `SessionConfig` (set in Setup, read by the runner).
- `session_review_store.gd` → holds the finished `SessionConfig`, `SessionResult`, end reason and the user's decision (set when the run ends, read by the summary).
- `session_history_store.gd` → appends one counts-only line (time, route, end reason, reps done and planned, speed choice) to `user://session_history.json` when the review screen is left by Retry or Finish; can export a CSV and clear the history. No screen shows it yet.

## How a screen connects to code and assets

The Godot project root is `code/`, so a path beginning `res://` means a file inside that folder. These pieces have different jobs:

```text
project.godot (startup scene and input actions)
  -> scenes/*.tscn (node tree: visible controls, sprites, audio players)
       -> scripts/*.gd (button signals, state, scene changes, animation control)
       -> art/* (textures, fonts, UI styles, sounds used by those nodes)
  -> data/levels/*.tres (route data and references to reusable prop scenes)
       -> scenes/props/*.tscn -> art/prompts/*
```

The `.tscn` file declares external resources near its top (`[ext_resource ... path="res://..."]`) and assigns them to nodes later (`script = ExtResource(...)`, `texture = ExtResource(...)`, or `stream = ExtResource(...)`). The attached script finds those nodes with `@onready` paths, connects signals such as `button.pressed`, and changes what is shown. A `.tres` level resource supplies content and settings; it is not a screen by itself.

| What the player sees | Scene and controller | Main asset connection |
| --- | --- | --- |
| Opening dashboard and Settings overlay | `scenes/main.tscn` + `scripts/main_dashboard.gd` | `art/backgrounds/dashboard_barangay_morning_hero_v03.png`, shared UI styles/fonts, an instance of `scenes/player.tscn`, and opening music loaded by the script |
| Patient Setup | `scenes/patient_setup.tscn` + `scripts/patient_setup_controller.gd` | `art/backgrounds/ui_barangay_flow_v01.png`, `art/ui/` card/theme resources, and the live repetition controls |
| Controller Check | `scenes/controller_check.tscn` + `scripts/controller_check_controller.gd` | The same flow backdrop and UI styles; the input indicators are live controls, not words baked into the image |
| Tutorial | `scenes/tutorial.tscn` + `scripts/tutorial_controller.gd` | The flow backdrop, `art/ui/action_icons/*.svg`, and the same `scenes/player.tscn` used by gameplay |
| Ready | `scenes/ready.tscn` + `scripts/ready_screen_controller.gd` | The flow backdrop and live plan/Start controls |
| L01 gameplay, HUD and Pause overlay | `scenes/levels/runner_level.tscn` + `scripts/runner_level_controller.gd` | L01 stage sprites under `art/backgrounds/`, reusable prop scenes, player scene, HUD styles, and `art/audio/l01_*.wav` cues. Pause is an overlay **inside** this scene, not another scene file |
| Session Review | `scenes/session_summary.tscn` + `scripts/session_summary_controller.gd` | `art/backgrounds/ui_barangay_plaza_review_v01.png`, route-stamp atlas, shared UI styles, and live result/rating controls |

### One complete gameplay connection: the Jump puddle

1. `data/levels/l01_barangay.tres` defines the L01 formations and points its Jump prop to `scenes/props/puddle.tscn`. That prop scene points to the active puddle image, ripple, and highlight under `art/prompts/l01_barangay/`. Crates and the laundry line use their own reusable prop scenes in the same way.
2. `runner_level_controller.gd` loads the level data, chooses a reachable formation, and instantiates its prop scenes under `LevelWorld/PromptWorldAnchor/PromptProps` in `runner_level.tscn`. It updates the live prompt word, action icon, and control hint; `action_icon_library.gd` maps the action name to `art/ui/action_icons/`.
3. `world_motion_controller.gd` uses `road_projection.gd` to place and scale the prop as it approaches. This is a visual effect: the 2D prop does not decide whether the movement counts.
4. `runner_level_controller.gd` filters input through `input_adapter.gd`, then calls `player_controller.gd` for movement and `prompt_director.gd` to judge the response. The runner checks the formation at contact, updates `session_result.gd`, and triggers the matching sound and contact effect. Those rules are separate from the puddle image.

L01 scenery is another connection: `runner_level.tscn` contains five stage groups under `L01BarangayLayers`. `route_journey.gd` derives Home, Waiting Shed, Sari-sari Store, Palengke, or Plaza from completed repetitions; `l01_layered_route_motion.gd` reveals the matching sky, street, landmark, road, and small animated side details. Home uses `art/backgrounds/l01_home_v10_layers/`; later stages use `art/backgrounds/l01_journey_v11_layers/`. The older single-image `LevelDefinition.background_texture` is a fallback for non-L01 levels and is hidden while L01 layers are active. The old whole-building `RoadsideMotion` node is also hidden; buildings do not travel during normal L01 play.

Peter's visible art has its own chain: `scenes/player.tscn` attaches `player_controller.gd` and `classic_runner_sprite.gd`; the sprite script reads `art/characters/peter_adult_image_v04/animation_manifest.json` and selects fixed-frame regions from that folder's atlases. The scene also references the separate ground shadow, landing ring/dust, lane trail, and slide dust. The controller owns lane position and action timing; the images only provide poses and feedback.

To trace an asset, start at the visible node in its `.tscn`, follow the `ExtResource` path or the attached script's `preload()`/`load()`, then check whether the node is actually active. A file being declared in an older scene is **not** proof it appears in the current L01. Editable Blender/image sources live in `Peter_Run_Visual_Production/`; changing those sources alone does not change the game until approved runtime art is exported under `code/art/` and the scene or manifest points to it. `code/art/_references/` is source/reference material, not runtime art.

## The modules that matter

| Script | Type | Purpose |
| --- | --- | --- |
| `input_adapter.gd` | model | Whitelists actions, ignores held keys, 0.35 s cooldown per action |
| `session_config.gd` | model | Affected side, route id, per-action repetition targets |
| `session_result.gd` | model | Completed reps, neutral misses, route seed, RPE (1–10) |
| `level_definition.gd` | Resource | Colours, props, timings (2.5 / 2.0 / 0.75 s), formations |
| `level_catalog.gd` / `level_selection.gd` | helpers | Look up and validate the chosen level |
| `pattern_definition.gd` | validator | Checks one formation is valid |
| `pattern_library_resolver.gd` | selector | Picks the next formation from remaining targets, current lane, and the recovery flag; seeded |
| `prompt_director.gd` | state machine | `IDLE → WARNING → ACTIVE → RESOLVED`; decides SUCCESS / NEUTRAL_MISS / SAFE_CLEAR |
| `formation_collision_resolver.gd` | pure function | "Is Peter's final lane holding an obstacle?" |
| `player_controller.gd`, `player_lane_state.gd` | node + model | Lane logic and animation |
| `world_motion_controller.gd` | node | Makes props approach the contact line |
| `l01_*`, `road_projection.gd`, `route_journey.gd`, `route_side_art.gd` | visuals | The layered 2.5D street |
| `contact_effects.gd`, `feedback_toast.gd`, `classic_runner_sprite.gd` | visuals | Effects, toasts, Peter sprite |
| `control_hints.gd` | helper | Keyboard / gamepad hint text |
| `game_settings.gd`, `menu_audio_settings.gd` | state | Pace, reduced motion, music (in memory only) |

## Follow one keypress

The player presses `W` while a **JUMP** prompt is active.

1. Godot's InputMap turns the key into the named action `jump`.
2. `runner_level_controller._input()` sees `is_action_pressed("jump")` and calls `receive_input("jump", true, now)`. It consumes the event so a focused button cannot treat it as menu navigation.
3. `InputAdapter.accept_action()` rejects it if the key is already held or still in its cooldown. Otherwise it returns the logical action.
4. While the start countdown is running (`is_countdown_active`) all input is ignored. Otherwise, if the action is `pause_session`, pause toggles and we stop. If the game is paused or ended, the input is ignored.
5. `player.handle_action("jump")` changes lane or starts the jump animation and returns whether the movement was accepted. For an obstacle formation the jump's visual is timed to land on the contact line.
6. For a formation prompt, the controller stores the latest accepted action and lane as a **pending response**, so the player can still correct themselves. For a simple prompt it calls `prompt_director.receive_action(...)` directly.
7. When `response_timer` fires, the pending response is passed to `PromptDirector.receive_action(action, lane, accepted)`.
8. The director checks the action matches, movement was accepted, and the lane is valid, then moves to `RESOLVED` with a resolution and emits `prompt_state_changed`.
9. `_on_prompt_state_changed(RESOLVED, ...)` runs the collision check:
   - `FormationCollisionResolver.player_hits_formation(...)` returns true only for non-success/non-safe-clear outcomes with Peter in an obstacle lane → "Run ended" overlay.
   - Otherwise `_record_prompt_resolution()` updates `SessionResult`, shows the toast, plays effects and sets the recovery preference after a miss.
10. If all targets are met, the "complete" overlay shows. Otherwise `resolve_timer` (0.75 s) returns the director to `IDLE`, and `_schedule_next_prompt()` picks the next formation.
11. When the run ends, `open_summary()` stores the result in `session_review_store` and changes to `session_summary.tscn`.

## Timers on the runner

| Timer | Duration (default) | On timeout |
| --- | --- | --- |
| `warning_timer` | 2.5 s at standard speed (1.5–4.0 s by game speed, `GameSettings.warning_seconds_for_pace`) | `prompt_director.open_response_window()` |
| `response_timer` | 2.0 s | judge the pending response, or `expire_active_prompt()` |
| `resolve_timer` | 0.75 s | back to `IDLE`, schedule the next prompt |

Pausing stops gameplay updates (`pause_gameplay()` → `_set_gameplay_updates_paused(true)`) and freezes the player and world.

## Where prompts come from

`_schedule_next_prompt()` tries three sources in order:

1. **Formation library** (current): `PatternLibraryResolver.select_next_for_targets()` picks a formation that is reachable from Peter's lane and still needed to reach the remaining repetition targets, preferring a recovery formation after a neutral miss. Seeded by `route_seed` so a run is reproducible.
2. **Pattern sets** (legacy): fixed action/lane lists from `LevelDefinition`.
3. **Planned sequence** (legacy): a simple repeating action list.

## Adding or changing things

| I want to… | Touch |
| --- | --- |
| Change timings or colours for a route | The level's `.tres` in `data/levels/` |
| Add a formation | The level's formation library, validated by `PatternDefinition.validate()`; add a resolver test |
| Add a new route | New `LevelDefinition` `.tres`, register it in `catalog.tres`, set `show_in_setup` |
| Change what counts as a correct response | `prompt_director._is_spatially_correct` + `prompt_director` tests |
| Change collision behaviour | `formation_collision_resolver.gd` + its test. **Confirm with the product owner first**: contact ending the run is a deliberate decision |
| Add a new input | InputMap in `project.godot`, `InputAdapter.ACCEPTED_ACTIONS`, `ControlHints`, controller-check tile |

## Running the tests

Godot must be on the PATH. From `code/`:

```text
godot --headless --path . -s res://tests/project_setup_smoke.gd
godot --headless --path . -s res://tests/input_adapter_test.gd
godot --headless --path . -s res://tests/formation_collision_resolver_test.gd
```

Each test is a standalone script run with `-s`. Graphics captures live in `tests/support/` and need a rendering run (`--rendering-method gl_compatibility`). Real results are recorded in `test_evidence/`.
