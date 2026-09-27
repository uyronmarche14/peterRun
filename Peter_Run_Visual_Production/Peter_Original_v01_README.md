# Original Peter source and export pipeline

This is a new original model, not an adaptation of `3D ASSETS/Cool guy low poly.blend`. The supplied directory did not establish permission to adapt that asset. It and the previous character artwork remain untouched.

## Editable source

`Peter_Original_Rigged_v01.blend` contains the original weighted character, `Peter_Rig`, 22 bones including IK foot controls and knee poles, locked orthographic gameplay camera, studio lights, and ten named `Peter_*` actions. The body uses connected remeshed surfaces with blended skin weights; face/hair/shoe details are separate bound meshes. Authoring is 30 fps. Toggle viewport overlays to inspect the skeleton.

| Action | Seconds | 24 fps samples | Loop |
|---|---:|---:|---|
| idle_ready | 2.00 | 48 | yes |
| walk_forward | 1.20 | 29 | yes |
| move_left / move_right | 0.22 each | 6 each | no |
| jump_low | 0.62 | 15 | no |
| slide_duck | 0.48 | 12 | no |
| rest | 2.00 | 48 | yes |
| success_settle | 0.50 | 12 | no |
| neutral_clear | 0.25 | 6 | no |
| paused | 1/24 | 1 | no |

`paused` is a standalone resting preview. Actual session pause freezes the current frame; it never switches to that clip. The fixed-duration slide remains a crouch/duck, matching the existing mechanic. No variable-duration hold state was introduced.

## Reproduce

Run from the project root, using the installed Blender executable:

```powershell
$blender = 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe'
& $blender --background --python-exit-code 1 --python Peter_Run_Visual_Production/build_peter_original.py
& $blender --background Peter_Run_Visual_Production/Peter_Original_Rigged_v01.blend --python-exit-code 1 --python Peter_Run_Visual_Production/export_peter_original.py
& $blender --background Peter_Run_Visual_Production/Peter_Original_Rigged_v01.blend --python-exit-code 1 --python Peter_Run_Visual_Production/export_peter_original.py -- preview
& $blender --background Peter_Run_Visual_Production/Peter_Original_Rigged_v01.blend --python-exit-code 1 --python Peter_Run_Visual_Production/validate_peter_original.py
& Peter_Run_Visual_Production/contact_peter_original.ps1
& Peter_Run_Visual_Production/verify_peter_original.ps1
```

Build deliberately overwrites only the new original source file; export overwrites only this version's generated/runtime artwork. Preserve manual changes before rebuilding. `-- pack` repacks existing rendered frames without rerendering. `-- stress` renders a raised-arm weight-inspection pose without saving it to the source.

## Runtime contract

- Source frames: `generated/peter_original_v01/<clip>/<clip>_000.png`, 512×512 RGBA; fixed ground coordinate (256,432).
- Runtime: `code/art/characters/peter_original_v01/`, ten atlases, separate shadow, and `animation_manifest.json`.
- Runtime tiles: 256×256, pivot (128,216), 2px gutters, maximum atlas dimension 1820. No independent frame crop or mirrored right-step art.
- Manifest records every timestamp, final shortened sample interval, exact action durations and atlas regions. Loop endpoint is not duplicated.
- Sprite scale 0.30 preserves the previous 512×512-at-0.15 screen footprint. Character ground remains player local (0,15), world y241.
- Existing controller owns lane translation and action completion. Jump lift is baked into artwork once, as in the previous runtime; no added visual-node displacement. The existing jump state drives the separate grounded shadow.
- Existing manual Sprite2D clock is retained; no competing AnimatedSprite2D clock, animation callbacks that count repetitions, input handler or runtime 3D scene is introduced.
- Existing reduced-motion setting remains respected.

Graphical evidence harness: `godot --path code -s res://tests/support/capture_peter_original.gd`. It captures the real level at the three requested sizes with prompt timers stopped for isolated character inspection. Recording adds `--fixed-fps 30 --write-movie <absolute AVI path> -- --record`. This is deterministic gameplay-render evidence, not a performance benchmark, therapist validation or controller hardware certification.
