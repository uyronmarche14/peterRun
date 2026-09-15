"""Alpha-composite the seven exported Blender layers for visual review only."""

import os

import bpy
import numpy as np


ROOT = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(ROOT, "generated", "l01_barangay_v03_layers")
ORDER = ("sky", "far", "mid", "road", "lane_overlay", "near", "foreground")
W, H = 960, 540
result = np.zeros((W*H,4), dtype=np.float32)
for layer in ORDER:
    path = os.path.join(ART, f"l01_barangay_{layer}_v03.png")
    img = bpy.data.images.load(path, check_existing=False)
    assert tuple(img.size) == (W,H), path
    pixels = np.empty(W*H*4, dtype=np.float32)
    img.pixels.foreach_get(pixels)
    src = pixels.reshape((-1,4))
    alpha = src[:,3:4]
    result[:,:3] = src[:,:3]*alpha + result[:,:3]*(1-alpha)
    result[:,3:4] = alpha + result[:,3:4]*(1-alpha)
out = bpy.data.images.new("L01_v03_Layer_Review", width=W, height=H, alpha=True)
out.pixels.foreach_set(result.ravel())
out.filepath_raw = os.path.join(ART, "l01_barangay_composite_review_v03.png")
out.file_format = "PNG"
out.save()
print("SAVED_REVIEW_COMPOSITE", out.filepath_raw)
