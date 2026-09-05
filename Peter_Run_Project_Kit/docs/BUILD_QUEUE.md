# PETER RUN — Build Queue

Each item is designed as a small, independently verifiable unit. Finish them in order unless the dependencies state otherwise. Do not start visual polish or L02–L05 before L01's basic safe loop works.

## Phase 0 — Project foundation

| ID | Build unit | Depends on | Done when | Required proof |
| --- | --- | --- | --- | --- |
| PR-00 | Create Godot 4 GDScript 2D project in `game/` | None | Project opens and has input actions `move_left`, `move_right`, `jump`, `slide`, `pause_session` | Screenshot or command output from an actual Godot project load |
| PR-01 | Add pure `SessionConfig` and `SessionResult` data models | PR-00 | Targets, affected side, selected level and neutral misses have explicit defaults | Unit tests for default and boundary values |
| PR-02 | Add `InputAdapter` keyboard path | PR-00, PR-01 | `A/D/W/S` produce exactly one named action after debounce | Unit tests for mapping, debounce and affected-side inversion |
| PR-03 | Create reusable `RunnerLevel.tscn` greybox | PR-00 | Three visible lanes, player placeholder, PromptWorldAnchor, HUD and Pause control load | Scene smoke check plus visual screenshot |

## Phase 1 — Safe L01 vertical slice

| ID | Build unit | Depends on | Done when | Required proof |
| --- | --- | --- | --- | --- |
| PR-04 | Add Player lane state and neutral action animations | PR-02, PR-03 | Player changes one lane only, cannot leave lane range, and action state returns safely | Unit tests for lane bounds and scene smoke check |
| PR-05 | Add one-prompt `PromptDirector` | PR-01, PR-03 | Only one active prompt can exist; it has warning, active and resolved states | Unit tests for state transitions |
| PR-06 | Add L01 crate / puddle / laundry prompts | PR-04, PR-05 | Each prompt maps to Move, Jump or Slide and resolves correctly | Prompt mapping test and screenshot at native scale |
| PR-07 | Add Pause and immediate neutral end path | PR-03, PR-05 | Pause freezes prompt timing and player movement; End Session leads to Summary | Manual smoke check; no data is lost without confirmation |
| PR-08 | Add repetition targets and neutral miss logging | PR-01, PR-05 | Correct action increments one matching counter; a miss changes no score/health | Unit tests for match, wrong action and no-input result |

## Phase 2 — Complete supervised session flow

| ID | Build unit | Depends on | Done when | Required proof |
| --- | --- | --- | --- | --- |
| PR-09 | Main Menu, Patient Setup and Controller Check | PR-00, PR-02 | Therapist can configure level, targets and affected side before play | UI smoke flow evidence |
| PR-10 | Tutorial and Ready screen | PR-04, PR-05 | One action is explained at a time; therapist can pause or skip | Manual UI walkthrough |
| PR-11 | Summary, RPE and therapist decision | PR-08 | Results show completed reps and neutral misses; RPE is 1–10 and mouse-operated | Flow test from level completion to Main Menu |

## Phase 3 — Data-driven levels and art

| ID | Build unit | Depends on | Done when | Required proof |
| --- | --- | --- | --- | --- |
| PR-12 | `LevelDefinition` data resources | PR-05, PR-08 | Level theme/props/sequence can change without changing prompt logic | Load L01 and a second fixture using the same scene |
| PR-13 | L02–L05 content resources | PR-12 | Each level has its approved obstacle mapping and readable palette | One scene-loading check per level |
| PR-14 | Parallax and final art integration | PR-03, PR-13 | Background supports—not hides—prompts, lanes or Pause control at 480 × 270 | Readability review and performance baseline |
| PR-15 | ESP32 HID integration | PR-02 | Controller emits one expected HID action per verified movement | Notepad evidence + Godot input log; therapist/hardware status recorded |

## Phase 4 — Release gate

| ID | Build unit | Depends on | Done when | Required proof |
| --- | --- | --- | --- | --- |
| PR-16 | Windows export and clean-machine test | PR-09–PR-15 | `.exe` opens, plays, pauses and returns to menu outside editor | Export log and separate Windows test record |
| PR-17 | Supervised UAT review | PR-16 | Therapist/product owner answers every blocking question and accepts/rejects the build | Signed/dated UAT record; no assumed approval |

## Standard Codex build prompt

> Read `AGENTS.md`, the design sources, and this build queue. Implement only **[WORK UNIT ID]** with test-first development. Preserve safety rules and file ownership. Before coding, state the acceptance criteria. Run the relevant automated and scene checks, report exact output, and create/update a regression test for each confirmed bug. Do not claim manual, ESP32, therapist, or Windows export validation without recorded evidence.
