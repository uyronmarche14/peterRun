# PETER RUN — Test Strategy and Acceptance Gates

> **Status:** living test plan for the Godot 4 2D desktop prototype.  
> **Purpose:** establish what can be automated, what requires a person, and when it is safe to progress. This document does not certify clinical safety; it supports supervised testing and therapist review.

## 1. Test objective

PETER RUN is a calm, Philippine-inspired 2D rehabilitation runner. A player uses four discrete actions—move left, move right, jump, and slide—to respond to one clearly signalled prompt at a time. It is intended for supervised adult stroke rehabilitation.

The game uses an original 2.5D forward-lane illusion made from 2D sprites and parallax. Visual review must reject copied commercial-runner UI/characters, rail/subway routes, trains, guards, coins, hoverboards, chase imagery, or reward/score loops.

Testing must prove four things before a build is shown to a participant:

1. **Correctness:** actions, prompts, repetition counting, menus, pause, and level completion behave as specified.
2. **Safety support:** the game never punishes a missed movement, avoids surprise actions, and provides an immediate pause/stop route.
3. **Input reliability:** keyboard and ESP32 controller inputs create one intentional game action, without accidental repeats.
4. **Usability:** a therapist can configure, observe, pause, and end a session; the player can understand the next action without relying on background detail.

## 2. Test principles

- Test the smallest unit first, then the scene, then the complete build.
- A passing automated test is evidence of logic only. It does **not** prove movement comfort, controller stability, or clinical suitability.
- Record the Godot version, Windows version, controller firmware version, test data, and build identifier with every test run.
- Use a scripted input source for repeatable logic tests; use real keyboard and real ESP32 hardware separately.
- Do not mark a feature “done” on a screenshot alone. Exercise its success, neutral-miss, pause, reset, and exit paths.
- Use the word **neutral miss** rather than failure: a late, wrong, or absent response must continue safely, show calm feedback, and must not cause a game-over.
- Keep one prompt active at a time. Tests must fail if two actionable movement prompts overlap.
- Stop supervised testing immediately if the participant, therapist, or tester reports discomfort, confusion, fatigue, or an unsafe device behaviour.

## 3. Test layers and ownership

| Layer | What it checks | Typical method | Owner | Can be automated? | Exit evidence |
| --- | --- | --- | --- | --- | --- |
| Static checks | Missing files, invalid scene/resource references, formatting and configuration mistakes | Godot editor warnings; command-line project parse where available | Developer | Partly | Clean load or reviewed warnings list |
| Unit logic | Pure GDScript rules: input cooldown, lane bounds, prompt matching, repetition counts | GUT or WAT tests using deterministic inputs | Developer / Codex-assisted | Yes | Test report with zero unexpected failures |
| Scene smoke | A scene instantiates and its required nodes/signals exist | Godot headless/smoke runner or manual F6 launch | Developer | Partly | Scene-by-scene result log |
| Integration | Player, prompt director, HUD, pause, level data, and session state work together | Scripted end-to-end playthrough plus visual check | Developer | Partly | Saved run record and screenshots/video if needed |
| Input simulation | Keyboard action mapping and debouncing work with predictable events | Godot `Input.action_press`/release or test adapter | Developer | Yes | Input event log and assertions |
| Hardware | ESP32 appears as expected and does not double-trigger | Windows + Notepad + Godot play session | Developer / hardware tester | No | Firmware/build IDs and observation checklist |
| UAT | The intended workflow is understandable and usable | Facilitated checklist with developer/therapist | Product owner / tester | No | Signed or recorded UAT responses |
| Clinical review | Movement prescription, pace, exertion response, and supervision process are acceptable | Therapist-led observation and approval | Licensed therapist | No | Explicit therapist decision; not inferred |
| Release / export | Windows build opens outside the editor with its required files | Clean-folder install/run on target Windows device | Developer | Partly | Versioned build verification log |

## 4. Environments and test data

### Required environments

| ID | Environment | Use | Minimum setup |
| --- | --- | --- | --- |
| DEV | Godot editor on development PC | fast scene and script tests | Godot 4.x, project source, keyboard |
| SIM | Deterministic input mode | repeatable automated tests | test adapter enabled; no physical controller required |
| HW | Windows PC with ESP32 controller | HID, timing, and physical-control validation | production-like firmware; keyboard available as fallback |
| UAT | Supervised desktop test setup | workflow and clarity review | therapist/operator, chair/walker setup as approved, immediate pause access |
| RELEASE | Fresh Windows folder/device | exported build verification | exported Windows build only; no Godot editor dependency |

### Canonical test session data

Use low, fixed values so test results are easy to inspect. These values are for software testing, not clinical prescription.

| Dataset | Level | Target actions | Sequence | Why |
| --- | --- | ---: | --- | --- |
| `SMOKE_L01` | Barangay Morning | 4 | left, right, jump, slide | covers every action once |
| `REPEAT_L01` | Barangay Morning | 8 | left, left, right, right, jump, jump, slide, slide | detects repeat/counter errors |
| `MISS_L01` | Barangay Morning | 4 | left, jump, right, slide | exercises neutral misses and recovery |
| `PAUSE_L01` | Barangay Morning | 4 | left, pause, resume, jump, slide, right | validates state freeze and resume |
| `BOUNDARY_L01` | Barangay Morning | 4 | left at left edge, right at right edge, jump, slide | validates lane limits and no invalid movement |

## 5. Automated unit tests

Automated unit tests should isolate game rules from rendering and hardware. If the project uses GUT or WAT, keep tests in a separate `tests/` folder and run them in a test-only configuration. If no framework is installed, use a small deterministic Godot test runner until one is added.

### 5.1 Required unit-test coverage

| ID | Subject | Setup / stimulus | Expected assertion |
| --- | --- | --- | --- |
| UT-01 | Lane movement left | player begins in centre lane; send `move_left` once | lane becomes left |
| UT-02 | Lane movement right | player begins in centre lane; send `move_right` once | lane becomes right |
| UT-03 | Left boundary | player begins in left lane; send `move_left` | lane remains left; no error; no rep change unless the active prompt permits it |
| UT-04 | Right boundary | player begins in right lane; send `move_right` | lane remains right; no error |
| UT-05 | Prompt match | active prompt is `jump`; send `jump` inside response window | result is success; correct counter increases exactly once |
| UT-06 | Wrong action | active prompt is `jump`; send `slide` | result is neutral miss; no game-over; session continues |
| UT-07 | No response | active prompt expires with no action | neutral miss; no game-over; next safe state is reached |
| UT-08 | Single active prompt | attempt to activate a second prompt while one is active | second prompt is queued/rejected; only one actionable prompt is visible |
| UT-09 | Debounce | send repeated same action inside configured cooldown | exactly one logical response is registered |
| UT-10 | Debounce expiry | send same action after configured cooldown | second action is eligible and recorded according to prompt rules |
| UT-11 | Pause freeze | pause during response window; advance simulated time | timer, obstacle motion, and scoring/repetition state do not progress |
| UT-12 | Resume | resume after pause | prior state returns without duplicated prompt or changed counter |
| UT-13 | End session | end session from pause | gameplay closes safely; session marked ended; no additional prompt accepted |
| UT-14 | Completion | reach prescribed action target | summary state opens once; no additional gameplay prompt begins |
| UT-15 | RPE validation | submit values outside and inside 1–10 | only integer values 1 through 10 are accepted; chosen value persists in session result |
| UT-16 | Affected-side mapping | invert lateral mapping setting; send physical left/right input representation | configured mapping is applied only at input adapter; game action semantics remain consistent |

### 5.2 Accuracy questions for every unit test

Before accepting a unit test as useful, answer these questions in its test name or comments:

1. What single rule is this test proving?
2. What deterministic input makes it fail when the rule breaks?
3. What state is observed—counter, lane index, prompt state, timer, or transition?
4. Could this pass while the player sees an unsafe or unclear screen? If yes, add a manual scene test too.
5. Does the test assert “exactly once” where duplicate inputs or duplicate screens are a risk?

## 6. Godot scene smoke tests

Smoke tests answer: “Can the scene load, show its essential controls, and exit safely?” They are not a replacement for visual or clinical review.

| ID | Scene / screen | Steps | Pass condition | Fail gate |
| --- | --- | --- | --- | --- |
| ST-01 | Main Menu | open project; run from entry scene | Play, Settings, Tutorial, and Quit/Exit controls are visible and selectable | Any missing or unresponsive route blocks build |
| ST-02 | Patient Setup | enter from Play | affected-side option, target/repetition setup, input status, and Continue route render | unclear or non-persistent settings block UAT |
| ST-03 | Tutorial | launch tutorial | all four action prompts can be previewed without pressure or countdown | any action is absent or tutorial traps user |
| ST-04 | Ready screen | leave tutorial/setup | selected level/session settings are visible; Start and Back routes work | starting with unknown settings blocks testing |
| ST-05 | L01 gameplay | run `SMOKE_L01` | player, three lanes, road, one prompt card, rep counter, and Pause button exist | missing essential node blocks all gameplay tests |
| ST-06 | Pause overlay | press pause in L01 | overlay appears immediately; Resume and End Session are selectable | if gameplay continues behind pause, block UAT |
| ST-07 | Summary and RPE | complete test target | result appears once; RPE 1–10 and next/rest/end decision route appear | cannot close or records invalid value |
| ST-08 | Each visual level | load L01 through L05 separately | shared gameplay contract works; theme assets do not hide lane/prompt readability | scene-specific error or unreadable obstacle blocks that level |

### Scene smoke checklist

- [ ] No missing-node, missing-resource, or parser errors are shown in the Godot output.
- [ ] Pause is reachable with mouse/trackpad and has a clear visible label.
- [ ] A screen has a visible way back or forward; no screen dead-ends unexpectedly.
- [ ] The HUD stays fixed while world layers scroll.
- [ ] Prompt text/icon remains above scenery contrast and is not covered by an obstacle.
- [ ] No screen communicates failure, punishment, score loss, or game-over after a miss.

## 7. Input simulation and ESP32 controller tests

### 7.1 Software input contract

Godot receives named actions, not raw sensor values:

```text
ESP32 sensor event → HID key press and release → Windows → Godot Input Map → input_adapter.gd → game action

A → move_left      D → move_right      W → jump      S → slide
```

The input adapter owns cooldown/debounce and affected-side mapping. `player_controller.gd` and `prompt_director.gd` should receive semantic actions such as `move_left`, not inspect ESP32 data directly.

### 7.2 Input test cases

| ID | Test | Method | Expected result |
| --- | --- | --- | --- |
| IN-01 | Keyboard mapping | press A, D, W, S in a test scene | one matching named Godot action per press |
| IN-02 | Press/release pair | inspect debug event log | key press is followed by release; held state is not treated as repeated discrete reps |
| IN-03 | Fast duplicate pulse | emit two pulses inside cooldown | first accepted; second ignored; diagnostic log explains ignored input |
| IN-04 | Alternating actions | emit A, D, W, S with valid spacing | all four actions are accepted in order |
| IN-05 | Pause isolation | pause then emit actions | no player, prompt, counter, or timer changes until resume |
| IN-06 | Controller fallback | disconnect ESP32 mid-session | game remains controllable by keyboard or offers clear operator status; it must not crash |
| IN-07 | ESP32 HID identity | connect controller to Windows | device is recognised as expected HID input; no special serial connection required for MVP |
| IN-08 | Notepad preflight | perform each intended physical movement in Notepad | each movement emits only its intended A/D/W/S character once; record any double/missing events |
| IN-09 | Godot hardware pass | repeat physical movements in input test scene | same one-action behaviour observed in Godot |
| IN-10 | Long session observation | run a non-clinical repeated test sequence | no stuck key, missed release, duplicate count, disconnect crash, or increasing input latency |

### ESP32 hardware questions and gates

| Question | Decision gate |
| --- | --- |
| Does each intended movement produce exactly one key press and one release in Notepad? | If no, fix firmware/sensor thresholds before Godot UAT. |
| Can an involuntary/noise movement trigger a command? | If yes, do not use controller with a participant; tune thresholds and debounce. |
| Does the controller reconnect predictably after power loss or Bluetooth loss? | If no, document a supervised recovery procedure and do not claim seamless recovery. |
| Is the selected ESP32 board confirmed to support the intended USB HID or BLE HID mode? | If unknown, validate board and firmware path before schedule commitments. |
| Is keyboard fallback available and clearly indicated to the operator? | If no, add it before hardware UAT. |

## 8. Integration and end-to-end test flows

Run these with a versioned build and the named test dataset. Record actual vs. expected result, including timestamp and tester.

| ID | Flow | Steps | Expected result |
| --- | --- | --- | --- |
| E2E-01 | Happy path | Menu → Setup → Tutorial → Ready → `SMOKE_L01`; correctly perform all four actions → Summary → submit RPE → End | target reached once; correct summary; no duplicate counters/prompts |
| E2E-02 | Neutral misses | start `MISS_L01`; give wrong/no input on selected prompts; then complete remaining prompts | misses remain calm; game continues; subsequent prompts work; no score/game-over language |
| E2E-03 | Pause and return | start `PAUSE_L01`; pause during active prompt; wait; resume; finish | world and prompt timing freeze; session resumes one coherent state; finish is possible |
| E2E-04 | Early end | start gameplay; open Pause; End Session; confirm | gameplay stops; operator returns to safe menu/summary route; no background actions persist |
| E2E-05 | Boundary movement | run `BOUNDARY_L01` | player never leaves three permitted lanes; feedback remains stable |
| E2E-06 | Level contract | repeat happy-path logic across L02–L05 | each level changes art/obstacles only; prompt, pause, counters, and summary retain same behaviour |
| E2E-07 | Fresh export | launch exported `.exe` from a clean folder | entry screen, input map, art/audio (if present), and all required levels function without editor |

## 9. Manual UAT checklist

UAT is a structured usability review, not a clinical trial. The facilitator must explain that the participant can stop at any time and that the therapist controls clinical use.

### 9.1 Before the session

- [ ] Record build ID, Godot version, Windows device, display resolution, and controller firmware version.
- [ ] Confirm whether testing is keyboard-only, ESP32-only, or both.
- [ ] Confirm a therapist/supervisor is present if any physical rehabilitation movement is involved.
- [ ] Confirm immediate access to a mouse/trackpad pause and an operator-controlled end-session route.
- [ ] Confirm walking aid/setup and movement plan are therapist-approved; do not improvise physical tasks from this document.
- [ ] Explain that missed prompts have no punishment and the session can be stopped immediately.

### 9.2 Questions to ask the player/tester

Ask after a short segment, not while they are actively responding to a prompt.

| Area | Questions | Pass signal |
| --- | --- | --- |
| Prompt clarity | “What action did you think the game wanted?” “Could you see the arrow/icon and text?” | answer matches intended action without guessing |
| Timing | “Did you have enough time to understand and respond?” “Did anything feel rushed?” | no reported rush/confusion; therapist agrees pacing is appropriate |
| Visual hierarchy | “What did you notice first: the instruction, obstacle, or background?” | instruction/prompt is noticed before decorative scenery |
| Obstacle meaning | “What made you choose that action?” | obstacle and prompt lead to one clear interpretation |
| Controls | “Did one movement ever trigger twice or not register?” | no unexplained duplicate/missed response |
| Comfort | “Was any movement uncomfortable, tiring, or hard to control?” | no discomfort; any concern is escalated to therapist, not tuned by assumption |
| Pause confidence | “If you needed to stop, do you know how?” | player/operator can identify the pause route; button is reachable |
| Theme respect | “Does the visual style feel calm, readable, and respectful?” | feedback supports clarity and respect; no distracting or stereotyped element reported |

### 9.3 Therapist/operator questions

| Area | Questions | Gate |
| --- | --- | --- |
| Movement suitability | Are the action labels, range, pace, and target repetitions appropriate for this supervised test? | therapist decision is required before participant progression |
| Observation | Can you see the current prompt, completed repetitions, and pause/end controls without ambiguity? | if no, revise HUD/workflow |
| Recovery | After a missed or wrong action, does the game support a calm restart of the next prompt? | must be yes before UAT pass |
| Fatigue management | Is exertion captured clearly and is there a clear Rest/End path? | must be yes; RPE is a record, not an automated clearance |
| Device safety | Is controller placement/operation acceptable for this session? | if no, hardware testing stops |

### 9.4 UAT decision record

```text
Build ID:
Date/time:
Environment (DEV/HW/UAT/RELEASE):
Tester(s):
Therapist/supervisor (if applicable):
Input method and firmware version:
Level/dataset:

Pass / conditional pass / fail:
Observed issue(s):
Severity: blocker / high / medium / low
Required change(s):
Retest owner and date:
Therapist decision (if applicable): approved for next supervised test / revise / not approved
```

## 10. Safety and release gates

### Blocker conditions

Do **not** run participant testing or distribute a build labelled for rehabilitation if any condition below is present:

- Pause or End Session is missing, unclear, or fails to immediately stop gameplay updates.
- A missed response results in game-over, punishment, score loss, shaming language, or forced speed increase.
- Two active movement prompts can appear together.
- ESP32 input can routinely double-trigger, remains stuck, or has unvalidated movement-to-key mapping.
- The prompt, obstacle, or lane cannot be read clearly at the intended display resolution.
- A therapist has not approved the intended supervised movement setup.
- The exported build has not been launched and checked outside Godot.

### Progress gates

| Gate | Required evidence | Decision |
| --- | --- | --- |
| G0 — Logic ready | UT-01 through UT-16 pass or every exception has a documented, accepted reason | move to scene smoke |
| G1 — Scene ready | ST-01 through ST-08 pass for the build scope | move to integration |
| G2 — Input ready | keyboard tests pass; ESP32 tests pass if hardware is in scope | move to hardware/UAT |
| G3 — UAT ready | no blocker condition; facilitator checklist is prepared; therapist present where required | conduct supervised UAT |
| G4 — UAT decision | recorded UAT result and therapist/operator feedback reviewed | fix and retest, or proceed to export check |
| G5 — Release candidate | fresh exported build passes E2E-07; known limitations are documented | share only within approved prototype scope |

## 11. Daily bug and regression check

Run this short check at the beginning or end of every development day. It is a **regression sweep**, not a promise that all defects were found.

### 10-minute daily sweep

1. Open the project and resolve/review new Godot parser, missing-resource, or missing-node warnings.
2. Run `SMOKE_L01` using keyboard actions. Complete each of left, right, jump, and slide once.
3. Pause during an active prompt; verify the timer/world/counter freeze; resume and end session once.
4. Force one wrong action and one no-response; verify neutral continuation and no game-over.
5. Launch one non-L01 level to verify the shared runner system still loads.
6. If controller code changed, execute Notepad preflight and IN-09 before marking the day’s build testable.
7. Record defects in the bug log, including reproduction steps and build ID.

### Daily bug log template

| Field | Record |
| --- | --- |
| Bug ID | `BUG-YYYYMMDD-###` |
| Build ID / commit | exact build or commit tested |
| Environment | DEV, SIM, HW, UAT, or RELEASE |
| Level / screen | e.g. L03 Gameplay / Pause |
| Preconditions | session setup, input source, firmware, target data |
| Steps to reproduce | numbered, minimal, repeatable steps |
| Expected result | reference to this test plan/PRD requirement |
| Actual result | exact observed behaviour and error text if any |
| Severity | blocker, high, medium, low |
| Evidence | screenshot, video, Godot log, input log, or none |
| Status | new, triaged, fixed, retest, closed |
| Retest result | pass/fail and tester/date |

### Severity definitions

| Severity | Meaning | Required action |
| --- | --- | --- |
| Blocker | safety route, session flow, input reliability, or launch is compromised | stop related UAT/release work; fix and retest |
| High | key action/level cannot be completed reliably, but app may launch | fix before the next integrated build |
| Medium | visible incorrect behaviour with a viable workaround | triage and schedule; retest after fix |
| Low | polish, copy, or non-blocking visual inconsistency | log and resolve when scope permits |

## 12. Test reporting and traceability

Each new feature should link its test evidence to one requirement from the BRD/PRD and one file/scene owner. Keep results honest:

| Requirement area | Primary test evidence | Secondary evidence |
| --- | --- | --- |
| Fixed progression/repetition target | UT-14, E2E-01 | Summary visual review |
| One prompt at a time | UT-08, ST-05 | UAT prompt clarity answer |
| No game-over / neutral misses | UT-06, UT-07, E2E-02 | therapist/operator observation |
| Immediate pause/end | UT-11–UT-13, ST-06, E2E-03/04 | UAT pause confidence question |
| ESP32 discrete actions | IN-03, IN-07–IN-10 | Notepad preflight record |
| Filipino-themed visual readability | ST-08 | player/theme feedback during UAT |
| Windows export | E2E-07 | release-folder launch log |

## 13. Definition of done for an MVP feature

A feature is ready only when all applicable statements are true:

- [ ] Its expected behaviour is written in a test case or acceptance question.
- [ ] Unit and scene tests cover its logical and visible paths where practical.
- [ ] It works with the keyboard before being attributed to ESP32 hardware.
- [ ] It handles wrong, absent, paused, resumed, and exit states safely.
- [ ] Any issue found is recorded, triaged, and retested after a fix.
- [ ] A user-facing claim about safety, comfort, or therapy use is made only after appropriate human/therapist review.
- [ ] The relevant full-game regression flow still passes.

## 14. What this plan cannot prove

This plan cannot determine medical appropriateness, diagnose movement quality, establish clinical effectiveness, or guarantee that an ESP32 controller works on every Windows device. Those questions require qualified clinical oversight, real-device validation, and documented deployment testing. Treat an automated pass as one piece of evidence—not a substitute for supervision.
