"""Render one named layer or the master preview from the cinematic source."""

import os
import sys

import bpy


ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "generated", "l01_barangay_hall_v01")
os.makedirs(OUT, exist_ok=True)
if "--" not in sys.argv:
    raise RuntimeError("Pass a layer name or master after --")
layer = sys.argv[sys.argv.index("--")+1]
if layer == "master":
    scene = bpy.data.scenes["L01_Barangay_Hall_Cinematic_Master_v01"]
    filename = "l01_barangay_hall_composite_review_v01.png"
else:
    scene = bpy.data.scenes["L01_EXPORT_" + layer.upper()]
    filename = "l01_barangay_hall_%s_v01.png" % layer
scene.render.filepath = os.path.join(OUT, filename)
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
bpy.ops.render.render(scene=scene.name, write_still=True)
image = bpy.data.images.load(scene.render.filepath, check_existing=False)
assert tuple(image.size) == (960,540)
assert image.channels == 4
print("RENDERED", layer, scene.render.filepath)
