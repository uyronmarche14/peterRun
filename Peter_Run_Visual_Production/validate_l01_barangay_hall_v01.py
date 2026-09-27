"""Deterministic export/alignment checks for L01 Barangay Hall layers."""

import os

import bpy


ROOT = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(ROOT, "generated", "l01_barangay_hall_v01")
LAYERS = (
    "sky_sun", "distant_hills_clouds", "barangay_hall_landmark",
    "distant_rooftops", "midground_homes_store", "near_roadside_props",
    "foreground_edges", "road_surface", "lane_overlay", "horizon_haze_glow",
)


def rgba(image, x, y):
    # Blender pixels count from bottom; requested coordinates count from top.
    index = ((image.size[1]-1-y)*image.size[0]+x)*4
    return tuple(image.pixels[index:index+4])


for layer in LAYERS:
    path = os.path.join(OUT, "l01_barangay_hall_%s_v01.png" % layer)
    assert os.path.exists(path), path
    image = bpy.data.images.load(path, check_existing=False)
    assert tuple(image.size) == (960,540), (layer, tuple(image.size))
    assert image.channels == 4, layer
    if layer not in ("sky_sun", "road_surface"):
        assert rgba(image,480,520)[3] < .05, (layer,"lower centre must remain transparent")
    bpy.data.images.remove(image)

road = bpy.data.images.load(os.path.join(OUT,"l01_barangay_hall_road_surface_v01.png"),check_existing=False)
assert rgba(road,480,500)[3] > .8
assert rgba(road,20,500)[3] < .05
bpy.data.images.remove(road)
lanes = bpy.data.images.load(os.path.join(OUT,"l01_barangay_hall_lane_overlay_v01.png"),check_existing=False)
assert rgba(lanes,480,500)[3] < .05
assert rgba(lanes,382,500)[3] > .3
assert rgba(lanes,577,500)[3] > .3
bpy.data.images.remove(lanes)
sky = bpy.data.images.load(os.path.join(OUT,"l01_barangay_hall_sky_sun_v01.png"),check_existing=False)
sun_pixel = rgba(sky,585,176)
sky_pixel = rgba(sky,585,70)
assert sum(abs(sun_pixel[i]-sky_pixel[i]) for i in range(3)) > .18, "sun must be visibly distinct from sky"
bpy.data.images.remove(sky)
distant = bpy.data.images.load(os.path.join(OUT,"l01_barangay_hall_distant_hills_clouds_v01.png"),check_existing=False)
assert rgba(distant,110,190)[3] > .5, "distant hills must render"
assert rgba(distant,760,108)[3] > .5, "soft cloud layer must render"
bpy.data.images.remove(distant)
hall = bpy.data.images.load(os.path.join(OUT,"l01_barangay_hall_barangay_hall_landmark_v01.png"),check_existing=False)
assert rgba(hall,480,230)[3] > .1, "landmark must occupy horizon centre"
assert rgba(hall,480,500)[3] < .05, "landmark must not enter player safe zone"
bpy.data.images.remove(hall)
print("L01_BARANGAY_HALL_V01_VALIDATION_PASS")
