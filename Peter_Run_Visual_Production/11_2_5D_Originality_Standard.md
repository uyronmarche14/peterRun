# PETER RUN — 2.5D Forward-Lane Originality Standard

> **Canonical visual and implementation boundary for the playable game**  
> **Version 0.1 · 05 September 2026**

## 1. The decision

PETER RUN is an **original Filipino-inspired 2D forward-lane runner with a 2.5D pixel-art perspective**.

It is not a 3D game and it is not a copy of any commercial runner. The player remains near the lower centre of a 2D scene while the road/path, prompt props, and scenery layers move downward to suggest calm forward travel. Depth is created with sprite scale, a trapezoid-like path, and slow parallax—not 3D models, a subway setting, or a chase sequence.

## 2. What stays the same

| System | Decision |
| --- | --- |
| Engine | Godot 4, 2D scenes, GDScript, Compatibility renderer |
| Player space | Three lanes: left, centre, right |
| Gameplay | One discrete Move / Jump / Slide prompt at a time |
| Session logic | Therapist-configured repetitions, neutral misses, immediate Pause |
| Content structure | Reusable `RunnerLevel` + data-driven `LevelDefinition` resources |

## 3. What the visual design must become

| Layer | PETER RUN implementation | Must not resemble |
| --- | --- | --- |
| Route | Barangay road, market walkway, riverside boardwalk, rice-terrace trail, Pasko plaza | Railway tracks, subway tunnels, station platforms |
| Player | Original adult-friendly pixel character, lower centre, small lateral shifts | A copied character, outfit, silhouette, or animation |
| World motion | Slow 2D parallax: sky → distant scenery → side scenery → road → prompt prop | Fast chase camera, violent shake, high-speed zoom |
| Prompt props | Crates, baskets, puddles, bamboo, rice sacks, parol strings | Coins, mystery boxes, hoverboards, trains, guards, enemies |
| UI | Deep-teal/cream panels, mango/coral accents, clear therapist controls | A copied commercial runner HUD, menu layout, font treatment, icons, or reward loop |

## 4. Screen composition

```text
Top 25%       Sky and distant mountains/rooftops — slowest layer
Middle 35%    Route horizon and the one upcoming prompt — highest game focus
Lower 25%     Three readable lanes and approaching prompt prop
Bottom 15%    Player safe zone — player remains readable and unobstructed
Overlay       Fixed HUD: action card, repetition progress, labelled Pause
```

The background establishes Filipino place and mood, but it never outranks the action card, obstacle silhouette, player lane, or Pause control.

## 5. Godot implementation rule

```text
CanvasLayer HUD            fixed; never scrolls
PromptWorldAnchor          moves toward player at readable, fixed speed
RoadAndLanes               scrolls downward at medium speed
Parallax2D Near            slow side scenery
Parallax2D Mid             slower buildings, stalls, terraces, riverbank
Parallax2D Far             almost static sky, mountain and clouds
Player                     stays near lower centre; changes only lane/action state
```

Use `Node2D`, `Sprite2D`, `AnimatedSprite2D`, `TileMapLayer`, and `Parallax2D`. Do not introduce a 3D scene, perspective camera, collision damage, enemy logic, collectible economy, or speed escalation.

## 6. Originality gate

Before any asset or UI screen is approved, answer **yes** to all of these:

- Is the route a Filipino place/material story rather than a subway/railway route?
- Is the character, icon set, screen layout, art, sound and animation original?
- Would the screen still be recognisably PETER RUN if all commercial-runner references were removed?
- Does the design avoid trains, stations, chase characters, coins, hoverboards, graffiti branding, score multipliers and power-up loops?
- Does it remain calm, readable and non-punishing for a supervised rehabilitation session?

If any answer is no, revise the asset before it enters Godot.
