"""Validate the seven camera-aligned L01 Barangay Morning Blender PNG layers."""

import os

import bpy


HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "generated", "l01_barangay_v03_layers")
LAYERS = ("sky", "far", "mid", "near", "foreground", "road", "lane_overlay")


def alpha(image, x, y):
    width, height = image.size
    return image.pixels[((height - 1 - y) * width + x) * 4 + 3]


assert os.path.isdir(ART), "L01 v03 layer export directory is missing"
images = {}
for layer in LAYERS:
    path = os.path.join(ART, "l01_barangay_%s_v03.png" % layer)
    assert os.path.isfile(path), "Missing Blender layer: " + path
    image = bpy.data.images.load(path, check_existing=False)
    images[layer] = image
    assert tuple(image.size) == (960, 540), "%s must be exactly 960x540" % layer
    assert image.channels == 4, "%s must be RGBA" % layer

assert alpha(images["sky"], 0, 0) > .98, "Sky must cover the entire canvas"
for layer in ("far", "mid", "near", "foreground"):
    assert alpha(images[layer], 480, 500) < .02, "%s obscures the lower player-safe zone" % layer
assert alpha(images["road"], 480, 500) > .95, "Road is missing under the player"
assert alpha(images["road"], 10, 500) < .02, "Road spills into the left verge"
assert alpha(images["road"], 950, 500) < .02, "Road spills into the right verge"
assert alpha(images["lane_overlay"], 480, 500) < .02, "Lane overlay blocks the center lane"
assert any(alpha(images["lane_overlay"], x, 500) > .25 for x in range(250, 420)), "Left lane separator missing"
assert any(alpha(images["lane_overlay"], x, 500) > .25 for x in range(540, 710)), "Right lane separator missing"
print("L01_BARANGAY_V03_LAYER_VALIDATION_PASS")
