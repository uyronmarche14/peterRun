"""Build L01_DeliveryCrates in the connected Blender document, then Save As.

The existing scene is retained untouched inside the new blend file. Run only
once in the active original obstacle-source session; this script never removes
existing scenes, collections, objects, or materials.
"""

import math
import os

import bpy
from mathutils import Vector


ROOT = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(ROOT, "L01_DeliveryCrates_Source_v01.blend")
RENDERS = os.path.join(ROOT, "generated", "l01_delivery_crates")
PREFIX = "L01_DeliveryCrates"
if any(scene.name.startswith(PREFIX) for scene in bpy.data.scenes):
    raise RuntimeError("L01_DeliveryCrates scenes already exist; refusing to duplicate them")
if os.path.exists(OUTPUT):
    raise RuntimeError("Output blend already exists; refusing to overwrite it")
os.makedirs(RENDERS, exist_ok=True)


def material(name, rgb, alpha=1.0, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, alpha)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    bsdf.inputs["Roughness"].default_value = .88
    bsdf.inputs["Alpha"].default_value = alpha
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1)
        bsdf.inputs["Emission Strength"].default_value = emission
    if alpha < 1 and hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "DITHERED"
    return mat


wood = material("L01DC_Weathered_Warm_Wood", (.43, .27, .16))
wood_light = material("L01DC_Sunlit_Bamboo_Slats", (.65, .47, .28))
wood_dark = material("L01DC_Recessed_Wood", (.27, .19, .14))
mango = material("L01DC_Mango_Orange_Painted_Edges", (.69, .27, .08))
cream = material("L01DC_Cream_Rope_Braces", (.78, .68, .49))
teal = material("L01DC_Teal_Delivery_Label", (.19, .43, .42))
ink = material("L01DC_Quiet_Deep_Teal_Shadow", (.12, .20, .20))
shadow_outer = material("L01DC_Shadow_Outer", (.09, .16, .15), .12)
shadow_inner = material("L01DC_Shadow_Contact", (.08, .14, .14), .29)
edge_cream = material("L01DC_Active_Pulse_Cream", (.98, .87, .61), emission=.35)
edge_mango = material("L01DC_Active_Pulse_Mango", (.98, .65, .30), emission=.35)
decor_wood = material("L01DC_Roadside_Desaturated_Wood", (.47, .43, .34))
decor_bamboo = material("L01DC_Roadside_Quiet_Bamboo", (.60, .55, .42))
review_ground = material("L01DC_Review_Only_Ground", (.59, .63, .55))


def cube(name, position, dimensions, mat, coll, bevel=.018, rotation_y=0.0):
    sx, sy, sz = [v / 2 for v in dimensions]
    verts = [(dx * sx, dy * sy, dz * sz)
             for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
    faces = [(0, 4, 6, 2), (1, 3, 7, 5), (0, 1, 5, 4),
             (2, 6, 7, 3), (0, 2, 3, 1), (4, 5, 7, 6)]
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    obj.location = position
    obj.rotation_euler.y = rotation_y
    if bevel:
        mod = obj.modifiers.new("Soft_Silhouette_Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        obj.modifiers.new("Weighted_Normals", "WEIGHTED_NORMAL")
    return obj


def ellipse(name, x_radius, y_radius, z, mat, coll):
    count = 32
    verts = [(x_radius * math.cos(math.tau * i / count),
              y_radius * math.sin(math.tau * i / count), z)
             for i in range(count)]
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(verts, [], [tuple(range(count))])
    mesh.update()
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    return obj


def new_scene(name, ortho_scale, resolution):
    scene = bpy.data.scenes.new(name)
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.compression = 15
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = -.12
    scene.world = bpy.data.worlds.new(name + "_Morning_Fill")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.get("Background").inputs["Color"].default_value = (.70, .75, .68, 1)
    scene.world.node_tree.nodes.get("Background").inputs["Strength"].default_value = .45
    support = bpy.data.collections.new(name + "_CAMERA_LIGHT_ONLY")
    scene.collection.children.link(support)
    camera_data = bpy.data.cameras.new(name + "_Orthographic_Camera")
    camera = bpy.data.objects.new(camera_data.name, camera_data)
    support.objects.link(camera)
    camera.location = (2.9, 5.2, 3.2)
    camera.rotation_euler = (Vector((0, 0, .78)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = ortho_scale
    scene.camera = camera
    light_data = bpy.data.lights.new(name + "_Soft_Warm_Key", "AREA")
    light = bpy.data.objects.new(light_data.name, light_data)
    support.objects.link(light)
    light.location = (-2.7, 3.3, 6.2)
    light.rotation_euler = (Vector((0, 0, .7)) - light.location).to_track_quat("-Z", "Y").to_euler()
    light_data.energy = 320
    light_data.shape = "DISK"
    light_data.size = 5
    scene.unit_settings.system = "METRIC"
    return scene


def root(coll, name):
    obj = bpy.data.objects.new(name + "_CENTERED_GROUND_ORIGIN", None)
    coll.objects.link(obj)
    obj.location = (0, 0, 0)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = .30
    obj["contact_z_m"] = 0.0
    return obj


def make_crate(coll, prefix, x, z, width, height, is_active, outside_sign):
    depth = .84 if is_active else .72
    body_mat = wood if is_active else decor_wood
    slat_mat = wood_light if is_active else decor_bamboo
    brace_mat = cream if is_active else decor_bamboo
    front = depth / 2 + .025
    cube(prefix + "_Recessed_Core", (x, 0, z), (width, depth, height),
         wood_dark if is_active else decor_wood, coll)
    # Broad horizontal boards and separated vertical corner bamboo poles.
    for row in (-1, 0, 1):
        cube(prefix + f"_Front_Wood_Plate_{row}",
             (x, front, z + row * height * .275),
             (width - .16, .06, height * .235), body_mat, coll, .012)
    for side in (-1, 1):
        px = x + side * (width / 2 - .075)
        cube(prefix + f"_Bamboo_Corner_{side}", (px, front + .035, z),
             (.115, .115, height), slat_mat, coll)
        cube(prefix + f"_Side_Rim_{side}", (px, 0, z),
             (.11, depth + .04, height + .04), slat_mat, coll)
    for sign in (-1, 1):
        brace_length = math.hypot(width - .30, height - .22)
        angle = sign * math.atan2(width - .30, height - .22)
        cube(prefix + f"_Cream_Rope_Cross_Brace_{sign}",
             (x, front + .075, z), (.075, .052, brace_length),
             brace_mat, coll, .008, angle)
    for sign in (-1, 1):
        height_offset = sign * (height / 2 - .045)
        cube(prefix + f"_Bamboo_Rim_{sign}", (x, front + .055, z + height_offset),
             (width + .025, .095, .09), slat_mat, coll)
    cube(prefix + "_Top_Panel", (x, 0, z + height / 2 + .028),
         (width + .07, depth + .07, .07), slat_mat, coll)
    cube(prefix + "_Side_Handle_Recess", (x + width / 2 + .014, 0, z + .08),
         (.018, .31, .115), ink if is_active else decor_wood, coll, .005)
    if is_active:
        # One outside mango rail is a lane-side cue, not a hazard stripe.
        px = x + outside_sign * (width / 2 + .014)
        cube(prefix + "_Mango_Outside_Edge", (px, front + .095, z),
             (.055, .034, height - .10), mango, coll, .012)
        cube(prefix + "_Mango_Top_Edge", (x, front + .095, z + height / 2 + .045),
             (width + .07, .035, .045), mango, coll, .009)
    # Large weathering marks stay readable after 2.5D downsampling.
    cube(prefix + "_Weathered_Slat_Grain", (x - width * .21, front + .046, z - height * .27),
         (width * .28, .012, .024), slat_mat, coll, .003)


def make_active(name, direction):
    coll = bpy.data.collections.new(name + "_MODEL")
    highlight = bpy.data.collections.new(name + "_PULSE_EDGE_SEPARATE")
    coll.children.link(highlight)
    owner = root(coll, name)
    shadow = bpy.data.collections.new(name + "_CONTACT_SHADOW_SEPARATE")
    coll.children.link(shadow)
    ellipse(name + "_Outer_Soft_Shadow", 1.12, .69, .012, shadow_outer, shadow)
    ellipse(name + "_Inner_Contact_Shadow", .86, .52, .016, shadow_inner, shadow)
    make_crate(coll, name + "_Bottom", 0, .43, 1.76, .78, True, direction)
    offset = direction * .19
    make_crate(coll, name + "_Top", offset, 1.20, 1.37, .66, True, direction)
    # A teal pictographic label without tiny text or implied score.
    cube(name + "_Teal_Delivery_Label", (offset, .523, 1.23),
         (.39, .026, .21), teal, coll, .018)
    cube(name + "_Cream_Label_Icon", (offset, .542, 1.23),
         (.18, .018, .035), cream, coll, .006)
    # Independent edge meshes can be rendered separately and pulsed later.
    for index, (cx, cz, width, height) in enumerate(((0, .43, 1.76, .78),
                                                      (offset, 1.20, 1.37, .66))):
        y = .548
        for side in (-1, 1):
            cube(name + f"_Pulse_Cream_Vertical_{index}_{side}",
                 (cx + side * (width / 2 + .04), y, cz),
                 (.023, .023, height + .045), edge_cream, highlight, .004)
        cube(name + f"_Pulse_Mango_Top_{index}",
             (cx, y, cz + height / 2 + .035),
             (width + .10, .024, .022), edge_mango, highlight, .004)
    coll["asset_name"] = "L01_DeliveryCrates"
    coll["variant"] = "left_lane_active" if direction < 0 else "right_lane_active"
    coll["only_one_active_stack_at_a_time"] = True
    coll["approx_width_m"] = 1.86
    coll["ground_origin"] = owner.name
    for part in list(coll.objects) + list(highlight.objects) + list(shadow.objects):
        if part != owner:
            part.parent = owner
    return coll, highlight


left, left_edge = make_active(PREFIX + "_LEFT", -1)
right, right_edge = make_active(PREFIX + "_RIGHT", 1)
decor = bpy.data.collections.new(PREFIX + "_ROADSIDE_DECORATIVE_MODEL")
decor_owner = root(decor, PREFIX + "_ROADSIDE")
decor_shadow = bpy.data.collections.new(PREFIX + "_ROADSIDE_SHADOW_SEPARATE")
decor.children.link(decor_shadow)
ellipse(PREFIX + "_ROADSIDE_Contact_Shadow", .72, .41, .012, shadow_outer, decor_shadow)
make_crate(decor, PREFIX + "_ROADSIDE_Single", 0, .34, 1.19, .62, False, 0)
for part in list(decor.objects) + list(decor_shadow.objects):
    if part != decor_owner:
        part.parent = decor_owner
decor["variant"] = "roadside_only_not_an_active_obstacle"
decor["approx_width_m"] = 1.25

left_scene = new_scene(PREFIX + "_LEFT_ACTIVE", 3.0, (512, 512))
right_scene = new_scene(PREFIX + "_RIGHT_ACTIVE", 3.0, (512, 512))
decor_scene = new_scene(PREFIX + "_ROADSIDE_DECORATIVE", 2.55, (512, 512))
left_scene.collection.children.link(left)
right_scene.collection.children.link(right)
decor_scene.collection.children.link(decor)

# The opening review shows exactly one active stack plus one muted roadside
# crate. The right-lane active variant has its own scene, never adjacent here.
review = new_scene(PREFIX + "_REVIEW_ONE_ACTIVE", 6.2, (1400, 900))
review.render.film_transparent = False
review.world.node_tree.nodes.get("Background").inputs["Color"].default_value = (.76, .81, .73, 1)
review_coll = bpy.data.collections.new(PREFIX + "_REVIEW_INSTANCES_ONLY")
review.collection.children.link(review_coll)
for source, name, x in ((left, "LEFT_ACTIVE", -1.35), (decor, "ROADSIDE_DECORATIVE", 1.65)):
    instance = bpy.data.objects.new(PREFIX + "_Review_" + name, None)
    review_coll.objects.link(instance)
    instance.instance_type = "COLLECTION"
    instance.instance_collection = source
    instance.location = (x, 0, 0)
cube(PREFIX + "_Review_Ground_NOT_FOR_EXPORT", (0, 0, -.075),
     (6.0, 2.9, .13), review_ground, review_coll, .04)
review.camera.location = (2.1, 6.8, 3.2)
review.camera.rotation_euler = (Vector((0, 0, .78)) - review.camera.location).to_track_quat("-Z", "Y").to_euler()
review["source_original_scene_preserved"] = bpy.data.filepath
review["not_for_game_runtime"] = True

# Put the review in the connected UI and save before any heavyweight renders.
# Transparent exports are produced later from this saved blend in background
# Blender, so the user's GUI document survives a renderer/add-on disconnect.
bpy.context.window.scene = review
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.region_3d.view_perspective = "CAMERA"
            area.spaces.active.shading.type = "MATERIAL"
bpy.ops.wm.save_as_mainfile(filepath=OUTPUT, check_existing=False)
print("ACTIVE_BLENDER_SAVED", OUTPUT)
print("PNG_EXPORT_DIRECTORY", RENDERS)
