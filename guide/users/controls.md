# Controls

PETER RUN uses five named actions. Keyboard, gamepad and the MOVE controller all trigger the same actions, so the game behaves identically with any of them.

## Control table

| Action | Keyboard | Gamepad |
| --- | --- | --- |
| Move Left | `A` | D-pad Left |
| Move Right | `D` | D-pad Right |
| Jump | `W` | Bottom face button (Xbox **A**, PlayStation **Cross**, Nintendo **B**) |
| Slide | `S` | Right face button (Xbox **B**, PlayStation **Circle**, Nintendo **A**) |
| Pause | `P` | Xbox **Start**, PlayStation **Options**, Nintendo **+** |

The on-screen hints switch automatically to match a connected gamepad.

## Menus use the mouse

Movement keys do **not** navigate menus. Use the mouse or trackpad to click buttons on the menu, setup, ready and review screens.

## The MOVE controller

The wearable MOVE controller is designed to act like a keyboard. Its firmware sends debounced presses and releases of `A`, `D`, `W`, `S` and `P`. The game never reads raw sensor data.

> The MOVE controller must be validated separately before clinical use. The controller firmware folder in this repository is currently empty. Until validated, use the keyboard.

## How the game filters input

- **One press = one action.** Holding a key does not repeat it. Release and press again.
- **Short cooldown.** After an accepted press, the same action is ignored for about **0.35 seconds**. This prevents accidental double triggers.
- Only the five actions above are accepted.
- While paused or after a run has ended, movement keys do nothing.

## Checking your controls

1. From the opening screen choose **Settings → Check controller** (also offered during Setup and on the Ready screen as **Test controls**).
2. Press each movement once. A tile turns **green** when detected. The counter reads, for example, *"3 of 5 detected · Keyboard"*.
3. When all five are green, continue.

## Troubleshooting

| Problem | Try this |
| --- | --- |
| A movement does nothing | Run **Check controller**. If its tile never turns green, that key or button is not reaching the game. |
| Peter moved twice | Release the key fully between presses. The adapter ignores held keys, so a stuck key or a chattering switch is likely. |
| Gamepad not detected | Connect it before opening the game, then check **Settings → Check controller**. |
| Menu button won't respond to movement keys | Expected. Menus are mouse-only. |
| Pressed `P` but nothing paused | The run may already be over. Pause works only during play. |

## Sensitivity and delay test (Controller Check)

Open **Settings → Check controller**. Below the five action tiles:

- **Sensitivity: Low / Normal / High.** It sets how soon the same action can repeat (0.50 s / 0.35 s / 0.15 s) and how far a gamepad stick must move to count (65% / 50% / 35%). **Normal** is the default. Use **High** if movements are missed; use **Low** if one movement is counted twice. It is remembered the next time the game opens.
- **Not counted messages.** If a press is ignored, the screen says why: too soon after the last press, or the button is still held.
- **Delay test.** Press **Delay test**, wait for **Press NOW**, then press any action. The screen shows the delay in milliseconds, the average of the last five, and the best. Run it once on the keyboard and once on the MOVE controller: the difference is the controller's own delay. The result includes your reaction time, so compare runs, not single presses.
