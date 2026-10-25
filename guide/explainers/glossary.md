# Glossary

Terms used in the game, the docs and the code. Code names are in `monospace`.

| Term | Meaning |
| --- | --- |
| **Action** | One of the four prescribed movements: `move_left`, `move_right`, `jump`, `slide`. (`pause_session` is the fifth named input, not a movement.) |
| **Affected side** | No longer asked for in Setup. A default value remains in the code for compatibility; it never swaps Left and Right. |
| **Barangay** | A Filipino neighbourhood. L01 is *Barangay Morning*. |
| **Contact** | Peter ending up in a lane that holds an obstacle when the prompt resolves. Contact **ends the run**. |
| **Contact line** | The point near Peter where an approaching obstacle is judged. |
| **Correct response** | The required action, accepted by the player, with Peter in a valid lane. Counts as a repetition. |
| **Formation** | One authored arrangement of obstacles across the lanes, together with the action that solves it. Defined in data (`PatternDefinition`). |
| **Formation categories** | `beginner`, `normal`, `recovery`, `mixed`. Chosen by the game to suit the remaining targets. |
| **HID** | Human Interface Device. The MOVE wearable pretends to be a keyboard over HID. |
| **Lane** | One of three paths (0 = left, 1 = middle, 2 = right) that Peter can stand in. |
| **Level / Route** | A themed street with its colours, props and timings, stored as a `LevelDefinition` resource (`data/levels/*.tres`). |
| **MOVE controller** | The planned ESP32 + sensor wearable that sends A/D/W/S/P keypresses. |
| **Named action** | An action in Godot's InputMap. The game only reacts to these, never to raw keys or sensor values. |
| **Neutral miss** | A prompt that was not answered correctly and did not cause contact. No penalty. It is counted for the review and the next formation is made easier. |
| **Prompt** | A single instruction shown to the player. Only one at a time. |
| **Prompt cycle** | `IDLE → WARNING → ACTIVE → RESOLVED → IDLE`, handled by `PromptDirector`. |
| **Recovery formation** | An easier formation chosen after a neutral miss. |
| **Repetition (rep)** | One correct response. Targets are set per action, 1–50 each. |
| **Resolution** | The outcome of a prompt: `SUCCESS`, `NEUTRAL_MISS`, or `SAFE_CLEAR`. |
| **RPE / game-speed choice** | The 1-10 number chosen in Setup or on the review screen. It is stored as `rpe` on the result and sets the pace for the next run (1 = faster, 10 = slower). See [Game Speed](game-speed.md). |
| **Safe clear** | The player was already in a safe lane when time ran out, so nothing was needed. It is not counted as a repetition. |
| **Session** | One supervised play-through, from Setup to Review. |
| **Session config** | The plan: affected side, route and repetition targets (`SessionConfig`). |
| **Session result** | What actually happened: completed reps, neutral misses, route seed and RPE (`SessionResult`). |
| **2.5D** | A 2D game made to look like forward travel using layered sprites, perspective and parallax. There are no 3D scenes. |
| **Warning / response / resolved time** | The three phases of a prompt: about 2.5 s to get ready (1.5 s at game speed 1 to 4.0 s at speed 10), 2.0 s to respond, 0.75 s to settle. |
