# L01_DeliveryCrates Blender source

Open `L01_DeliveryCrates_Source_v01.blend`. The opening scene, `L01_DeliveryCrates_REVIEW_ONE_ACTIVE`, shows exactly one active stack and one quiet roadside crate. The separate `LEFT_ACTIVE`, `RIGHT_ACTIVE`, and `ROADSIDE_DECORATIVE` scenes contain the reusable variants. The original obstacle-source scene from the active Blender session is preserved in the file; the original `.blend` on disk was not overwritten.

Each variant has a centered ground-contact Empty that parents its meshes. Active stacks are approximately 1.86 m wide and have two staggered wooden/bamboo crates, mango-painted edges, cream cross-braces, teal labels, and separate contact-shadow and pulse-edge collections. The decorative crate is one smaller, desaturated roadside-only object.

Transparent 512×512 orthographic PNGs are in `generated/l01_delivery_crates/`: left active, right active, roadside decorative, and separate left/right pulse-edge layers. The review PNG is 1400×900. These are Blender source exports only; nothing is integrated into Godot.

`build_l01_delivery_crates_live.py` records the live Blender construction. `render_l01_delivery_crates.py` regenerates one PNG at a time from the saved blend using `blender -b ... --python ... -- filename.png`. One-render-per-process is intentional because Blender 5.2 crashed during repeated renders in one process on this machine.
