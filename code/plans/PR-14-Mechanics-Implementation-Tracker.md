# PETER RUN — PR-14 Mechanics Implementation Tracker

> Status: PR-14A through PR-14D implemented locally; PR-14E planned  
> Owner: Development team  
> Scope: L01 Barangay Morning first  
> Last reviewed: 2026-09-13

## 1. Purpose

This tracker monitors the implementation of PETER RUN's next gameplay layer: **readable obstacle formations and lane-safe route logic**.

The current runner already supports three lanes, four named actions, lane-aware validation, approaching props, neutral misses, pause, prescribed repetitions, and simple action/lane pattern sets. This phase replaces the simplified pattern arrays with complete, validated formations that can describe multiple obstacles and safe openings.

This is not a competitive endless-runner feature. It must preserve the supervised rehabilitation boundaries in the BRD and PRD.

## 2. Product boundaries — must remain true

- The only gameplay actions are `move_left`, `move_right`, `jump`, `slide`, and `pause_session`.
- One formation is active at a time; its prompt includes an icon, action word, controller/keyboard hint, and distinct world-prop silhouette.
- The player always has at least one reachable response.
- Jump and slide are lane-specific prescribed actions.
- A missed formation is neutral: no damage, health, score loss, game-over, chase, or forced end.
- Completion remains based on clinician-configured action repetitions, never elapsed time, points, route clears, or collisions.
- Pause remains immediately visible and freezes timers, player motion, prop motion, and formation resolution.
- The established `2.5 / 2.0 / 0.75` second warning, response, and resolve cadence stays fixed unless a separately approved clinical decision changes it.
- L01 is the approval template. L02 and L03 remain technical route previews until L01 meets its interaction and visual acceptance checks.

## 3. Terminology

| Term | Meaning |
| --- | --- |
| Formation | One approaching, authored set of active obstacles across the three lanes. |
| Obstacle | An individual visual prop within a formation: block/crate, jump prop, or slide prop. |
| Open lane | A lane that is not blocked by a movement-gate obstacle. |
| Action lane | The lane in which a prescribed jump or slide must be performed. |
| Contact line | The point at Peter's feet where the approaching formation resolves. It is a timing marker, not a damaging collision system. |
| Action repetition | A successful prescribed move, jump, or slide recorded toward the therapist target. |
| Route progression | Calm visual journey feedback (landmark, route strip, or stamp). It is not a score, coin, streak, or completion condition. |

## 4. Current baseline and gaps

| Area | Current state | Required outcome | Status |
| --- | --- | --- | --- |
| Lanes | Three-lane player state and lane-aware input work. | Retain. | Complete baseline |
| Patterns | L01 has 40 validated formations plus deterministic reachable selection; its runner now consumes that library. | Keep the legacy sets only for routes that have not migrated. | PR-14A/B/C complete |
| Movement gates | Every authored obstacle is pooled, rendered, and projected from formation data. | Add visual playtest evidence in PR-14E. | PR-14C complete |
| Jump/slide | Lane-specific props are part of formations; an input is recorded only when the response window reaches contact. | Add final visual/motion polish in later work. | PR-14C complete |
| Safe clear | An already-safe open lane increments internal route progress and receives positive non-repetition feedback. The HUD and review use calm journey landmarks, not a numeric counter. | Confirm with L01 visual QA in PR-14E. | PR-14C/D complete |
| Feedback | Safe clear wording is positive, but its visual/toast treatment is currently neutral. | Make positive route feedback visually consistent without adding a repetition. | Not started |
| Routes | L02/L03 have palette and short pattern data. | Defer new content production until L01 is approved. | Deferred |

## 5. Target formation data

The final implementation may use a Godot `Resource` or validated `Dictionary`, but it must represent the following information without relying on controller-side special cases:

```text
pattern_id: "l01_gate_left_01"
category: "beginner" | "normal" | "recovery" | "mixed"
obstacles:
  - { kind: "crate", lane: 1 }
  - { kind: "crate", lane: 2 }
open_lanes: [0]
required_action: "move_left" | "move_right" | "jump" | "slide"
action_lane: 1                 # required for jump/slide; optional for movement gates
allow_idle_safe_clear: true    # only for movement gates
entry_lanes: [0, 1, 2]         # lanes from which the formation is valid
ending_lane: 0                 # resulting safe/action lane after resolution
```

### Rules for the data

1. Every lane value is `0`, `1`, or `2`.
2. A formation has at least one obstacle and at least one valid response.
3. An obstacle lane cannot be duplicated unless stacking is deliberately added and documented later.
4. A movement gate has at least one `open_lanes` entry. Its required movement must lead to an open lane from a permitted entry lane.
5. A jump/slide formation has an `action_lane`; action success requires Peter to be in that lane at the contact line.
6. Moving away from a jump/slide prop avoids a punishment but is a neutral miss; it cannot become a route-clear reward because it skips the prescribed action.
7. `allow_idle_safe_clear` is valid only for movement gates and only when Peter starts/ends in a declared open lane.
8. The resolver must choose a next formation reachable from the player’s actual ending lane.
9. The data model must not encode speed, countdown pressure, score multipliers, lives, or penalties.

## 6. Delivery plan and monitoring table

| Work unit | Deliverable | Status | Entry check | Exit / acceptance check |
| --- | --- | --- | --- | --- |
| PR-14A | `PatternDefinition` data shape, validation, migration of current eight L01 patterns | Implemented locally | Existing tests are green | Invalid lanes, impossible gates, duplicate blocks, missing action lane, and no-response data are rejected by deterministic tests. |
| PR-14B | Curated L01 library: 24–40 reachable patterns across beginner, normal, recovery, and mixed categories | Implemented locally | PR-14A complete | No immediate repeat; every transition is reachable from the prior ending lane; all four actions remain represented. |
| PR-14C | Generic formation renderer and contact-line resolver | Implemented locally | PR-14A complete | One-, two-, and three-obstacle formations approach in perspective; all pause/resume together; stale props reset between formations. |
| PR-14D | Calm feedback and route-progression treatment | Implemented locally | PR-14C complete | Action repetitions and neutral misses remain correct; safe movement route feedback is positive but not a visible score or completion trigger. |
| PR-14E | L01 gameplay/visual QA and authoring handoff | Not started | PR-14B–D complete | 480×270 and 1920×1080 visual playtests; no ambiguous cue; documented format for a future route. |
| PR-15 | Apply approved L01 formation system to L02/L03 | Blocked by L01 acceptance | PR-14E approved | Each route supplies its own formations, art, landmarks, and readability review. |

## 7. Required test coverage

Before marking a work unit complete, add or update the smallest deterministic test for each change.

### PR-14A tests

- Valid one-obstacle jump and slide formations load.
- Valid two-block and three-block movement gates load.
- Invalid lane values are rejected.
- Duplicate obstacle lanes are rejected.
- A movement gate without an open lane is rejected.
- Jump/slide without an action lane is rejected.
- Idle safe clear on jump/slide is rejected.

### PR-14B tests

- Every pattern has a reachable response from each declared entry lane.
- Consecutive selected patterns never repeat immediately.
- A full deterministic cycle contains all prescribed action families.
- A pattern sequence cannot leave Peter outside lanes `0..2`.

### PR-14C and PR-14D tests

- All visual obstacles use the same depth projection and reach the contact line together.
- Pause freezes every prop, the contact timer, and player state.
- Correct jump/slide at the action lane records exactly one matching repetition.
- Correct lane move into an open lane records exactly one matching movement repetition.
- Already occupying an open lane produces route progression only; it adds no repetition and no neutral miss.
- Wrong action, wrong lane, or no response records a neutral miss only.
- Route feedback uses no numeric score, streak, multiplier, or punitive language.
- Session review distinguishes repetitions and neutral misses; route progress is optional descriptive context, never a score ranking.

## 8. Manual playtest checklist

Run after automated tests for each completed unit.

- [ ] Native `480 × 270`: all three lanes, active prop, prompt word, icon, and Pause are readable.
- [ ] `1920 × 1080`: no stretched or overlapping formation/HUD elements.
- [ ] Player can understand the safe opening before contact without relying on text alone.
- [ ] Jump visibly clears a jump prop; slide visibly passes under a slide prop.
- [ ] A two- or three-block gate visibly shows the open lane.
- [ ] A formation never asks for an impossible movement from Peter’s current lane.
- [ ] A missed response passes calmly with no crash, loss, or pressure.
- [ ] Safe-lane route feedback feels encouraging but not competitive.
- [ ] Pause, End Level, and End Session remain immediately usable.
- [ ] Keyboard works; controller/HID verification is recorded separately and never assumed from keyboard tests.

## 9. Decisions required before PR-14C

These are implementation choices, not clinical changes. Record the decision in this table before the renderer is changed.

| Decision | Recommended default | Decision | Date / owner |
| --- | --- | --- | --- |
| Pattern storage | `formation_library` on the Godot `LevelDefinition` resource, validated by `PatternDefinition` | Accepted | 2026-09-13 / Development |
| Selection policy | Deterministic no-immediate-repeat, reproducible across a session | Pending | — |
| Route progress UI | Small route strip plus 3–5 Barangay landmarks; no points display | Pending | — |
| Safe-lane feedback | Brief marker glow and supportive text; no repetition increment | Pending | — |
| Warning input policy | Permit lane preparation during warning; resolve only at contact line | Pending | — |

## 10. Definition of done for this mechanics phase

PR-14 is complete only when L01 has a validated 24–40 formation library; each formation has a reachable response; multi-obstacle layouts render and resolve together at the contact line; feedback remains calm and non-competitive; clinician repetition counts stay accurate; all relevant automated tests pass; and native/1080p gameplay has been manually reviewed.

L02/L03 expansion, new art production, controller hardware approval, Windows export validation, and clinical approval are separate follow-up work. They must not be represented as complete by this mechanics tracker.

## 11. Implementation log

Add one entry per completed work unit. Record actual evidence only.

| Date | Work unit | Change summary | Tests / manual evidence | Result | Reviewer |
| --- | --- | --- | --- | --- | --- |
| 2026-09-13 | Tracker created | Baseline and planned mechanics work documented. | Source/planning review only; no implementation change. | Planned | Codex |
| 2026-09-13 | PR-14A | Added `PatternDefinition`; migrated the eight legacy L01 runner sets into 32 validated formation definitions in the L01 resource. Rendering and timing remain unchanged. | RED: `pattern_definition_test.gd` failed because the model was absent. GREEN: `pattern_definition_test.gd`, `level_definition_test.gd`, `l01_prompt_test.gd`, and `project_setup_smoke.gd` passed with Godot 4.7.2. | Implemented locally | Codex |
| 2026-09-13 | PR-14B | Expanded L01 to 40 validated formations, including jump/slide three-obstacle gates. Added a deterministic resolver that skips invalid/unreachable formations and never immediately repeats a selected formation. Rendering and timing remain unchanged. | RED: `pattern_definition_test.gd` reported missing 40-formation/three-obstacle coverage; `pattern_library_resolver_test.gd` reported the absent resolver. GREEN: both tests, `level_definition_test.gd`, `l01_prompt_test.gd`, and `project_setup_smoke.gd` passed with Godot 4.7.2. | Implemented locally | Codex |
| 2026-09-13 | PR-14C | Connected L01 to the formation library. Pooled props render every one-, two-, and three-obstacle formation through a shared 2.5D projection. Inputs made during `MOVE NOW` resolve at the contact line; Pause freezes formation motion. Safe route progress receives positive feedback without adding a repetition. | RED: `formation_runner_test.gd` showed missing formation rendering and immediate scoring; safe-clear feedback initially failed its positive-feedback assertion. GREEN: all 29 headless `*_test.gd` scripts passed with Godot 4.7.2; runner-polish 1,000-cycle check completed in 23.33 ms (CPU timing only, not rendering FPS). | Implemented locally | Codex |
| 2026-09-15 | PR-14D | Replaced the visible `Clear: #` HUD with the non-competitive landmark journey Home → Waiting Shed → Sari-sari Store → Barangay Plaza. Added matching journey context to session review. Repetitions and neutral misses remain separate. | RED: `route_journey_test.gd` reported the missing journey model; summary test initially caught mismatched label wording. GREEN: all 30 headless `*_test.gd` scripts passed with Godot 4.7.2; compact UI layout stayed within its existing size caps. | Implemented locally | Codex |
