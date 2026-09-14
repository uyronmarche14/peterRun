"""Create Blender-only L01_LaundryLine scenes in the connected Blender window.

Save As a new source file; prior scenes and .blend files remain untouched.
Transparent PNG rendering is done separately in background Blender.
"""

import math
import os

import bpy
from mathutils import Vector


ROOT = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(ROOT, "L01_LaundryLine_Source_v01.blend")
P = "L01_LaundryLine"
if os.path.exists(OUTPUT):
    raise RuntimeError("L01_LaundryLine source already exists; refusing overwrite")
if any(scene.name.startswith(P) for scene in bpy.data.scenes):
    raise RuntimeError("L01_LaundryLine scenes already exist; refusing duplicate")


def material(name, color, roughness=.82, alpha=1):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, alpha)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Alpha"].default_value = alpha
    if alpha < 1 and hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "DITHERED"
    return mat


bamboo = material("L01LL_Warm_Bamboo_Posts", (.61, .47, .27))
bamboo_light = material("L01LL_Sunlit_Bamboo_Joints", (.77, .63, .38))
painted_wood = material("L01LL_Quiet_Painted_Wood", (.33, .49, .46))
rope = material("L01LL_Soft_Cream_Clothesline", (.83, .76, .55))
mango = material("L01LL_Mango_Active_Accent", (.72, .39, .15))
teal = material("L01LL_Cloth_Muted_Teal", (.22, .48, .46))
coral = material("L01LL_Cloth_Warm_Coral", (.71, .42, .34))
cream = material("L01LL_Cloth_Warm_Cream", (.87, .79, .62))
cloth_edge = material("L01LL_Cloth_Hem_Shade", (.40, .42, .36))
shadow_outer = material("L01LL_Shadow_Outer", (.12, .20, .19), .90, .13)
shadow_contact = material("L01LL_Shadow_Contact", (.10, .16, .16), .90, .28)
decor_post = material("L01LL_Roadside_Weathered_Post", (.47, .49, .40))
decor_rope = material("L01LL_Roadside_Quiet_Rope", (.57, .59, .48))
decor_teal = material("L01LL_Roadside_Quiet_Teal_Cloth", (.39, .52, .48))
decor_coral = material("L01LL_Roadside_Quiet_Coral_Cloth", (.59, .48, .42))
decor_cream = material("L01LL_Roadside_Quiet_Cream_Cloth", (.68, .65, .55))


def cube(name, pos, dims, mat, coll, bevel=.015):
    sx, sy, sz = (v / 2 for v in dims)
    verts = [(dx*sx, dy*sy, dz*sz)
             for dx in (-1, 1) for dy in (-1, 1) for dz in (-1, 1)]
    faces = [(0,4,6,2),(1,3,7,5),(0,1,5,4),
             (2,6,7,3),(0,2,3,1),(4,5,7,6)]
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    obj.location = pos
    if bevel:
        mod = obj.modifiers.new("Soft_Illustrated_Edge", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        obj.modifiers.new("Weighted_Normals", "WEIGHTED_NORMAL")
    return obj


def ellipse(name, center, radii, z, mat, coll):
    cx, cy = center
    rx, ry = radii
    n = 24
    verts = [(cx + rx*math.cos(math.tau*i/n),
              cy + ry*math.sin(math.tau*i/n), z) for i in range(n)]
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(verts, [], [tuple(range(n))])
    mesh.update()
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    return obj


def rope_curve(name, points, radius, mat, coll):
    curve = bpy.data.curves.new(name + "_Curve", type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 8
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    spline = curve.splines.new("POLY")
    spline.points.add(len(points)-1)
    for control, point in zip(spline.points, points):
        control.co = (*point, 1)
    curve.materials.append(mat)
    obj = bpy.data.objects.new(name, curve)
    coll.objects.link(obj)
    return obj


def cloth_panel(name, cx, top, width, length, material, coll, sway=1):
    # Four rows and four columns add soft drape and an uneven hem without
    # requiring a simulation or a fast game-time animation.
    vertices = []
    for row in range(4):
        depth_fraction = row / 3
        z = top - length * depth_fraction
        bend_x = sway * (.018 * depth_fraction + .018 * depth_fraction**2)
        for column in range(4):
            across = column / 3
            x = cx + (across-.5)*width + bend_x
            y = .095 + .025*math.sin(math.pi*across) * depth_fraction + .023*depth_fraction**2
            hem_variation = .018*math.sin(math.pi*across) if row == 3 else 0
            vertices.append((x,y,z+hem_variation))
    faces = []
    for row in range(3):
        for column in range(3):
            a = row*4+column
            faces.append((a,a+1,a+5,a+4))
    mesh = bpy.data.meshes.new(name + "_Cloth_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    mesh.materials.append(material)
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    return obj


def root(name, coll):
    obj = bpy.data.objects.new(name + "_CENTERED_GROUND_ORIGIN", None)
    coll.objects.link(obj)
    obj.location = (0,0,0)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = .19
    obj["ground_contact_z_m"] = 0.0
    return obj


frame = bpy.data.collections.new(P + "_ACTIVE_FRAME_MODEL")
cloth = bpy.data.collections.new(P + "_COLOURED_CLOTH_SEPARATE")
shadows = bpy.data.collections.new(P + "_GROUND_SHADOWS_SEPARATE")
frame_root = root(P + "_ACTIVE", frame)
cloth_root = root(P + "_CLOTH", cloth)
for side in (-1, 1):
    x = side * 1.19
    ellipse(P + f"_Soft_Post_Shadow_{side}", (x,.045), (.32,.20), .010,
            shadow_outer, shadows)
    ellipse(P + f"_Post_Contact_Shadow_{side}", (x,.045), (.18,.13), .013,
            shadow_contact, shadows)
    cube(P + f"_Bamboo_Upright_{side}", (x,0,1.28),
         (.13,.13,2.56), bamboo, frame)
    for i, z in enumerate((.20,1.25,2.31)):
        cube(P + f"_Bamboo_Joint_{side}_{i}", (x,0,z),
             (.16,.16,.045), bamboo_light, frame, .007)
    cube(P + f"_Stable_Post_Foot_{side}", (x,0,.10),
         (.20,.20,.17), painted_wood, frame)
    cube(P + f"_Mango_Active_Post_Cap_{side}", (x,0,2.54),
         (.19,.19,.06), mango, frame, .009)

line_points = []
for i in range(13):
    x = -1.19 + 2.38*i/12
    sag = .072 * (1-(abs(x)/1.19)**2)
    line_points.append((x,.02,2.55-sag))
rope_curve(P + "_Gentle_Sag_Clothesline", line_points, .024, rope, frame)
cube(P + "_Cream_Active_Gap_Top_Left", (-.99,.075,2.48),
     (.20,.045,.033), rope, frame, .005)
cube(P + "_Cream_Active_Gap_Top_Right", (.99,.075,2.48),
     (.20,.045,.033), rope, frame, .005)

# The lowest cloth hem is about 1.55 m above ground. Nothing blocks the
# route-facing central pass-under gap. Colours stay soft and adult-friendly.
panels = ((-.72,.58,.73,cream,-1),
          (0,.68,.92,coral,1),
          (.76,.55,.68,teal,-1))
for index, (cx,width,length,cloth_mat,sway) in enumerate(panels):
    top = 2.48 - (.015 if index == 1 else 0)
    cloth_panel(P + f"_Hanging_Cloth_{index}", cx, top,
                width, length, cloth_mat, cloth, sway)
    for pin_side in (-1,1):
        cube(P + f"_Wooden_Clothespin_{index}_{pin_side}",
             (cx + pin_side*width*.31, .11, top+.025),
             (.07,.08,.11), bamboo_light, cloth, .008)
    rope_curve(P + f"_Soft_Hem_{index}",
               [(cx-width*.46,.12,top-length+.016),
                (cx,.145,top-length+.025),
                (cx+width*.46,.12,top-length+.016)],
               .008, cloth_edge, cloth)

for obj in frame.objects:
    if obj != frame_root:
        obj.parent = frame_root
for obj in shadows.objects:
    obj.parent = frame_root
for obj in cloth.objects:
    if obj != cloth_root:
        obj.parent = cloth_root
frame["asset_name"] = P
frame["meaning"] = "friendly slide pass-under cue, never a barrier or hazard"
frame["approx_span_m"] = 2.48
frame["clear_opening_below_lowest_cloth_m"] = 1.54
cloth["overlay_motion"] = "slow side-to-side sway only; no lane crossing"

# A slow optional Blender source pose. Godot is not modified or animated here.
cloth_root.location.x = 0
cloth_root.keyframe_insert(data_path="location", frame=1, index=0)
cloth_root.location.x = -.025
cloth_root.keyframe_insert(data_path="location", frame=31, index=0)
cloth_root.location.x = 0
cloth_root.keyframe_insert(data_path="location", frame=61, index=0)
cloth_root.location.x = .025
cloth_root.keyframe_insert(data_path="location", frame=91, index=0)
cloth_root.location.x = 0
cloth_root.keyframe_insert(data_path="location", frame=121, index=0)

decor = bpy.data.collections.new(P + "_ROADSIDE_DECORATIVE_MODEL")
decor_shadow = bpy.data.collections.new(P + "_ROADSIDE_SHADOWS_SEPARATE")
decor_root = root(P + "_ROADSIDE", decor)
for side in (-1,1):
    x = side*.67
    ellipse(P + f"_Roadside_Post_Shadow_{side}", (x,.02), (.17,.10), .010,
            shadow_outer, decor_shadow)
    cube(P + f"_Roadside_Post_{side}", (x,0,.85),
         (.075,.075,1.70), decor_post, decor, .009)
rope_curve(P + "_Roadside_Quiet_Line",
           [(-.67,.01,1.69),(0,.01,1.63),(.67,.01,1.69)],
           .015, decor_rope, decor)
for i, (cx,width,length,mat) in enumerate(((-.37,.27,.43,decor_teal),
                                            (0,.30,.52,decor_coral),
                                            (.39,.26,.39,decor_cream))):
    cloth_panel(P + f"_Roadside_Cloth_{i}", cx, 1.62,
                width,length,mat,decor,1 if i%2 else -1)
for obj in decor.objects:
    if obj != decor_root:
        obj.parent = decor_root
for obj in decor_shadow.objects:
    obj.parent = decor_root
decor["placement"] = "roadside only; never across active road"
decor["low_contrast_decoration"] = True


def new_scene(name, collections, resolution, ortho_scale, aim_z):
    scene = bpy.data.scenes.new(name)
    for coll in collections:
        scene.collection.children.link(coll)
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = -.16
    scene.world = bpy.data.worlds.new(name + "_Morning_Fill")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.get("Background").inputs["Color"].default_value = (.68,.75,.69,1)
    scene.world.node_tree.nodes.get("Background").inputs["Strength"].default_value = .48
    support = bpy.data.collections.new(name + "_CAMERA_LIGHT_ONLY")
    scene.collection.children.link(support)
    camera_data = bpy.data.cameras.new(name + "_Orthographic_Camera")
    camera = bpy.data.objects.new(camera_data.name, camera_data)
    support.objects.link(camera)
    camera.location = (0,5.7,3.63)
    camera.rotation_euler = (Vector((0,0,aim_z))-camera.location).to_track_quat("-Z","Y").to_euler()
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = ortho_scale
    scene.camera = camera
    light_data = bpy.data.lights.new(name + "_Soft_Morning_Key", "AREA")
    light = bpy.data.objects.new(light_data.name, light_data)
    support.objects.link(light)
    light.location = (-2.8,3.4,6.4)
    light.rotation_euler = (Vector((0,0,1.2))-light.location).to_track_quat("-Z","Y").to_euler()
    light_data.energy = 330
    light_data.shape = "DISK"
    light_data.size = 5
    scene.unit_settings.system = "METRIC"
    return scene


active_scene = new_scene(P + "_ACTIVE_SLIDE", [frame,shadows,cloth], (256,192), 3.60, 1.30)
overlay_scene = new_scene(P + "_CLOTH_SWAY_OVERLAY", [cloth], (256,192), 3.60, 1.30)
decor_scene = new_scene(P + "_ROADSIDE_DECORATIVE", [decor,decor_shadow], (128,96), 2.10, .85)
for scene in (active_scene,overlay_scene):
    scene.frame_end = 121
    scene.frame_set(1)
active_scene["ground_origin"] = frame_root.name
active_scene["under_space_m"] = 1.54
active_scene["not_runtime_3d"] = True

bpy.context.window.scene = active_scene
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.region_3d.view_perspective = "CAMERA"
            area.spaces.active.shading.type = "MATERIAL"
bpy.ops.wm.save_as_mainfile(filepath=OUTPUT, check_existing=False)
print("SAVED_BLENDER_LAUNDRY", OUTPUT)
