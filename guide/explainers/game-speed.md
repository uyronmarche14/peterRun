# Game Speed (1–10)

The game speed is a number from **1 (faster) to 10 (slower)**. It is set in Session Setup and can be changed again on the review screen for the next run. Standard speed shows as 7.

## What each number changes

| | Speed 1 | Speed 7 (standard) | Speed 10 |
| --- | --- | --- | --- |
| Scenery and road scroll | 2.2× | 1.0× | 0.4× |
| Peter's stride and the ambience pitch | follow the scenery | normal | follow the scenery |
| **GET READY warning** | **1.5 s** | **2.5 s** | **4.0 s** |
| Response window (MOVE NOW) | 2.0 s | 2.0 s | 2.0 s |
| Settle after an answer | 0.75 s | 0.75 s | 0.75 s |
| Time for an obstacle to reach Peter | 3.5 s | 4.5 s | 6.0 s |

## How an obstacle travels
- Every obstacle starts **far up the road** and moves toward Peter at **one steady pace** to the contact line. There is no slow start followed by a rush.
- It always reaches the contact line exactly when the response window closes, so the timing the patient relies on never drifts.
- A higher speed (lower number) only shortens the warning, so the same journey takes less time.

## Why this design
- Real perspective makes a steadily moving object look as if it speeds up near the camera. The game flattens that on purpose so the movement reads as calm.
- Speed is not done by starting obstacles nearer: that made new obstacles appear close to Peter and was removed.
- Only the **warning** changes. The response window and the settle stay fixed, so what the patient has to do is the same at every speed.

## Where it lives in the code
| Piece | Place |
| --- | --- |
| Number ↔ pace, pace range 0.4–2.2 | `game_settings.gd` (`pace_for_rating`, `rating_for_pace`) |
| Warning length for a pace | `game_settings.gd` (`warning_seconds_for_pace`) |
| Steady obstacle path | `game_settings.gd` (`approach_fraction`), used by `world_motion_controller.gd` |
| Peter's stride | `player_controller.gd` (`_process`) |
| Where it is chosen | `patient_setup_controller.gd`, `session_summary_controller.gd` |

Tests: `speed_application_test`, `speed_warning_time_test`, `obstacle_speed_feel_test`, `speed_cues_follow_speed_test`.

> **Clinical note:** a 1.5 s warning at speed 1 is shorter than the original 2.5 s. This needs the therapist's sign-off before patient use.
