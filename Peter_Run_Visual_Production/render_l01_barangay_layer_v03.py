"""Render one 960x540 L01 Barangay Morning layer from its Blender source.

Usage: blender -b L01_Barangay_Morning_Layered_Source_v03.blend --python render_l01_barangay_layer_v03.py -- sky
Use one Blender process per layer to avoid the local multi-render crash.
"""

import os
import sys

import bpy


ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "generated", "l01_barangay_v03_layers")
os.makedirs(OUT, exist_ok=True)
if "--" not in sys.argv or sys.argv.index("--")+1 >= len(sys.argv):
    raise RuntimeError("Pass one layer name after --")
layer = sys.argv[sys.argv.index("--")+1]
if layer not in ("sky","far","mid","near","foreground","road","lane_overlay"):
    raise RuntimeError("Unknown L01 layer: " + layer)
scene = bpy.data.scenes["L01_LAYER_"+layer.upper()]
scene.render.filepath = os.path.join(OUT,"l01_barangay_%s_v03.png" % layer)
scene.render.image_settings.color_mode = "RGBA"
scene.render.film_transparent = layer != "sky"
bpy.ops.render.render(scene=scene.name,write_still=True)
image = bpy.data.images.load(scene.render.filepath,check_existing=False)
assert tuple(image.size) == (960,540)
assert image.channels == 4
bpy.data.images.remove(image)
print("RENDERED_L01_LAYER",layer,scene.render.filepath)
