PETER RUN V4 - Windows Prototype

How to run
1. Extract the whole ZIP to a folder on a local drive.
2. Keep PETER_RUN_v4.exe and PETER_RUN_v4.pck together.
3. Double-click PETER_RUN_v4.exe.
4. This prototype is not code-signed. If Windows shows a security warning, confirm the source before deciding whether to run it.

Controls
A / Left Arrow: move left
D / Right Arrow: move right
W / Up Arrow or gamepad A: jump
S / Down Arrow or gamepad B: slide
P or gamepad Start: pause

What changed since V3
- Restored the original fixed Barangay Morning street and road composition.
- Removed the mismatched sidewalk cutouts that floated over the flower pots and market stall.
- Kept gentle aligned clouds, laundry, leaves, resident, and road-depth motion.
- The passing-house layer remains hidden; prompt and movement behavior remain as in the current project.

Session safety
This is a supervised prototype, not a clinically validated release. Use Pause or stop if the player reports discomfort, fatigue, pain, dizziness, shortness of breath, or instability. No cloud account or patient database is included; session information is kept only for the current app session.

Build status
Godot 4.7.2 Windows x86_64 release export from the local PR-OBSTICLES working tree on 2026-09-30. Base commit e385d7c plus uncommitted project changes; this ZIP is the frozen V4 build snapshot. All 56 available headless Godot tests passed after updating one outdated roadside-visibility assertion. The exported executable passed a headless startup smoke check. Hardware controller, therapist, clinical, and Windows UAT validation have not been performed.
