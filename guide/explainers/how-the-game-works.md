# How the Game Works

## One run in plain words

1. The therapist sets the plan: how many repetitions of each movement.
2. Peter stands near the bottom of the screen on one of three lanes. The street moves toward him.
3. The game shows **one** instruction and obstacles that match it. First *GET READY* (about 2½ s at standard speed; 1½ s at game speed 1 up to 4 s at speed 10), then *MOVE NOW* (about 2 s).
4. The player does the movement. If it is the right movement and Peter ends in the right lane, it counts as a repetition.
5. If not, it is a *neutral miss*: no penalty, and the next obstacle is easier. If Peter is left in a lane with an obstacle, the run ends and everything done is kept.
6. After a short settle (under 1 s), the next instruction comes. This repeats until every repetition target is met, or the therapist ends the session.
7. The player chooses the game speed for the next run (1 = faster, 10 = slower; also set in Setup), then the therapist chooses Rest, Retry or Finish.

The diagrams below show the same thing in more detail. For the code behind it, see [How the Code Works](how-the-code-works.md) and the [Glossary](glossary.md).

---

> Mermaid diagrams: they render in GitHub, VS Code (Markdown Preview Mermaid Support), and Obsidian.
> Source of truth: `code/scripts/*.gd`. Updated for the v18 build, 2026-10-26. The speed model is explained in [Game Speed](game-speed.md).

---

## 1. What the game is (one picture)

```mermaid
flowchart LR
    T["Therapist<br/>configures session"] --> G["PETER RUN<br/>Godot 4 · 2D + 2.5D lanes"]
    P["Patient<br/>does leg movements"] -->|"MOVE wearable (ESP32)<br/>sends HID keys A/D/W/S/P"| G
    P -.->|"or keyboard / gamepad"| G
    G --> R["Session review<br/>reps done · speed choice 1–10"]
    R --> T
```

**Rules that never change:** fixed response window of 2.0 s (difficulty = repetition count; game speed only changes the GET READY warning and the scenery) · one prompt at a time · Left/Right are literal · **obstacle contact ends the run** · no lives, score loss, chase or shaming.

---

## 2. Screen flow (scene to scene)

```mermaid
flowchart TD
    M["main.tscn<br/>Opening dashboard + settings"] -->|Start Session| S["patient_setup.tscn<br/>reps 1–50 per action · route"]
    M -->|Tutorial| TU["tutorial.tscn"]
    M -->|Settings → Check controller| CC["controller_check.tscn"]
    S -->|Continue| RD["ready.tscn<br/>review plan"]
    S -.optional.-> CC
    S -.optional.-> TU
    RD -->|Start Session| L["runner_level.tscn<br/>THE GAME LOOP"]
    RD -.optional.-> TU
    RD -.optional.-> CC
    TU --> RD
    CC --> RD
    L -->|"run ends (reps done / collision / End Level / End Session)"| SM["session_summary.tscn<br/>rate effort 1–10"]
    SM -->|"Retry (needs rating)"| RD
    SM -->|Rest| SM
    SM -->|Finish| M
```

Shared state between scenes lives in static stores: `session_setup_store.gd` (the `SessionConfig`), `session_review_store.gd` (the `SessionResult` and the review decision).

---

## 3. Code architecture

```mermaid
flowchart TB
    subgraph IN["Input"]
        IM["project.godot InputMap<br/>move_left · move_right · jump · slide · pause_session"]
        IA["input_adapter.gd<br/>whitelist + 0.35s cooldown + ignore held keys"]
    end

    subgraph DATA["Data (no logic)"]
        SC["session_config.gd<br/>affected side · reps per action"]
        LD["level_definition.gd + data/levels/*.tres<br/>colors · timings · props · formations"]
        PD["pattern_definition.gd<br/>validates a formation"]
        LS["level_selection.gd / level_catalog.gd"]
    end

    subgraph CORE["Core loop — runner_level_controller.gd (orchestrator)"]
        RLC["runner_level_controller.gd"]
        PDIR["prompt_director.gd<br/>state machine"]
        FR["pattern_library_resolver.gd +<br/>formation_collision_resolver.gd"]
        PC["player_controller.gd +<br/>player_lane_state.gd"]
        SR["session_result.gd<br/>counts reps · misses · RPE"]
    end

    subgraph VIS["Presentation (2.5D illusion)"]
        WM["world_motion_controller.gd<br/>props approach the contact line"]
        L01["l01_* scripts + road_projection.gd +<br/>route_journey.gd + route_side_art.gd"]
        FX["contact_effects · feedback_toast · classic_runner_sprite"]
    end

    IM --> IA --> RLC
    SC --> RLC
    LS --> LD --> RLC
    PD --> FR
    RLC <--> PDIR
    RLC --> FR
    RLC --> PC
    RLC --> SR
    RLC --> WM
    WM --> L01
    RLC --> FX
    SR --> SUM["session_summary_controller.gd"]
```

**Division of labour**
| Piece | Owns | Does *not* know about |
| --- | --- | --- |
| `input_adapter` | which actions are valid, debounce | what the game wants |
| `prompt_director` | WARNING → ACTIVE → RESOLVED → IDLE and whether the answer was correct | timers, art, collisions |
| `runner_level_controller` | timers, wiring, HUD, end/pause flow | art details |
| `formation_collision_resolver` | "is the player in an obstacle lane?" | everything else (19 lines, pure) |
| `world_motion_controller` + `l01_*` | how it *looks* | whether the answer was right |
| `session_result` | counts | UI |

---

## 4. The heart of the game: one prompt cycle

Per level timing (defaults in `level_definition.gd`): **warning 2.5 s → response 2.0 s → resolved 0.75 s ≈ 5.25 s per prompt.**

```mermaid
stateDiagram-v2
    [*] --> IDLE
    IDLE --> WARNING: _schedule_next_prompt()<br/>picks formation + action
    WARNING --> ACTIVE: warning_timer (2.5s)<br/>"GET READY" → "MOVE NOW"
    ACTIVE --> RESOLVED: player input accepted<br/>or response_timer (2.0s)
    RESOLVED --> IDLE: resolve_timer (0.75s)
    RESOLVED --> [*]: collision / reps met → end overlay
```

### Sequence — what happens between a keypress and the next prompt

```mermaid
sequenceDiagram
    actor Pt as Patient
    participant IA as InputAdapter
    participant RLC as RunnerLevelController
    participant PL as Player
    participant PDIR as PromptDirector
    participant COL as CollisionResolver
    participant RES as SessionResult
    participant WM as WorldMotion (visuals)

    RLC->>PDIR: schedule(action, lanes)
    PDIR-->>RLC: WARNING
    RLC->>WM: props start approaching ("GET READY")
    Note over RLC: after 2.5s
    RLC->>PDIR: open_response_window()
    PDIR-->>RLC: ACTIVE ("MOVE NOW")

    Pt->>IA: press W / A / D / S
    IA-->>RLC: logical action (or "" if held / cooling down)
    RLC->>PL: handle_action()  (move lane / jump / slide)
    PL-->>RLC: movement_accepted?
    Note over RLC: formation prompts keep the LATEST valid action<br/>and judge it at the contact line (correctable)
    RLC->>PDIR: receive_action(action, lane, accepted)
    PDIR-->>RLC: RESOLVED (SUCCESS | NEUTRAL_MISS | SAFE_CLEAR)

    RLC->>COL: player_hits_formation(formation, lane, resolution)
    alt collided
        RLC-->>Pt: "Run ended" overlay, reps saved
    else no collision
        RLC->>RES: SUCCESS → record rep · NEUTRAL_MISS → count miss
        RLC->>WM: resolve approach, toast "Nice step!"
        alt all targets met
            RLC-->>Pt: "Level complete" overlay
        else more to do
            RLC->>PDIR: (0.75s) → IDLE → schedule next
        end
    end
```

---

## 5. Decision logic: how a response is judged

```mermaid
flowchart TD
    A["Prompt ACTIVE<br/>(needed action X, obstacle lane L)"] --> B{"Input arrived<br/>before 2.0s?"}
    B -- no --> C{"Idle safe-clear allowed<br/>and Peter already in safe lane?"}
    C -- yes --> SC["SAFE_CLEAR ✅<br/>no rep counted, no miss"]
    C -- no --> NM["NEUTRAL_MISS"]
    B -- yes --> D{"Same action as required<br/>AND movement accepted<br/>AND lane correct?"}
    D -- yes --> OK["SUCCESS ✅<br/>rep recorded"]
    D -- no --> NM

    OK --> Z["No collision possible"]
    SC --> Z
    NM --> E{"Is Peter's final lane<br/>one with an obstacle?"}
    E -- yes --> X["💥 RUN ENDS<br/>review opens, completed reps kept"]
    E -- no --> F["Count neutral miss<br/>next formation = RECOVERY (easier)"]
```

**Lane rules (`prompt_director._is_spatially_correct`)**
| Action | Counts as correct when Peter ends in… |
| --- | --- |
| `move_left` | lane `prompt_lane − 1` (clamped 0–2) |
| `move_right` | lane `prompt_lane + 1` (clamped 0–2) |
| `jump` / `slide` | one of the formation's allowed `action_lanes` (or the prompt lane) |

**Prop → action:** crate = move · puddle = jump · laundry line = slide (each has a distinct silhouette, per the one-prompt-at-a-time rule).

---

## 6. Session lifecycle & ending a run

```mermaid
flowchart LR
    RUN["Running prompts"] --> P{"Pause (P / Start)"}
    P --> PO["Pause overlay<br/>everything frozen<br/>Resume · End Level · End Session"]
    PO --> CONF["Confirm dialog<br/>(Cancel returns to pause)"]
    CONF --> END
    RUN -->|"all rep targets met"| END["End overlay<br/>(reason: completed)"]
    RUN -->|"obstacle contact"| END2["End overlay<br/>(reason: collision)"]
    RUN -->|"bad level / empty route"| END3["End overlay<br/>(reason: configuration_error)"]
    END --> SUMM["session_summary<br/>RPE 1–10 → Retry · Rest · Finish"]
    END2 --> SUMM
    END3 --> SUMM
```

---

## 7. The 2.5D illusion (what the player *sees*)

```mermaid
flowchart LR
    S["Sky / distant layer"] --> H["Horizon"]
    H --> RD["Road in perspective<br/>road_projection.gd"]
    RD --> SD["Side art: houses, stalls<br/>route_side_art / l01_roadside_travel"]
    SD --> PR["Prompt props scale up<br/>toward the contact line<br/>world_motion_controller"]
    PR --> PK["Peter fixed near the bottom<br/>3 lanes: 0 · 1 · 2"]
```

Nothing is 3D: Peter never moves forward; the world moves *toward* him. Level look (colors, props, timings) comes from `data/levels/l01_barangay.tres`, `l02_market.tres`, `l03_rainy_crossing.tres` (hidden routes stay in the catalog via `show_in_setup = false`).

---

## 8. Test map (how it's protected)

| Area | Examples in `code/tests/` |
| --- | --- |
| Input safety | `input_adapter_test`, `keyboard_gameplay_input_test`, `controller_safety_test` |
| Prompt/collision logic | `formation_collision_resolver_test`, `formation_runner_test`, `contact_response_test` |
| Flow | `session_setup_flow_test`, `guided_tutorial_test`, `controller_check_interaction_test` |
| Visuals | `l01_*` route tests, `classic_*` sprite/animation tests |

Run all-rules check: `godot --headless --path code -s res://tests/project_setup_smoke.gd`.

---

## 9. Status & planned work

**Done (v19):** full flow menu → setup → ready → moving 3-2-1 countdown → L01 → summary; formation-based prompts; contact-ends-run; game speed 1–10 (scenery, stride, GET READY warning); up to 50 reps per movement; local session history file; tutorial; controller check with a Sensitivity setting and a delay test; 86 Godot test scripts green.

**Open / to plan**
1. **Docs drift:** BRD, PRD and the originality docs still say misses are neutral. Update them to "contact ends the run" (no code change).
2. **Clinical sign-off** for the collision rule is not recorded.
3. **Art in progress (uncommitted):** L01 v04–v08 image sets, Blender 3D adaptation, classic character compositor. Needs an approved final set and a provenance entry before it ships.
4. **Hardware:** validate the MOVE controller (`controller_firmware/`) end-to-end as HID keys.
5. **More routes:** only L01 is offered in setup; L02/L03 exist but are hidden.
6. **Export:** Windows build / Electron wrapper (`electron-peterrun/`) not yet confirmed as the delivery path.
