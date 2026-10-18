# L01 Home researched pass-by source candidates

These are **source-art candidates**, not approved runtime art. The current fixed Home street remains active in Godot. The transparent files are independent frontages without roads, curbs, sky, HUD, or gameplay props. `layout.json` records their intended sides, cycle phases and provisional ground-contact origins for test-only compositing. The left veranda is the v01 source in the adjacent folder; three new original cutouts are stored here.

## Research-to-design decisions

- [Godot's 2D parallax guide](https://docs.godotengine.org/en/stable/tutorials/2d/2d_parallax.html) treats parallax as camera-relative layer scroll and requires seamless repeat art for looping. Distinct perspective-grounded houses should instead follow the measured curb and grow with travel depth; clouds and distant hills can retain slow layer drift. This is an implementation inference, not a claim that Godot forbids Parallax2D.
- [Godot's pause guide](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html) documents process-mode behavior, but this project explicitly freezes its motion subsystems rather than pausing the whole tree. Any future frontage motion must be driven by the same frozen world distance and tested at Pause and Reduced Motion.
- The [NCCA history of Philippine architecture](https://ncca.gov.ph/about-ncca-3/subcommissions/subcommission-on-the-arts-sca/architecture-and-allied-arts-2/history-of-philippine-architecture/) documents varied bamboo/wood and masonry traditions. The left sawali-screened home uses these cues without recreating a specific building.
- A [UP Diliman study of sari-sari storefronts](https://www.digitalarchives.upd.edu.ph/item/64306/7/) describes different openings, canopies, counters, and seating as social thresholds between home and street. The right shop is domestic-scale with a counter and stool, not a repeated market facade.

The frontages deliberately differ in roofline, height, material and use: two-storey veranda, sawali home, mixed-use sari-sari, and compact bungalow. At game scale, clear silhouettes and sidewalk contact matter more than tiny roof or package detail. The generated source PNGs may still need cropping, contact-origin correction, and restrained color grading after native-size preview.

## Visual gate

Run `code/tests/support/preview_l01_home_passby_v02.gd` from the Godot project to render a deterministic whole-cycle comparison in `test_evidence/experience_revamp_geometry/home_passby_v02/`. Reject if any phase has a blank verge, clipping through the painted curb, a detached base, oversized near house, Hall obstruction, duplicate fixed building, or a recycle pop. Do **not** enable these files in `runner_level.tscn` merely because the source test passes.
