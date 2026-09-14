"""Render the saved L01_DeliveryCrates source in background Blender.

Usage: blender -b L01_DeliveryCrates_Source_v01.blend --python render_l01_delivery_crates.py
This does not save or modify the .blend file or any Godot resources.
"""

import os
import sys

import bpy


ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "generated", "l01_delivery_crates")
os.makedirs(OUT, exist_ok=True)
P = "L01_DeliveryCrates"
jobs = (
    (P + "_LEFT_ACTIVE", "l01_delivery_crates_left_active.png", P + "_LEFT_MODEL", P + "_LEFT_PULSE_EDGE_SEPARATE", "base"),
    (P + "_RIGHT_ACTIVE", "l01_delivery_crates_right_active.png", P + "_RIGHT_MODEL", P + "_RIGHT_PULSE_EDGE_SEPARATE", "base"),
    (P + "_ROADSIDE_DECORATIVE", "l01_delivery_crates_roadside_decorative.png", None, None, "base"),
    (P + "_LEFT_ACTIVE", "l01_delivery_crates_left_pulse_edge.png", P + "_LEFT_MODEL", P + "_LEFT_PULSE_EDGE_SEPARATE", "edge"),
    (P + "_RIGHT_ACTIVE", "l01_delivery_crates_right_pulse_edge.png", P + "_RIGHT_MODEL", P + "_RIGHT_PULSE_EDGE_SEPARATE", "edge"),
    (P + "_REVIEW_ONE_ACTIVE", "l01_delivery_crates_review.png", None, None, "review"),
)
selection = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else None
for scene_name, filename, variant_name, edge_name, mode in jobs:
    if selection and filename != selection:
        continue
    source = bpy.data.scenes[scene_name]
    scene = source
    if mode == "edge":
        # A new scene links only the edge collection and source lighting.
        # Do not mutate object visibility in the saved source document.
        scene = bpy.data.scenes.new("TEMP_" + scene_name + "_EDGE_EXPORT")
        scene.render.engine = "BLENDER_EEVEE"
        scene.render.resolution_x = 512
        scene.render.resolution_y = 512
        scene.render.resolution_percentage = 100
        scene.render.image_settings.file_format = "PNG"
        scene.render.image_settings.color_mode = "RGBA"
        scene.render.film_transparent = True
        scene.world = source.world
        scene.camera = source.camera
        scene.view_settings.view_transform = source.view_settings.view_transform
        scene.view_settings.look = source.view_settings.look
        scene.view_settings.exposure = source.view_settings.exposure
        scene.collection.children.link(bpy.data.collections[edge_name])
        scene.collection.children.link(bpy.data.collections[scene_name + "_CAMERA_LIGHT_ONLY"])
    scene.render.filepath = os.path.join(OUT, filename)
    bpy.ops.render.render(scene=scene.name, write_still=True)
    image = bpy.data.images.load(scene.render.filepath, check_existing=False)
    assert tuple(image.size) == ((1400, 900) if mode == "review" else (512, 512))
    if mode != "review":
        assert image.pixels[3] < .01, filename + " has a non-transparent export corner"
    bpy.data.images.remove(image)
    print("RENDERED", filename)
