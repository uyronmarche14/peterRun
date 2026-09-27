# PETER RUN

> **Product Requirements Document (PRD)**  
> **Version 0.1 · 2–3 day MVP · 05 September 2026**

**Visual-production companion:** [Visual Production Master](/mnt/c/Users/Rhyss/Documents/Codex/2026-09-05/fix-x20/outputs/Peter_Run_Visual_Production/00_Visual_Production_Master.md)

---

## ✦ Build decision

### Recommended technology stack

| Layer | Choice | Why it fits this MVP |
| --- | --- | --- |
| Game engine | **Godot 4** | Fast 2D workflow, excellent Windows export, lightweight project structure, native input support |
| Language | **GDScript** | Godot-native, concise, fast to iterate on in a 2–3 day build |
| Input | Godot `InputMap` | Lets WASD and a HID gamepad call the same named actions |
| Level data | Godot `Resource` (`.tres`) or JSON | Enables many levels without changing runner logic |
| Art | Pixel-art PNG sprite sheets / tile maps | Matches the requested visual style and keeps assets lightweight |
| Packaging | Godot Windows export | Produces a runnable Windows build with no engine installation required |

**Why not Unity/C# for this deadline?** Unity is capable, but Godot + GDScript has less setup and iteration overhead for a compact 2D prototype. Choose Unity/C# only if the team already has a Unity codebase or a developer who is substantially faster in C#.

> “Tech stack” assumed from the request; if “tech stocks” was intended literally, it is unrelated to the game build.

---

## 1. Product definition

PETER RUN is a fixed-pace, three-lane rehabilitation runner. It is implemented in **2D with a 2.5D forward-lane illusion**: the player stays near the lower screen while an original Filipino route and prompt props scroll toward them through parallax layers. The player uses clinician-prescribed leg movements—represented initially by WASD—to perform four discrete in-game actions. The game schedules a planned sequence of prompts, records successful repetitions, offers encouraging feedback, and ends a level when its target set is completed.

### Product principles

1. **Calm over fast.** Difficulty scales through planned repetition count, never character speed.
2. **Clear consequences without punishment.** Physical obstacle contact ends the current run, while non-contact misses remain neutral; there are no lives, score loss, or shaming messages.
3. **Therapist in control.** Safety actions and clinical decisions are not automated away.
4. **Content scales.** Levels are definitions, not one-off code paths.
5. **Input is replaceable.** The game only knows named actions; it does not depend on a keyboard or a particular sensor implementation.

---

## 2. MVP scope

### Included

- Main menu: Play, Tutorial, Settings, Quit.
- Skippable visual tutorial.
- Three-lane runner with fixed forward motion.
- Original 2D route system: barangay road, market walkway, riverside boardwalk, terrace trail and Pasko plaza—not railway/subway routes.
- Four gameplay actions: move left, move right, jump, slide.
- WASD development controls: `A` left, `D` right, `W` jump, `S` slide.
- One-action-per-trigger input behavior.
- Data-driven planned prompt sequence and repetition targets.
- Five themed levels using the same core mechanics.
- Pause, End Level, and End Session flow.
- Summary screen and 1–10 in-game exertion rating.
- Windows test export.

The game may use generic runner conventions such as lanes and forward scrolling, but must not copy another game's characters, art, interface, menus, route design, sound, reward loop, branding, trains, guards, coins, hoverboards, or chase premise.

### Deferred

- Direct BNO085/ESP32 firmware work.
- Individualised clinical angle classification in the game client.
- User profiles, longitudinal data storage, cloud sync, analytics, leaderboards, and achievements.
- Multiple languages, controller remapping UI, music/audio settings beyond mute.
- Final bespoke art, extensive animation, and formal accessibility/clinical validation.

---

## 3. Player flow

```text
Main Menu
  └─ Play
      └─ Patient Setup (affected side, target set, optional calibration status)
          └─ Tutorial (auto-continues; trackpad/mouse skip)
              └─ Ready screen
                  └─ Level
                      ├─ Pause → Resume / End Level / End Session
                      └─ Target set complete → Summary → Exertion rating
                          └─ Therapist chooses: Next Level / Rest & Retry / End Session
```

The exertion rating may be displayed with the historical “1–10” product requirement, but progression must be a visible supervising-person decision in the MVP. A high rating should never result in an automatic retry.

---

## 4. Functional requirements

| ID | Requirement | Acceptance criteria |
| --- | --- | --- |
| FR-01 | Configure named input actions | `move_left`, `move_right`, `jump`, and `slide` exist in `InputMap`; WASD triggers them. |
| FR-02 | Provide an input adapter | Runner receives only named actions, so a HID gamepad can replace WASD without runner code edits. |
| FR-03 | Debounce input | Pressing/holding a mapped input fires one event until release and a cooldown expires. |
| FR-04 | Record affected side | Settings stores affected side for session review; left/right controls remain literal in every configuration. |
| FR-05 | Show prompt warnings | Every exercise prompt is visible sufficiently before its response window; time values are configuration constants. |
| FR-06 | Resolve actions without punishment | Correct action in window increments its target count; incorrect/missed action gives neutral or encouraging feedback and never ends play. |
| FR-07 | End on targets or collision | A level completes when each required action target is reached. Physical obstacle contact ends the current run and retains completed repetitions for review; neither outcome depends on score or elapsed time. |
| FR-08 | Pause instantly | Pause stops runner movement, timers, and prompt resolution on the same frame; it exposes Resume, End Level, and End Session. |
| FR-09 | Display progress | HUD shows per-action or aggregate repetitions remaining and a clear pause control. |
| FR-10 | Capture exertion rating | Summary permits one trackpad/mouse-selected integer 1–10 and displays the selected value in the session summary. |
| FR-11 | Load level definitions | The game can load five level resources with no level-specific runner code. |
| FR-12 | Support an offline Windows build | Export runs on the designated Windows test computer without an installed editor/engine. |

---

## 5. Input contract

The wearable's firmware is responsible for translating measured angles into discrete HID button events. The game is responsible for receiving those events safely and consistently.

### Logical actions

| Logical game action | Development key | Right-affected leg | Left-affected leg |
| --- | --- | --- | --- |
| `move_right` | `D` | Hip abduction | Hip adduction |
| `move_left` | `A` | Hip adduction | Hip abduction |
| `jump` | `W` | Forward step | Forward step |
| `slide` | `S` | Backward step | Backward step |

The game preserves literal directions: `A` / Left always means `move_left`, and `D` / Right always means `move_right`. A therapist may record the affected side in session setup, but the game does not invert lateral controls.

### Required controller behavior before integration

- Gamepad exposes four documented, stable buttons or actions.
- Each threshold crossing produces a press and release / single event, not a continuous stream.
- Firmware includes calibration and movement-specific re-arm thresholds; the exact clinical ranges are clinician-configured.
- The game detects a missing/disconnected controller and pauses with a therapist-facing message.
- HID mapping is tested using an ordinary USB gamepad before the final MOVE hardware arrives.

---

## 6. Runner and prompt rules

### Lane state

- Three positions: left, center, right.
- Character begins in center.
- Left/right actions move one lane and cannot exceed the outer lane.
- Jump and slide play short animation states; their duration is configurable.
- Forward speed is constant within and across levels.

### Prompt state machine

```text
Scheduled → Warning → Active response window → Resolved (success / neutral miss) → Removed
```

- Only one active response prompt in the MVP.
- The upcoming action is announced with a large icon, action label, and consistent color/shape pairing.
- A successful prompt increments exactly one matching action counter.
- A prompt without a matching action is a neutral miss only when Peter reaches no obstacle. If Peter remains in an occupied lane at contact, the run ends. There are no streaks, negative score, lives, or health.
- Use a deterministic generated sequence for each level during development to make testing repeatable. Optional randomisation can be added later while preserving target balance.

---

## 7. Data-driven level design

Each level is a `LevelDefinition` resource. New content is created by duplicating a resource and assigning art, prompt rules, and target counts.

```yaml
# Illustrative shape; Godot Resource or JSON is acceptable
id: barangay_morning
title: Barangay Morning
theme:
  background: res://art/backgrounds/barangay_morning.png
  palette: sunny_barangay
targets:
  move_left: 3
  move_right: 3
  jump: 3
  slide: 3
timing:
  warning_seconds: 2.5
  response_seconds: 2.0
  gap_seconds: 2.0
sequence:
  - jump
  - move_right
  - slide
  - move_left
```

### Initial level plan

| ID | Name | Target pattern | Visual mood |
| --- | --- | --- | --- |
| L01 | Barangay Morning | 3 per action | Sunny neighborhood, warm stone and teal |
| L02 | Palengke Dash | 4 per action | Fruit stalls, woven textures, bright bunting |
| L03 | Riverside Walk | 5 per action | Calm river blues, bamboo and tropical greens |
| L04 | Rice Terrace Trail | 6 per action | Terrace greens, mountain sky and earthy paths |
| L05 | Pasko Festival | 7 per action | Parols, warm lights and a calm celebration |

This structure supports dozens of levels: add a new resource and assets, then add it to the level select/order list. Keep target changes therapist-configurable; additional level art must not secretly increase speed or narrow reaction windows.

---

## 8. UI and visual direction

### Aesthetic brief

**Mood:** sunny, familiar, gentle arcade adventure—not a medical dashboard.  
**Style:** clean 16-bit-inspired pixel art, rounded UI panels, chunky readable type, sparse backgrounds, and friendly motion.

| Screen | Essential content |
| --- | --- |
| Main menu | Large Play button; Settings, Tutorial, Quit beneath it |
| Setup | Affected-side toggle, target count / preset, controller status |
| Tutorial | Four large movement/action cards; skip control reachable by trackpad/mouse |
| HUD | Progress, large next-action cue, small timer/progress indicator, Pause |
| Pause | Resume, End Level, End Session; no small touch targets |
| Summary | Celebration, target completion, exertion selector, therapist next-step actions |

### Accessibility requirements

- Minimum high-contrast palette and large typography.
- Pair every color cue with an icon and text label.
- Do not use flashing effects, rapidly moving camera, or timed punishment.
- Optional audio must not be the sole source of instructions.
- All non-gameplay menus are mouse/trackpad navigable.

---

## 9. Suggested Godot project structure

```text
res://
├── art/
│   ├── characters/
│   ├── backgrounds/
│   └── ui/
├── data/
│   └── levels/
├── scenes/
│   ├── MainMenu.tscn
│   ├── Setup.tscn
│   ├── Tutorial.tscn
│   ├── RunnerLevel.tscn
│   ├── PauseMenu.tscn
│   └── Summary.tscn
├── scripts/
│   ├── GameState.gd
│   ├── InputAdapter.gd
│   ├── Runner.gd
│   ├── PromptDirector.gd
│   ├── LevelDefinition.gd
│   └── SessionConfig.gd
└── project.godot
```

`InputAdapter.gd` is the boundary between hardware and game. It emits logical actions only; `Runner.gd` must not inspect key codes or sensor values.

---

## 10. 2–3 day implementation plan

| Day | Build focus | Demonstrable outcome |
| --- | --- | --- |
| 1 | Godot setup, InputMap, input debouncing, lane motion, jump/slide, prompt state machine, pause | Keyboard-controlled one-level runner that counts correct discrete reps safely |
| 2 | Menus, setup, tutorial, summary/exertion, level resources, five themes, HUD and art direction | End-to-end playable experience with five configurable levels |
| 3 | HID gamepad test, controller-loss state, accessibility pass, balance/testing, Windows export | Testable Windows MVP and a supervised playtest checklist |

### Explicit scope guard

If the deadline is strict, use a cohesive asset pack or simple custom tiles, one character, and palette-swapped themed backgrounds. Do not spend the MVP window on custom animation volume, complex procedural obstacle generation, cloud services, or sensor firmware debugging.

---

## 11. Test checklist

### Core function

- [ ] Every WASD action produces the expected action once per press.
- [ ] Holding a key cannot farm repetitions.
- [ ] Wrong, late, and missed actions never show a fail state or terminate the level.
- [ ] Each level completes only once all configured targets are met.
- [ ] Pause freezes animation, timers, and scoring immediately.
- [ ] End Session safely returns to the main menu.

### Content scalability

- [ ] A sixth level can be added by duplicating and editing a level resource.
- [ ] Changing targets does not require editing runner code.
- [ ] The sequence contains the expected count of each required action.

### Input and deployment

- [ ] A standard HID gamepad maps to the four logical actions.
- [ ] Disconnecting the gamepad pauses play and clearly informs the therapist.
- [ ] Build launches offline on the target Windows device.
- [ ] All text is legible at the target screen resolution.

### Supervised safety review

- [ ] Therapist agrees that prompt cadence, planned movements, and session targets are appropriate.
- [ ] Therapist can pause/end a session without asking the patient to release the walker.
- [ ] Exertion-rating language and post-rating workflow are approved before patient use.

---

## 12. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Sensor emits duplicate/noisy events | Firmware re-arm + game input cooldown + HID test harness |
| Angle range differs by patient | Therapist-approved calibration; do not hard-code clinical thresholds in gameplay |
| Random prompts create an unbalanced exercise set | Use planned sequences that exactly satisfy targets |
| Patient fatigue or instability | Therapist supervision, immediate pause/stop, no pressure to continue |
| Single-EXE expectation conflicts with export format | Validate target-device packaging on Day 3; provide a portable ZIP/folder if needed |
| Visual polish threatens schedule | Keep one polished UI system and reuse modular themed assets |

---

## 13. Definition of done: MVP

The MVP is done when it is a visually coherent Windows game build with five playable, data-defined levels; keyboard and test-gamepad support through named actions; configurable repetition targets; encouraging non-failure feedback; a working pause/end flow; and an end-of-level exertion summary. It is ready for supervised prototype feedback—not for unsupervised or clinically validated deployment.
