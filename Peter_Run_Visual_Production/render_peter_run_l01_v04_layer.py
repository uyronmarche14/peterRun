"""Render one PR V04 layer or the master review image."""

import os
import sys

import bpy


ROOT=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(ROOT,"generated","l01_v04_fresh")
os.makedirs(OUT,exist_ok=True)
if "--" not in sys.argv:
    raise RuntimeError("Pass a layer name or master after --")
layer=sys.argv[sys.argv.index("--")+1]
if layer=="master":
    scene=bpy.data.scenes["PETER_RUN_L01_V04_FRESH_MASTER"]
    filename="l01_v04_composite_review.png"
else:
    scene=bpy.data.scenes["PR_V04_EXPORT_"+layer.upper()]
    filename=scene["output_filename"]
scene.render.filepath=os.path.join(OUT,filename)
bpy.ops.render.render(scene=scene.name,write_still=True)
image=bpy.data.images.load(scene.render.filepath,check_existing=False)
assert tuple(image.size)==(960,540)
assert image.channels==4
print("RENDERED",layer,scene.render.filepath)
