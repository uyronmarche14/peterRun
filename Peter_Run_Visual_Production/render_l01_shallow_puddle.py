"""Render one transparent L01_ShallowPuddle PNG from the saved Blender source.

Usage: blender -b L01_ShallowPuddle_Source_v01.blend --python render_l01_shallow_puddle.py -- filename.png
One image per process avoids the Blender 5.2 multi-render crash seen locally.
"""

import os
import sys

import bpy


ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "generated", "l01_shallow_puddle")
os.makedirs(OUT, exist_ok=True)
jobs = {
    "prompt_l01_shallow_puddle_v03.png": ("L01_ShallowPuddle_ACTIVE_JUMP", (256,128)),
    "prompt_l01_shallow_puddle_ripple_v01.png": ("L01_ShallowPuddle_RIPPLE_OVERLAY", (256,128)),
    "decor_l01_small_puddle_v01.png": ("L01_ShallowPuddle_ROADSIDE_DECORATIVE", (128,64)),
}
if "--" not in sys.argv or sys.argv.index("--") + 1 >= len(sys.argv):
    raise RuntimeError("Pass exactly one requested PNG filename after --")
filename = sys.argv[sys.argv.index("--") + 1]
scene_name, expected_size = jobs[filename]
scene = bpy.data.scenes[scene_name]
scene.render.filepath = os.path.join(OUT, filename)
scene.render.film_transparent = True
scene.render.image_settings.color_mode = "RGBA"
bpy.ops.render.render(scene=scene.name, write_still=True)
image = bpy.data.images.load(scene.render.filepath, check_existing=False)
assert tuple(image.size) == expected_size, (filename, tuple(image.size))
assert image.pixels[3] < .01, filename + " has a non-transparent export corner"
assert max(image.pixels[3::4]) > .5, filename + " has no visible puddle geometry"
bpy.data.images.remove(image)
print("VERIFIED_TRANSPARENT_PNG", filename, expected_size)
