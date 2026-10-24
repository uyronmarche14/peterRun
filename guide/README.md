# PETER RUN — Guide

*"One step at a time." · "Bawat hakbang ng buhay."*

PETER RUN is a calm, supervised rehabilitation game for Windows. A person does four leg movements to guide Peter along a Filipino street, and the therapist reviews what was done afterwards. This folder explains the game, how it works, and how the code is built.

## Start here

| I am… | Read this first | Then |
| --- | --- | --- |
| **A patient / player** | [How to Play](users/how-to-play.md) | [Controls](users/controls.md), [FAQ](users/faq.md) |
| **A therapist / supervisor** | [Therapist Guide](users/therapist-guide.md) | [How to Play](users/how-to-play.md), [Controls](users/controls.md) |
| **Presenting or demoing the game** | [Game Overview](explainers/game-overview.md) | [Demo Script](explainers/demo-script.md), [Glossary](explainers/glossary.md) |
| **A new developer** | [How the Game Works](explainers/how-the-game-works.md) | [How the Code Works](explainers/how-the-code-works.md), [Glossary](explainers/glossary.md) |

## Contents

### For users — `users/`
- [How to Play](users/how-to-play.md) — the four movements, the obstacles, what the screen says.
- [Therapist Guide](users/therapist-guide.md) — setting up a session, running it, reading the review.
- [Controls](users/controls.md) — keyboard, gamepad, the MOVE controller, and the controller check.
- [FAQ](users/faq.md) — short answers to common questions.

### For explainers — `explainers/`
- [Game Overview](explainers/game-overview.md) — what the game is and why it is designed this way.
- [How the Game Works](explainers/how-the-game-works.md) — one run in plain words, plus diagrams of the flow and rules.
- [How the Code Works](explainers/how-the-code-works.md) — project map and how a keypress travels through the code.
- [Guided Code Tour](explainers/code-tour.md) — a stop-by-stop walk through the code with presenter notes, check questions and exercises.
- [Glossary](explainers/glossary.md) — the words used across the game, docs and code.
- [Demo Script](explainers/demo-script.md) — a 5-minute guided walkthrough.

## Other documentation in this repository

These are the detailed source documents. This guide summarises them and does not replace them.

- `Peter_Run_BRD.md`, `Peter_Run_PRD.md` — product intent.
- `Peter_Run_Visual_Production/` — art specs and asset notes.
- `Peter_Run_Project_Kit/docs/` — build queue, status and test strategy.
- `code/README.md`, `code/AGENTS.md` — Godot project setup and rules.
- `code/plans/PR-16-Collision-Run-End-Logic.md` — why contact ends a run.

> **Accuracy note:** this guide was written from the code on branch `v8` (October 2026). The older BRD and PRD still describe obstacle misses as neutral in places; the game now ends the run on obstacle contact, and this guide follows the game.

> **Not a medical device.** PETER RUN is a supervised practice tool. It does not diagnose, treat, or replace a therapist's judgement.
