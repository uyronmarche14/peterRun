# PETER RUN

> **Business Requirements Document (BRD)**  
> **Version 0.1 · MVP proposal · 05 September 2026**

**Visual-production companion:** [Visual Production Master](/mnt/c/Users/Rhyss/Documents/Codex/2026-09-05/fix-x20/outputs/Peter_Run_Visual_Production/00_Visual_Production_Master.md)

---

## ✦ Product at a glance

**PETER RUN** is an accessible, pixel-art rehabilitation runner for adult stroke patients with hemiparesis. A wearable **MOVE Controller** on the affected ankle converts prescribed lower-limb movements into four simple game actions. The player travels through cheerful levels, completes a therapist-assigned exercise set, and records their perceived exertion after each level.

The game is designed for **supervised rehabilitation**. It is a motivating exercise companion, not a diagnostic device and not a replacement for clinician judgement.

| Area | MVP decision |
| --- | --- |
| Primary users | Adult stroke patients; therapists/caregivers supervise every session |
| Play position | Standing with a walker; both hands remain available for support |
| Platform | Offline Windows desktop executable |
| Input | MOVE Controller as USB/Bluetooth HID gamepad; WASD development fallback |
| Session goal | Complete a configurable, planned set of exercise repetitions |
| Visual direction | Large, high-contrast, colorful pixel art with calm arcade polish |

---

## 1. Business need

Conventional lower-limb rehabilitation repetitions can feel repetitive and provide little immediate feedback. PETER RUN turns therapist-prescribed movements into a short, understandable game loop without rewarding speed or penalising missed movements.

The product must make prescribed repetition feel purposeful while preserving the clinician's authority over safety, progression, and exercise selection.

### Desired outcomes

- Improve willingness to complete prescribed lower-limb repetitions.
- Give patients immediate, encouraging feedback for movement completion.
- Give therapists a clear, interruptible session structure.
- Provide a reusable game framework in which new levels can be added without rewriting game logic.

### Out of scope for the MVP

- Diagnosis, treatment recommendations, or autonomous clinical decisions.
- Unsupervised home use.
- Cloud accounts, patient records, leaderboards, multiplayer, or social sharing.
- Motion-quality assessment beyond receiving the controller's discrete input signal.
- A claim that score, repetition count, or RPE alone determines readiness to advance clinically.

---

## 2. Users and needs

| User | Need | Product response |
| --- | --- | --- |
| Patient | Exercise that is clear, encouraging, and not embarrassing or punishing | Slow predictable prompts, no fail state, large visuals, positive language |
| Therapist | Safe control over a structured exercise session | Always-available pause/stop, configurable sets, visible progress, clinician-confirmed continuation |
| Caregiver | A simple way to assist without learning game controls | One obvious stop control and brief tutorial |
| Developer | A testable way to build before wearable hardware is final | Identical action abstraction for WASD and HID gamepad input |

---

## 3. Core experience

```text
Select patient setup → Calibrate / choose affected side → Tutorial →
Play a planned exercise set → Level summary → Record perceived exertion →
Therapist chooses next step, rest, retry, or end session
```

During play, the character moves forward at a fixed, gentle pace. Clearly telegraphed obstacles/prompts request one of four movements. A successful input collects or clears the prompt; a missed input simply passes by. The session ends when the planned repetition targets have been reached—not because the player collided with something.

---

## 4. Functional business requirements

| ID | Requirement | Priority |
| --- | --- | --- |
| BR-01 | The game shall support right- and left-affected-leg configurations, including correct lateral mapping. | Must |
| BR-02 | The game shall provide four actions: left, right, jump, and slide, sourced through one input layer. | Must |
| BR-03 | Each movement/action shall be treated as one discrete event; held input must not generate repeated reps. | Must |
| BR-04 | A session shall use configurable planned targets, with 10–15 repetitions per movement as the initial default range. | Must |
| BR-05 | The game shall not have a lose screen, lives, score penalty, or forced early termination for missed prompts. | Must |
| BR-06 | A therapist-accessible pause/stop control shall be available throughout gameplay and take effect immediately. | Must |
| BR-07 | The game shall show a level summary and an exertion-rating screen when the planned set is complete. | Must |
| BR-08 | The game shall make progression a therapist-confirmed action; an exertion rating informs the discussion but does not automatically prescribe more exercise. | Must |
| BR-09 | The game shall include a main menu, short skippable tutorial, settings, and quit action. | Should |
| BR-10 | The level system shall be data-driven so additional themed levels can be authored without code changes. | Should |
| BR-11 | The game shall run offline as a Windows deliverable without requiring an installed game engine. | Must |

---

## 5. Safety, accessibility, and clinical guardrails

The therapist/caregiver remains responsible for determining whether play should begin, continue, pause, resume, or stop. Product design must support—not override—that responsibility.

- The patient is expected to use a walker and must never need to release it to play.
- Provide a therapist-oriented **Pause / Stop** action available by mouse/trackpad and a dedicated keyboard/gamepad fallback during development.
- After **Pause**, show large actions: *Resume*, *End level*, and *End session*.
- High exertion, pain, dizziness, shortness of breath, abnormal movement, fatigue, or balance loss must lead the supervising person to stop or rest; the game should display a calm safety prompt, never pressure the patient to continue.
- Use plain, positive copy: “Nice step!”, “Take your time”, and “Ready when you are.” Avoid “Failed”, “Too slow”, or red error feedback for misses.
- Minimum visual design: large text, high contrast, no reliance on color alone, gentle motion, and optional sound mute.
- The game must clearly say that its simplified exertion scale is an in-game rating and must be agreed with the clinical team before use. Do not describe it as a clinical scoring instrument without validation.

---

## 6. Level and content strategy

Five levels are sufficient for the first playable release, but the product architecture should support many more.

### Launch themes

| Level | Theme | Purpose |
| --- | --- | --- |
| 1 | Barangay Morning | Learn prompts and establish a calm rhythm |
| 2 | Palengke Dash | Add a longer planned sequence |
| 3 | Riverside Walk | Increase repetition targets, never movement speed |
| 4 | Rice Terrace Trail | Use varied visual prompt arrangements |
| 5 | Pasko Festival | Celebrate completion with the fullest planned set |

Every level shares the same safe cadence and input rules. Variety comes from backdrop, obstacle art, animation, music, and planned sequence composition—not reflex demand. Future levels are content packs: define a theme, background, prompt sequence, and targets in data.

---

## 7. Success measures for the MVP

- A developer can complete a full session with WASD without an input getting counted twice.
- A clinician can configure a target set, pause immediately, end safely, and interpret progress without technical assistance.
- Each of the five level themes runs from start to summary without a fail state.
- New levels can be created by editing a level-definition file/resource rather than game code.
- The Windows build launches on the agreed test device offline.

---

## 8. Feasibility and delivery recommendation

### Can this be made in 2–3 days?

**Yes—for a polished, keyboard-controlled MVP with placeholder or licensed pixel-art assets.** It can include the core runner, four actions, configurable exercise targets, five themed data-driven levels, pause/stop, tutorial, exertion screen, and a Windows test build.

**Not safely in 2–3 days:** clinically validated controller calibration, extensive therapist/patient testing, production hardware integration, bespoke art for every asset, or a claim of clinical readiness. Those need a separate validation phase.

### Recommended delivery slices

| Time | Deliverable |
| --- | --- |
| Day 1 | Input abstraction, fixed-pace runner, discrete action cooldown, prompt/rep logic, pause/stop |
| Day 2 | Menu, tutorial, settings, exertion/summary flow, five data-defined levels, initial art pass |
| Day 3 | Controller integration test, accessibility polish, bug fixing, Windows packaging, supervised playtest |

---

## 9. Stakeholder decisions needed before clinical deployment

1. Confirm exact MOVE Controller HID button mapping, connection type, and disconnect behavior.
2. Confirm therapist-approved movement ranges and whether they vary per patient.
3. Confirm the session's intended target distribution across all four movements.
4. Agree on the exertion-scale wording, range, and the clinician workflow after a high rating.
5. Confirm deployment device, Windows version, display resolution, and whether a portable folder is acceptable if a single EXE is impractical.

---

## 10. Approval statement

This document defines the intended MVP business scope. Clinical use requires clinician review, safety testing, and approval of the final exercise protocol and hardware behavior.
