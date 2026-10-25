# Controller-to-game delay

The delay between a leg movement and Peter reacting has four parts. Only the last two are in the game's code.

| Stage | What adds delay | Can the game change it? |
| --- | --- | --- |
| Sensor to firmware | Sampling rate and any smoothing of the movement signal | No. `controller_firmware/` is empty, so this was not measured. |
| Wireless link | Bluetooth connection interval (often 7.5–30 ms, up to ~50 ms) and retries | No. Set on the ESP32 (shorter interval, fewer retries). |
| Computer input | Godot batching input events once per frame | **Yes.** Fixed in this version. |
| Game rules | Cooldown, held-key check and the lane animation | Partly, see below. |

## Changed in the game
- `Input.use_accumulated_input = false` while a run is on: every key press is handled as it arrives, not merged into one event per frame.
- `input_devices/buffering/agile_event_flushing = true` in `project.godot`: Godot flushes buffered input sooner. Covered by `tests/input_latency_settings_test.gd`.

## Left as it is on purpose
- **0.35 s cooldown** per action (`input_adapter.gd`): stops a noisy sensor from counting one movement many times.
- **Key must be released before the next press counts**: if the controller sends "pressed" without a clean "released", the next movement is ignored. Check this first if movements feel dropped.
- **0.22 s lane glide** (`player_controller.gd`): the lane is chosen at once; the glide is only animation.
- **Judged at the contact line**: a jump or slide is counted when the obstacle arrives, by design.

## How to measure the hardware part
1. Run the controller check screen and press the action; note the on-screen reaction time by filming at 60 fps (frames x 16.7 ms).
2. Compare with the keyboard. The difference is the controller and wireless delay.
3. If the difference is more than about 80 ms: shorten the Bluetooth connection interval, send one packet per movement (not a stream), and lower any smoothing window in the firmware.

Not established: real controller delay (no hardware or firmware in the repository).

## Built into the game (v19)
- **Sensitivity** (Low / Normal / High) on the Controller Check screen sets the repeat lockout and the stick threshold. Code: `game_settings.gd` (`set_input_sensitivity`, `input_cooldown_seconds`, `stick_threshold`), saved in `user://settings.cfg`.
- **Delay test** on the same screen. Code: `latency_test.gd` and `controller_check_controller.gd`. It measures cue-to-press time, which includes the player, so use it to compare the keyboard with the controller.
- **Reason for an ignored press.** `input_adapter.gd` reports `held`, `cooldown` or `unknown` in `last_rejection`.
- Test: `tests/input_sensitivity_latency_test.gd`.
