"""Build the original L01 Barangay Hall cinematic 2.5D Blender source.

This script starts from an empty Blender file. It creates one master scene and
ten camera-aligned export scenes at 960x540. Blender is the authoring source;
the exports are intended for Godot's 480x270 2D Compatibility canvas.
"""

import math
import os

import bpy
from mathutils import Vector


ROOT = os.path.dirname(os.path.abspath(__file__))
OUT_BLEND = os.path.join(ROOT, "L01_Barangay_Hall_Cinematic_Source_v01.blend")
W, H = 960, 540
LAYERS = (
    "sky_sun",
    "distant_hills_clouds",
    "barangay_hall_landmark",
    "distant_rooftops",
    "midground_homes_store",
    "near_roadside_props",
    "foreground_edges",
    "road_surface",
    "lane_overlay",
    "horizon_haze_glow",
)

bpy.ops.wm.read_factory_settings(use_empty=True)
factory_scene = bpy.context.scene
master = bpy.data.scenes.new("L01_Barangay_Hall_Cinematic_Master_v01")
bpy.context.window.scene = master
bpy.data.scenes.remove(factory_scene)
master.render.engine = "BLENDER_EEVEE"
master.render.resolution_x = W
master.render.resolution_y = H
master.render.resolution_percentage = 100
master.render.image_settings.file_format = "PNG"
master.render.image_settings.color_mode = "RGBA"
master.render.image_settings.compression = 18
master.render.film_transparent = False
master.view_settings.view_transform = "Standard"
master.view_settings.look = "Medium High Contrast"
master.view_settings.exposure = 0.0
master.view_settings.gamma = 1.0
master.world = bpy.data.worlds.new("L01V01_Warm_Morning_World")
master.world.use_nodes = True
world_nodes = master.world.node_tree.nodes
world_links = master.world.node_tree.links
world_nodes.clear()
world_tex = world_nodes.new("ShaderNodeTexCoord")
world_sep = world_nodes.new("ShaderNodeSeparateXYZ")
world_map = world_nodes.new("ShaderNodeMapRange")
world_map.inputs["From Min"].default_value = -0.20
world_map.inputs["From Max"].default_value = 0.40
world_ramp = world_nodes.new("ShaderNodeValToRGB")
world_ramp.color_ramp.elements[0].color = (.88,.80,.61,1)
world_ramp.color_ramp.elements[1].color = (.42,.68,.72,1)
world_mid = world_ramp.color_ramp.elements.new(.46)
world_mid.color = (.70,.81,.71,1)
world_bg = world_nodes.new("ShaderNodeBackground")
world_bg.inputs["Strength"].default_value = .72
world_out = world_nodes.new("ShaderNodeOutputWorld")
world_links.new(world_tex.outputs["Normal"], world_sep.inputs[0])
world_links.new(world_sep.outputs["Z"], world_map.inputs["Value"])
world_links.new(world_map.outputs["Result"], world_ramp.inputs[0])
world_links.new(world_ramp.outputs[0], world_bg.inputs["Color"])
world_links.new(world_bg.outputs[0], world_out.inputs[0])

root = bpy.data.collections.new("L01_BARANGAY_HALL_CINEMATIC_V01")
master.collection.children.link(root)
collections = {}
for layer in LAYERS:
    coll = bpy.data.collections.new("L01V01_" + layer.upper())
    root.children.link(coll)
    collections[layer] = coll


def mat(name, color, rough=.88, alpha=1.0, emission=None):
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*color, alpha)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Alpha"].default_value = alpha
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 0.7
    if alpha < 1.0:
        material.surface_render_method = "BLENDED"
    return material


cream = mat("L01V01_Cream_Plaster", (0.82, 0.76, 0.60))
cream_light = mat("L01V01_Capiz_Glow", (0.98, 0.88, 0.61), emission=(0.96, 0.74, 0.34))
mango = mat("L01V01_Mango_Accent", (0.88, 0.57, 0.20))
mango_light = mat("L01V01_Sun_Inner_Cream", (1.0, 0.85, 0.48), emission=(1.0, 0.65, 0.20))
sun_mango = mat("L01V01_Warm_Mango_Sun", (0.96, 0.60, 0.19), emission=(1.0, 0.52, 0.12))
teal = mat("L01V01_Deep_Teal", (0.12, 0.39, 0.39))
teal_soft = mat("L01V01_Soft_Teal", (0.28, 0.57, 0.54))
teal_haze = mat("L01V01_Hill_Haze", (0.37, 0.58, 0.53))
coral = mat("L01V01_Coral_Paint", (0.72, 0.36, 0.29))
clay = mat("L01V01_Clay_Roof", (0.50, 0.25, 0.18))
roof_teal = mat("L01V01_Teal_Roof", (0.17, 0.38, 0.40))
wood = mat("L01V01_Warm_Wood", (0.42, 0.27, 0.15))
bamboo = mat("L01V01_Bamboo", (0.61, 0.47, 0.25))
leaf = mat("L01V01_Leaf_Green", (0.18, 0.46, 0.32))
leaf_light = mat("L01V01_Banana_Leaf", (0.34, 0.60, 0.36))
road_mat = mat("L01V01_Warm_Grey_Road", (0.40, 0.43, 0.40))
road_patch = mat("L01V01_Road_Variation", (0.48, 0.46, 0.40), alpha=.42)
earth = mat("L01V01_Warm_Roadside_Earth", (0.58, 0.46, 0.32))
sidewalk = mat("L01V01_Quiet_Concrete_Walk", (0.60, 0.63, 0.55))
lane_teal = mat("L01V01_Teal_Lane", (0.21, 0.61, 0.58))
shadow = mat("L01V01_Contact_Shadow", (0.05, 0.10, 0.10), alpha=.28)
cloud = mat("L01V01_Soft_Cloud", (0.96, 0.92, 0.80), alpha=.86, emission=(0.78, 0.79, 0.72))
haze = mat("L01V01_Horizon_Haze", (1.0, 0.73, 0.35), alpha=.16, emission=(1.0, 0.62, 0.23))


def link_only(obj, coll):
    for previous in tuple(obj.users_collection):
        previous.objects.unlink(obj)
    coll.objects.link(obj)
    return obj


def cube(name, loc, dims, material, coll, bevel=.04):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = link_only(bpy.context.object, coll)
    obj.name = name
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    if bevel:
        mod = obj.modifiers.new("Soft_Illustrated_Edge", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    return obj


def cylinder(name, loc, radius, depth, material, coll, vertices=12, rotation=(0,0,0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth,
                                       location=loc, rotation=rotation)
    obj = link_only(bpy.context.object, coll)
    obj.name = name
    obj.data.materials.append(material)
    bevel = obj.modifiers.new("Soft_Illustrated_Edge", "BEVEL")
    bevel.width = min(radius*.12, .055)
    bevel.segments = 2
    return obj


def ico(name, loc, scale, material, coll, subdivisions=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1, location=loc)
    obj = link_only(bpy.context.object, coll)
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    return obj


def roof(name, loc, width, depth, height, material, coll):
    x, y, z = loc
    verts = [
        (-width/2,-depth/2,0),(width/2,-depth/2,0),(0,-depth/2,height),
        (-width/2,depth/2,0),(width/2,depth/2,0),(0,depth/2,height),
    ]
    faces = [(0,1,2),(3,5,4),(0,2,5,3),(1,4,5,2),(0,3,4,1)]
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.materials.append(material)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    obj.location = (x,y,z)
    bevel = obj.modifiers.new("Roof_Edge", "BEVEL")
    bevel.width = .06
    bevel.segments = 2
    return obj


def flat_shadow(name, loc, sx, sy, coll):
    bpy.ops.mesh.primitive_circle_add(vertices=32, radius=1, fill_type="NGON", location=loc)
    obj = link_only(bpy.context.object, coll)
    obj.name = name
    obj.scale = (sx, sy, 1)
    obj.data.materials.append(shadow)
    return obj


def add_text(name, body, loc, size, material, coll):
    curve = bpy.data.curves.new(name + "_Curve", "FONT")
    curve.body = body
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.size = size
    curve.extrude = .012
    curve.bevel_depth = .006
    curve.materials.append(material)
    obj = bpy.data.objects.new(name, curve)
    coll.objects.link(obj)
    obj.location = loc
    obj.rotation_euler.x = math.radians(90)
    return obj


# Fixed elevated camera behind Peter, aimed along the route.
camera_data = bpy.data.cameras.new("L01V01_Route_Camera_Data")
camera = bpy.data.objects.new("L01V01_Route_Camera", camera_data)
master.collection.objects.link(camera)
camera.location = (0, -22.5, 8.7)
target = Vector((0, 15.0, 2.5))
camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.lens = 48
camera_data.sensor_width = 36
camera_data.clip_end = 300
master.camera = camera

# Warm key and cool fill keep the façade readable without a harsh spotlight.
key_data = bpy.data.lights.new("L01V01_Warm_Sun_Key_Data", "AREA")
key_data.energy = 1700
key_data.color = (1.0, .68, .38)
key_data.shape = "DISK"
key_data.size = 8
key = bpy.data.objects.new("L01V01_Warm_Sun_Key", key_data)
master.collection.objects.link(key)
key.location = (-7,-10,18)
key.rotation_euler = (Vector((0,11,1.5))-key.location).to_track_quat("-Z","Y").to_euler()
fill_data = bpy.data.lights.new("L01V01_Cool_Teal_Fill_Data", "AREA")
fill_data.energy = 540
fill_data.color = (.34,.64,.68)
fill_data.size = 10
fill = bpy.data.objects.new("L01V01_Cool_Teal_Fill", fill_data)
master.collection.objects.link(fill)
fill.location = (10,-2,11)
fill.rotation_euler = (Vector((0,12,2.0))-fill.location).to_track_quat("-Z","Y").to_euler()

# Camera-local illustration planes below must use the evaluated rotation,
# not Blender's pre-update transform cache.
bpy.context.view_layer.update()


def camera_local(px, py, depth):
    frame = camera.data.view_frame(scene=master)
    base = abs(frame[0].z)
    factor = depth/base
    left = min(v.x for v in frame)*factor
    right = max(v.x for v in frame)*factor
    bottom = min(v.y for v in frame)*factor
    top = max(v.y for v in frame)*factor
    return (left+(right-left)*px/W, top-(top-bottom)*py/H, -depth)


def screen_mesh(name, points, depth, material, coll):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata([camera_local(x,y,depth) for x,y in points], [],
                     [tuple(reversed(range(len(points))))])
    mesh.materials.append(material)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    coll.objects.link(obj)
    obj.matrix_world = camera.matrix_world.copy()
    return obj


def screen_ellipse(name, cx, cy, rx, ry, depth, material, coll, count=48):
    points = [(cx + math.cos(i*math.tau/count)*rx,
               cy + math.sin(i*math.tau/count)*ry) for i in range(count)]
    return screen_mesh(name, points, depth, material, coll)


# Sky gradient authored as a Blender shader on a camera-aligned mesh.
sky_coll = collections["sky_sun"]
sky = screen_mesh("L01V01_Morning_Sky_Gradient", [(0,0),(W,0),(W,H),(0,H)], 90,
                  cream, sky_coll)
uv = sky.data.uv_layers.new(name="SkyGradientUV")
for loop in sky.data.loops:
    idx = loop.vertex_index
    uv.data[loop.index].uv = ((0 if idx in (0,3) else 1), (0 if idx in (0,1) else 1))
sky_mat = bpy.data.materials.new("L01V01_Pale_Mint_To_Cream_Sky")
sky_mat.use_nodes = True
nodes = sky_mat.node_tree.nodes
nodes.clear()
tex = nodes.new("ShaderNodeTexCoord")
sep = nodes.new("ShaderNodeSeparateXYZ")
ramp = nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].color = (.90,.82,.62,1)
ramp.color_ramp.elements[1].color = (.44,.70,.72,1)
middle = ramp.color_ramp.elements.new(.43)
middle.color = (.72,.82,.70,1)
emit = nodes.new("ShaderNodeEmission")
out = nodes.new("ShaderNodeOutputMaterial")
links = sky_mat.node_tree.links
links.new(tex.outputs["UV"], sep.inputs[0])
links.new(sep.outputs["Y"], ramp.inputs[0])
links.new(ramp.outputs[0], emit.inputs["Color"])
links.new(emit.outputs[0], out.inputs[0])
sky.data.materials.clear()
sky.data.materials.append(sky_mat)
sky.hide_render = True
screen_ellipse("L01V01_Large_Mango_Sun", 585, 176, 82, 82, 66.0, sun_mango, sky_coll)
screen_ellipse("L01V01_Pale_Sun_Core", 585, 176, 57, 57, 65.8, mango_light, sky_coll)

# Distant hills stay below the civic tower; clouds softly frame, never cover it.
distant = collections["distant_hills_clouds"]
for i,(cx,cy,rx,ry) in enumerate(((205,119,128,23),(760,108,142,28),(78,151,105,20))):
    screen_ellipse(f"L01V01_Soft_Cloud_{i}", cx,cy,rx,ry,65.5-i*.05,cloud,distant)
for i,points in enumerate((
    [(0,232),(0,194),(115,148),(245,216),(340,184),(440,234)],
    [(350,236),(455,196),(532,218),(662,168),(790,229),(960,185),(960,246)],
)):
    screen_mesh(f"L01V01_Low_Distant_Hill_{i}", points, 65-i*.1,
                teal_haze if i else teal_soft, distant)

# Landmark: two-storey hall, veranda, central tower/lantern and grounded plaza.
hall = collections["barangay_hall_landmark"]
flat_shadow("L01V01_Hall_Plaza_Shadow", (0,28.4,.025), 6.8,3.5,hall)
cube("L01V01_Hall_Plaza_Base", (0,30.0,.16),(12.6,6.2,.30),cream,hall,.09)
cube("L01V01_Hall_Main_Block", (0,31.8,3.0),(9.8,4.0,5.8),cream,hall,.10)
cube("L01V01_Hall_Cool_Shadow_Wing", (4.15,31.72,3.0),(1.5,4.05,5.65),teal_soft,hall,.08)
roof("L01V01_Hall_Main_Pitched_Roof",(0,31.8,5.85),10.7,4.8,1.65,clay,hall)
cube("L01V01_Hall_Veranda_Roof",(0,29.35,3.55),(10.5,1.15,.22),roof_teal,hall,.06)
for x in (-4.25,-2.15,2.15,4.25):
    cylinder(f"L01V01_Veranda_Column_{x}",(x,28.94,1.72),.12,3.18,cream,hall,12)
for floor_z in (2.08,4.25):
    for x in (-3.55,-1.75,1.75,3.55):
        cube(f"L01V01_Capiz_Window_{floor_z}_{x}",(x,29.76,floor_z),(.92,.08,.88),cream_light,hall,.025)
        cube(f"L01V01_Window_Teal_Sill_{floor_z}_{x}",(x,29.68,floor_z-.51),(1.03,.12,.08),teal,hall,.015)
cube("L01V01_Hall_Central_Door",(0,29.72,1.45),(1.35,.12,2.45),wood,hall,.035)
cube("L01V01_Hall_Sign_Frame",(0,29.59,5.03),(4.45,.18,.72),mango,hall,.055)
cube("L01V01_Hall_Sign_Panel",(0,29.47,5.03),(4.13,.08,.47),cream,hall,.025)
add_text("L01V01_Hall_Sign_Text","BARANGAY HALL",(0,29.41,5.01),.37,teal,hall)
cube("L01V01_Central_Tower",(0,32.0,7.05),(2.65,2.7,3.3),cream,hall,.08)
roof("L01V01_Tower_Lantern_Roof",(0,32.0,8.72),3.25,3.25,1.15,roof_teal,hall)
cube("L01V01_Tower_Capiz_Lantern",(0,30.61,7.2),(1.16,.10,1.15),cream_light,hall,.05)
cylinder("L01V01_Civic_Sun_Emblem",(0,30.50,6.35),.47,.10,mango,hall,32,
         rotation=(math.radians(90),0,0))
cube("L01V01_Notice_Board",(-5.4,29.0,1.15),(1.85,.18,1.55),wood,hall,.045)
cube("L01V01_Notice_Board_Insert",(-5.4,28.88,1.18),(1.55,.06,1.22),cream,hall,.02)
for x in (-5.95,-4.85):
    cylinder(f"L01V01_Notice_Post_{x}",(x,29.0,.62),.06,1.05,bamboo,hall,10)

# Three distant roof groups lead the eye inward without repeating a village grid.
rooftops = collections["distant_rooftops"]
for side in (-1,1):
    for idx,(y,w,color) in enumerate(((21.5,3.0,clay),(25.0,2.35,roof_teal))):
        x = side*(7.3+idx*.55)
        cube(f"L01V01_Distant_Home_{side}_{idx}",(x,y,1.15),(w,2.6,2.1),cream if idx else teal_soft,rooftops,.05)
        roof(f"L01V01_Distant_Roof_{side}_{idx}",(x,y,2.2),w+.5,3.0,.72,color,rooftops)
        cube(f"L01V01_Distant_Window_{side}_{idx}",(x-side*.62,y-1.32,1.28),(.55,.06,.56),cream_light,rooftops,.02)

# Only three varied places per side: home, sari-sari frontage, and veranda home.
mid = collections["midground_homes_store"]
house_specs = ((4.7,3.75,coral,clay),(11.2,3.45,teal_soft,roof_teal),(17.2,3.20,cream,clay))
for side in (-1,1):
    for idx,(y,width,wall,roof_mat) in enumerate(house_specs):
        x = side*((8.15 if idx == 0 else 7.55) + idx*.16)
        flat_shadow(f"L01V01_Home_Shadow_{side}_{idx}",(x,y-.2,.018),width*.63,1.75,mid)
        cube(f"L01V01_Home_{side}_{idx}",(x,y,1.65),(width,3.15,3.1),wall,mid,.07)
        roof(f"L01V01_Home_Roof_{side}_{idx}",(x,y,3.2),width+.55,3.65,.95,roof_mat,mid)
        cube(f"L01V01_Home_Door_{side}_{idx}",(x-side*.72,y-1.61,1.28),(.78,.09,1.95),wood,mid,.03)
        cube(f"L01V01_Home_Capiz_{side}_{idx}",(x+side*.70,y-1.64,1.78),(.82,.08,.82),cream_light,mid,.025)
        cube(f"L01V01_Veranda_Slab_{side}_{idx}",(x,y-1.82,.50),(width+.35,.75,.16),cream,mid,.04)
        for px in (-width*.38,width*.38):
            cylinder(f"L01V01_Veranda_Post_{side}_{idx}_{px}",(x+px,y-1.82,1.58),.07,2.08,bamboo,mid,10)
        if idx == 1 and side == -1:
            cube("L01V01_SariSari_Counter",(x,y-1.91,1.10),(2.25,.38,1.35),wood,mid,.04)
            cube("L01V01_SariSari_Awning",(x,y-2.03,2.43),(2.65,.74,.17),mango,mid,.04)
            for shelf in (-.62,0,.62):
                cube(f"L01V01_SariSari_Display_{shelf}",(x+shelf,y-2.14,1.35),(.42,.08,.42),cream_light,mid,.015)

# Roadside props remain outside x +/-6.1, safely clear of all three lanes.
near = collections["near_roadside_props"]
# Warm verges and quiet concrete walks ground every roadside object while the
# centre three-lane road remains an independent transparent export.
for side in (-1,1):
    x = side*8.9
    cube(f"L01V01_Warm_Earth_Verge_{side}",(x,10.5,-.06),(6.0,47,.08),earth,near,0)
    cube(f"L01V01_Concrete_Walk_{side}",(side*6.32,10.5,-.015),(.86,47,.07),sidewalk,near,.015)
for side in (-1,1):
    # Bamboo fence rhythm.
    for idx,y in enumerate((-5.0,-1.6,6.1,13.2)):
        x = side*6.65
        cylinder(f"L01V01_Fence_Post_{side}_{idx}",(x,y,.72),.075,1.38,bamboo,near,10)
        if idx < 3:
            cube(f"L01V01_Fence_Rail_{side}_{idx}",(x,y+1.35,.88),(.07,2.55,.08),bamboo,near,.018)
    # Potted plants and shrubs.
    for idx,(y,offset) in enumerate(((-7.0,.0),(1.2,.35),(8.6,-.2),(15.1,.15))):
        x = side*(7.0+offset)
        cylinder(f"L01V01_Pot_{side}_{idx}",(x,y,.35),.30,.55,coral,near,10)
        ico(f"L01V01_Potted_Plant_{side}_{idx}",(x,y,.84),(.46,.38,.54),leaf_light if idx%2 else leaf,near)
    # Waiting shed on right, community bench on left.
    if side > 0:
        cube("L01V01_Waiting_Shed_Bench",(7.3,7.0,.58),(2.25,.46,.17),wood,near,.04)
        for x in (6.45,8.15):
            cylinder(f"L01V01_Waiting_Shed_Post_{x}",(x,7.3,1.55),.09,2.8,bamboo,near,10)
        cube("L01V01_Waiting_Shed_Roof",(7.3,7.25,3.02),(2.9,2.0,.18),roof_teal,near,.05)
    else:
        cube("L01V01_Community_Bench",(-7.2,5.3,.60),(2.25,.44,.16),wood,near,.04)
        for x in (-7.95,-6.45):
            cube(f"L01V01_Community_Bench_Leg_{x}",(x,5.3,.34),(.12,.20,.48),wood,near,.025)
    # Varied broadleaf / banana / palm rather than identical trees.
    if side < 0:
        cylinder("L01V01_Broadleaf_Trunk",(-8.1,-2.2,2.35),.26,4.6,wood,near,12)
        ico("L01V01_Broadleaf_Crown_A",(-8.1,-2.2,5.0),(1.45,1.10,1.18),leaf,near)
        ico("L01V01_Broadleaf_Crown_B",(-7.20,-2.0,4.8),(.90,.78,.82),leaf_light,near)
    else:
        cylinder("L01V01_Palm_Trunk",(8.15,1.8,2.65),.20,5.1,bamboo,near,12)
        for idx,angle in enumerate((-58,-28,4,36,68)):
            leaf_obj = ico(f"L01V01_Palm_Frond_{idx}",(8.15+math.sin(math.radians(angle))*1.0,1.8,5.25+math.cos(math.radians(angle))*.25),(.25,1.25,.18),leaf_light,near,1)
            leaf_obj.rotation_euler.z = math.radians(angle)
    # Banana cluster farther down each verge.
    bx,by = side*7.2,13.6
    cylinder(f"L01V01_Banana_Stem_{side}",(bx,by,1.35),.13,2.5,bamboo,near,10)
    for idx,angle in enumerate((-55,-20,20,58)):
        obj = ico(f"L01V01_Banana_Leaf_{side}_{idx}",(bx+math.sin(math.radians(angle))*.65,by,2.75+math.cos(math.radians(angle))*.18),(.24,.90,.13),leaf_light,near,1)
        obj.rotation_euler.z = math.radians(angle)

# Foreground framing is restricted to extreme corners.
foreground = collections["foreground_edges"]
for side in (-1,1):
    fx = side*8.6
    cylinder(f"L01V01_Foreground_Fence_Edge_{side}",(fx,-9.5,1.45),.13,2.8,bamboo,foreground,10)
    for idx,(dy,dz,rot) in enumerate(((-.2,2.4,-30),(.0,1.65,15),(.2,.95,48))):
        obj = ico(f"L01V01_Foreground_Leaf_{side}_{idx}",(side*(7.95+idx*.25),-10.2+dy,dz),(.36,.95,.18),leaf if idx%2 else leaf_light,foreground,1)
        obj.rotation_euler.y = math.radians(rot*side)

# Broad road, exactly two internal separators = exactly three lanes.
road = collections["road_surface"]
road_mesh = bpy.data.meshes.new("L01V01_Road_Surface_Mesh")
road_mesh.from_pydata([(-5.8,-13,0),(5.8,-13,0),(5.8,34,0),(-5.8,34,0)],[],[(0,1,2,3)])
road_mesh.materials.append(road_mat)
road_obj = bpy.data.objects.new("L01V01_Three_Lane_Road",road_mesh)
road.objects.link(road_obj)
for idx,y in enumerate((-7,-1,6,14,22)):
    cube(f"L01V01_Road_Texture_Mark_{idx}",((-1 if idx%2 else 1)*1.15,y,.018),(1.25,.42,.018),road_patch,road,.02)
for idx,y in enumerate((-3.5,8.5,18.5)):
    cube(f"L01V01_Road_Depth_Seam_{idx}",(0,y,.014),(11.1,.055,.015),road_patch,road,.008)

lanes = collections["lane_overlay"]
for x,label in ((-1.93,"Left_Center"),(1.93,"Right_Center")):
    cube(f"L01V01_Teal_Lane_Separator_{label}",(x,10.5,.045),(.075,45,.025),lane_teal,lanes,.012)
for x,label in ((-5.72,"Left"),(5.72,"Right")):
    cube(f"L01V01_Mango_Curb_{label}",(x,10.5,.075),(.18,45,.14),mango,lanes,.025)
    for idx,y in enumerate((-5,3,12,21)):
        cube(f"L01V01_Side_Marker_{label}_{idx}",(x+(.42 if x<0 else -.42),y,.12),(.22,.55,.18),cream,lanes,.025)

# Soft destination glow sits behind the hall when composited.
glow = collections["horizon_haze_glow"]
screen_ellipse("L01V01_Landmark_Warm_Glow",520,215,180,82,64,haze,glow)
screen_ellipse("L01V01_Low_Horizon_Haze",480,252,610,48,63.9,haze,glow)

# Layer scenes share one camera and lighting, but only one export collection.
for layer in LAYERS:
    scene = bpy.data.scenes.new("L01_EXPORT_" + layer.upper())
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = W
    scene.render.resolution_y = H
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.compression = 18
    scene.render.film_transparent = layer != "sky_sun"
    scene.view_settings.view_transform = master.view_settings.view_transform
    scene.view_settings.look = master.view_settings.look
    scene.world = master.world
    scene.collection.children.link(collections[layer])
    support = bpy.data.collections.new("L01V01_" + layer.upper() + "_CAMERA_LIGHTS")
    scene.collection.children.link(support)
    support.objects.link(camera)
    support.objects.link(key)
    support.objects.link(fill)
    scene.camera = camera
    scene["export_layer"] = layer
    scene["render_size"] = "960x540; exact 2x of Godot 480x270"

master["project"] = "PETER RUN"
master["route"] = "L01 Barangay Morning"
master["composition"] = "cinematic forward three-lane route to a single Barangay Hall"
master["lane_count"] = 3
master["player_safe_zone"] = "lower central road unobstructed"
master["reference_scope"] = "top-level peter_run images only"
master["godot_behavior_notes"] = "sky almost static; clouds slow; hills slowest; landmark stable; homes gentle; foreground slightly faster; Pause freezes all"

bpy.context.window.scene = master
for window in bpy.context.window_manager.windows:
    window.scene = master
    for area in window.screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.region_3d.view_perspective = "CAMERA"
            area.spaces.active.shading.type = "MATERIAL"
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND, check_existing=False)
print("SAVED", OUT_BLEND)
print("LAYERS", LAYERS)
print("OBJECTS", len(bpy.data.objects))
