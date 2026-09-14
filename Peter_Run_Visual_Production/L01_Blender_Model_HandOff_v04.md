# L01 Barangay Morning — Blender model source

Open `L01_Barangay_Morning_Models_v04.blend` in Blender 5.2 or later. It contains two scenes:

- `L01_Obstacle_Model_Review` opens first. Each usable model has its own collection: active delivery crates, shallow puddle, pass-under laundry, and a back-view Peter style study. The ground, camera, and light are review-only.
- `L01_Barangay_Route_Source` preserves the layered barangay road, houses, sari-sari frontage, roadside details, sky, and five landmark collections from the v03 route source. It is not a Godot scene.

The crate is a staggered, single-lane target rather than a repeated road-wide stack. The puddle is a nearly flat irregular water surface with separate reflection and ripple geometry. The laundry fabrics are separate meshes and leave an approximately 1.67 m opening below the line. Peter is a visual study only; the existing game character and animations are untouched.

The Blender-generated preview is `generated/l01_v04_models_preview.png`. `build_l01_blender_models_v04.py` rebuilds this source from `L01_Barangay_Morning_Visual_Source_v03.blend`. No asset in this package is wired into Godot or placed under `code/art/`.
