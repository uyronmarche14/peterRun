"""Create editable L01 models inside a new Blender source, without touching Godot.

Run: blender -b L01_Barangay_Morning_Visual_Source_v03.blend --python build_l01_blender_models_v04.py
The original route is retained as a separate scene. The model-review scene opens first.
"""

import math
import os

import bpy
from mathutils import Vector


HERE = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(HERE, "L01_Barangay_Morning_Models_v04.blend")
PREVIEW = os.path.join(HERE, "generated", "l01_v04_models_preview.png")
ROUTE = bpy.context.scene
ROUTE.name = "L01_Barangay_Route_Source"
review = bpy.data.scenes.new("L01_Obstacle_Model_Review")
review.render.engine = "BLENDER_EEVEE"
review.render.resolution_x = 1600
review.render.resolution_y = 900
review.render.resolution_percentage = 100
review.render.image_settings.file_format = "PNG"
review.render.image_settings.color_mode = "RGBA"
review.render.film_transparent = False
review.render.filepath = PREVIEW
review.world = bpy.data.worlds.new("L01_Review_Warm_Sky")
review.world.use_nodes = True
review.world.node_tree.nodes.get("Background").inputs["Color"].default_value = (0.72, 0.79, 0.72, 1)
review.world.node_tree.nodes.get("Background").inputs["Strength"].default_value = 0.55
review.view_settings.view_transform = "Standard"
review.view_settings.look = "Medium High Contrast"
review.view_settings.exposure = -0.35


def material(name, color, roughness=0.86):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


ink = material("L01V04_Deep_Teal_Outline", (0.105, 0.19, 0.19))
wood = material("L01V04_Warm_Slat_Wood", (0.48, 0.29, 0.16))
wood_light = material("L01V04_Sunlit_Wood_Edge", (0.69, 0.49, 0.28))
wood_dark = material("L01V04_Shadowed_Wood_Inset", (0.30, 0.18, 0.12))
bamboo = material("L01V04_Bamboo", (0.66, 0.52, 0.29))
cream = material("L01V04_Warm_Cream", (0.88, 0.78, 0.57))
mango = material("L01V04_Mango_Accent", (0.94, 0.57, 0.23))
teal = material("L01V04_Muted_Teal", (0.17, 0.43, 0.43))
coral = material("L01V04_Muted_Coral", (0.68, 0.34, 0.27))
water_dark = material("L01V04_Puddle_Deep_Edge", (0.13, 0.34, 0.40), 0.55)
water = material("L01V04_Puddle_Surface", (0.28, 0.58, 0.60), 0.27)
water_light = material("L01V04_Puddle_Morning_Reflection", (0.72, 0.82, 0.73), 0.25)
ground = material("L01V04_Review_Ground", (0.62, 0.65, 0.55))
skin = material("L01V04_Peter_Skin", (0.55, 0.36, 0.23))
shirt = material("L01V04_Peter_Terracotta_Shirt", (0.64, 0.36, 0.25))
trousers = material("L01V04_Peter_Trousers", (0.17, 0.32, 0.31))
hair = material("L01V04_Peter_Hair", (0.20, 0.16, 0.12))


def collection(name):
    coll = bpy.data.collections.new(name)
    review.collection.children.link(coll)
    return coll


crate_coll = collection("MODEL_01_Delivery_Crates_Active_One_Lane")
puddle_coll = collection("MODEL_02_Shallow_Puddle_Jump")
laundry_coll = collection("MODEL_03_Laundry_Pass_Under_Slide")
peter_coll = collection("MODEL_04_Peter_Back_View_Style_Study")
stage = collection("REVIEW_ONLY_Ground_Camera_Lighting")


def mesh(name, vertices, faces, mat, coll):
    data = bpy.data.meshes.new(name + "_Mesh")
    data.from_pydata(vertices, [], faces)
    data.update()
    data.materials.append(mat)
    obj = bpy.data.objects.new(name, data)
    coll.objects.link(obj)
    return obj


def box(name, center, size, mat, coll, bevel=0.018, rotation_y=0):
    x, y, z = center
    sx, sy, sz = (v / 2 for v in size)
    verts = [(x + dx * sx, y + dy * sy, z + dz * sz)
             for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
    faces = [(0, 4, 6, 2), (1, 3, 7, 5), (0, 1, 5, 4),
             (2, 6, 7, 3), (0, 2, 3, 1), (4, 5, 7, 6)]
    obj = mesh(name, verts, faces, mat, coll)
    if rotation_y:
        obj.rotation_euler.y = rotation_y
        # Rotations operate around the mesh origin, so preserve the intended centre.
        obj.data.transform(__import__("mathutils").Matrix.Translation(Vector((-x, -y, -z))))
        obj.location = (x, y, z)
    if bevel:
        mod = obj.modifiers.new("Restrained_Edge_Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        obj.modifiers.new("Weighted_Normals", "WEIGHTED_NORMAL")
    return obj


def disk(name, center, radii, mat, coll, z=0.015, count=24):
    cx, cy = center
    rx, ry = radii
    outer = [(cx + rx * math.cos(2 * math.pi * i / count),
              cy + ry * math.sin(2 * math.pi * i / count), z) for i in range(count)]
    return mesh(name, [(cx, cy, z), *outer],
                [(0, i + 1, (i + 1) % count + 1) for i in range(count)], mat, coll)


def ribbon(name, points, width, mat, coll):
    vertices = []
    for i, (x, y, z) in enumerate(points):
        prev = Vector(points[max(0, i - 1)])
        nxt = Vector(points[min(len(points) - 1, i + 1)])
        tangent = (nxt - prev).normalized()
        side = Vector((-tangent.y, tangent.x, 0)).normalized() * width / 2
        vertices.extend([(x - side.x, y - side.y, z), (x + side.x, y + side.y, z)])
    return mesh(name, vertices,
                [(2 * i, 2 * i + 1, 2 * i + 3, 2 * i + 2) for i in range(len(points) - 1)],
                mat, coll)


# Architectural accents live in the route scene, separate from the review
# model kit. They stay outside the three road lanes and remain real geometry.
route_accents = bpy.data.collections.new("L01_V04_Route_Architectural_Accents")
ROUTE.collection.children.link(route_accents)
for side in (-1, 1):
    for index in (0, 1):
        house = bpy.data.objects[f"Route_House_{side}_{index}"]
        x, y, _ = house.location
        front = y + house.dimensions.y / 2 + .075
        width = house.dimensions.x
        facade = cream if index == 0 else wood_light
        # Porch depth, pillars, lintel and a sober painted-concrete plinth.
        box(f"RouteV04_House_{side}_{index}_Plinth", (x, front + .025, .13),
            (width + .14, .15, .22), facade, route_accents, .018)
        for post_side in (-1, 1):
            px = x + post_side * (width * .37)
            box(f"RouteV04_House_{side}_{index}_Veranda_Post_{post_side}",
                (px, front + .52, 1.14), (.09, .10, 2.05), bamboo, route_accents)
            box(f"RouteV04_House_{side}_{index}_Post_Foot_{post_side}",
                (px, front + .52, .15), (.18, .18, .22), wood_light, route_accents)
        box(f"RouteV04_House_{side}_{index}_Veranda_Lintel", (x, front + .52, 2.12),
            (width * .82, .13, .11), wood_light, route_accents)
        box(f"RouteV04_House_{side}_{index}_Eave_Fascia", (x, y + .78, 2.25),
            (width + .33, .12, .11), coral if index == 0 else teal, route_accents)
        # Large-scale wall strips give a sawali feel without unreadable text.
        for row in range(3):
            box(f"RouteV04_House_{side}_{index}_Sawali_{row}",
                (x + side * .85, front + .07, .72 + row * .29),
                (.39, .025, .025), bamboo, route_accents, .006)
        # The light remains a window, not a flashing gameplay cue.
        box(f"RouteV04_House_{side}_{index}_Window_Shutter", (x + side * .44,
            front + .13, 1.45), (.08, .045, .59), teal, route_accents, .008)
        for pot_index in range(2):
            px = x - side * (.75 + pot_index * .37)
            py = front + .79
            box(f"RouteV04_House_{side}_{index}_Pot_{pot_index}",
                (px, py, .26), (.25, .25, .37), coral, route_accents)
            mesh(f"RouteV04_House_{side}_{index}_Pot_Leaf_{pot_index}",
                 [(px, py, .41), (px - .20, py + .03, .85),
                  (px + .03, py + .02, .70), (px + .18, py, .89)],
                 [(0, 1, 2), (0, 2, 3)], teal, route_accents)

# Sari-sari frontage and market cue: shelves and color groups, no micro-text.
store_x = bpy.data.objects["SariSari_Awning"].location.x
store_y = bpy.data.objects["SariSari_Awning"].location.y
for i in range(5):
    box(f"RouteV04_Store_Awning_Scallop_{i}",
        (store_x - .85 + i * .42, store_y + .43, 1.99),
        (.39, .055, .16), cream if i % 2 else coral, route_accents)
for row in range(2):
    box(f"RouteV04_Store_Shelf_{row}",
        (store_x, store_y + .56, .72 + row * .43),
        (1.35, .16, .07), wood_light, route_accents)
    for item in range(4):
        box(f"RouteV04_Store_Goods_{row}_{item}",
            (store_x - .51 + item * .34, store_y + .55, .86 + row * .43),
            (.19, .12, .22), (cream, coral, teal, mango)[(item + row) % 4],
            route_accents, .01)

# Near-road drainage and pavers offer forward depth rhythm, but cannot be
# mistaken for a playable prompt. Everything is beyond the road edge.
for side in (-1, 1):
    for i, y in enumerate((-5.5, -8.3, -11.6, -15.2, -19.1)):
        box(f"RouteV04_Drainage_Slot_{side}_{i}", (side * 4.88, y, .167),
            (.43, .09, .014), wood_dark, route_accents, .005)
        box(f"RouteV04_Quiet_Curb_Mark_{side}_{i}", (side * 4.48, y + .38, .20),
            (.08, .39, .02), cream, route_accents, .006)


# Delivery crates: staggered, asymmetric, with large readable X-braces and
# a single warm accent. Model dimensions are one lane, not a road-wide wall.
X = -5.8
disk("Crate_Contact_Shadow", (X, 0), (1.00, 0.59), ink, crate_coll, 0.015)
for index, (dx, z, width) in enumerate(((0, 0.55, 1.75), (0.25, 1.50, 1.34))):
    cx = X + dx
    box(f"Crate_{index}_Dark_Core", (cx, 0, z), (width, .86, .90), wood_dark, crate_coll)
    box(f"Crate_{index}_Front_Inset", (cx, .447, z), (width - .20, .035, .69), wood, crate_coll)
    for side in (-1, 1):
        box(f"Crate_{index}_Side_Frame_{side}", (cx + side * (width / 2 - .08), .47, z),
            (.13, .10, .90), wood_light, crate_coll)
    for height in (-.39, .39):
        box(f"Crate_{index}_Horizontal_Rim_{height}", (cx, .48, z + height),
            (width, .11, .13), wood_light, crate_coll)
    length = math.hypot(width - .30, .70)
    for sign in (-1, 1):
        box(f"Crate_{index}_Cross_Brace_{sign}", (cx, .51, z),
            (.11, .08, length), wood_light, crate_coll,
            rotation_y=sign * math.atan2(width - .30, .70))
    box(f"Crate_{index}_Top", (cx, 0, z + .47), (width + .08, .94, .11), bamboo, crate_coll)
    box(f"Crate_{index}_Handle", (cx + width / 2 + .009, 0, z + .11),
        (.018, .37, .12), ink, crate_coll)
box("Crate_Active_Delivery_Band", (X + .24, .565, 1.48),
    (.64, .035, .13), mango, crate_coll)
box("Crate_Readable_Cream_Tag", (X + .22, .59, 1.64),
    (.48, .032, .20), cream, crate_coll)


# Puddle: a thin, irregular ground silhouette, quiet reflection and two
# geometry-based ripple arcs. Its profile cannot read as a raised obstacle.
X = -1.8
points = []
for i in range(28):
    a = math.tau * i / 28
    r = 1 + .065 * math.sin(3 * a + .3) + .09 * math.sin(7 * a)
    points.append((X + 1.18 * r * math.cos(a), .76 * r * math.sin(a)))
outline = mesh("Puddle_Dark_Irregular_Rim", [(x, y, .019) for x, y in points],
               [tuple(range(len(points)))], water_dark, puddle_coll)
mesh("Puddle_Shallow_Water", [(X + (x - X) * .91, y * .89, .024) for x, y in points],
     [tuple(range(len(points)))], water, puddle_coll)
disk("Puddle_Reflection_Broad", (X - .25, .17), (.62, .23), water_light, puddle_coll, .027)
disk("Puddle_Reflection_Small", (X + .53, -.18), (.20, .07), cream, puddle_coll, .028)
for index, (cx, cy, rx, ry) in enumerate(((X + .20, -.05, .39, .19), (X + .20, -.05, .62, .32))):
    arc = [(cx + rx * math.cos(math.pi * t / 14),
            cy + ry * math.sin(math.pi * t / 14), .030) for t in range(2, 13)]
    ribbon(f"Puddle_Ripple_Arc_{index}", arc, .025, cream, puddle_coll)


# Laundry: two bamboo uprights, a clear empty opening, three gently uneven
# cloth shapes. The fabric is physically separate for future Blender poses.
X = 2.1
for side in (-1, 1):
    px = X + side * 1.42
    disk(f"Laundry_Post_Shadow_{side}", (px, .03), (.27, .20), ink, laundry_coll)
    box(f"Laundry_Bamboo_Post_{side}", (px, 0, 1.37), (.13, .13, 2.74), bamboo, laundry_coll)
    for z in (.28, 1.33, 2.51):
        box(f"Laundry_Bamboo_Node_{side}_{z}", (px, 0, z),
            (.16, .16, .045), wood_light, laundry_coll)
box("Laundry_Soft_Top_Rail", (X, 0, 2.71), (2.9, .075, .075), ink, laundry_coll)
for index, (cx, width, length, cloth_mat) in enumerate((
        (X - .85, .64, .72, cream), (X, .79, 1.00, coral), (X + .89, .59, .79, teal))):
    top = 2.67
    zs = [top, top - length * .35, top - length * .72, top - length]
    verts = []
    for row, z in enumerate(zs):
        sway = (0, .035, .065, .085)[row] * (1 if index % 2 else -1)
        verts.extend([(cx - width / 2 + sway, .095 + row * .035, z),
                      (cx + width / 2 + sway, .095 + row * .035, z + (0.045 if index == 1 and row == 3 else 0))])
    mesh(f"Laundry_Cloth_{index}_Separate_Sway_Mesh", verts,
         [(2 * row, 2 * row + 1, 2 * row + 3, 2 * row + 2) for row in range(3)],
         cloth_mat, laundry_coll)
    box(f"Laundry_Clothespin_{index}", (cx, .13, top + .015),
        (.095, .07, .11), wood_light, laundry_coll)
box("Laundry_Pass_Under_Height_Guide", (X, 0, 1.40),
    (2.5, .014, .013), cream, laundry_coll, bevel=0)
laundry_coll.objects["Laundry_Pass_Under_Height_Guide"]["review_only"] = True


# A respectful adult back view matching the existing terracotta/teal design.
# This is a source-model study; no game character asset is replaced.
X = 6.5
disk("Peter_Soft_Foot_Shadow", (X, 0), (.57, .31), ink, peter_coll)
for side in (-1, 1):
    box(f"Peter_Shoe_{side}", (X + side * .25, .10, .11),
        (.31, .50, .20), wood_dark, peter_coll)
    box(f"Peter_Leg_{side}", (X + side * .24, 0, .54),
        (.27, .34, .82), trousers, peter_coll, .055)
box("Peter_Adult_Torso", (X, 0, 1.45), (.99, .48, 1.10), shirt, peter_coll, .13)
for side in (-1, 1):
    box(f"Peter_Arm_{side}", (X + side * .64, .02, 1.35),
        (.26, .35, .85), shirt, peter_coll, .10)
    box(f"Peter_Hand_{side}", (X + side * .65, .03, .86),
        (.22, .25, .20), skin, peter_coll, .08)
box("Peter_Visible_Neck", (X, .00, 2.09), (.30, .30, .22), skin, peter_coll, .07)
box("Peter_Head_Back", (X, .00, 2.40), (.53, .45, .56), skin, peter_coll, .16)
box("Peter_Dark_Hair", (X, -.005, 2.69), (.58, .49, .22), hair, peter_coll, .12)
box("Peter_Hair_Back_Edge", (X, .25, 2.54), (.57, .08, .18), hair, peter_coll, .05)
box("Peter_Teal_Backpack", (X, .31, 1.50), (.67, .21, .79), teal, peter_coll, .09)
box("Peter_Backpack_Mango_Strip", (X, .43, 1.56), (.39, .02, .07), mango, peter_coll, .01)
for side in (-1, 1):
    box(f"Peter_Backpack_Strap_{side}", (X + side * .36, .24, 1.76),
        (.075, .11, .64), ink, peter_coll, .02)


# A review stage is deliberately separate from every usable model collection.
box("Review_Neutral_Ground", (0, 0, -.10), (15.2, 4.1, .17), ground, stage, .03)
for x in (-5.8, -1.8, 2.1, 6.5):
    disk(f"Review_Station_{x}", (x, 0), (1.65, 1.04), cream, stage, -.004)
camera_data = bpy.data.cameras.new("L01_Model_Review_Orthographic")
camera = bpy.data.objects.new("L01_Model_Review_Orthographic", camera_data)
stage.objects.link(camera)
camera.location = (0, 18, 10)
aim = Vector((0, 0, 1.23))
camera.rotation_euler = (aim - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 15.9
review.camera = camera
light_data = bpy.data.lights.new("Warm_Morning_Key", "AREA")
light = bpy.data.objects.new("Warm_Morning_Key", light_data)
stage.objects.link(light)
light.location = (-4.5, 6, 11)
light_data.energy = 1250
light_data.shape = "DISK"
light_data.size = 9
light.rotation_euler = (Vector((0, 0, 1)) - light.location).to_track_quat("-Z", "Y").to_euler()

review["design_intent"] = "Editable 2.5D source models only; not a Godot/runtime scene"
review["lane_rule"] = "One active crate target; puddle low; laundry has a visible pass-under gap"
crate_coll["approx_width_m"] = 1.75
puddle_coll["approx_width_m"] = 2.36
laundry_coll["opening_clear_height_m"] = 1.67
peter_coll["status"] = "Back-view style study; existing gameplay animations untouched"

os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
bpy.context.window.scene = review
bpy.ops.wm.save_as_mainfile(filepath=OUTPUT)
review.render.filepath = PREVIEW
bpy.ops.render.render(write_still=True)
print("SAVED_BLEND", OUTPUT)
print("RENDERED_PREVIEW", PREVIEW)
