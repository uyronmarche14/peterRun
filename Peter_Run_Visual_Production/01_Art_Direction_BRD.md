# PETER RUN — Art Direction BRD

> **Visual requirements for a Filipino-inspired rehabilitation runner**  
> **Companion to:** [Visual Production Master](00_Visual_Production_Master.md)

## 1. Visual promise

PETER RUN should feel like a warm, original journey through Filipino places: familiar, optimistic, and adult-friendly. It must look like a game—not a clinic dashboard—while every on-screen decision remains calm and easy to understand for a player who may be tired, balancing with a walker, or processing instructions slowly.

**Style sentence:** *An original 2D forward-lane pixel-art journey through Filipino community spaces and landscapes, using a calm 2.5D perspective, soft arcade charm, and safety-first readability.*

## 2. Visual rules that cannot change

- Original Filipino-inspired environments and props; never copy a commercial runner game's assets, UI, character, level layout, or branding.
- The play lane and upcoming action cue are visually stronger than scenery.
- The player character is an adult, represented respectfully and without exaggerated disability imagery.
- No visual punishment: no danger flashes, skulls, crash screens, sharp red fail banners, or aggressive camera shake.
- No culturally generic “tropical” collage. Every reference should serve a clear place, material, or story purpose.
- The game must remain legible in colour-blind, muted-audio, and low-attention conditions.
- Use a 2.5D illusion made from 2D sprite layers and parallax; do not introduce 3D scenes, railway tracks, chase imagery, coins, hoverboards, or copied commercial-runner UI patterns.

## 3. Core art system

### 3.1 Palette

| Token | Hex | Purpose |
| --- | --- | --- |
| Ink | `#263238` | Outlines and primary readable text |
| Deep Teal | `#155E63` | UI panels, gutters, quiet contrast |
| Mango | `#F7B733` | Positive highlights, jump cue accent |
| Coral | `#E85D5D` | Warm attention accent; never “failure” alone |
| Leaf | `#4E9F5A` | Environment and positive movement accents |
| Sky | `#75C9E8` | Background and calm space |
| Cream | `#FFF4D6` | Text panels and soft highlights |
| Earth | `#A66B3D` | Paths, wood and terrain shadow |

Each level uses its own palette variation but keeps **Ink, Cream, and the same action-icon shapes**. Test text/icons against their background before approval.

### 3.2 Composition

- Camera: fixed elevated **2D forward-lane** view, centred behind the player. It is a sprite/parallax illusion, not a 3D camera.
- Path: exactly three readable lanes; lane edges use a light border or texture contrast, not only colour.
- Safe zone: bottom 30% of the play view stays mostly clear around the player.
- Prompt zone: upcoming prompt appears in the central 40% width, above the path horizon; never hide it behind foreground art.
- Scenery: use distant/side layers. It may animate gently but must never cross the play lane during a prompt.

See [2.5D Originality Standard](11_2_5D_Originality_Standard.md) before creating a route, character, HUD, or concept image.

### 3.3 Texture vocabulary

| Material | Use | Pixel-art treatment |
| --- | --- | --- |
| Banig / woven mat | UI accents, market baskets | 2–3 colour diagonal weave; subtle, not a reading background |
| Sawali / bamboo weave | Walls and stalls | Simple repeating diamond/strip pattern |
| Capiz | Window highlights | Cream/sky pixels with restrained sparkle |
| Stone plaza | Barangay/Pasko ground | 16 px modular tiles, quiet contrast |
| Bamboo | Riverside/Rice Terrace props | 2–3 segment shading, rounded joints |
| Water | Riverside background | Two horizontal shades; slow looping ripple only |

## 4. Level visual identities

| Level | Visual identity | Background layers | Avoid |
| --- | --- | --- | --- |
| Barangay Morning | Welcoming start, sunny neighborhood | Sky, rooftops, store fronts, path-side plants | Traffic, crowding the lane, tiny sign text |
| Palengke Dash | Friendly, colorful market route | Sky, canopies, stalls, baskets/produce | Clutter that resembles active prompts |
| Riverside Walk | Calm and spacious | Sky, distant trees, river, bamboo rail | Fast water, narrow bridge gameplay lane |
| Rice Terrace Trail | Open view and achievement | Sky, mountains, terraces, earthy trail | Steep-drop imagery or visually busy terraces |
| Pasko Festival | Warm completion, not sensory overload | Night sky, plaza, lights, parols | Flashing lights, dense people, strobing effects |

## 5. Character direction

The player is a friendly adult travelling forward, viewed mostly from behind. The silhouette must be readable at 4× scale before facial detail is considered.

- Neutral sporty top, shorts/trousers, supportive shoes; no copied uniform or celebrity likeness.
- Use a relaxed upright idle/run pose. The in-game character is symbolic; do not portray unsafe balance loss.
- Use a small palette: skin tone set, dark hair, cream top, teal lower garment, mango/coral accent.
- Keep the affected ankle device out of the active gameplay sprite unless it is shown in the tutorial/setup close-up. It is medical hardware, not decoration.
- The character reacts positively to success with a brief smile/celebration effect; misses receive no defeated pose.

Full production measurements are in [Character Sprite Spec](02_Character_Sprite_Spec.md).

## 6. Prompt language

Every prompt needs three redundant signals:

1. **Shape/icon** — ↔, ↑, or ↓.
2. **Plain text** — `MOVE`, `STEP`, or `BACK` (final clinician-reviewed wording).
3. **World prop** — an obstacle/prompt with a distinct silhouette.

The icon system must remain constant across all levels. Environmental props change by level, but their action grammar does not.

| Action | Icon/shape | Default cue colour | Visual behaviour |
| --- | --- | --- | --- |
| Move left/right | Double arrow in rounded sign | Teal/cream | One side lane visibly occupied |
| Jump / forward step | Up arrow in rounded sign | Mango/ink | Low across-path cue |
| Slide / backward step | Down arrow in rounded sign | Coral/cream | Overhead cue with clear under-space |

The action phrase must be clinically approved before the first patient test. Do not depend on the player recognising the environmental prop alone.

## 7. UI direction

- Rounded arcade cards on deep-teal or cream surfaces.
- Use chunky, highly legible display type only for short labels; use a clean sans-serif for longer instructions.
- Touch/mouse targets: minimum 64 × 64 screen pixels at the 1920 × 1080 target output.
- Pause is persistent in the top-right, with a dark outline and text/icon pairing.
- HUD includes: one next-action card, progress display, and pause. Avoid timers unless clinician-approved.
- Summary uses celebration graphics, clear completion counts, and a calm in-game exertion selector. It does not present a “rank” or competitive score.

## 8. Motion and VFX rules

- Character animations: 6–8 FPS, 4–8 frames per loop; readability beats fluidity.
- Backgrounds: one gentle loop per layer; never use parallax speed that makes the scene feel fast.
- Success effect: 4–6 small stars/flowers rising and fading over 0.5–0.8 seconds.
- Miss effect: prompt fades or drifts off with no red flash, screen shake, or negative message.
- Pasko lights may glow softly but must not flash faster than a slow, steady pulse.

## 9. Art-direction sign-off checklist

- [ ] Looks Filipino-inspired through places/materials, not copied or stereotyped imagery.
- [ ] Lane edges, player, prompt and pause are identifiable at target resolution.
- [ ] The active prompt remains obvious with the background converted to greyscale.
- [ ] The environment contains no visual fail-state language.
- [ ] Palette, file name, tile size and action grammar follow the master file.
- [ ] Source/model/asset licence is recorded in the Asset Register.
