import os
import struct
import bpy

ROOT = os.path.dirname(os.path.abspath(__file__))
PNG = os.path.normpath(os.path.join(ROOT, "..", "code", "art", "backgrounds", "dashboard_barangay_complete_v02.png"))
errors = []
scene = bpy.data.scenes.get("PETER_RUN_DASHBOARD_COMPLETE_V02")
if scene is None:
    errors.append("missing complete dashboard scene")
else:
    if scene.get("asset_id") != "dashboard_barangay_complete_v02": errors.append("wrong asset metadata")
    if not {"Dashboard_Complete_UI", "Dashboard_Landmark", "Dashboard_Market"}.issubset(set(bpy.data.collections.keys())): errors.append("missing complete dashboard collections")
    if scene.render.resolution_x != 960 or scene.render.resolution_y != 540: errors.append("wrong dimensions")
if not os.path.isfile(PNG):
    errors.append("missing complete dashboard PNG")
else:
    with open(PNG, "rb") as f: header = f.read(26)
    if header[:8] != b"\x89PNG\r\n\x1a\n": errors.append("not png")
    else:
        width, height, _bit, color_type = struct.unpack(">IIBB", header[16:26])
        if (width, height) != (960, 540) or color_type != 6: errors.append("invalid RGBA canvas")
if errors: raise RuntimeError("PETER_RUN_DASHBOARD_COMPLETE_V02_VALIDATION_FAIL: " + "; ".join(errors))
print("PETER_RUN_DASHBOARD_COMPLETE_V02_VALIDATION_PASS", PNG)
