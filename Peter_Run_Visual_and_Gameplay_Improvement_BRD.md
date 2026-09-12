# PETER RUN - Visual and Gameplay Improvement BRD

> Business Requirements Document
>
> Version 1.0 | Improvement and visual-production phase | 12 September 2026
>
> This document supplements, and does not replace, Peter_Run_BRD.md and Peter_Run_PRD.md.

---

## 1. Purpose

PETER RUN has a working Godot rehabilitation-runner foundation: dashboard, patient setup, controller check, guided tutorial, ready screen, one playable Barangay Morning route, pause flow, feedback, and session summary. The next business need is to turn that functional prototype into a clear, calm, visually cohesive, deployment-ready supervised rehabilitation experience.

This phase prioritises final visual integration, readable motion, compact accessible UI, gameplay presentation, quality assurance, and Windows delivery preparation. It retains the original clinical and safety boundaries: PETER RUN motivates prescribed repetitions; it does not diagnose, prescribe treatment, assess movement quality, or make clinical decisions.

## 2. Current baseline

| Area | Current state |
| --- | --- |
| Engine | Godot 4, 2D Compatibility renderer, 480 x 270 logical canvas |
| Main route | L01 Barangay Morning |
| Supported actions | Move left, move right, jump, slide, and pause |
| Core flow | Dashboard -> setup -> controller check -> tutorial -> ready -> gameplay -> summary |
| Gameplay logic | One prompt at a time; success and neutral miss outcomes; no game-over loop |
| Current art | Code-drawn/prototype visuals plus reference-only ComfyUI concepts |
| UI | Compact themed cards, setup, tutorial, HUD, pause, settings, and summary |
| Input | Named input actions with keyboard fallback; controller integration remains subject to hardware validation |
| Test baseline | 24 automated checks passed during the latest project health check |

## 3. Business objectives

1. Make the player immediately understand what movement is requested and what happened after they respond.
2. Make the game look like a coherent original Barangay-inspired runner rather than a technical prototype.
3. Improve perceived smoothness without increasing unsafe pace or clinical pressure.
4. Preserve accessibility, supervised-use guardrails, predictable flow, and neutral handling of missed prompts.
5. Establish an asset pipeline that can add later routes without rewriting gameplay code.
6. Prepare a reliable Windows demonstration build and a documented verification path.

## 4. Users and needs

| User | Need in this phase | Required response |
| --- | --- | --- |
| Patient | Clear, encouraging and non-embarrassing gameplay | Large readable prompts, calm feedback, consistent art, no punishment or speed pressure |
| Therapist | Fast setup and trustworthy safety controls | Visible pause/end controls, understandable repetition progress, predictable route behaviour |
| Caregiver | Assistance without learning a complex interface | Compact dashboards, plain-language labels, obvious continuation and stop actions |
| Visual producer | A repeatable way to make cohesive original assets | Versioned prompt guide, reference tracking, cleanup/export rules, asset acceptance checklist |
| Developer | Art that is easy to integrate and regression-test | Stable filenames, transparent PNGs, common canvas sizes, documented scene mapping |

## 5. Product principles and guardrails

- Calm over fast: character travel speed remains gentle and predictable. Difficulty must not be increased by making the game move faster.
- Encouragement over punishment: missed prompts remain neutral. No health bars, crashes, score loss, chase logic, collision damage, or game-over state may be introduced.
- Therapist in control: pause and end-session actions remain immediately visible and freeze gameplay without delay.
- Originality: all routes, props, UI, characters, audio, text, and animation must be original or properly licensed. Do not copy commercial endless-runner branding, assets, characters, chase structures, trains, guards, coins, or hoverboards.
- Accessibility before decoration: interface text and prompts must remain legible before optional texture, illustrations, or effects are added.
- Reusable content: later routes must use level data and replaceable visual resources, not bespoke forks of gameplay code.
- Art is not clinical evidence: visual feedback may motivate movement, but must not imply diagnosis, recovery prediction, or therapeutic effectiveness.

## 6. Scope

### In scope

- Final 2D art integration for the existing L01 Barangay Morning route.
- Peter character animation assets for run, lane shift, jump, slide, landing, and success feedback.
- Original route props, effects, parallax/background layers, dashboard artwork, and compact UI icon support.
- Gameplay presentation improvements: depth, motion readability, obstacle anticipation, feedback timing, and safe route variety.
- UI refinement across dashboard, setup, tutorial, HUD, pause, settings, and summary.
- Display scaling, performance, regression testing, art validation, Windows export preparation, and supervised usability checks.

### Out of scope

- New clinical claims, automated therapeutic recommendations, diagnosis, or motion-quality scoring.
- Unsupervised home deployment, patient accounts, cloud sync, leaderboards, advertising, multiplayer, or social features.
- 3D gameplay scenes, 3D cameras, or conversion away from the Godot 2D approach.
- Raw sensor parsing in gameplay. The controller must continue to provide debounced named HID actions.
- New routes before L01 reaches the visual and interaction acceptance criteria.
- Treating AI-generated source renders as final runtime art without selection, cleanup, licensing review, and export preparation.

## 7. Functional business requirements

### 7.1 Visual asset pipeline

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| IBR-01 | Maintain one visual-production prompt guide for all planned L01 assets. | Must | It includes character poses, route layers, props, effects, dashboard art, level thumbnail, UI icons, feedback badges, export rules, and an asset checklist. |
| IBR-02 | Keep raw AI/reference renders separate from runtime art. | Must | References are stored below code/art/_references; only approved cleaned assets are linked from Godot scenes/resources. |
| IBR-03 | Record source, model/workflow, seed where applicable, licence status, owner, and approval status for each selected runtime asset. | Must | Each runtime asset can be traced to a source record before release. |
| IBR-04 | Export runtime sprites with transparent backgrounds and documented canvas dimensions. | Must | No white rectangular background appears around Peter, props, effects, or UI icons in the game. |
| IBR-05 | Store runtime assets under stable, descriptive filenames by category. | Should | Scenes do not depend on root-level temporary image files. |

### 7.2 Player character and animation

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| IBR-10 | Use an original, back-facing, readable Peter runner design consistent with the Barangay palette. | Must | Peter is recognisable at native canvas size and does not resemble a commercial runner character. |
| IBR-11 | Deliver idle, running, lane movement, jump, slide, landing, and success animation. | Must | At least one idle pose, four run frames, two lane-lean poses, three jump poses, two slide poses, one landing pose, and one success pose are available. |
| IBR-12 | Preserve consistent silhouette, outfit, hairstyle, scale, and anchor point in all frames. | Must | No action loop visibly changes Peter's clothing, body proportions, direction, or foot placement unexpectedly. |
| IBR-13 | Keep action physics in Godot. | Must | Replacing art does not alter action timing, repetition counting, pause behaviour, or input handling. |
| IBR-14 | Add lightweight player feedback. | Should | Jump separates visibly from the shadow; slide is visibly low; lane shifts lean; landing has subtle dust; running has restrained motion detail. |

### 7.3 Route, background, and obstacles

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| IBR-20 | Present L01 as an original Filipino-inspired Barangay Morning route with a clear forward perspective and three readable lanes. | Must | A player can distinguish left, centre, and right lanes at native and 1080p output without relying only on text. |
| IBR-21 | Keep foreground space open for Peter and active prompts. | Must | Route art never obscures player, prompt prop, HUD, or pause control. |
| IBR-22 | Support layered world depth. | Should | Sky/distance, homes, roadside, road, and foreground can move at distinct rates or otherwise show clear 2.5D depth. |
| IBR-23 | Keep one distinct world-prop silhouette for every action. | Must | Move left/right uses crate or marker, jump uses puddle or curb, slide uses laundry line or awning; all are distinguishable before the response window. |
| IBR-24 | Make obstacle approach clear, gentle, and consistent. | Must | Props scale and move predictably, include grounding/shadow treatment, and do not pop suddenly onto the route. |
| IBR-25 | Keep decoration distinct from active prompts. | Must | Active prompts have stronger silhouette, placement, contrast, or anticipation than non-active scenery. |

### 7.4 UI, feedback, and audio

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| IBR-30 | Use one compact visual system across dashboard, setup, tutorial, pause, settings, and summary. | Must | Cards, buttons, colours, type scale, spacing, focus states, and icon treatment are visibly consistent. |
| IBR-31 | Keep gameplay HUD quieter than the active world prompt. | Must | The movement prompt dominates in-game attention; progress and pause stay visible without covering route action. |
| IBR-32 | Give each screen one obvious primary action and compact secondary actions. | Must | There is no ambiguous tappable-looking decoration or competing primary button. |
| IBR-33 | Preserve aspect ratio and readability at approved display sizes. | Must | 480 x 270, 1280 x 720, and 1920 x 1080 checks show no stretching, clipping, or inaccessible controls. |
| IBR-34 | Keep praise supportive, brief, and editable text. | Should | Messages such as Great timing, Nice jump, and Keep going do not shame a miss or claim clinical progress. |
| IBR-35 | Keep audio calm, distinct, and user-controllable. | Should | Music volume works; action, success, and pause cues are not startling and can be safely mixed or disabled. |
| IBR-36 | Use UI icons as supplements, not replacements for essential text. | Should | Icon-only controls have an accessible label, tooltip, or adjacent text. |

### 7.5 Gameplay presentation and content

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| IBR-40 | Keep L01 a planned rehabilitation session, not a competitive score chase. | Must | Completion is based on prescribed action targets; no score-loss or game-over condition is added. |
| IBR-41 | Add visual route variety while preserving predictability. | Should | Lane placement, safe prop spacing, and non-critical scenery can vary without simultaneous ambiguous prompts. |
| IBR-42 | Give every prompt readable anticipation. | Must | Every active prompt shows an action word, icon, prop silhouette, and understandable warning-to-response transition. |
| IBR-43 | Make tutorial visuals compatible with final gameplay visuals. | Should | Tutorial player and props use the same or clearly compatible runtime art. |
| IBR-44 | Gate future routes on L01 completion. | Should | L01 becomes the approved reusable template before new route production starts. |

### 7.6 Input, safety, and accessibility

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| IBR-50 | Continue to consume only named actions: move_left, move_right, jump, slide, and pause_session. | Must | Art and UI work introduces no direct raw sensor dependency. |
| IBR-51 | Keep Pause visible and immediately freeze player, props, timers, feedback, and presentation motion. | Must | Manual testing confirms no active world motion continues while paused. |
| IBR-52 | Keep misses neutral and sessions safely endable. | Must | No punitive collision or game-over logic exists; end-session confirmation is understandable and recoverable. |
| IBR-53 | Keep text, icons, and prop silhouettes understandable at native and approved scaled displays. | Must | Contrast and layout checks pass at all three approved display sizes. |
| IBR-54 | Validate actual controller hardware before any clinical or deployment claim. | Must | HID mapping, debounce, disconnect behaviour, left/right mapping, and therapist-approved movement range are documented and tested. |

## 8. Asset delivery inventory

### Essential first integration

| Asset | Quantity | Runtime use |
| --- | ---: | --- |
| Peter sprite set | 14 poses/frames minimum | Idle, running, lane shift, jump, slide, landing, success |
| Barangay route master | 1 | Initial L01 background |
| Route layers | 5 | Sky/distance, homes, roadside, road/lane overlay, foreground |
| Crate/marker | 1-2 | Move left/right prompt |
| Puddle/curb | 1 | Jump prompt |
| Laundry line/awning | 1 | Slide prompt |
| Effects | 3 | Run dust, landing puff, success sparkle |
| Player shadow | 1-3 variants | Grounding during run/jump/slide |

### Second visual pass

| Asset | Quantity | Runtime use |
| --- | ---: | --- |
| Dashboard hero illustration | 1 | Opening dashboard |
| L01 thumbnail | 1 | Level selection/route card |
| Session-complete illustration | 1 | Summary screen |
| UI icon set | 12 minimum | Play, pause, settings, sound, navigation, controller, action hints |
| Feedback badges | 3 | Optional decorative toast/summary accents |
| Decorative props | 4-8 | Non-active route variety, clearly distinct from action props |

## 9. Delivery plan

| Phase | Focus | Exit criteria |
| --- | --- | --- |
| A. Art lock | Select master Peter and Barangay style; record source/licence/workflow details | One approved style direction and no ambiguous visual references |
| B. Essential asset production | Peter frames, route base, three prompt props, effects, transparency cleanup | Assets meet naming, canvas, silhouette, and approval rules |
| C. Godot integration | Replace prototype visuals while retaining existing logic and tests | Player and props work in tutorial and L01 without regression |
| D. Presentation polish | Parallax, depth, feedback timing, HUD refinement, audio mix | Gameplay is clear and calm at all target display sizes |
| E. Validation and release | Regression, visual review, controller test, supervised usability check, Windows export | Release checklist and known limitations are documented |

## 10. Test and acceptance strategy

### Automated regression

- Run the existing project setup and gameplay/UI test suite after each logic or scene integration change.
- Add deterministic checks for sprite assignment, resource loading, asset visibility, pause behaviour, and responsive UI conditions where practical.
- Keep test evidence separate from runtime art.

### Visual checks

- Review dashboard, setup, tutorial, ready, L01 gameplay, pause, and summary at 480 x 270, 1280 x 720, and 1920 x 1080.
- Confirm aspect ratio is preserved; no source image, HUD, or text may be stretched.
- Verify Peter and active props are recognisable at native size.
- Confirm prompt props do not blend into route décor.
- Check transparent assets for halos, white boxes, clipped feet, or inconsistent anchors.

### Supervised play checks

- Observe a therapist/caregiver navigating a full setup-to-summary session.
- Observe whether a player can identify the required action from prop, icon, and label without excessive coaching.
- Confirm pause/end-session controls are discoverable and immediately effective.
- Record usability issues without treating the observation as clinical validation.

### Hardware checks before deployment

- Test actual MOVE Controller HID mapping.
- Confirm one physical movement produces one named action event.
- Test disconnect, reconnect, input hold, accidental repeat, and left/right mapping.
- Obtain therapist approval for all actual movement ranges and session configuration.

## 11. Performance and release requirements

| Area | Requirement |
| --- | --- |
| Platform | Offline Windows desktop build remains the intended MVP delivery target. |
| Frame pacing | Gameplay should be visually smooth on approved demonstration hardware; art must not cause visible hitches in normal prompt flow. |
| Asset budget | Use suitable imported textures for the 2D base canvas; do not load full-resolution reference renders at runtime. |
| Scaling | Preserve the 480 x 270 logical canvas and aspect-preserving scale policy. |
| Build contents | Include executable, export dependencies as required, licence/attribution record, controller instructions, and basic run instructions. |
| Data | Do not introduce cloud accounts or patient data storage in this phase. |
| Known limitations | Clearly state prototype and clinical-validation limitations in the handoff. |

## 12. Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| AI generations vary between frames | Animation looks unstable | Lock reference, model, seed and palette; clean selected frames before export; use Godot tweening for in-between motion |
| Reference images are used directly at runtime | Licensing, visual, or performance issues | Keep raw images in _references; require approval and cleanup before runtime use |
| Decorative art hides prompts | Players miss movement cues | Maintain clear action space, distinct silhouettes, contrast review, and visual regression checks |
| Polishing adds unsafe intensity | Experience becomes stressful | Keep travel speed fixed, use soft effects, never add punitive mechanics, validate with supervised play |
| UI art reduces legibility | Accessibility regression | Keep text/contrast rules; use icons as supplements; test three display sizes |
| Full-resolution assets reduce performance | Stutter during play | Export fit-for-purpose runtime textures and test on target hardware |
| Controller assumptions differ from device | Input failure or unsafe mapping | Validate physical HID behaviour before release |
| Scope expands into new routes early | L01 remains unfinished | Treat L01 completion as the gate for future route production |

## 13. Definition of done

This improvement phase is complete only when:

- L01 Barangay Morning uses approved original runtime art for Peter, background, and all three action props.
- Peter has consistent readable animation for run, lane shift, jump, slide, landing, and success.
- Active props approach with understandable depth, grounding, and anticipation without becoming threatening.
- Dashboard, tutorial, HUD, pause, settings, and summary follow one compact UI system.
- Gameplay and UI preserve aspect ratio and usability at all three approved display sizes.
- Pause/end session, neutral misses, named action input, and all safety guardrails remain intact.
- Automated regression passes after integration; visual/manual checks are recorded.
- Runtime assets are traceable, cleaned, approved, correctly licensed, and outside the raw-reference path.
- A tested Windows demonstration export, known-limitations note, and controller-validation plan are available.

## 14. Stakeholder decisions required

1. Approve the chosen Peter character master and Barangay visual master before production starts.
2. Decide whether the final style is hand-drawn cartoon, pixel-art-inspired, or a controlled hybrid.
3. Confirm AI-assisted art source/licence policy and final asset approver.
4. Confirm target Windows hardware, display sizes, and controller connection/mapping assumptions.
5. Confirm therapist-approved action ranges, repetition defaults, left/right mapping, and disconnect protocol.
6. Decide whether future routes begin only after L01 usability feedback.

## 15. Document relationship

- Peter_Run_BRD.md: product and clinical/business baseline.
- Peter_Run_PRD.md: technical product requirements and MVP architecture.
- code/art/_references/comfyui_prompts/l01_barangay_v01.md: focused Barangay route prompt.
- code/art/_references/comfyui_prompts/peter_runner_animation_v01.md: full visual-production prompt guide.
- This document: improvement-phase business requirements, acceptance conditions, and delivery gates.

