"""Build the Blender-only L01_ShallowPuddle source in the connected session.

Creates new scenes/collections, keeps all existing Blender data, and Save As to
L01_ShallowPuddle_Source_v01.blend. Transparent PNGs are rendered separately.
"""

import math
import os

import bpy
from mathutils import Vector


ROOT = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(ROOT, "L01_ShallowPuddle_Source_v01.blend")
P = "L01_ShallowPuddle"
if os.path.exists(OUTPUT):
    raise RuntimeError("Puddle source already exists; refusing to overwrite")
if any(s.name.startswith(P) for s in bpy.data.scenes):
    raise RuntimeError("Puddle scenes already exist; refusing to duplicate")


def material(name, rgb, roughness=.58, alpha=1):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, alpha)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Alpha"].default_value = alpha
    if alpha < 1 and hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "DITHERED"
    return mat


wet_rim = material("L01SP_Dark_Wet_Road_Rim", (.23, .30, .30), .91)
water_deep = material("L01SP_Muted_Teal_Blue_Deep", (.20, .43, .47), .38)
water_light = material("L01SP_Muted_Teal_Blue_Shallow", (.35, .59, .60), .31)
reflection = material("L01SP_Soft_Cream_Sky_Reflection", (.80, .83, .70), .36, .72)
reflection_bright = material("L01SP_Cream_Reflection_Edge", (.89, .85, .66), .34)
mango = material("L01SP_Mango_Active_Edge", (.75, .45, .19), .66)
cream = material("L01SP_Cream_Active_Edge", (.86, .80, .59), .54)
leaf_green = material("L01SP_Quiet_Leaf_Green", (.25, .43, .33), .90)
leaf_ochre = material("L01SP_Quiet_Leaf_Ochre", (.55, .45, .25), .90)
decor_rim = material("L01SP_Roadside_Rim_Low_Contrast", (.36, .43, .42), .90)
decor_water = material("L01SP_Roadside_Water_Low_Contrast", (.40, .52, .51), .46)
ripple_cream = material("L01SP_Ripple_Cream_Overlay", (.92, .88, .68), .38, .73)
ripple_teal = material("L01SP_Ripple_Teal_Overlay", (.52, .70, .68), .38, .62)


def collection(name):
    return bpy.data.collections.new(name)


def poly(name, vertices, faces, mat, coll):
    data = bpy.data.meshes.new(name + "_Mesh")
    data.from_pydata(vertices, [], faces)
    data.update()
    data.materials.append(mat)
    obj = bpy.data.objects.new(name, data)
    coll.objects.link(obj)
    return obj


def irregular_outline(rx, ry, n=40, phase=.17):
    result = []
    for i in range(n):
        a = math.tau * i / n
        radius = 1 + .050 * math.sin(3 * a + phase) + .038 * math.sin(7 * a - .7) + .022 * math.sin(11 * a + 1.2)
        result.append((rx * radius * math.cos(a), ry * radius * math.sin(a)))
    return result


def fill(name, points, scale, offset, z, mat, coll):
    ox, oy = offset
    verts = [(ox + x * scale, oy + y * scale, z) for x, y in points]
    return poly(name, verts, [tuple(range(len(verts)))], mat, coll)


def band(name, points, width, z, mat, coll):
    verts = []
    for i, (x, y) in enumerate(points):
        previous = Vector(points[max(0, i - 1)])
        following = Vector(points[min(len(points) - 1, i + 1)])
        tangent = (following - previous).normalized()
        side = Vector((-tangent.y, tangent.x)) * (width / 2)
        verts.extend([(x - side.x, y - side.y, z),
                      (x + side.x, y + side.y, z)])
    faces = [(2*i, 2*i+1, 2*i+3, 2*i+2) for i in range(len(points)-1)]
    return poly(name, verts, faces, mat, coll)


def arc_points(rx, ry, first, last, n=18, offset=(0, 0)):
    ox, oy = offset
    return [(ox + rx * math.cos(first + (last-first)*i/(n-1)),
             oy + ry * math.sin(first + (last-first)*i/(n-1))) for i in range(n)]


def leaf(name, x, y, angle, size, mat, coll):
    direction = Vector((math.cos(angle), math.sin(angle)))
    cross = Vector((-direction.y, direction.x))
    center = Vector((x, y))
    points = [center - direction*size*.52,
              center + cross*size*.24,
              center + direction*size*.53,
              center - cross*size*.19]
    verts = [(p.x, p.y, .030) for p in points]
    return poly(name, verts, [(0,1,2,3)], mat, coll)


def root(coll, name):
    obj = bpy.data.objects.new(name + "_CENTERED_GROUND_ORIGIN", None)
    coll.objects.link(obj)
    obj.location = (0,0,0)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = .15
    obj["contact_z_m"] = 0.0
    return obj


active_coll = collection(P + "_ACTIVE_BASE_MODEL")
active_root = root(active_coll, P + "_ACTIVE")
outline = irregular_outline(1.17, .40)
fill(P + "_Dark_Wet_Road_Edge", outline, 1.0, (0,0), .013, wet_rim, active_coll)
fill(P + "_Deep_Teal_Blue_Shallow_Surface", outline, .91, (0,.005), .016, water_deep, active_coll)
fill(P + "_Second_Muted_Teal_Blue_Tone", outline, .66, (.04,.012), .019, water_light, active_coll)

# A broad irregular cream patch reads as sky reflection, not a hole or splash.
reflection_points = [(-.70,.02),(-.41,.17),(-.09,.15),(.16,.21),(.47,.12),
                     (.61,.02),(.42,-.02),(.09,.01),(-.24,-.08),(-.57,-.04)]
poly(P + "_Soft_Cream_Sky_Reflection", [(x,y,.023) for x,y in reflection_points],
     [tuple(range(len(reflection_points)))], reflection, active_coll)
fill(P + "_Small_Cloud_Reflection", irregular_outline(.29,.065,24,.64),
     1.0, (.47,-.12), .024, reflection_bright, active_coll)

# Two short outer-edge accents are intentional active-prompt cues; the far
# side stays unmarked so the low water silhouette remains calm.
band(P + "_Mango_Active_Edge_Accent", arc_points(1.105,.378,3.61,5.24),
     .025, .026, mango, active_coll)
band(P + "_Cream_Active_Edge_Accent", arc_points(1.105,.378,.18,1.40),
     .024, .027, cream, active_coll)
leaf(P + "_Small_Leaf_01", -.75, .26, .48, .18, leaf_green, active_coll)
leaf(P + "_Small_Leaf_02", .77, -.25, -2.12, .13, leaf_ochre, active_coll)
for obj in active_coll.objects:
    if obj != active_root:
        obj.parent = active_root
active_coll["asset_name"] = P
active_coll["meaning"] = "low friendly jump cue, not hazard or hole"
active_coll["approx_width_m"] = 2.34
active_coll["max_surface_height_m"] = .027

ripple_coll = collection(P + "_RIPPLE_OVERLAY_SEPARATE")
ripple_root = root(ripple_coll, P + "_RIPPLE")
band(P + "_Ripple_Cream_Outer", arc_points(.45,.145,.22,2.72,24,(.15,-.05)),
     .018,.036,ripple_cream,ripple_coll)
band(P + "_Ripple_Teal_Inner", arc_points(.29,.090,3.45,5.99,20,(.15,-.05)),
     .015,.037,ripple_teal,ripple_coll)
for obj in ripple_coll.objects:
    if obj != ripple_root:
        obj.parent = ripple_root
ripple_coll["overlay_only"] = True

decor_coll = collection(P + "_ROADSIDE_DECORATIVE_MODEL")
decor_root = root(decor_coll, P + "_ROADSIDE")
small = irregular_outline(.35,.14,28,.83)
fill(P + "_Roadside_Low_Contrast_Rim", small, 1.0, (0,0), .011, decor_rim, decor_coll)
fill(P + "_Roadside_Quiet_Water", small, .83, (0,.003), .013, decor_water, decor_coll)
fill(P + "_Roadside_Tiny_Reflection", irregular_outline(.095,.024,20,.21),
     1.0, (-.08,.015), .015, decor_rim, decor_coll)
for obj in decor_coll.objects:
    if obj != decor_root:
        obj.parent = decor_root
decor_coll["roadside_only"] = True
decor_coll["approx_width_m"] = .70


def new_scene(name, model_coll, resolution, ortho_scale):
    scene = bpy.data.scenes.new(name)
    scene.collection.children.link(model_coll)
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x, scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "Medium High Contrast"
    scene.view_settings.exposure = -.22
    scene.world = bpy.data.worlds.new(name + "_Warm_Overcast_Fill")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.get("Background").inputs["Color"].default_value = (.63,.72,.68,1)
    scene.world.node_tree.nodes.get("Background").inputs["Strength"].default_value = .52
    support = bpy.data.collections.new(name + "_CAMERA_LIGHT_ONLY")
    scene.collection.children.link(support)
    cam_data = bpy.data.cameras.new(name + "_Orthographic_Camera")
    camera = bpy.data.objects.new(cam_data.name, cam_data)
    support.objects.link(camera)
    camera.location = (0, 1.75, 5.0)
    camera.rotation_euler = (Vector((0,0,.02))-camera.location).to_track_quat("-Z","Y").to_euler()
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = ortho_scale
    scene.camera = camera
    light_data = bpy.data.lights.new(name + "_Soft_Morning_Key", "AREA")
    light = bpy.data.objects.new(light_data.name, light_data)
    support.objects.link(light)
    light.location = (-1.6,1.4,4.0)
    light.rotation_euler = (Vector((0,0,0))-light.location).to_track_quat("-Z","Y").to_euler()
    light_data.energy = 250
    light_data.shape = "DISK"
    light_data.size = 4.5
    scene.unit_settings.system = "METRIC"
    return scene


active_scene = new_scene(P + "_ACTIVE_JUMP", active_coll, (256,128), 2.78)
ripple_scene = new_scene(P + "_RIPPLE_OVERLAY", ripple_coll, (256,128), 2.78)
decor_scene = new_scene(P + "_ROADSIDE_DECORATIVE", decor_coll, (128,64), 1.40)
active_scene["centered_origin"] = active_root.name
active_scene["player_shadow_space"] = "transparent canvas around low water footprint"
active_scene["not_game_runtime"] = True

bpy.context.window.scene = active_scene
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.region_3d.view_perspective = "CAMERA"
            area.spaces.active.shading.type = "MATERIAL"
bpy.ops.wm.save_as_mainfile(filepath=OUTPUT, check_existing=False)
print("SAVED_BLENDER_PUDDLE", OUTPUT)
