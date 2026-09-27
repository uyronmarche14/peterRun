"""Validate the dedicated Blender-authored PETER RUN dashboard hero export."""

import os
import struct

import bpy

ROOT = os.path.dirname(os.path.abspath(__file__))
BLEND = os.path.join(ROOT, "Dashboard_Barangay_Hero_Source_v01.blend")
PNG = os.path.normpath(os.path.join(ROOT, "..", "code", "art", "backgrounds", "dashboard_barangay_morning_hero_v01.png"))
EXPECTED_SCENE = "PETER_RUN_DASHBOARD_BARANGAY_HERO_V01"
EXPECTED_COLLECTIONS = {"Dashboard_Sky", "Dashboard_Clouds", "Dashboard_Hills", "Dashboard_Landmark", "Dashboard_Market", "Dashboard_Homes", "Dashboard_Road", "Dashboard_Plants"}

errors = []
if bpy.data.filepath and os.path.normcase(bpy.data.filepath) != os.path.normcase(BLEND):
    errors.append("unexpected blend source")
scene = bpy.data.scenes.get(EXPECTED_SCENE)
if scene is None:
    errors.append("missing dashboard hero scene")
else:
    if scene.render.resolution_x != 960 or scene.render.resolution_y != 540:
        errors.append("wrong render dimensions")
    if scene.render.image_settings.file_format != "PNG" or scene.render.image_settings.color_mode != "RGBA":
        errors.append("dashboard hero must export RGBA PNG")
    if scene.get("asset_id") != "dashboard_barangay_morning_hero_v01":
        errors.append("missing dashboard asset metadata")
if not EXPECTED_COLLECTIONS.issubset(set(bpy.data.collections.keys())):
    errors.append("missing dashboard hero collections")
if not os.path.isfile(PNG):
    errors.append("hero PNG missing")
else:
    with open(PNG, "rb") as image:
        header = image.read(26)
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        errors.append("hero output is not PNG")
    else:
        width, height, bit_depth, color_type = struct.unpack(">IIBB", header[16:26])
        if (width, height) != (960, 540):
            errors.append("hero PNG dimensions are not 960x540")
        # PNG color type 6 is RGBA. Blender may write truecolor+alpha only.
        if color_type != 6:
            errors.append("hero PNG lacks alpha channel")

if errors:
    raise RuntimeError("PETER_RUN_DASHBOARD_HERO_VALIDATION_FAIL: " + "; ".join(errors))
print("PETER_RUN_DASHBOARD_HERO_VALIDATION_PASS", PNG)
