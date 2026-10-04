# PETER RUN — Instructions for Codex Agents

## Mission

Build an original, calm, Filipino-inspired 2D desktop runner for supervised adult stroke rehabilitation. Use a 2.5D forward-lane illusion made from 2D sprites and parallax—not 3D scenes or a copy of a commercial runner. The game supports a walker user, has no game-over state, shows one discrete movement prompt at a time, and is evaluated by prescribed repetitions—not speed or score.

## Mandatory reading order

Before any implementation task, read:

1. `../Peter_Run_BRD.md`
2. `../Peter_Run_PRD.md`
3. `../Peter_Run_Visual_Production/10_End_to_End_System_Flow.md`
4. `docs/BUILD_QUEUE.md`
5. The role section in `docs/AGENT_TEAM.md`
6. `docs/TEST_STRATEGY.md` when code changes

## Non-negotiable product rules

- Godot 4 standard build with GDScript, 2D, Windows desktop target.
- ESP32 controller behaves as a HID keyboard initially: `A`, `D`, `W`, `S` map to Godot actions. Keep controller firmware separate from game code.
- `InputAdapter` debounces input and handles affected-side lateral mapping. Game scenes never read raw ESP32 sensor values.
- Menus, configuration and RPE use mouse/trackpad or a therapist gamepad (A/Cross select, B/Circle back). Movement inputs (including the patient's MOVE controller) are for the gameplay/tutorial action flow only and never navigate menus.
- Pause must remain visible and immediately freeze the session.
- One active prompt: icon + word + obstacle silhouette. Never rely on colour alone.
- A missed action is neutral. Never implement health, death, chase, ridicule, score loss, or a game-over screen.
- Do not use Subway Surfers names, assets, code, audio, logos, or copied level design.
- Do not use rail/subway routes, trains, guards, chase logic, coins, hoverboards, graffiti branding, score multipliers, copied HUD patterns, or copied character/animation silhouettes.

## Scope discipline

Work only on the assigned build unit. Do not rewrite unrelated files, add online accounts, leaderboards, ads, monetisation, procedural generation, or medical claims. Ask a blocking question when a decision changes safety, input hardware protocol, clinical targets, or required user data.

## Required implementation loop

1. State the work unit and its done condition.
2. Add or update the smallest relevant automated test first where the system is testable.
3. Run it and record an actual RED result when adding/fixing logic.
4. Implement the smallest change.
5. Run the test again and record GREEN output.
6. Run the appropriate Godot scene smoke check.
7. Update test evidence and add a regression test for every confirmed bug.
8. Stop and report blockers honestly; never invent a pass result.

## Ownership boundaries

| Area | Primary owner | Files |
| --- | --- | --- |
| Architecture and integration | Build Lead | `game/project.godot`, cross-cutting scenes, build queue |
| Player, prompts, session and input | Gameplay/Input Agent | `game/scripts/`, `game/data/`, gameplay tests |
| Menus, HUD, visual assets | Art/UI Agent | `game/scenes/ui/`, `game/art/`, UI specifications |
| ESP32 HID firmware | Firmware Agent | `controller_firmware/` only |
| Independent verification | QA Agent | `game/tests/`, `test_evidence/`, bug reports |

See [Agent Team](docs/AGENT_TEAM.md) for prompts, handoffs and expanded criteria.

## Definition of done

A work unit is done only when its acceptance criteria pass, the relevant automated test evidence exists, no known safety rule is violated, and its manual-test status is accurately labelled `not run`, `passed`, or `failed`. “Looks correct” is not evidence.
