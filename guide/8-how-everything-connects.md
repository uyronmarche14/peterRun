# 8 · How everything connects

> 🧩 No code here. Think of the game as a small team. Each member has one job, and they pass messages to each other.

## 👷 The team

| Member | Its one job |
| --- | --- |
| **The input guard** | Listens to the keyboard or controller, ignores held and repeated presses, and passes on only the five real actions. |
| **The run manager** | The conductor. Starts the countdown, runs the clock, keeps the screen text and ends the run. |
| **The prompt keeper** | Decides what is asked now, and whether the answer was right. |
| **The obstacle picker** | Chooses which arrangement of obstacles comes next, easier ones after a miss. |
| **The contact checker** | Answers one question: "Is Peter in a lane with an obstacle?" |
| **Peter** | Moves, jumps, slides and walks. |
| **The street** | Moves the road, houses and obstacles toward Peter. |
| **The score keeper** | Counts completed repetitions. There are no points. |
| **The review page** | Shows what was done and lets the player pick a speed. |
| **The notebook** | Remembers the plan and the result between screens, and adds a line of numbers to the history file. |

## 🗺️ How they connect

```mermaid
flowchart TB
    subgraph IN["👂 Listening"]
        K["Keyboard, gamepad<br/>or MOVE wearable"] --> G["Input guard"]
    end

    subgraph CORE["🎬 The run"]
        M["Run manager"]
        PK["Prompt keeper"]
        OP["Obstacle picker"]
        CC["Contact checker"]
        SK["Score keeper"]
    end

    subgraph LOOK["👀 What you see"]
        PE["Peter"]
        ST["The street"]
        HUD["Words and progress on screen"]
    end

    subgraph KEEP["📒 Remembering"]
        PL["The plan<br/>(repetitions, speed)"]
        NB["Notebook<br/>result + history file"]
    end

    PL --> M
    G --> M
    M <--> PK
    M --> OP
    M --> CC
    M --> SK
    M --> PE
    M --> ST
    M --> HUD
    SK --> NB
    NB --> R["Review page"]
```

## 🔄 What happens when you press a button

```mermaid
sequenceDiagram
    actor Pl as Player
    participant IG as Input guard
    participant RM as Run manager
    participant Pe as Peter
    participant PK as Prompt keeper
    participant CC as Contact checker
    participant SK as Score keeper
    participant ST as The street

    Pl->>IG: presses a button
    IG-->>RM: "jump" (or nothing, if it was held or too soon)
    RM->>Pe: move, jump or slide
    RM->>PK: here is the answer
    PK-->>RM: right or wrong
    RM->>CC: is Peter in a lane with an obstacle?
    alt yes
        RM-->>Pl: the run ends, everything done is kept
    else no
        RM->>SK: count a repetition (if right)
        RM->>ST: obstacle passes, show "Nice step!"
        RM->>PK: next instruction after a short rest
    end
```

## 🎨 How the speed reaches everything

```mermaid
flowchart LR
    SP["Game speed 1–10"] --> ST["Street and scenery"]
    SP --> PE["Peter's walking"]
    SP --> AU["Ambient sound"]
    SP --> WA["GET READY length"]
    WA --> OB["When obstacles arrive"]
```

## 📂 Where things live (for the curious)

| In the game | In the project folder `code/` |
| --- | --- |
| Screens | `scenes/` |
| The team members' behaviour | `scripts/` |
| Levels, colours, obstacle arrangements | `data/` |
| Art and sound | `art/`, `audio/` |
| Checks that the game still works | `tests/` (86 test scripts) |

> 🛠️ Developers: see [How the code works](developers/how-the-code-works.md) and the [code tour](developers/code-tour.md).
