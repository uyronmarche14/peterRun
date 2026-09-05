# PETER RUN — Project Kit

> The operating folder for building the Godot desktop prototype with Codex as a supervised development team.

This kit turns the design documents into a repeatable build workflow. Keep it in the same repository as the future Godot project. It does not pretend that code or AI alone can validate rehabilitation safety, ESP32 hardware, or a Windows release; those checks require recorded human evidence.

## Start here

1. Read [AGENTS.md](AGENTS.md). It is the rulebook for every Codex task in this project.
2. Read [Build Queue](docs/BUILD_QUEUE.md), choose one unchecked work unit, and use its build prompt.
3. Build and test only that work unit in Godot.
4. Record the actual test evidence in `test_evidence/`.
5. Run the [Daily Bug Check](docs/DAILY_BUG_CHECK.md) after meaningful changes or let the scheduled daily check report actionable findings.

## Canonical design sources

| Document | Use it when deciding |
| --- | --- |
| [BRD](../Peter_Run_BRD.md) | Patient safety, supervision and product purpose |
| [PRD](../Peter_Run_PRD.md) | Gameplay, inputs, data and functional criteria |
| [Visual Production Master](../Peter_Run_Visual_Production/00_Visual_Production_Master.md) | Pixel-art standards and art handoff |
| [System & Screen Flow](../Peter_Run_Visual_Production/10_End_to_End_System_Flow.md) | Screen order, data ownership and Godot connection |
| [Agent Team](docs/AGENT_TEAM.md) | Which AI role does a task and in what order |
| [Test Strategy](docs/TEST_STRATEGY.md) | What is automatically testable and what needs people/hardware |

When there is a conflict: BRD safety → PRD gameplay → System Flow → project kit process.

## Folder layout when Godot work begins

```text
Peter_Run_Project/
├── AGENTS.md                       # Codex instructions and safety contract
├── README.md
├── docs/
│   ├── AGENT_TEAM.md
│   ├── BUILD_QUEUE.md
│   ├── DAILY_BUG_CHECK.md
│   ├── TEST_STRATEGY.md
│   └── TEST_QUESTIONS.md
├── game/                            # Godot 4 project root
│   ├── project.godot
│   ├── scenes/
│   ├── scripts/
│   ├── data/
│   ├── art/
│   └── tests/
├── controller_firmware/             # ESP32 firmware; separate from Godot
└── test_evidence/                   # Manual, ESP32, therapist and export evidence
```

The `game/` and `controller_firmware/` folders are deliberately separated. Godot must receive simple action names such as `move_left`; it must never need to interpret raw sensor values directly.

## How to call a build task in Codex

Use one focused request at a time:

> Read `AGENTS.md`, the BRD, PRD, System Flow, and `docs/BUILD_QUEUE.md`. Implement work unit `PR-01` using test-first development. Do not change unrelated files. Run the stated automated checks and update the evidence record with only results you actually ran.

For a visual task:

> Act as the Art/UI Agent. Read the Visual Production Master and `docs/AGENT_TEAM.md`. Produce the requested L01 asset specification or Godot UI scene. Preserve the 480 × 270 canvas and do not obscure the persistent Pause control.

For a bug:

> Reproduce BUG-___ from `test_evidence/`. Write a regression test first, confirm it fails for the stated reason, implement the smallest fix, rerun the test, then update the bug record with real output.

## Build philosophy

- Work in **small vertical slices**: one player action, one prompt type, one screen transition, one testable result.
- Use test-first logic for pure game systems; use smoke checks for Godot scene loading; use human UAT for comfort and safety.
- An AI reviewer must not mark its own work as fully validated without automated output or independent human evidence.
- Optimise only after a playable, readable L01 exists. A fast but confusing rehabilitation game is not a success.
