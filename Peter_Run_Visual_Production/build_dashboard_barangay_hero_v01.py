"""Build the Blender-authored PETER RUN Barangay Morning dashboard hero.

This source is intentionally separate from the gameplay route. It renders one
960x540 opaque hero image with left-side negative space for the Godot route card.
"""

import math
import os

import bpy
from mathutils import Vector

ROOT = os.path.dirname(os.path.abspath(__file__))
OUT_BLEND = os.path.join(ROOT, "Dashboard_Barangay_Hero_Source_v01.blend")
OUT_PNG = os.path.normpath(os.path.join(ROOT, "..", "code", "art", "backgrounds", "dashboard_barangay_morning_hero_v01.png"))
W, H = 960, 540

bpy.ops.wm.read_factory_settings(use_empty=True)
factory_scene = bpy.context.scene
scene = bpy.data.scenes.new("PETER_RUN_DASHBOARD_BARANGAY_HERO_V01")
bpy.context.window.scene = scene
bpy.data.scenes.remove(factory_scene)
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = W
scene.render.resolution_y = H
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.compression = 18
scene.render.film_transparent = False
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "Medium High Contrast"
scene.render.filepath = OUT_PNG

world = bpy.data.worlds.new("Dashboard_Morning_Sky")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.59, 0.78, 0.75, 1.0)
world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.42
scene.world = world

root = bpy.data.collections.new("PETER_RUN_DASHBOARD_HERO")
scene.collection.children.link(root)
collections = {}
for name in ("Sky", "Clouds", "Hills", "Landmark", "Market", "Homes", "Road", "Plants", "Light"):
    collection = bpy.data.collections.new("Dashboard_" + name)
    root.children.link(collection)
    collections[name] = collection


def material(name, color, roughness=0.82, emission=None):
    value = bpy.data.materials.new(name)
    value.diffuse_color = (*color, 1.0)
    value.use_nodes = True
    bsdf = value.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 0.65
    return value


def relink(obj, collection):
    for old in tuple(obj.users_collection):
        old.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def cube(name, location, dimensions, mat, collection, bevel=0.04):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = relink(bpy.context.object, collection)
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        modifier = obj.modifiers.new("Soft_Illustrated_Edge", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    return obj


def cylinder(name, location, radius, depth, mat, collection, vertices=12, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location, rotation=rotation)
    obj = relink(bpy.context.object, collection)
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def ico(name, location, scale, mat, collection, subdivisions=1):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1.0, location=location)
    obj = relink(bpy.context.object, collection)
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    return obj


def roof(name, location, width, depth, height, mat, collection):
    verts = [
        (-width / 2, -depth / 2, 0), (width / 2, -depth / 2, 0), (0, -depth / 2, height),
        (-width / 2, depth / 2, 0), (width / 2, depth / 2, 0), (0, depth / 2, height),
    ]
    faces = [(0, 2, 1), (3, 4, 5), (0, 3, 5, 2), (1, 2, 5, 4), (0, 1, 4, 3)]
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.location = location
    modifier = obj.modifiers.new("Roof_Edge", "BEVEL")
    modifier.width = 0.06
    modifier.segments = 2
    return obj


def text(name, body, location, size, mat, collection):
    curve = bpy.data.curves.new(name + "_Curve", "FONT")
    curve.body = body
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.size = size
    curve.extrude = 0.01
    curve.bevel_depth = 0.004
    curve.materials.append(mat)
    obj = bpy.data.objects.new(name, curve)
    collection.objects.link(obj)
    obj.location = location
    obj.rotation_euler.x = math.radians(90)
    return obj


def plant(name, location, scale=1.0):
    collection = collections["Plants"]
    cube(name + "_Planter", location + Vector((0, 0, 0.28 * scale)), (0.7 * scale, 0.55 * scale, 0.55 * scale), terracotta, collection, 0.05)
    cylinder(name + "_Stem", location + Vector((0, 0, 0.95 * scale)), 0.055 * scale, 1.4 * scale, wood, collection, 8)
    for side in (-1, 1):
        for row in range(3):
            ico(name + "_Leaf_%s_%s" % (side, row), location + Vector((side * (0.25 + row * 0.05) * scale, 0, (1.15 + row * 0.35) * scale)), (0.35 * scale, 0.18 * scale, 0.25 * scale), leaf_light if row % 2 else leaf, collection)


def house(name, location, facade, roof_mat, width=3.2, depth=2.2, height=2.6):
    collection = collections["Homes"]
    base = Vector(location)
    cube(name + "_Wall", base + Vector((0, 0, height / 2)), (width, depth, height), facade, collection, 0.08)
    roof(name + "_Roof", base + Vector((0, 0, height)), width + 0.45, depth + 0.4, 0.9, roof_mat, collection)
    cube(name + "_Door", base + Vector((0, -depth / 2 - 0.02, 0.85)), (0.65, 0.08, 1.65), deep_teal, collection, 0.02)
    for x in (-0.85, 0.85):
        cube(name + "_Window_" + str(x), base + Vector((x, -depth / 2 - 0.03, 1.7)), (0.62, 0.08, 0.56), capiz, collection, 0.02)


ink = material("Ink", (0.05, 0.16, 0.17))
deep_teal = material("Deep_Teal", (0.05, 0.25, 0.27))
teal = material("Teal", (0.12, 0.43, 0.43))
teal_soft = material("Teal_Soft", (0.26, 0.55, 0.52))
cream = material("Warm_Cream", (0.91, 0.80, 0.57))
capiz = material("Capiz_Glint", (1.0, 0.89, 0.55), emission=(1.0, 0.68, 0.28))
mango = material("Mango", (0.98, 0.56, 0.10), emission=(1.0, 0.44, 0.07))
sun_core = material("Sun_Cream", (1.0, 0.86, 0.50), emission=(1.0, 0.72, 0.24))
coral = material("Coral", (0.74, 0.29, 0.20))
clay = material("Clay_Roof", (0.46, 0.18, 0.11))
wood = material("Warm_Wood", (0.33, 0.17, 0.08))
terracotta = material("Terracotta", (0.63, 0.31, 0.16))
leaf = material("Leaf", (0.09, 0.36, 0.20))
leaf_light = material("Leaf_Light", (0.27, 0.59, 0.27))
hill_far = material("Hill_Far", (0.24, 0.49, 0.52))
hill_near = material("Hill_Near", (0.10, 0.32, 0.35))
road = material("Route_Stone", (0.54, 0.48, 0.34))
road_edge = material("Route_Edge", (0.95, 0.64, 0.18))
cloud = material("Cloud", (1.0, 0.94, 0.75))

# Camera: a welcoming forward journey, with the landmark high at centre-right.
cam_data = bpy.data.cameras.new("Dashboard_Hero_Camera_Data")
camera = bpy.data.objects.new("Dashboard_Hero_Camera", cam_data)
root.objects.link(camera)
camera.location = (0.0, -24.0, 7.0)
target = Vector((2.9, 18.0, 4.2))
camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
cam_data.lens = 31
cam_data.sensor_width = 36
cam_data.clip_end = 300
scene.camera = camera

# Soft, warm morning lighting.
key_data = bpy.data.lights.new("Morning_Key_Data", "AREA")
key_data.energy = 1600
key_data.color = (1.0, 0.62, 0.30)
key_data.shape = "DISK"
key_data.size = 10
key = bpy.data.objects.new("Morning_Key", key_data)
collections["Light"].objects.link(key)
key.location = (-8, -10, 17)
key.rotation_euler = (Vector((2, 16, 2)) - key.location).to_track_quat("-Z", "Y").to_euler()
fill_data = bpy.data.lights.new("Teal_Fill_Data", "AREA")
fill_data.energy = 650
fill_data.color = (0.37, 0.69, 0.68)
fill_data.size = 11
fill = bpy.data.objects.new("Teal_Fill", fill_data)
collections["Light"].objects.link(fill)
fill.location = (11, -3, 12)
fill.rotation_euler = (Vector((3, 15, 3)) - fill.location).to_track_quat("-Z", "Y").to_euler()

# Warm sun and mountain silhouette are behind the civic landmark.
for x, radius in ((6.0, 3.7), (6.0, 2.65)):
    cylinder("Sun_Glow" if radius > 3 else "Sun_Core", (x, 28.0, 10.5), radius, 0.22, mango if radius > 3 else sun_core, collections["Sky"], 48, rotation=(math.radians(90), 0, 0))
for index, (x, z, width, height) in enumerate(((-13, 4.0, 13, 5.0), (1, 3.4, 14, 4.1), (14, 4.0, 12, 5.0))):
    roof("Mountain_%s" % index, (x, 31.0, z), width, 2.0, height, hill_far if index != 1 else hill_near, collections["Hills"])
for index, (x, y, z, scale) in enumerate(((-8, 24, 9.0, 1.2), (12, 26, 10.0, 1.0), (17, 20, 8.4, 0.75))):
    ico("Cloud_%s_A" % index, (x, y, z), (2.4 * scale, 0.5, 0.65 * scale), cloud, collections["Clouds"])
    ico("Cloud_%s_B" % index, (x + 1.8 * scale, y, z + 0.1), (1.7 * scale, 0.45, 0.5 * scale), cloud, collections["Clouds"])

# Route is deliberately one welcoming pathway, not the gameplay lane layout.
road_vertices = [(-7, -1, 0), (11, -1, 0), (6.8, 24, 0), (0.3, 24, 0)]
road_mesh = bpy.data.meshes.new("Dashboard_Route_Mesh")
road_mesh.from_pydata(road_vertices, [], [(0, 1, 2, 3)])
road_mesh.materials.append(road)
road_obj = bpy.data.objects.new("Dashboard_Route", road_mesh)
collections["Road"].objects.link(road_obj)
for side in (-1, 1):
    edge_vertices = [(side * 7.05, -1, 0.03), (side * 6.65, -1, 0.03), (side * (0.3 if side < 0 else 6.8), 24, 0.03), (side * (0.6 if side < 0 else 6.45), 24, 0.03)]
    edge_mesh = bpy.data.meshes.new("Route_Edge_Mesh_%s" % side)
    edge_mesh.from_pydata(edge_vertices, [], [(0, 1, 2, 3)])
    edge_mesh.materials.append(road_edge)
    edge_obj = bpy.data.objects.new("Route_Edge_%s" % side, edge_mesh)
    collections["Road"].objects.link(edge_obj)

# Tall Barangay Hall, intentionally placed above all homes and market roofs.
hall = collections["Landmark"]
cube("Hall_Plaza", (3.0, 19.3, 0.22), (10.8, 4.5, 0.44), cream, hall, 0.10)
cube("Hall_Main", (3.0, 20.5, 3.25), (8.3, 3.0, 6.0), cream, hall, 0.12)
cube("Hall_Shadow_Wing", (6.35, 20.46, 3.28), (1.2, 3.04, 5.8), teal_soft, hall, 0.08)
roof("Hall_Roof", (3.0, 20.5, 6.15), 9.2, 3.8, 1.45, clay, hall)
cube("Hall_Tower", (3.0, 20.8, 8.4), (2.3, 2.1, 3.5), cream, hall, 0.08)
roof("Hall_Tower_Roof", (3.0, 20.8, 10.1), 2.9, 2.7, 1.0, teal, hall)
for floor_z in (2.45, 4.5):
    for x in (0.4, 2.05, 3.95, 5.55):
        cube("Hall_Window_%s_%s" % (floor_z, x), (x, 18.96, floor_z), (0.72, 0.10, 0.70), capiz, hall, 0.02)
cube("Hall_Door", (3.0, 18.94, 1.45), (1.05, 0.12, 2.25), wood, hall, 0.03)
cube("Hall_Sign", (3.0, 18.90, 5.55), (4.1, 0.10, 0.55), mango, hall, 0.03)
text("Hall_Sign_Text", "BARANGAY HALL", (3.0, 18.82, 5.56), 0.30, deep_teal, hall)

# Sari-sari storefront and community market flank the route, below the hall.
market = collections["Market"]
cube("Market_Wall", (9.4, 14.7, 1.7), (4.2, 2.3, 3.2), cream, market, 0.08)
roof("Market_Coral_Awning", (9.4, 13.6, 3.15), 5.0, 1.4, 0.72, coral, market)
for x in (8.1, 9.4, 10.7):
    cylinder("Market_Post_" + str(x), (x, 13.55, 1.5), 0.10, 3.0, wood, market, 10)
cube("Market_Counter", (9.4, 13.42, 0.95), (3.6, 0.38, 0.65), terracotta, market, 0.03)
for x in (8.25, 9.1, 9.95, 10.7):
    ico("Market_Produce_" + str(x), (x, 13.12, 1.32), (0.20, 0.18, 0.16), mango if int(x * 10) % 2 else leaf_light, market)

cube("SariSari_Wall", (-1.8, 15.0, 1.55), (3.7, 2.15, 2.9), cream, market, 0.07)
roof("SariSari_Awning", (-1.8, 13.95, 2.85), 4.4, 1.15, 0.66, coral, market)
cube("SariSari_Display", (-1.8, 13.87, 1.95), (2.9, 0.09, 1.3), deep_teal, market, 0.02)
for x in (-2.7, -1.8, -0.9):
    cube("SariSari_Shelf_" + str(x), (x, 13.78, 2.12), (0.42, 0.08, 0.32), capiz, market, 0.01)
text("SariSari_Sign", "SARI-SARI", (-1.8, 13.75, 3.12), 0.24, ink, market)

# Homes, waiting shed, plants, fence, and readable route-side details.
house("Home_Right", (13.4, 12.8, 0.0), teal_soft, teal, width=3.9, depth=2.6, height=3.0)
house("Home_Left", (-7.5, 12.2, 0.0), cream, coral, width=3.5, depth=2.4, height=2.8)
for x in (-8.0, -6.5, 11.6, 13.0, 14.5):
    plant("Route_Plant_" + str(x), Vector((x, 8.0 + abs(x) * 0.18, 0.0)), 0.75)
for index, x in enumerate((5.8, 6.4, 7.0)):
    cube("Fence_Post_" + str(index), (x, 4.6 + index * 1.8, 0.6), (0.09, 0.09, 1.2), wood, collections["Plants"], 0.01)
    if index:
        cube("Fence_Rail_" + str(index), (x - 0.3, 4.6 + (index - 0.5) * 1.8, 0.72), (0.07, 1.8, 0.07), cream, collections["Plants"], 0.01)
# Waiting shed beside the route.
cube("Waiting_Shed_Roof", (-5.2, 9.2, 2.25), (2.8, 1.15, 0.22), teal, collections["Homes"], 0.04)
for x in (-6.3, -4.1):
    cylinder("Waiting_Shed_Post_" + str(x), (x, 9.2, 1.15), 0.08, 2.2, wood, collections["Homes"], 10)
cube("Waiting_Shed_Bench", (-5.2, 8.82, 0.72), (1.9, 0.45, 0.20), wood, collections["Homes"], 0.02)

# Metadata records the intended Godot composition contract.
scene["asset_id"] = "dashboard_barangay_morning_hero_v01"
scene["canvas"] = "960x540 RGBA; displays beneath the Godot 480x270 opening UI"
scene["left_safe_region"] = "x=0..440 reserved for dashboard card at 2x export scale"
scene["peter_safe_region"] = "lower-right route remains open for Godot OpeningPlayer overlay"
scene["reduced_motion"] = "runtime overlay animation only; no progress or input semantics"

os.makedirs(os.path.dirname(OUT_PNG), exist_ok=True)
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
bpy.ops.render.render(write_still=True)
print("PETER_RUN_DASHBOARD_HERO_BUILD_PASS", OUT_BLEND, OUT_PNG)
