"""Render every modular PR V04 house variant and component layer."""

import os

import bpy


ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "generated", "l01_v04_fresh")
os.makedirs(OUT, exist_ok=True)

scenes = sorted(
    (scene for scene in bpy.data.scenes if scene.get("asset_kind") == "house"),
    key=lambda scene: scene.name,
)
assert len(scenes) == 48, ("expected 48 house export scenes", len(scenes))

for scene in scenes:
    filename = scene["output_filename"]
    scene.render.filepath = os.path.join(OUT, filename)
    bpy.ops.render.render(scene=scene.name, write_still=True)
    image = bpy.data.images.load(scene.render.filepath, check_existing=False)
    assert tuple(image.size) == (960, 540), (filename, tuple(image.size))
    assert image.channels == 4, filename
    bpy.data.images.remove(image)
    print("RENDERED_HOUSE_ASSET", scene.name, scene.render.filepath)

print("PETER_RUN_L01_V04_HOUSE_ASSETS_RENDERED", len(scenes))
