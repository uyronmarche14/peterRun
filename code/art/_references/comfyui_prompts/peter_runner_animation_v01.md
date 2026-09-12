# Peter Runner Animation — ComfyUI Prompt v01

Use the same Peter reference image, model, seed, and style settings for every pose. In ComfyUI, use the Peter back-view image with medium-to-high reference strength so the clothing, proportions, and hairstyle remain consistent.

## Base character prompt

```text
original 2D game character sprite, back-facing young Filipino boy runner,
full body, centered, clean readable silhouette,
short round black hair with a small upward tuft,
white t-shirt with a teal collar,
teal athletic shorts,
white sneakers with small yellow accents,
friendly rehabilitation game character,
simple chibi proportions, large head, short limbs,
smooth clean black outline, soft cel shading,
warm modern hand-drawn cartoon game art,
consistent proportions, crisp edges, polished mobile game sprite,
isolated single character, no scenery, no objects,
plain white background for easy removal,
camera positioned behind the character, character looking away from camera,
same character design, same clothing, same colors
```

## Negative prompt

```text
text, letters, logo, watermark, UI, background, road, house,
multiple characters, duplicate body parts, extra arms, extra legs,
cropped feet, cropped head, side-view character, front-facing character,
realistic photo, 3D render, pixelated, blurry, messy lines,
different clothes, hat, bag, weapon, dark horror style,
incorrect shoes, inconsistent hairstyle
```

## Pose additions

Append one pose block below to the base character prompt. Generate each pose as an individual image, not as a combined sprite sheet.

### 01 — Idle back

```text
standing naturally from behind, feet shoulder width apart,
arms relaxed, ready to start running, balanced neutral pose
```

### 02 — Run contact left

```text
running from behind, left foot touching the ground in front,
right leg extended behind, opposite arms swinging naturally,
energetic but friendly running pose
```

### 03 — Run passing left

```text
running from behind, left knee raised,
right foot passing under the body,
arms mid-swing, natural forward momentum
```

### 04 — Run contact right

```text
running from behind, right foot touching the ground in front,
left leg extended behind, opposite arms swinging naturally,
energetic but friendly running pose
```

### 05 — Run passing right

```text
running from behind, right knee raised,
left foot passing under the body,
arms mid-swing, natural forward momentum
```

### 06 — Jump takeoff

```text
back-facing character beginning a jump,
knees bent, both feet pushing off the ground,
arms slightly lifted for balance, clear anticipation pose
```

### 07 — Jump apex

```text
back-facing character high in the air,
both feet clearly off the ground,
knees slightly bent, arms open for balance,
happy energetic jump, readable silhouette
```

### 08 — Jump landing

```text
back-facing character landing from a jump,
knees bent deeply, feet apart,
arms slightly out for balance, soft safe landing pose
```

### 09 — Slide start

```text
back-facing character starting a low slide,
body lowered, one leg forward, one leg bent,
arms positioned for balance, dynamic forward momentum
```

### 10 — Slide hold

```text
back-facing character in a very low slide pose,
body compact and low to the ground,
legs extended forward, arms tucked safely,
clear silhouette that can pass beneath an obstacle
```

### 11 — Move left

```text
back-facing character running while leaning slightly left,
left foot stepping toward the left side,
torso and shoulders angled left,
natural lane-change motion
```

### 12 — Move right

```text
back-facing character running while leaning slightly right,
right foot stepping toward the right side,
torso and shoulders angled right,
natural lane-change motion
```

### 13 — Success celebration

```text
back-facing character stopping after a successful action,
small happy celebration, one arm raised,
upright confident posture, warm positive energy
```

## Recommended generation process

1. Generate four previews per pose at `768 × 1024` or `1024 × 1024`.
2. Select one consistent result for each pose, then upscale only that image.
3. Remove the white background in Krita or with a background-removal node.
4. Export every final frame as a transparent PNG with the same canvas size.
5. Do not ask the model to create all frames in one image; individual poses are easier to correct and keep consistent.

## Barangay background prompt

```text
original 2D illustrated endless runner game background,
Filipino-inspired barangay morning street,
camera looking forward from behind the runner,
wide clean road with three readable movement lanes,
strong central vanishing point, open foreground for player character,
small sari-sari store, warm colorful homes, laundry lines,
banana trees, tropical plants, utility poles, soft sunny sky,
welcoming calm neighborhood, adult-friendly rehabilitation game,
clean black linework, warm cel shading, modern hand-drawn cartoon game art,
large readable shapes, uncluttered road, no people, no vehicles,
 16:9 composition, space reserved at bottom center for player
```

## Route and parallax layer prompts

Generate these as separate transparent layers only after selecting the master Barangay background. Keep the same palette, line weight, horizon, and vanishing point as the master image. Do not place the player, interface, text, vehicles, or crowds in these layers.

### Sky and distant canopy

\`\`\`text
original 2D endless runner background layer, bright warm Filipino barangay morning sky,
soft cream clouds, pale sky blue, distant tropical tree canopy on the horizon,
wide 16:9 transparent environment layer, modern hand-drawn cartoon game art,
clean charcoal linework, warm cel shading, calm welcoming atmosphere,
no ground, no buildings in the foreground, no text, no characters
\`\`\`

### Distant homes and storefronts

\`\`\`text
original 2D endless runner background layer, distant Filipino barangay houses and small sari-sari stores,
warm coral, mango yellow, teal, leaf green, and cream palette,
fixed central road vanishing point, clear open centre for the route,
wide 16:9 transparent environment layer, clean readable silhouettes,
modern hand-drawn cartoon game art, no text, no people, no vehicles
\`\`\`

### Roadside midground

\`\`\`text
original 2D endless runner roadside layer, barangay shop fronts, potted plants, utility poles,
laundry hanging high in the distance, tropical shrubs, low curbs,
wide centre lane left open, perspective toward a central vanishing point,
transparent 16:9 game layer, crisp large shapes, warm cel shading,
no player, no UI, no words, no crowds, no vehicles
\`\`\`

### Foreground plants and shadows

\`\`\`text
original 2D game foreground overlay, large tropical leaves, small flowers, soft curb shadows,
placed only around the far left and right frame edges,
open centre and bottom-centre space for a runner,
transparent 16:9 layer, clean hand-drawn cartoon art, no text, no character
\`\`\`

### Road and lane guide overlay

\`\`\`text
original 2D endless runner road overlay, clean warm asphalt road seen in forward perspective,
three subtly distinct playable lanes, gentle lane shading and sparse centre markings,
strong central vanishing point, safe uncluttered open route,
transparent-friendly game layer, no objects, no character, no UI, no text
\`\`\`

## Gameplay prop prompts

Use the master Barangay background as the style reference. Generate one isolated prop per image on a plain white background, then remove the background and export a transparent PNG. Keep silhouettes large and readable from a distance.

### Delivery crate — move-left and move-right prompt

\`\`\`text
original 2D game obstacle sprite, small stack of sturdy delivery crates,
Filipino barangay morning style, warm natural wood with a deep teal fabric tie,
friendly non-dangerous rehabilitation game obstacle, three-quarter front view,
large simple readable silhouette, soft ground contact shadow,
clean charcoal outline, warm cel shading, isolated object, plain white background,
no text, no logo, no character, no vehicle
\`\`\`

### Puddle — jump prompt

\`\`\`text
original 2D game obstacle sprite, shallow blue rain puddle with a small raised curb edge,
friendly jump prompt for a calm rehabilitation endless runner,
three-quarter front view, broad readable silhouette, subtle pale reflection,
clean charcoal outline, warm cel shading, soft ground contact shadow,
isolated object, plain white background, no text, no character
\`\`\`

### Laundry line — slide prompt

\`\`\`text
original 2D game obstacle sprite, low hanging laundry line between two simple roadside posts,
bright clean clothes in teal, mango yellow, coral, and cream,
safe friendly slide-under prompt for a barangay runner,
large readable silhouette, three-quarter front view, clean charcoal outline,
warm cel shading, isolated object, plain white background,
no text, no character, no background scenery
\`\`\`

### Optional roadside marker

\`\`\`text
original 2D game roadside marker sprite, small painted wooden direction sign,
Filipino barangay morning palette, teal and mango yellow paint,
simple readable silhouette, friendly decorative route marker,
clean charcoal outline, warm cel shading, isolated object, plain white background,
no words, no letters, no logo, no character
\`\`\`

## Effect sprite prompts

Generate effects as isolated images on a plain white background, remove the background, and export transparent PNGs. Effects should be simple enough to animate with Godot scaling, fading, and rotation.

### Running dust

\`\`\`text
original 2D game effect sprite, small soft dust puff from running shoes,
warm cream and light mango colors, clean rounded shapes, subtle charcoal outline,
friendly modern cartoon game effect, isolated on plain white background,
no character, no text, no scenery
\`\`\`

### Landing puff

\`\`\`text
original 2D game effect sprite, low wide soft dust puff from a gentle jump landing,
warm cream and light mango colors, clean readable rounded shapes,
friendly modern cartoon game effect, isolated on plain white background,
no character, no text, no scenery
\`\`\`

### Success sparkle

\`\`\`text
original 2D game effect sprite, three small celebratory sparkles and a subtle teal starburst,
mango yellow, teal, cream, and leaf green palette, calm positive energy,
clean thick outline, friendly rehabilitation game feedback effect,
isolated on plain white background, no text, no character
\`\`\`

### Near-miss indicator

\`\`\`text
original 2D game effect sprite, gentle coral curved motion line and two small dots,
calm supportive near-miss feedback, never alarming or aggressive,
clean rounded shapes, isolated on plain white background, no text, no character
\`\`\`

## Dashboard and level artwork prompts

### Opening dashboard hero image

\`\`\`text
original 2D game dashboard hero illustration for PETER RUN,
back-facing young boy in white shirt with teal collar, teal shorts, white sneakers with yellow accents,
standing at the start of a warm Filipino barangay morning road,
three readable route lanes leading toward a sunny village horizon,
sari-sari store, tropical plants, colorful homes, calm welcoming atmosphere,
leave clean negative space on the left for a game title and buttons,
modern hand-drawn cartoon game art, clean charcoal outline, warm cel shading,
16:9 composition, no text, no logo, no UI elements
\`\`\`

### Barangay Morning level-card thumbnail

\`\`\`text
original 2D game level selection thumbnail, Filipino barangay morning road,
warm sunny sky, small sari-sari store, colorful homes, tropical plants,
clear forward road and calm welcoming atmosphere,
simple strong composition readable at small size,
modern hand-drawn cartoon game art, charcoal outline, warm cel shading,
square composition, no text, no logo, no UI
\`\`\`

### Session-complete illustration

\`\`\`text
original 2D game session complete illustration,
back-facing young boy runner giving a small happy celebration at the end of a bright Barangay route,
soft sunshine, subtle sparkles, friendly achievement moment,
calm adult-friendly rehabilitation game art,
clean charcoal outline, warm cel shading, open space for summary text,
16:9 composition, no words, no logo, no UI
\`\`\`

## UI icon prompts

Prefer vector or code-drawn icons for the final runtime UI because they stay sharp at all screen sizes. If illustrated icons are desired, generate each icon as a single centred symbol with the same outline and palette, then export it as a transparent PNG at \`256 × 256\`.

### Shared icon base

\`\`\`text
single original 2D game UI icon, centred, simple rounded silhouette,
deep teal linework with mango yellow and cream accents,
modern friendly rehabilitation game design, clean thick outline,
transparent-style plain white background, no text, no letters, no logo,
no border, no button shape, no character
\`\`\`

Append one of the following icon subjects to the shared icon base:

| Icon | Subject addition |
| --- | --- |
| Play | \`solid rounded right-pointing play triangle\` |
| Pause | \`two rounded vertical pause bars\` |
| Settings | \`simple rounded gear\` |
| Sound on | \`small speaker with two soft sound waves\` |
| Sound off | \`small speaker with one gentle diagonal mute line\` |
| Back | \`rounded left-pointing arrow\` |
| Keyboard | \`small friendly keyboard with no letters on keys\` |
| Controller | \`simple game controller with blank circular buttons\` |
| Move left | \`single rounded left arrow\` |
| Move right | \`single rounded right arrow\` |
| Jump | \`rounded upward arrow above a tiny ground line\` |
| Slide | \`rounded downward arrow under a low horizontal line\` |

## Feedback badge prompts

Use these only as decorative badge art; keep actual praise words as Godot text so they remain editable and accessible.

### Great timing badge

\`\`\`text
original 2D game feedback badge, small teal star with mango yellow sparkle accents,
friendly positive rehabilitation game reward, clean rounded silhouette,
charcoal outline, isolated on plain white background, no words, no letters
\`\`\`

### Keep going badge

\`\`\`text
original 2D game feedback badge, small warm coral sun rising over a teal curved path,
calm encouraging energy, clean rounded silhouette, charcoal outline,
isolated on plain white background, no words, no letters
\`\`\`

### Session complete badge

\`\`\`text
original 2D game feedback badge, simple mango yellow ribbon and teal check mark,
warm achievement moment, clean rounded silhouette, charcoal outline,
isolated on plain white background, no words, no letters
\`\`\`

## Asset completion checklist

### Essential first integration

- [ ] Peter idle, four run frames, three jump frames, two slide frames, and two lane-lean frames.
- [ ] Delivery crate, puddle, and laundry-line props.
- [ ] Selected Barangay road background.
- [ ] Running dust, landing puff, and success sparkle effects.
- [ ] Transparent backgrounds and matching PNG canvas sizes.

### Second visual pass

- [ ] Four parallax route layers and road/lane guide overlay.
- [ ] Dashboard hero art, level-card thumbnail, and session-complete illustration.
- [ ] Shared UI icon set and feedback badges.
