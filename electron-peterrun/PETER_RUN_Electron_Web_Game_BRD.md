# PETER RUN - Electron Web Game BRD

> Business Requirements Document
>
> Version 1.0 | Proposed Electron, React, TypeScript and Canvas implementation | 13 September 2026
>
> Status: planning only. This document authorises no replacement or deletion of the working Godot prototype.

## 1. Purpose and decision

This BRD defines a potential clean rebuild of PETER RUN as an offline Windows desktop application built with Electron, React, TypeScript, Vite tooling, Canvas 2D, Anime.js, and browser-standard input APIs.

The product remains a calm, original 2.5D Barangay journey for supervised movement practice. It is not a competitive endless runner, a medical diagnostic tool, a treatment recommender, or an unsupervised clinical product.

The rebuild shall preserve the existing business and safety rules:

- One active movement prompt at a time.
- Four semantic actions: move_left, move_right, jump, and slide.
- A clearly visible, immediate Pause and End Session route.
- Planned repetition targets rather than score, speed, coins, streaks, or game-over states.
- Neutral misses with calm continuation.
- Therapist/caregiver control over session setup and continuation.
- Original Filipino-inspired places, art, characters, interface, sound, and animation.

The existing Godot game remains the behavioural reference until the Electron version demonstrates equivalent tested flow.

## 2. Product outcomes

1. Deliver a desktop game with a polished, modern web-style dashboard and compact therapist controls.
2. Deliver a smooth Canvas 2D three-lane runner with layered 2.5D Barangay scenery.
3. Use one typed game state and named-action input contract across keyboard, standard gamepad, and MOVE HID keyboard fallback.
4. Make AI-assisted art easy to import, review, animate, replace, and trace.
5. Keep gameplay responsive and calm at approved 16:9 display sizes without stretching art.
6. Produce a signed, offline Windows distributable after functional, hardware, and supervised usability checks.

## 3. Users and needs

| User | Need | Product response |
| --- | --- | --- |
| Player | Understand one movement at a time without pressure | Large route-sign prompt, icon, prop silhouette, short instruction, neutral misses |
| Therapist/caregiver | Configure and stop a supervised session quickly | Session setup, controller status, visible Pause, confirmable End Session, clear summary |
| Visual producer | Create AI-assisted art without inconsistent or untraceable assets | Reference registry, master-style lock, transparent final exports, sprite/frame checklist |
| Developer | A maintainable TypeScript desktop app | Separate Electron main/preload/renderer layers; pure domain state; testable Canvas engine |
| Hardware tester | Know whether input is keyboard, standard gamepad, or MOVE HID | Input status, controlled debounce, controller check, disconnect messaging, documented test procedure |

## 4. Approved technology baseline

Use currently supported stable releases when the project is scaffolded. Exact versions must be resolved then locked in the package manager lockfile, recorded in a release manifest, and updated through a controlled dependency review. Do not use nightly, alpha, beta, or unpinned production dependencies.

| Layer | Approved technology | Role and boundary |
| --- | --- | --- |
| Desktop shell | Electron, current stable release | Windows window lifecycle, packaging, app-level settings, restricted native capabilities |
| Build/dev | electron-vite with Vite and TypeScript | Fast local development and separate main, preload, and renderer bundles |
| UI | React 19.3 or current stable React release at scaffold time | Dashboard, setup, tutorial, settings, pause, summary, accessibility semantics |
| Gameplay render | HTML Canvas 2D plus requestAnimationFrame | Authoritative 2D world rendering, sprite animation, parallax, prompt projection, effects |
| UI motion | Current Anime.js release | DOM card, button, toast, modal, and progress motion only; not game simulation timing |
| Input | DOM Keyboard Events plus Gamepad API | Keyboard and compatible standard gamepads mapped to semantic actions |
| MOVE integration | Debounced HID keyboard events initially | Firmware emits A/D/W/S/P press-release pairs; no raw sensor values are parsed in renderer gameplay |
| Audio | Web Audio / HTML audio behind an AudioService | Local licensed music and effects, controlled volume, mute, and pause-safe playback |
| Unit tests | Vitest | Pure session, input, prompt, lane, timing, asset-manifest, and settings logic |
| UI/app tests | Playwright Electron automation | Renderer flow and packaging smoke checks; native dialog cases are mocked deterministically |
| Formatting/linting | ESLint, Prettier, TypeScript strict mode | Static quality gate |
| Packaging | Electron Forge packaging evaluation | Windows installer/portable release proof, signing plan, clean-machine verification |
| Dependency hygiene | npm lockfile plus automated update pull requests | Reproducible installs and reviewed current-stable upgrades |

React's current official documentation identifies version 19.3 as latest at the time of this BRD. Electron, Vite, TypeScript, Anime.js, Playwright, and Electron Forge must be selected at their then-current stable compatible releases during scaffolding, never by copying stale version numbers from a document.

## 5. Architecture

### 5.1 Process boundary

~~~text
Electron main process
  - creates the local application window
  - owns app lifecycle, packaging-only services, and narrow preference storage
  - never contains gameplay state

Preload process
  - exposes a small, typed allowlist through contextBridge
  - offers only preference read/write and controlled app metadata APIs
  - never exposes generic IPC send, Node, filesystem, shell, or raw HID access

React renderer process
  - owns application navigation, accessible UI, settings forms, and summary
  - mounts the Canvas game surface
  - owns the typed game session and Canvas engine
  - has no Node integration and no direct privileged Electron APIs
~~~

Electron security is a release requirement. The renderer shall run with nodeIntegration disabled, contextIsolation enabled, sandboxing enabled, a restrictive Content Security Policy, local packaged content only, blocked untrusted navigation, and a typed allowlist of preload APIs. Any future remote content requires a new security review.

### 5.2 Renderer modules

~~~text
src/renderer/
  app/                 React routes, shell, providers, error boundary
  features/
    dashboard/         opening, music control, route introduction
    session-setup/     affected side, targets, route and input readiness
    controller-check/  keyboard/gamepad/HID instructions and status
    tutorial/          guided action practice
    game/              React host for CanvasRunner
    pause/             pause, end-level, end-session confirmations
    summary/           result, exertion, rest/retry/finish
    settings/          audio, accessibility, controls and session link
  game-engine/
    loop/              fixed-step update and requestAnimationFrame render
    world/             lanes, player state, prompt prop, parallax, effects
    input/             semantic action adapter and debounce
    prompts/           deterministic prompt state machine
    session/           targets, neutral misses, result snapshot
    render/            Canvas draw passes and sprite atlas loading
  shared/
    domain/            typed actions, session config/result, level definition
    assets/            runtime asset manifest and loader
    accessibility/     reduced motion, high contrast, labels
~~~

### 5.3 Canvas game loop

The Canvas surface is a game renderer, not a React component that rerenders every frame.

- Preserve a 480 x 270 logical game world for continuity with the current prototype.
- Render Canvas at device-pixel-ratio-aware backing resolution while mapping world coordinates to the logical 480 x 270 space.
- Maintain a 16:9 CSS viewport with letterboxing instead of geometric distortion.
- Use one requestAnimationFrame renderer and a fixed simulation update step.
- Clamp long background-tab deltas before simulation. A paused session must run no world, prompt, counter, or effect updates.
- Use Canvas engine interpolation for lane movement, jump arc, prop approach, sprite frames, shadows, dust, and parallax.
- Use Anime.js only for React/DOM presentation: cards, menu transitions, toast entry/exit, modal dimming, and optional progress polish. It must not control repetition timing or Canvas physics.

Canvas draw order:

1. Sky and far environment
2. Distant Barangay houses and trees
3. Midground roadside layer
4. Road/lane layer
5. Active prompt prop and ground shadow
6. Peter and player shadow
7. Near foreground
8. Canvas-safe feedback effects
9. React DOM HUD, prompt text, Pause, and accessibility overlay

## 6. Functional business requirements

### 6.1 Session and gameplay

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| EBR-01 | The game shall use move_left, move_right, jump, slide, and pause_session as its only gameplay action names. | Must | Canvas world and session logic never inspect raw keycodes, raw HID data, or sensor angles. |
| EBR-02 | The player shall occupy left, centre, or right lane and never leave the permitted lane range. | Must | Boundary input remains safe and does not create duplicate repetitions. |
| EBR-03 | The game shall show at most one actionable prompt at a time. | Must | A prompt uses word, icon, prop silhouette, and applicable input hint in warning and response states. |
| EBR-04 | Correct action shall increment exactly one matching planned target. | Must | Held, duplicate, late, and wrong input cannot create extra repetitions. |
| EBR-05 | Wrong or absent response shall be a neutral miss. | Must | No score loss, health, collision damage, chase, fail screen, forced restart, or shame language exists. |
| EBR-06 | A level shall complete only after prescribed targets are met. | Must | Completion is never based on score, speed, time, collision, or collectible count. |
| EBR-07 | Pause shall be visible during play and freeze Canvas, Anime.js feedback, timers, audio effects, and input acceptance immediately. | Must | Resume returns to the same coherent prompt state; End Session asks for confirmation. |
| EBR-08 | Gentle route progression may use landmarks, stamps, or completion moments only. | Should | It never changes pace, target counts, neutral-miss rules, or therapist control. |

### 6.2 Controls and MOVE controller

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| EBR-10 | Keyboard support shall always remain available. | Must | A/D/W/S/P map to semantic actions and are shown in Controller Check. |
| EBR-11 | A compatible standard gamepad shall support D-pad Left/Right, South/A jump, East/B slide, and Start pause. | Must | Gamepad connection, disconnection, and standard-mapping status are visible; only one press counts once. |
| EBR-12 | MOVE controller support shall initially use debounced HID keyboard events. | Must | Firmware press/release pairs produce the same semantic actions as keyboard without gameplay changes. |
| EBR-13 | A non-standard raw HID controller shall not be assumed to work through the Gamepad API. | Must | If the device is not keyboard HID or standard-mapped gamepad, implementation stops at a hardware-spike decision; no unsafe raw-device parsing is added to the renderer. |
| EBR-14 | Controller loss during an active session shall not crash the app. | Must | Keyboard remains available; the operator receives a clear status/pause route. |
| EBR-15 | Affected-side inversion shall occur only in the semantic input adapter. | Must | Art, prompt meaning, Canvas player, and repetition result remain unaware of physical-device orientation. |

### 6.3 React UI and therapist controls

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| EBR-20 | The app shall provide Dashboard, Setup, Controller Check, Tutorial, Ready, Gameplay, Pause, Settings, and Summary states. | Must | The full supervised flow has no dead-end route. |
| EBR-21 | Settings shall separate comfort/preferences from session controls. | Must | Audio, mute, reduced motion, high contrast, input guide, and display information are separate from affected side and target configuration. |
| EBR-22 | Session Setup shall expose affected side, prescribed repetitions, route, and controller readiness. | Must | No speed slider, leaderboard, score goal, or unsafe pacing control is offered. |
| EBR-23 | UI controls shall be compact, text-led, mouse/trackpad accessible, and keyboard-focusable. | Must | Icons complement labels; Pause and End Session never rely on colour or an icon alone. |
| EBR-24 | The gameplay HUD shall be visually quieter than the active route prompt and world prop. | Must | It provides only necessary progress, action cue, input hint, and Pause information. |
| EBR-25 | Summary shall show completion, neutral misses, optional in-game exertion rating, Rest, Retry, and Finish choices. | Must | An exertion value is recorded only; it never automatically clears a player to continue. |

### 6.4 Art, animation, and assets

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| EBR-30 | Runtime art shall be original or licensed and stored independently from raw references. | Must | AI source render, source/workflow, seed when available, licence, owner, and approval state are recorded before runtime use. |
| EBR-31 | L01 shall be a calm layered 2.5D Barangay Morning route. | Must | It avoids railway/subway settings, trains, guards, chases, coins, hoverboards, graffiti branding, and copied commercial-runner patterns. |
| EBR-32 | Peter shall use a consistent back-facing sprite set. | Must | Idle, four running frames, lane leans, jump, slide, landing, and success pose share clothing, scale, canvas anchor, and ground baseline. |
| EBR-33 | Action props shall have clear separate silhouettes. | Must | Crate/marker supports lane shift, puddle/curb supports jump, laundry line/awning supports slide. |
| EBR-34 | Canvas shall provide smooth visual feedback through code plus assets. | Should | Parallax, grounded shadows, jump separation, dust, landing puff, prompt anticipation, and calm success effects are present without speed pressure. |
| EBR-35 | Asset loading shall be manifest-driven. | Must | Missing assets fail safely in development, show a clear diagnostic, and do not silently substitute unrelated art in a release. |

### 6.5 Accessibility, safety, and performance

| ID | Requirement | Priority | Acceptance criteria |
| --- | --- | --- | --- |
| EBR-40 | The app shall remain a supervised prototype and clearly avoid clinical claims. | Must | Copy does not diagnose, score movement quality, prescribe actions, or claim rehabilitation outcomes. |
| EBR-41 | The app shall support reduced motion and high contrast without removing prompt clarity. | Must | Reduced motion lowers nonessential parallax/effect intensity; prompts, pause, and session flow remain available. |
| EBR-42 | Essential instruction shall not depend on colour, sound, or animation alone. | Must | Every active action is communicated by text, icon, and distinct prop silhouette. |
| EBR-43 | The renderer shall maintain responsive input and calm presentation on approved target hardware. | Must | No frame hitch causes duplicate action acceptance, prompt-state corruption, or hidden Pause control. |
| EBR-44 | The app shall work offline after installation. | Must | No external network service is required to play a session or load final assets. |
| EBR-45 | The app shall preserve the 16:9 game composition without stretching. | Must | Test at 480 x 270 logical world, 960 x 540, 1024 x 768, 1280 x 720, and 1920 x 1080 output. |

## 7. Asset production and AI-assisted art workflow

AI assistance can generate concepts and approved source poses, but it cannot be treated as a final asset pipeline by itself.

~~~text
Style reference approved
  -> generated concept candidates
  -> selected master visual
  -> cleanup, transparency, palette and silhouette check
  -> sprite/frame or parallax-layer export
  -> asset manifest and licence record
  -> Canvas integration
  -> native-size and scaled visual review
~~~

Required L01 runtime asset inventory:

| Group | Minimum delivery |
| --- | --- |
| Peter | Idle, 4 run frames, 2 lane leans, 3 jump frames, 2 slide frames, landing, success, shadow |
| Route | Road base plus sky/far, home/mid, roadside, road/lane, and foreground layers |
| Prompts | Crate/marker, puddle/curb, laundry line/awning, matching ground shadows |
| Effects | Run dust, landing puff, restrained success sparkle, soft prompt marker |
| UI art | Logo/wordmark, optional icon set, Dashboard hero, L01 thumbnail, completion illustration |
| Journey | 3-5 calm landmarks and one non-competitive progress/stamp treatment |

Raw generation references belong in a references folder. Final runtime PNG/WebP assets belong under assets/runtime and must not have baked UI text, white backgrounds, inconsistent frames, or unreviewed licence status.

## 8. Data model and persistence

The first Electron release shall use local-only preferences and in-memory session results.

| Model | Fields |
| --- | --- |
| SessionConfig | affectedSide, targets by action, selectedLevel, input preference, accessibility preferences |
| LevelDefinition | id, title, palette, asset references, planned sequence, prompt timing, landmark plan |
| PromptState | scheduled, warning, active, resolved, action, lane, elapsed time |
| SessionResult | completed by action, neutralMisses, selected level, optional exertion rating, explicit therapist decision |
| AssetManifestEntry | id, file path, dimensions, source record, version, licence, approval status |

No accounts, cloud sync, analytics, patient database, background telemetry, or automatic progression is in scope.

Preferences may persist locally only through a narrow typed preload API. Do not expose filesystem-wide access to the React renderer.

## 9. Quality, security, and testing requirements

### Test layers

| Layer | Tooling | Required focus |
| --- | --- | --- |
| Pure domain logic | Vitest | lane bounds, action debounce, affected-side mapping, prompt transitions, neutral misses, target completion |
| Canvas engine | Vitest with deterministic time/input | pause freeze, projection scale, sprite-state selection, one-prompt rule, asset-manifest validation |
| React UI | React Testing Library with Vitest | setup, settings, accessibility labels, focus, summary choices, route safety copy |
| Electron E2E | Playwright Electron | Dashboard to summary flow, Pause/Resume/End, settings, local packaged window smoke |
| Visual regression | Playwright screenshot capture | native and approved output sizes; no clipped/hiding prompt or distortion |
| Hardware | Windows manual test | keyboard, standard gamepad, MOVE HID Notepad preflight, disconnect/reconnect |
| Supervised usability | Facilitated checklist | prompt clarity, comfort, pause confidence, therapist control; not clinical effectiveness |
| Release | Electron Forge output on a clean Windows machine | offline launch, full session, assets/audio, signed distribution when applicable |

### Required automated scenarios

1. Every keyboard and gamepad mapping produces one semantic action once per press.
2. Holding or duplicate pulses do not farm repetitions.
3. Left/right boundaries retain a safe lane.
4. Wrong, late, and absent input record neutral misses and continue.
5. Pause freezes Canvas updates, route approach, timers, audio feedback, and session counters.
6. Resume does not create a duplicate prompt.
7. End Session reaches a confirmable summary safely.
8. Assets load from manifest and missing assets are reported in development.
9. Settings and Controller Check remain keyboard/mouse accessible.
10. The same scene remains legible at every approved output size.

## 10. Migration plan and gates

### Phase A - Foundation decision

- Create this new repository/folder without changing or deleting Godot.
- Scaffold Electron, React, TypeScript, and Vite build layers.
- Establish security defaults, strict TypeScript, linting, formatting, Vitest, and a smoke Electron test.
- Demonstrate a local window and a Canvas 480 x 270 surface.

Exit gate: packaged development shell launches offline and all security defaults are verified.

### Phase B - Behavioural vertical slice

- Implement typed SessionConfig, SessionResult, named actions, keyboard adapter, basic gamepad adapter, and deterministic prompt state machine.
- Implement three lanes, one placeholder player, one prompt at a time, neutral miss, immediate Pause, and Summary.
- Port the existing L01 behavioural tests conceptually; do not copy Godot code.

Exit gate: keyboard-only L01 can complete one planned action set with Pause and neutral misses.

### Phase C - Controls and session UI

- Implement Dashboard, Setup, Controller Check, Tutorial, Ready, Settings, Pause, Summary, and local-only preference storage.
- Implement generic gamepad support and MOVE HID keyboard compatibility.
- Run real standard-gamepad and MOVE HID hardware checks separately.

Exit gate: an operator can complete setup-to-summary using keyboard; supported controller state is clear.

### Phase D - Art and presentation

- Integrate selected Peter and Barangay assets.
- Add Canvas sprite animation, parallax, prop approach, shadows, effects, and route landmarks.
- Add Anime.js menu, modal, toast, and feedback motion.
- Complete visual regression checks and reduced-motion variant.

Exit gate: L01 meets art, readability, originality, and performance acceptance criteria.

### Phase E - Packaging and supervised prototype review

- Package a Windows candidate with Electron Forge.
- Perform clean-machine offline test, signing decision, hardware tests, and facilitated supervised usability review.
- Document known limitations and retain no unapproved clinical claims.

Exit gate: prototype distribution decision is documented; any clinical use still requires qualified approval.

## 11. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| Rebuild loses working Godot behaviour | Keep Godot intact as reference; port one testable vertical slice before visual work |
| React rerenders interfere with gameplay | Keep mutable simulation state in Canvas engine; React receives coarse UI state only |
| Anime.js and Canvas use competing clocks | Canvas fixed-step loop owns gameplay; Anime.js only owns DOM presentation |
| Gamepad API sees an unknown device | Maintain keyboard/HID fallback; validate MOVE as HID keyboard or standard gamepad before dependency commitment |
| Custom raw HID access expands security/scope | Treat it as a separate native hardware spike with explicit approval and threat review |
| AI sprite frames vary | Lock master reference, model/workflow/seed where available; clean selected frames; enforce anchor/palette/silhouette checklist |
| Canvas becomes visually stretched | Use logical coordinates, DPR-aware backing store, CSS 16:9 containment, and output-size tests |
| Electron security is weakened for convenience | Keep Node out of renderer; expose narrow typed preload APIs only; use local content and CSP |
| Dependency drift | Lock versions, review updates, and follow current stable Electron security releases |
| UI becomes medical or too large | Use compact cards, one primary action, text-led safety controls, and visual regressions |
| Scope includes clinical validation | Keep supervised prototype claims only; require therapist and hardware evidence separately |

## 12. Definition of done

The Electron rebuild is ready for supervised prototype feedback only when:

- It launches as an offline Windows Electron application using current stable, locked dependencies.
- Electron security defaults are active: local content, nodeIntegration disabled, context isolation, sandboxing, CSP, and narrow typed preload APIs.
- Dashboard through Summary is complete with safe Pause/End, neutral misses, planned repetitions, and no competitive progression.
- Keyboard works; standard gamepad support and MOVE HID keyboard behaviour are honestly tested and documented.
- L01 uses approved original Barangay world art, Peter animation, and distinct action props in a layered Canvas 2D world.
- Canvas movement, prompt approach, pause behaviour, and React/Anime.js feedback are smooth and do not alter session rules.
- Automated unit, UI, Electron flow, and visual checks pass at all approved display sizes.
- The Windows package has been tested outside development tooling on a clean target machine.
- Known limitations, asset provenance, licence status, controller test result, and clinical non-claims are documented.

## 13. Decisions required before implementation

1. Confirm that Electron rebuild is approved instead of continued Godot development.
2. Confirm Windows-only first release versus future cross-platform support.
3. Confirm MOVE controller mode: HID keyboard, standard gamepad, or separate raw-HID feasibility spike.
4. Approve the Peter and Barangay master visual references and AI-assisted asset licence policy.
5. Confirm whether settings remain local-only or future patient/session storage is separately funded and reviewed.
6. Confirm target device hardware and display sizes for the first Windows package.
7. Confirm whether Electron Forge packaging is selected after its compatibility spike with the chosen Vite template.

## 14. Technical references

- Electron security and context isolation: https://www.electronjs.org/docs/latest/tutorial/security
- Electron preload and context bridge: https://www.electronjs.org/docs/latest/tutorial/context-isolation
- Electron packaging with Forge: https://www.electronjs.org/docs/latest/tutorial/forge-overview
- electron-vite React and TypeScript templates: https://electron-vite.org/guide/
- React TypeScript guidance: https://react.dev/learn/typescript
- Canvas animation loop: https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API/Tutorial/Basic_animations
- Gamepad API: https://developer.mozilla.org/en-US/docs/Web/API/Gamepad_API
- Anime.js current documentation: https://animejs.com/documentation/
- Playwright Electron automation: https://playwright.dev/docs/api/class-electron

