"""Render one transparent L01_LaundryLine PNG from the saved Blender source.

Usage: blender -b L01_LaundryLine_Source_v01.blend --python render_l01_laundry_line.py -- filename.png
Use one render per process to keep the connected Blender window stable.
"""

import os
import sys

import bpy


ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "generated", "l01_laundry_line")
os.makedirs(OUT, exist_ok=True)
jobs = {
    "prompt_l01_laundry_line_v03.png": ("L01_LaundryLine_ACTIVE_SLIDE", (256,192)),
    "prompt_l01_laundry_cloth_sway_v01.png": ("L01_LaundryLine_CLOTH_SWAY_OVERLAY", (256,192)),
    "decor_l01_laundry_line_v01.png": ("L01_LaundryLine_ROADSIDE_DECORATIVE", (128,96)),
}
if "--" not in sys.argv or sys.argv.index("--") + 1 >= len(sys.argv):
    raise RuntimeError("Pass one requested PNG filename after --")
filename = sys.argv[sys.argv.index("--") + 1]
scene_name, expected_size = jobs[filename]
scene = bpy.data.scenes[scene_name]
scene.frame_set(1)
scene.render.filepath = os.path.join(OUT, filename)
scene.render.film_transparent = True
scene.render.image_settings.color_mode = "RGBA"
bpy.ops.render.render(scene=scene.name, write_still=True)
image = bpy.data.images.load(scene.render.filepath, check_existing=False)
assert tuple(image.size) == expected_size, (filename, tuple(image.size))
assert image.pixels[3] < .01, filename + " has a non-transparent corner"
assert max(image.pixels[3::4]) > .5, filename + " has no visible geometry"
bpy.data.images.remove(image)
print("VERIFIED_TRANSPARENT_PNG", filename, expected_size)
