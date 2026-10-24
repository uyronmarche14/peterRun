# Game Overview

## In one sentence

PETER RUN is a calm, supervised, three-lane street runner for Windows in which a patient practises four prescribed leg movements, and a therapist reviews the result.

## The pitch

Rehabilitation exercise is repetitive. PETER RUN turns a set of repetitions into a short walk through a Filipino barangay street. The player is **Peter**, who walks forward at a steady pace. Ahead on the road are crates, a puddle and a laundry line. Each one asks for one simple movement: step left, step right, jump or slide. The therapist decides how many repetitions to do, and the game keeps count.

## Who it is for

| Person | What they get |
| --- | --- |
| **Patient** | A gentle, clear task: one instruction at a time, no pressure. |
| **Therapist** | Control over the plan and a review of what was actually done, plus the speed the player chose for the next run. |
| **Device team** | A game that accepts plain keyboard-style input, so a wearable can drive it. |

## Design principles

1. **Calm over fast.** The time to respond is fixed. Difficulty is only the number of repetitions. (The player can only change how fast the scenery scrolls.)
2. **Clear, not punishing.** There are no lives, health, score loss, chase or shaming. If Peter reaches an obstacle the run ends and all completed work is saved.
3. **Therapist in control.** Setup, pause and ending the session are always available and carry no penalty. The game does not make clinical decisions.
4. **One thing at a time.** One prompt on screen, each with an icon, a word and a distinct prop shape.
5. **Input is replaceable.** The game only knows five named actions, so keyboard, gamepad and a wearable all work the same way.
6. **Original and local.** An original Filipino setting, art, music and character. No copied commercial-runner assets, names or mechanics.

## The experience

```text
Open the game  →  Set up (reps)  →  Ready  →  Run Barangay Morning  →  Review & game-speed choice  →  Retry, Rest or Finish
```

A run lasts as long as the planned repetitions take: roughly 5 seconds per prompt, so a default 40-repetition plan is a few minutes.

## What is in the game today

- Opening screen with original music (*Hakbang sa Umaga*), settings, and a tutorial.
- Supervised setup with 1–15 repetitions per movement.
- Controller check for keyboard, gamepad and the MOVE wearable.
- One playable route: **Barangay Morning**, with a layered, travelling street and living background.
- Authored obstacle **formations** that vary the lanes and movements.
- Session review with completed vs planned counts and a 1–10 game-speed choice (1 = faster, 10 = slower) for the next run.
- Pause, end-level and end-session at any time.

## What it is not

- Not a medical device, diagnosis tool or clinical measurement of angles or range of motion.
- Not a competitive game: no score, leaderboard or achievements.
- Not (yet) a patient-record system: results are held for the review flow only.

## Technology in brief

Godot 4 and GDScript, 2D with a 2.5D "forward lane" illusion using layered sprites and parallax (no 3D), Compatibility renderer, a 480×270 base canvas scaled to HD, and a Windows build. A separate Electron wrapper also exists in the repository.

## Where things stand

The full session flow works and is covered by automated tests. In progress: final L01 artwork, validation of the MOVE controller, and extra routes (L02 Market Morning and L03 Rainy Crossing exist in data but are hidden). The clinical sign-off on the "contact ends the run" rule is not yet recorded.
