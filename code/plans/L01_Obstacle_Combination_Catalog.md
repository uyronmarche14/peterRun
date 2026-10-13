# L01 Barangay Morning — obstacle combination catalog

Status: 2026-10-13 implementation inventory. The 19 J09-J18/S10-S18 formations below are authored in [`l01_barangay.tres`](../data/levels/l01_barangay.tres) and pass deterministic rendering, lane-clearance, and one-repetition integration tests. They have not received therapist, controller-hardware, or user acceptance testing. J19/S19 remain deferred. This catalog does not change repetition rules, timing, or art.

Visual review on 2026-10-14 found that a side-lane laundry line became much shorter than a centre-lane line at the same depth. The L01 projection now preserves the slide gate's vertical post/under-space height while fitting its crossbar width inside the painted curb. [`l01_new_formation_integration_test.gd`](../tests/l01_new_formation_integration_test.gd) checks equal same-depth laundry height; local 960x540, 1024x768, and 1920x1080 comparison captures are in `test_evidence/l01_v6_formations/`. A bespoke narrow-lane redraw may further improve cloth proportions after art review.

## Meaning of a combination

Read each layout as **Left / Centre / Right** at one shared approach depth:

- `C` = delivery crate; a blocking prop, never its own repetition.
- `P` = shallow puddle; the matching cue for **Jump**.
- `L` = laundry line; the matching cue for **Slide**.
- `O` = visibly open road lane; no blocking prop. It may have a restrained safe-path ground treatment, but it must remain open.

“Fill all three lanes” means give every lane a clear role. For **Move Left/Right**, two crates plus one `O` are correct; placing a third obstacle in the destination lane would make that movement impossible. For **Jump/Slide**, a three-prop layout may use two crates plus one matching cue, or two matching cues plus one crate. A single matching cue with two visually open lanes remains a calm beginner/recovery option.

The game records **one prescribed therapy repetition per correctly resolved prompt**, not one point per visible prop. A correct `move_left`, `move_right`, `jump`, or `slide` earns at most one matching rep at contact. Merely occupying an already-open lane earns no rep. Dodging to an open lane without the requested Jump/Slide earns no Jump/Slide rep. There is no separate score or per-crate point. These are the current rules in [`runner_level_controller.gd`](../scripts/runner_level_controller.gd) and [`session_result.gd`](../scripts/session_result.gd).

## Original formations retained in the game

The original resource had **60 authored entries**: 15 per action. They resolve to **21 distinct action/layout combinations** because some IDs repeat the same silhouette in beginner, normal, recovery, or mixed categories. These entries remain present in the now-79-entry resource. `O` in a Jump/Slide row describes the visible empty lane; those formations store `open_lanes: []`, so an empty lane is **not** a rep-awarding safe-clear target.

| Key | Action | Left / Centre / Right | Entries | Current pattern IDs |
| --- | --- | --- | ---: | --- |
| ML1 | Move Left | `O/C/C` | 8 | `l01_p01_move_left`, `l01_p03_move_left`, `l01_p05_move_left`, `l01_p07_move_left`, `l01_p12_move_left`, `l01_p23_move_left_open_left`, `l01_p24_move_left_open_left`, `l01_p25_move_left_open_left` |
| ML2 | Move Left | `C/O/C` | 7 | `l01_p02_move_left`, `l01_p04_move_left`, `l01_p06_move_left`, `l01_p08_move_left`, `l01_p26_move_left_open_center`, `l01_p27_move_left_open_center`, `l01_p28_move_left_open_center` |
| MR1 | Move Right | `C/O/C` | 8 | `l01_p01_move_right`, `l01_p03_move_right`, `l01_p05_move_right`, `l01_p07_move_right`, `l01_p15_move_right`, `l01_p29_move_right_open_center`, `l01_p30_move_right_open_center`, `l01_p31_move_right_open_center` |
| MR2 | Move Right | `C/C/O` | 7 | `l01_p02_move_right`, `l01_p04_move_right`, `l01_p06_move_right`, `l01_p08_move_right`, `l01_p16_move_right`, `l01_p32_move_right_open_right`, `l01_p33_move_right_open_right` |
| J01 | Jump | `P/O/O` | 3 | `l01_p01_jump_left`, `l01_p07_jump_left`, `l01_p13_jump_left` |
| J02 | Jump | `O/P/O` | 5 | `l01_p03_jump_center`, `l01_p05_jump_center`, `l01_p06_jump_center`, `l01_p08_jump_center`, `l01_p09_jump_center` |
| J03 | Jump | `O/O/P` | 2 | `l01_p02_jump_right`, `l01_p04_jump_right` |
| J04 | Jump | `P/C/C` | 1 | `l01_p21_jump_gate_left` |
| J05 | Jump | `C/P/C` | 1 | `l01_p10_jump_gate_center` |
| J06 | Jump | `C/C/P` | 1 | `l01_p22_jump_gate_right` |
| J07 | Jump | `P/P/C` | 1 | `l01_p17_jump_choice_left_center` |
| J08 | Jump | `C/P/P` | 1 | `l01_p18_jump_choice_center_right` |
| S01 | Slide | `L/O/O` | 2 | `l01_p03_slide_left`, `l01_p14_slide_left` |
| S02 | Slide | `O/L/O` | 5 | `l01_p01_slide_center`, `l01_p02_slide_center`, `l01_p04_slide_center`, `l01_p05_slide_center`, `l01_p07_slide_center` |
| S03 | Slide | `O/O/L` | 2 | `l01_p06_slide_right`, `l01_p08_slide_right` |
| S04 | Slide | `L/C/C` | 1 | `l01_p34_slide_gate_left` |
| S05 | Slide | `C/L/C` | 1 | `l01_p11_slide_gate_center` |
| S06 | Slide | `C/C/L` | 1 | `l01_p35_slide_gate_right` |
| S07 | Slide | `L/L/C` | 1 | `l01_p19_slide_choice_left_center` |
| S08 | Slide | `C/L/L` | 1 | `l01_p20_slide_choice_center_right` |
| S09 | Slide | `L/C/L` | 1 | `l01_p36_slide_choice_outer` |

The four movement layouts above are all the distinct **one-step Left/Right** possibilities with two crates and exactly one open destination. The selector keeps the first four choices beginner, then offers per-action single-, two-, and three-prop Jump/Slide layouts in a gentle cycle; it does not schedule two three-prop gates back-to-back. A short session still need not show every gate. See [`pattern_library_resolver.gd`](../scripts/pattern_library_resolver.gd).

## Added L01 Jump and Slide combinations

Within one action family, use only crates, that action's matching cue, and open road. This yields **19 possible lane layouts for Jump** and **19 for Slide**. Eight Jump and nine Slide layouts already existed above. The following 21 layouts complete that bounded catalog: **19 are implemented**, while the two all-cue layouts remain **deferred** pending readability and safety review. Runtime IDs use the `l01_v6_j09_pco` / `l01_v6_s10_lco` pattern.

For each implemented layout, the valid entry lane contains its matching cue (`P` for Jump, `L` for Slide). If there are two matching lanes, either can be an action lane. The authored `ending_lane` is valid, but runtime uses Peter's actual lane after the action. A visibly open lane offers avoidance, **not** a therapy repetition.

| Catalog ID | Action | Left / Centre / Right | Type | Status and role |
| --- | --- | --- | --- | --- |
| J09 | Jump | `P/C/O` | puddle + crate + open | Implemented; left-lane Jump, right side stays open |
| J10 | Jump | `P/O/C` | puddle + open + crate | Implemented; left-lane Jump, centre stays open |
| J11 | Jump | `C/P/O` | crate + puddle + open | Implemented; centre Jump, right side stays open |
| J12 | Jump | `O/P/C` | open + puddle + crate | Implemented; centre Jump, left side stays open |
| J13 | Jump | `C/O/P` | crate + open + puddle | Implemented; right-lane Jump, centre stays open |
| J14 | Jump | `O/C/P` | open + crate + puddle | Implemented; right-lane Jump, left side stays open |
| J15 | Jump | `P/P/O` | two puddles + open | Implemented; Jump in left or centre |
| J16 | Jump | `P/O/P` | two puddles + open | Implemented; Jump in left or right |
| J17 | Jump | `O/P/P` | open + two puddles | Implemented; Jump in centre or right |
| J18 | Jump | `P/C/P` | two puddles + crate | Implemented; completes the left/right two-puddle gate |
| J19 | Jump | `P/P/P` | three puddles | **Deferred**; all lanes demand Jump and the silhouette may become a cross-road mass |
| S10 | Slide | `L/C/O` | laundry + crate + open | Implemented; left-lane Slide, right side stays open |
| S11 | Slide | `L/O/C` | laundry + open + crate | Implemented; left-lane Slide, centre stays open |
| S12 | Slide | `C/L/O` | crate + laundry + open | Implemented; centre Slide, right side stays open |
| S13 | Slide | `O/L/C` | open + laundry + crate | Implemented; centre Slide, left side stays open |
| S14 | Slide | `C/O/L` | crate + open + laundry | Implemented; right-lane Slide, centre stays open |
| S15 | Slide | `O/C/L` | open + crate + laundry | Implemented; right-lane Slide, left side stays open |
| S16 | Slide | `L/L/O` | two laundry lines + open | Implemented; Slide in left or centre |
| S17 | Slide | `L/O/L` | two laundry lines + open | Implemented; Slide in left or right |
| S18 | Slide | `O/L/L` | open + two laundry lines | Implemented; Slide in centre or right |
| S19 | Slide | `L/L/L` | three laundry lines | **Deferred**; three overhead silhouettes may hide Peter or the road |

The 19 added layouts provide spatial variety without faster motion, more simultaneous prompts, or extra repetition targets. They are selected one formation at a time. Crate, puddle, and laundry visual skins remain a future art proposal, not assets delivered here.

## Active authoring and selection rules

1. Keep exactly three lanes and **one active prompt**. Never mix a puddle and laundry line in the same formation: that would demand Jump and Slide at once. Do not use `C/C/C` for a movement prompt or place a crate in its required open destination.
2. For Move Left/Right, select only a one-step-reachable `O` from Peter's current lane. If he is already on that open lane, label it safe passage and award **zero** new reps. The third lane position is intentionally open, not a missing obstacle.
3. For Jump/Slide, select a formation only if Peter starts in a matching `P`/`L` action lane. A correct matching input in that lane awards **one** corresponding rep at contact, regardless of whether there are one, two, or three visible props. Wrong action, wrong lane, or an empty-lane dodge never awards that rep.
4. Preserve calm onboarding: single-cue formations remain available for beginner/recovery use. Add controlled variety later; do not turn every encounter into a fully blocked gate merely to fill the screen. A three-prop gate with side crates makes a wrong sidestep a physical contact that **ends the run** under the current rule; review that consequence before increasing its frequency.
5. Library validation now confirms each declared action lane has the matching cue, each open lane contains no obstacle, entry/ending lanes are reachable, IDs are unique, and no conflicting action cue is present. Keep the action count balanced without fabricating duplicate layout entries as if they were new silhouettes.
6. The 19 added layouts have automated in-game lane-to-prop rendering, painted-curb clearance at three approach depths, and one-repetition checks in [`l01_new_formation_integration_test.gd`](../tests/l01_new_formation_integration_test.gd). Existing tests cover safe passage, wrong-action contact, response correction, Pause, and seeded reachability. Full visual captures of every new layout at every display size, therapist review, and hardware UAT remain outstanding.

## Explicitly excluded combinations

- Mixed Jump **and** Slide cues in one row (`P/L/*`): two different instructions at once.
- Three crates (`C/C/C`) or other layouts with no reachable prescribed response.
- A third blocking prop in a Move Left/Right `O` lane.
- Scoring each crate, puddle, or cloth separately, because this would inflate therapy repetitions and create a competitive points system.
- Obstacles beyond the existing crate/puddle/laundry families until their action meaning, art, and safety are reviewed.

Related sources: [`pattern_definition.gd`](../scripts/pattern_definition.gd), [`prompt_director.gd`](../scripts/prompt_director.gd), [`formation_collision_resolver.gd`](../scripts/formation_collision_resolver.gd), [`pattern_definition_test.gd`](../tests/pattern_definition_test.gd), and [`formation_runner_test.gd`](../tests/formation_runner_test.gd). The older [`PR-Pattern-Library-Expansion.md`](PR-Pattern-Library-Expansion.md) describes an earlier state (24–40 patterns and route-clear points); use the current resource and scripts above for the 2026-10-13 inventory.
