# Demo Script (about 5 minutes)

A walkthrough for showing PETER RUN to a therapist, teacher, panel or stakeholder. Have a keyboard ready. Use a 1920×1080 window.

**Before you start:** launch the game, check the sound, and decide who will press the keys. Lower the repetitions to **2 per movement** in Setup so a full run takes about a minute.

---

### 1. Opening screen (30 s)
**Show:** the welcome screen. **Say:** "PETER RUN is a supervised rehabilitation game. The patient does four leg movements to guide Peter down a Filipino street. The tagline is *One step at a time*." Point out the music toggle and Settings.

### 2. Tutorial (45 s) — optional
**Click:** Tutorial. **Say:** "Patients can practice each movement first." Press `A`, `D`, `W`, `S` and show the response. Skip back to the menu.

### 3. Setup (45 s)
**Click:** Start Session. **Say:** "The therapist is in control." Show the **− / +** repetition buttons and the single route. **Say:** "Left and Right stay literal." Set 2 repetitions each. Click **Review session**.

### 4. Ready screen (20 s)
**Say:** "Nothing starts until the therapist presses Start." Briefly show **Test controls** and **Edit session**, then click **Start Session**. Point out the 3-2-1-Go! countdown: "A moment to settle before anything is asked of the patient."

### 5. Gameplay (90 s)
**Show:** the street moving toward Peter. **Say:** "One instruction at a time. Yellow *GET READY*, then green *MOVE NOW*." Perform a **move**, a **jump** and a **slide** correctly. Point out the progress display and *Nice step!*.

**Then show the three safety points:**
1. Press `P`. **Say:** "Pause freezes everything immediately." Resume.
2. Deliberately do the wrong thing once. **Say:** "A wrong movement is a *neutral miss*. No penalty, and the next one gets easier."
3. (Optional) Stay in an obstacle lane. **Say:** "If Peter reaches an obstacle the run ends, and every completed repetition is kept. No lives, no score loss."

### 6. Review (45 s)
**Show:** completed vs planned counts and the 1-10 game-speed choice. **Say:** "The player picks the game speed for next time: 1 faster, 10 slower. It changes the scenery and the length of GET READY; the 2-second response time never changes. The therapist can Rest, Retry, or Finish. Nothing starts automatically." Pick a number and show that **Retry** is now enabled.

### 7. Close (30 s)
**Say:** "Under the hood it is Godot 4 with a 2.5D illusion. The game only listens to five named actions, so a keyboard, a gamepad or our wearable controller all work the same way." Mention what is next: final artwork, validating the wearable, more routes.

---

## Likely questions

| Question | Short answer |
| --- | --- |
| Is there a score? | No. Calm over fast: no lives, score or chase. |
| Why does touching an obstacle end the run? | A clear stopping point to review. Everything completed is kept. |
| Does it speed up? | Only by the game speed the player chooses (1–10); the 2-second response time never changes. |
| How does the wearable connect? | It sends keyboard keys (A/D/W/S/P) over HID. The game never reads raw sensor data. |
| Is it a medical device? | No. It is a supervised practice aid. |
| Where do I see how it works? | [How the Game Works](how-the-game-works.md). |
