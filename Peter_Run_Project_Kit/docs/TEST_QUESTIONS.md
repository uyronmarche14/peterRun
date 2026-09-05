# PETER RUN — Required Test Questions

These questions turn “it looks fine” into evidence. A test owner answers each question with **Pass**, **Fail**, or **Not Run**, plus a date, build/version, tester and evidence link. `Not Run` is honest and blocks only the release gates that require it.

## Before any gameplay test

| Question | Why it matters |
| --- | --- |
| Is this the intended build/version and level data? | Prevents testing the wrong files |
| Is the test input keyboard, ESP32 HID, or a simulated event? | Prevents confusing code validation with hardware validation |
| Is the affected-side setting recorded? | Lateral mapping depends on it |
| Are a therapist and appropriate supervision present if a real participant is moving? | Safety requirement |

## Gameplay questions

| Question | Pass condition |
| --- | --- |
| Is there exactly one active action prompt? | One icon, word and obstacle silhouette are visible; no competing instruction |
| Can the intended action be identified in two seconds without relying only on colour? | Tester names the correct Move/Jump/Slide action before acting |
| Does one deliberate movement count once? | Counter increases by one, not zero or more than one |
| Does a wrong/absent action remain neutral? | No game-over, health loss, shaming message or forced retry appears |
| Does each matching action increase only its own prescribed target? | The correct counter changes and unrelated counters do not |
| Does target completion open Summary rather than a score/failure screen? | Summary is reachable only after targets are satisfied |

## Safety and UI questions

| Question | Pass condition |
| --- | --- |
| Is Pause visible during all gameplay and tutorial states? | It is clear, readable and not covered by art |
| Does Pause freeze player motion and the prompt timer immediately? | No new prompt resolves while paused |
| Are menus operated by mouse/trackpad rather than required leg movement? | Menu navigation works without controller movement |
| Can a therapist end a session without a punitive result? | Confirmation then neutral Summary appears |
| Is the visual density calm enough to keep prompts legible? | Tester can identify prompt and Pause without searching |

## ESP32 and Windows questions

| Question | Pass condition |
| --- | --- |
| Does the ESP32 type one expected `A/D/W/S` event in Notepad per movement? | Recorded physical test shows one press/release, no repeats |
| Does the same event create one matching Godot action? | Godot debug/event evidence agrees with Notepad result |
| Does disconnect/reconnect leave the game in a safe state? | No stuck movement; status is honest; keyboard fallback remains usable |
| Does the exported Windows build work outside Godot? | It opens, reaches L01, pauses, ends and returns to Main Menu |

## Release-blocking question

> Has a qualified therapist approved the movement configuration, target repetitions, pacing, and real-session supervision plan for the intended participant group?

If the answer is `Not Run` or `Fail`, the game may be a technical prototype but must not be represented as clinically validated or ready for unsupervised rehabilitation.
