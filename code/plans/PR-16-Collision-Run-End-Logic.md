# PR-16 — Collision Run-End Logic

## Decision

An obstacle is no longer only a visual prompt. If it reaches Peter in his
final lane at the contact line, the current run ends and opens the existing
review flow. Completed repetitions are retained.

## Contact rules

| Formation situation | Final contact outcome |
| --- | --- |
| Peter is in a crate lane | Run ends. |
| Peter is in a puddle lane and resolves Jump correctly | Clears puddle; run continues. |
| Peter is in a laundry-line lane and resolves Slide correctly | Clears laundry line; run continues. |
| Peter leaves an obstacle lane before contact | No collision; unresolved prompt is a neutral miss. |
| Peter is in any occupied lane without a correct resolution | Run ends. |
| Peter is already in an authorised open lane | Safe clear; run continues. |

## Boundaries retained

- No health, lives, score loss, chase, or shaming copy.
- The same named input actions and fixed timing remain in use.
- Pause still freezes all state immediately.
- A collision is checked once, at contact, from Peter's final lane.
- The existing review retains repetitions and allows a therapist-led retry.

## Acceptance checks

- Crate, puddle, and laundry contacts end a run only when their lane remains occupied.
- Correct Jump and Slide responses do not collide.
- Moving out of a puddle/laundry lane avoids collision.
- A collision records the unresolved formation once and opens `Run ended` review.
- Correct safe-lane movement remains playable and does not end the run.
