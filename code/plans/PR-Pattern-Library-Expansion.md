# PETER RUN — Pattern Library Expansion Plan

## Current finding

L01 currently cycles through eight authored action/lane sets. Prompt validation checks action plus lane, movement prompts can show a two-box gate, and already-safe movement prompts can award a route-clear point. The pattern arrays are still code constants, however, and the data model does not yet describe a complete obstacle formation.

## Goal

Make L01 varied without making it random or confusing. Every pattern must describe its obstacles, open lane(s), required exercise action, and whether staying safe is valid. Future levels must be able to provide their own pattern library without changing the runner controller.

## Invariants

- Three lanes remain the only play space.
- A pattern always has at least one reachable response.
- Jump and slide remain lane-specific exercises.
- A movement gate may be cleared by moving to, or already occupying, its open lane.
- Wrong actions and late responses remain neutral misses; there is no health loss or game over.
- The 2.5-second warning, 2.0-second response, and 0.75-second resolution timings remain unchanged.
- Therapist repetition counts and route-clear points remain separate metrics.

## Construction steps

### Step 1 — Define pattern data (PR-14A)

Replace the default pattern dictionaries with a validated data shape:

```text
pattern_id
actions[]
obstacles[]: { kind, lane }
open_lanes[]
required_action
allow_idle_clear
```

Move the L01 library into its level resource or a dedicated pattern resource. Keep eight existing patterns as compatibility fixtures while adding the new fields.

Verification: resource validation rejects missing actions, invalid lanes, duplicate impossible obstacles, and patterns with no open lane.

### Step 2 — Expand the authored L01 library (PR-14B)

Create 24–40 curated patterns, grouped by beginner, normal, recovery, and mixed movement. Include single puddles, single laundry lines, two-box gates, three-obstacle gates, and patterns where Peter is already in the safe lane.

Do not select patterns randomly yet. Use a deterministic no-immediate-repeat resolver so automated tests and therapy review remain reproducible.

Verification: every pattern is reachable from the previous pattern’s ending lane and no pattern repeats immediately.

### Step 3 — Generalize obstacle rendering (PR-14C)

Render every obstacle entry from the pattern instead of deriving companion boxes from the action name. Reuse pooled prop instances and project all obstacles through the same world-motion depth calculation.

Verification: two- and three-obstacle formations stay aligned in perspective, pause/resume freezes every obstacle, and hidden props are reset between prompts.

### Step 4 — Clarify scoring and review (PR-14D)

Keep exercise repetitions for successful prescribed actions. Keep route-clear points for occupying an open lane without unnecessary movement. Show both in the HUD and session review; never convert a route-clear point into a therapist repetition.

Verification: jump/slide successes increment only their action repetition; safe idle clears increment only route-clear points; misses increment neither.

### Step 5 — Playtest and future-level contract (PR-14E)

Add deterministic tests for all pattern categories, then perform a graphics playtest at 1920×1080 and the native 480×270 canvas. Document how a future L02 resource supplies its own pattern library, obstacle scenes, and palette.

Exit criteria: at least 24 L01 patterns pass validation, the route feels varied over a complete session, no input creates an impossible state, and all existing Godot tests remain green.

## Current verification baseline

The existing prompt, L01, project setup, session progress, presentation, and pause tests pass before this expansion. The current working tree also contains uncommitted SVG character and lane-pattern changes; those should be reviewed and committed as a coherent change before starting PR-14A.

