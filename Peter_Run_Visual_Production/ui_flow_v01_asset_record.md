# UI flow image assets v01

This batch gives the setup and review screens image-backed barangay settings while keeping all buttons, clinical text, and session data as live Godot controls. It does not replace the in-game route art or change gameplay logic.

## Artwork and production

| Runtime asset | Source artwork | Use |
| --- | --- | --- |
| `code/art/backgrounds/ui_barangay_flow_v01.png` | `Peter_Run_Visual_Production/imagegen_sources/ui_flow_v01/ui_barangay_flow_v01_source.png` | Patient setup, controller check, tutorial, ready |
| `code/art/backgrounds/ui_barangay_plaza_review_v01.png` | `Peter_Run_Visual_Production/imagegen_sources/ui_flow_v01/ui_barangay_plaza_review_v01_source.png` | Session review |

The source images were generated with OpenAI image generation. The accepted flow image used an edit/style-transfer pass to establish a warm illustrated Filipino neighbourhood street with open central space for live UI. The review image was edited from that accepted visual direction into a calm community plaza. Both exclude legible text, prompt objects, traffic, and characters. Sources are 1672×941 pixels; approved runtime candidates were downscaled to 960×540 PNG with Lanczos filtering. These are original generated artwork candidates, not adaptations of a commercial runner. Final project art approval remains with the team.

`code/tools/build_ui_frame_assets.gd` deterministically generates three 64×64 RGBA nine-slice images: cream card, dark-teal HUD surface, and mango-accent prompt sign. Their `StyleBoxTexture` resources are in `code/art/ui/`. The two-pixel slice margins are intentional: they preserve the project's native-size card constraints and align with the source corners.

## Composition and validation

- Gameplay remains a 480×270 Godot 2D Compatibility scene. Backdrops use aspect-covered `TextureRect`s, with live controls layered above them.
- The dashboard hero art and gameplay route art remain the existing assets.
- The focused resource/layout test is `code/tests/ui_image_unification_test.gd`.
- The UI screen-flow test is `code/tests/ui_theme_pass_test.gd`; its optional `--capture-dir` argument writes captures without replacing the earlier evidence set.
- Fresh captures for 960×540, 1024×768, and 1920×1080 are in `test_evidence/ui_image_unification/` (local evidence, not packaged runtime art).

No Blender file, repetition logic, input mapping, controller integration, or clinical wording was changed in this batch.
