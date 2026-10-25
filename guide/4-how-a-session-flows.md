# 4 · How a session flows

> 🗺️ This page shows the whole journey of one session, from opening the game to finishing. Each box is a screen you can see.

## 🧭 The screens and how you move between them

```mermaid
flowchart TD
    A["🏠 Welcome screen<br/>Start Session · Tutorial · Settings · Quit"]
    B["🧩 Set up this session<br/>repetitions · game speed"]
    C["✅ Ready when you are<br/>check the plan"]
    D["🏃 The run<br/>3-2-1-Go! then the game"]
    E["📊 Review<br/>what was done · choose a speed"]
    T["📘 Tutorial<br/>practise the movements"]
    K["🎮 Check controller<br/>sensitivity · delay test"]

    A -->|Start Session| B
    A -->|Tutorial| T
    A -->|"Settings → Check controller"| K
    B -->|Review session| C
    B -.->|optional| T
    B -.->|optional| K
    C -->|Start Session| D
    C -.->|optional| T
    C -.->|optional| K
    T --> C
    K --> C
    D -->|"all done, touched an obstacle,<br/>or ended by the therapist"| E
    E -->|Retry| C
    E -->|Rest| E
    E -->|Finish| A
```

> 💡 Menus are used with the **mouse**. The movement keys only work inside the run.

## 🧑‍🤝‍🧑 Who does what

```mermaid
sequenceDiagram
    actor T as Therapist
    actor P as Patient
    participant G as PETER RUN
    T->>G: chooses repetitions and game speed
    T->>G: presses Start Session
    G-->>P: 3 · 2 · 1 · Go!
    loop until every repetition is done
        G-->>P: shows ONE instruction (GET READY, then MOVE NOW)
        P->>G: does the movement
        G-->>P: "Nice step!" or "Take your time."
    end
    G-->>T: Review: completed vs planned
    T->>G: Rest, Retry or Finish
```

## ⏯️ Ways a run can end

```mermaid
flowchart LR
    R["Running"] --> P{"Pause (P)"}
    P --> O["Pause screen<br/>Resume · End Level · End Session"]
    O --> C["Are you sure?<br/>(Cancel goes back)"]
    C --> E
    R -->|"all repetitions done"| E["Review screen"]
    R -->|"Peter reaches an obstacle"| E
    E --> D["Rest · Retry · Finish"]
```

## 🔁 Retry and the game speed

```mermaid
flowchart LR
    A["Choose game speed 1–10<br/>(in setup or on the review)"] --> B["Retry or New session"]
    B --> C["Ready screen shows the speed"]
    C --> D["Start Session"]
    D --> E["3 · 2 · 1 · Go! then play at that speed"]
    E --> F["Review"]
```
