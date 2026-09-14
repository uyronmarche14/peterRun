# PETER RUN — Visual and Gameplay Improvement BRD v1.1

> Design-pattern amendment for `Peter_Run_Visual_and_Gameplay_Improvement_BRD.md` v1.0
>
> 12 September 2026

This amendment formalises the intended game-feel and 2.5D visual direction. It does not change the project’s supervised-use, safety, clinical, input, or neutral-miss boundaries.

## Approved design pattern

**PETER RUN is a calm 2.5D Barangay journey for supervised movement practice, not a competitive endless runner.**

The player should feel they are moving through a familiar, welcoming place. Game-like motivation comes from readable movement, changing scenery, route landmarks, and calm completion moments—not from speed, points, streaks, loss states, or competition.

### Visual-system rules

- Use an original, simplified illustrated 2.5D Barangay Morning style: clear silhouettes, layered depth, warm morning light, restrained texture, and a consistent muted Barangay palette.
- Keep the world visually primary during gameplay. HUD and modal UI must support the route and never make the route feel like a backdrop for an app dashboard.
- Treat movement prompts as route-sign language: action word, directional/action icon, active prop silhouette, and keyboard/controller hint remain readable together.
- Use large, calm feedback: grounded player shadow, brief dust on landing, restrained marker glow, subtle environmental response, and short supportive text.
- Essential controls remain text-led. Icons complement labels and never replace pause, end-session, or safety-critical wording.
- Raw AI generations remain reference material. Runtime art must be selected, cleaned, licensed, exported, and approved before integration.

## Required BRD changes

### 1. Metadata

Replace the version line with:

> Version 1.1 | Improvement and visual-production phase | 12 September 2026

Add this note immediately below it:

> v1.1 locks the calm 2.5D Barangay journey pattern and gentle visual-progression rules; it does not change clinical, safety, or gameplay-input boundaries.

### 2. Section 3 — business objectives

Add objective 7:

7. Make L01 feel like a welcoming journey through Barangay Morning, using non-competitive environmental progression rather than score-based motivation.

### 3. Section 5 — product principles and guardrails

Add these principles:

- Journey over competition: motivation may come from route landmarks, stamps, postcard-style completion moments, and changing scenery. Do not add scores, coins, streaks, leaderboards, countdown pressure, or loss states.
- World-first presentation: during gameplay, the route is the primary experience; HUD and feedback remain clear but visually quieter than the active route prompt and surrounding world.
- Controlled 2.5D: use layered 2D art, parallax, grounded shadows, and perspective to create depth. Do not introduce a 3D gameplay scene or camera.

### 4. Section 6 — scope

Replace the first in-scope item with:

- Final 2D art integration for L01 Barangay Morning, presented as a layered 2.5D world; no 3D gameplay scene or camera.

Add this in-scope item:

- Gentle visual progression through route landmarks, stamps, or completion moments that do not alter repetition counting, speed, neutral misses, or therapist control.

### 5. Section 7.2 — replace IBR-12 acceptance criterion

Replace the acceptance criterion with:

> No action loop visibly changes Peter’s clothing, body proportions, intended direction, canvas anchor point, or ground baseline unexpectedly. Running frames may alternate feet while retaining the same intended direction and ground contact.

### 6. Section 7.3 — add route progression requirement

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| IBR-26 | Use gentle environmental journey progression in L01. | Should | Planned action completion visibly advances a route strip, reveals a landmark, applies a route stamp, or presents a calm completion moment. It adds no score, streak, speed, loss state, or gameplay consequence. |

### 7. Section 7.4 — add prompt and hierarchy requirements

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| IBR-37 | Integrate movement prompts with the Barangay route-sign visual language. | Should | Each active prompt retains an action word, icon, readable prop silhouette, and applicable keyboard/controller hint; decorative styling cannot reduce recognition or contrast. |
| IBR-38 | Use restrained, grounded visual feedback. | Should | Landing dust, marker glow, route response, and success feedback remain brief and calm; no coins, combo counters, fireworks, or competitive reward effects are used. |

### 8. Section 8 — second visual pass

Add these assets:

| Asset | Quantity | Runtime use |
| --- | ---: | --- |
| L01 landmark set | 3–5 | Route progression: e.g., sari-sari store, waiting shed, plaza/market arrival |
| Route progress/stamp treatment | 1 system | Calm, non-competitive journey completion feedback |
| Road-sign action frame | 1 system | World-integrated movement prompt presentation |

### 9. Section 10 — visual checks

Replace the first visual-check bullet with:

- Review dashboard, setup, tutorial, ready, L01 gameplay, pause, and summary at 480 x 270, 960 x 540, 1024 x 768, 1280 x 720, and 1920 x 1080.

Add these checks:

- Verify the route is visually more prominent than persistent HUD elements during active play.
- Verify route progress/landmarks are understandable as completion feedback, never as score, speed, or performance pressure.
- Verify prompt sign styling preserves large text, icon, prop, and input-hint recognition at every approved display size.

### 10. Section 13 — definition of done

Add these bullets:

- L01 communicates a calm, non-competitive Barangay journey through layered scenery and at least one approved route-progression treatment.
- Prompt presentation, world art, and feedback use one consistent illustrated 2.5D Barangay visual system.
- No journey-feedback feature introduces points, coins, streak pressure, leaderboards, faster travel, loss states, or changes to neutral miss handling.

## Implementation boundary

This amendment is deliberately visual and experiential. Repetition targets, input mapping, action timing, pause/end behaviour, controller validation, therapist authority, and neutral missed prompts remain governed by the original BRD and PRD.
