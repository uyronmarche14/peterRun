"""Build PETER RUN L01 V04 from fresh primitives.

No existing environment models are loaded or reused. The only inherited
constraints are the 960x540 (2x 480x270) camera output, exactly three lanes,
and an unobstructed lower central gameplay zone.
"""

import math
import os

import bpy
from mathutils import Vector


ROOT = os.path.dirname(os.path.abspath(__file__))
BLEND_PATH = os.path.join(ROOT, "Peter_Run_L01_Barangay_Morning_V04_Fresh_Source.blend")
OUT_DIR = os.path.join(ROOT, "generated", "l01_v04_fresh")
W, H = 960, 540

COLLECTION_NAMES = (
    "PR_V04_Sky", "PR_V04_Sun", "PR_V04_Clouds", "PR_V04_Mountains",
    "PR_V04_Tall_Barangay_Hall", "PR_V04_Market", "PR_V04_Houses_Left",
    "PR_V04_Houses_Right", "PR_V04_SariSari", "PR_V04_Waiting_Shed",
    "PR_V04_Roadside_Plants", "PR_V04_Street_Details", "PR_V04_Road",
    "PR_V04_Lane_Overlay", "PR_V04_Foreground", "PR_V04_Lighting",
    "PR_V04_Render_Cameras", "PR_V04_PlantsAndForeground",
    "PR_V04_Landmark_Barangay_Entry", "L01_SariSariStore",
    "PR_V04_Landmark_Waiting_Shed", "PR_V04_Landmark_Garden_Plaza",
    "PR_House_Concrete", "PR_House_Sawali",
    "PR_House_CoralRoof", "PR_House_Residence",
)

EXPORTS = (
    ("sky", "l01_v04_sky.png"),
    ("sun", "l01_v04_sun.png"),
    ("clouds", "l01_v04_clouds.png"),
    ("mountains", "l01_v04_mountains.png"),
    ("barangay_hall", "l01_v04_barangay_hall.png"),
    ("market", "l01_v04_market.png"),
    ("houses_far", "l01_v04_houses_far.png"),
    ("houses_mid", "l01_v04_houses_mid.png"),
    ("roadside", "l01_v04_roadside.png"),
    ("road", "l01_v04_road.png"),
    ("lane_overlay", "l01_v04_lane_overlay.png"),
    ("foreground", "l01_v04_foreground.png"),
    ("plants_foreground", "l01_v04_plants_foreground.png"),
    ("plant_sway_overlay", "l01_v04_plant_sway_overlay.png"),
    ("light_overlay", "l01_v04_light_overlay.png"),
    ("landmark_barangay_entry", "l01_landmark_barangay_entry_v01.png"),
    ("landmark_barangay_entry_far", "l01_landmark_barangay_entry_v01_far.png"),
    ("landmark_barangay_entry_mid", "l01_landmark_barangay_entry_v01_mid.png"),
    ("landmark_barangay_entry_near", "l01_landmark_barangay_entry_v01_near.png"),
    ("landmark_sari_sari", "l01_landmark_sari_sari_v01.png"),
    ("landmark_sari_sari_far", "l01_landmark_sari_sari_v01_far.png"),
    ("landmark_sari_sari_mid", "l01_landmark_sari_sari_v01_mid.png"),
    ("landmark_sari_sari_near", "l01_landmark_sari_sari_v01_near.png"),
    ("landmark_waiting_shed", "l01_landmark_waiting_shed_v01.png"),
    ("landmark_waiting_shed_far", "l01_landmark_waiting_shed_v01_far.png"),
    ("landmark_waiting_shed_mid", "l01_landmark_waiting_shed_v01_mid.png"),
    ("landmark_waiting_shed_near", "l01_landmark_waiting_shed_v01_near.png"),
    ("landmark_garden_or_plaza", "l01_landmark_garden_or_plaza_v01.png"),
    ("landmark_garden_or_plaza_far", "l01_landmark_garden_or_plaza_v01_far.png"),
    ("landmark_garden_or_plaza_mid", "l01_landmark_garden_or_plaza_v01_mid.png"),
    ("landmark_garden_or_plaza_near", "l01_landmark_garden_or_plaza_v01_near.png"),
)

LANDMARK_LAYERS = {
    "landmark_barangay_entry": ("barangay_entry", None),
    "landmark_barangay_entry_far": ("barangay_entry", "far"),
    "landmark_barangay_entry_mid": ("barangay_entry", "mid"),
    "landmark_barangay_entry_near": ("barangay_entry", "near"),
    "landmark_sari_sari": ("sari_sari", None),
    "landmark_sari_sari_far": ("sari_sari", "far"),
    "landmark_sari_sari_mid": ("sari_sari", "mid"),
    "landmark_sari_sari_near": ("sari_sari", "near"),
    "landmark_waiting_shed": ("waiting_shed", None),
    "landmark_waiting_shed_far": ("waiting_shed", "far"),
    "landmark_waiting_shed_mid": ("waiting_shed", "mid"),
    "landmark_waiting_shed_near": ("waiting_shed", "near"),
    "landmark_garden_or_plaza": ("garden_or_plaza", None),
    "landmark_garden_or_plaza_far": ("garden_or_plaza", "far"),
    "landmark_garden_or_plaza_mid": ("garden_or_plaza", "mid"),
    "landmark_garden_or_plaza_near": ("garden_or_plaza", "near"),
}

HOUSE_COLLECTIONS = {
    "concrete": "PR_House_Concrete",
    "sawali": "PR_House_Sawali",
    "coralroof": "PR_House_CoralRoof",
    "residence": "PR_House_Residence",
}
HOUSE_COMPONENTS = ("roof", "facade", "windows", "veranda_fence", "plants", "shadows")
HOUSE_LAYER_RULES = {}
HOUSE_EXPORTS = []
for house_id in HOUSE_COLLECTIONS:
    for facing in ("left", "right"):
        for depth in ("far", "mid", "near"):
            layer = f"house_{house_id}_{facing}_{depth}"
            HOUSE_LAYER_RULES[layer] = (house_id, facing, None, depth)
            HOUSE_EXPORTS.append((layer, f"l01_house_{house_id}_{facing}_{depth}_v01.png"))
    for component in HOUSE_COMPONENTS:
        layer = f"house_{house_id}_{component}"
        HOUSE_LAYER_RULES[layer] = (house_id, "left", component, "mid")
        HOUSE_EXPORTS.append((layer, f"l01_house_{house_id}_{component}_v01.png"))
EXPORTS += tuple(HOUSE_EXPORTS)

bpy.ops.wm.read_factory_settings(use_empty=True)
factory_scene = bpy.context.scene
scene = bpy.data.scenes.new("PETER_RUN_L01_V04_FRESH_MASTER")
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
scene.world = bpy.data.worlds.new("PR_V04_Morning_World")
scene.world.use_nodes = True
world_bg = scene.world.node_tree.nodes.get("Background")
world_bg.inputs["Color"].default_value = (.30,.50,.54,1)
world_bg.inputs["Strength"].default_value = .34

root = bpy.data.collections.new("PETER_RUN_L01_V04_FRESH")
scene.collection.children.link(root)
collections = {}
for name in COLLECTION_NAMES:
    coll = bpy.data.collections.new(name)
    root.children.link(coll)
    collections[name] = coll

# Keep the established primary collections while giving the two requested
# landmarks explicit, inspectable sub-collections in the source file.
root.children.unlink(collections["L01_SariSariStore"])
collections["PR_V04_SariSari"].children.link(collections["L01_SariSariStore"])
root.children.unlink(collections["PR_V04_Landmark_Waiting_Shed"])
collections["PR_V04_Waiting_Shed"].children.link(collections["PR_V04_Landmark_Waiting_Shed"])

# Keep the modular sprite asset stage out of the gameplay master camera. The
# dedicated library scene remains inspectable, while export scenes link the
# tagged objects directly and render them with their own cameras and lights.
house_asset_scene=bpy.data.scenes.new("PETER_RUN_L01_HOUSE_ASSET_LIBRARY")
house_asset_scene["purpose"]="off-camera modular house source for transparent Godot exports"
for collection_name in HOUSE_COLLECTIONS.values():
    house_collection=collections[collection_name]
    root.children.unlink(house_collection)
    house_asset_scene.collection.children.link(house_collection)


def material(name, rgb, rough=.84, alpha=1.0, emission=None, metallic=0.0):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb, alpha)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb,1)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Alpha"].default_value = alpha
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission[:3],1)
        bsdf.inputs["Emission Strength"].default_value = emission[3] if len(emission) > 3 else .8
    if alpha < 1:
        m.surface_render_method = "BLENDED"
    m.use_backface_culling = False
    return m


ink = material("V04_Ink_Teal", (.045,.16,.17))
deep_teal = material("V04_Deep_Teal", (.08,.31,.32))
teal = material("V04_Painted_Teal", (.13,.49,.48))
teal_light = material("V04_Cool_Teal_Shadow", (.27,.56,.54))
cream = material("V04_Warm_Cream", (.83,.72,.52))
capiz = material("V04_Capiz_Glow", (.98,.76,.32), emission=(1.0,.58,.18,.9))
mango = material("V04_Mango", (.95,.49,.10))
coral = material("V04_Coral", (.76,.25,.20))
sun_yellow = material("V04_Sun_Mango", (1.0,.55,.08), emission=(1.0,.42,.06,1.1))
sun_core = material("V04_Sun_Cream", (1.0,.86,.48), emission=(1.0,.72,.28,1.0))
earth = material("V04_Earth", (.38,.25,.16))
road_mat = material("V04_Road_Warm_Grey", (.31,.35,.34))
road_variation = material("V04_Road_Variation", (.47,.39,.28), alpha=.30)
concrete = material("V04_Painted_Concrete", (.57,.58,.50))
bamboo = material("V04_Bamboo", (.60,.39,.16))
wood = material("V04_Timber", (.34,.18,.09))
sawali = material("V04_Sawali", (.72,.48,.22))
clay_roof = material("V04_Clay_Roof", (.50,.17,.11))
corrugated = material("V04_Corrugated_Teal", (.08,.36,.39), metallic=.12)
pale_green = material("V04_House_Pale_Green", (.52,.68,.56))
sunlit_cream = material("V04_House_Sunlit_Cream", (.93,.78,.50))
cool_wall = material("V04_House_Cool_Shadow", (.20,.43,.45))
light_corrugated = material("V04_Light_Corrugated_Roof", (.62,.68,.63), metallic=.10)
painted_blue = material("V04_Residence_Painted_Blue", (.32,.55,.58))
leaf = material("V04_Leaf", (.10,.38,.22))
leaf_light = material("V04_Banana_Leaf", (.29,.60,.25))
flower = material("V04_Bougainvillea", (.78,.18,.34))
water_blue = material("V04_Water_Container", (.12,.40,.52))
shadow = material("V04_Contact_Shadow", (.015,.035,.035), alpha=.40)
cloud_mat = material("V04_Cloud_Cream", (.93,.84,.68), alpha=.84, emission=(.75,.68,.55,.25))
mountain_far = material("V04_Mountain_Far", (.20,.43,.48))
mountain_near = material("V04_Mountain_Near", (.12,.35,.39))
glow_mat = material("V04_Landmark_Glow", (1.0,.55,.10), alpha=.12, emission=(1.0,.45,.08,.45))


def link_only(obj, coll):
    for old in tuple(obj.users_collection):
        old.objects.unlink(obj)
    coll.objects.link(obj)
    return obj


def box(name, loc, dims, mat, coll, bevel=.04, export_group=None):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = link_only(bpy.context.object, coll)
    obj.name = name
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("V04_Soft_Edge", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    obj["export_group"] = export_group or ""
    return obj


def cyl(name, loc, radius, depth, mat, coll, vertices=12, rotation=(0,0,0), export_group=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth,
                                       location=loc, rotation=rotation)
    obj = link_only(bpy.context.object, coll)
    obj.name = name
    obj.data.materials.append(mat)
    obj["export_group"] = export_group or ""
    return obj


def ico(name, loc, scale, mat, coll, subdivisions=1, export_group=None):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1, location=loc)
    obj = link_only(bpy.context.object, coll)
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(mat)
    obj["export_group"] = export_group or ""
    return obj


def roof(name, loc, width, depth, height, mat, coll, export_group=None):
    verts = [(-width/2,-depth/2,0),(width/2,-depth/2,0),(0,-depth/2,height),
             (-width/2,depth/2,0),(width/2,depth/2,0),(0,depth/2,height)]
    faces = [(0,2,1),(3,4,5),(0,3,5,2),(1,2,5,4),(0,1,4,3)]
    mesh = bpy.data.meshes.new(name+"_Mesh")
    mesh.from_pydata(verts,[],faces)
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name,mesh)
    coll.objects.link(obj)
    obj.location = loc
    obj["export_group"] = export_group or ""
    bevel = obj.modifiers.new("V04_Roof_Edge","BEVEL")
    bevel.width = .07
    bevel.segments = 2
    return obj


def shadow_disc(name, loc, scale, coll, export_group=None):
    bpy.ops.mesh.primitive_circle_add(vertices=32,radius=1,fill_type="NGON",location=loc)
    obj=link_only(bpy.context.object,coll)
    obj.name=name
    obj.scale=(scale[0],scale[1],1)
    obj.data.materials.append(shadow)
    obj["export_group"] = export_group or ""
    return obj


def text_obj(name, body, loc, size, mat, coll, export_group=None):
    curve=bpy.data.curves.new(name+"_Curve","FONT")
    curve.body=body
    curve.align_x="CENTER"
    curve.align_y="CENTER"
    curve.size=size
    curve.extrude=.015
    curve.bevel_depth=.006
    curve.materials.append(mat)
    obj=bpy.data.objects.new(name,curve)
    coll.objects.link(obj)
    obj.location=loc
    obj.rotation_euler.x=math.radians(90)
    obj["export_group"] = export_group or ""
    return obj


def mark_landmark(obj, landmark_id, parallax_depth):
    """Tag a landmark object for composite and aligned parallax exports."""
    if parallax_depth not in {"far", "mid", "near"}:
        raise ValueError(parallax_depth)
    obj["landmark_id"] = landmark_id
    obj["route_phase"] = landmark_id
    obj["parallax_depth"] = parallax_depth
    obj["progression_message"] = "continuing through the neighbourhood"
    return obj


def mark_house(obj, house_id, facing, component):
    """Tag modular house geometry for variant and component exports."""
    if facing not in {"left", "right"}:
        raise ValueError(facing)
    if component not in HOUSE_COMPONENTS:
        raise ValueError(component)
    obj["house_id"] = house_id
    obj["house_facing"] = facing
    obj["house_component"] = component
    obj["godot_asset"] = True
    return obj


# Lower, forward-facing camera. The slight downward angle puts the horizon near 37%.
cam_data=bpy.data.cameras.new("PR_V04_Game_Camera_Data")
camera=bpy.data.objects.new("PR_V04_Game_Camera",cam_data)
collections["PR_V04_Render_Cameras"].objects.link(camera)
camera.location=(0,-24.0,6.4)
camera.rotation_euler=(Vector((0,17.0,3.1))-camera.location).to_track_quat("-Z","Y").to_euler()
cam_data.lens=24.2
cam_data.sensor_width=36
cam_data.clip_end=400
scene.camera=camera

# Directional-feeling warm key, cool fill, and a dim market interior source.
light_coll=collections["PR_V04_Lighting"]
key_data=bpy.data.lights.new("PR_V04_Golden_Key_Data","AREA")
key_data.energy=1900
key_data.color=(1.0,.55,.25)
key_data.size=9
key=bpy.data.objects.new("PR_V04_Golden_Key",key_data)
light_coll.objects.link(key)
key.location=(-11,-8,19)
key.rotation_euler=(Vector((0,17,3))-key.location).to_track_quat("-Z","Y").to_euler()
fill_data=bpy.data.lights.new("PR_V04_Teal_Fill_Data","AREA")
fill_data.energy=780
fill_data.color=(.19,.55,.62)
fill_data.size=12
fill=bpy.data.objects.new("PR_V04_Teal_Fill",fill_data)
light_coll.objects.link(fill)
fill.location=(12,2,13)
fill.rotation_euler=(Vector((0,20,4))-fill.location).to_track_quat("-Z","Y").to_euler()
bpy.context.view_layer.update()


def camera_local(px,py,depth):
    frame=camera.data.view_frame(scene=scene)
    base=abs(frame[0].z)
    scale=depth/base
    left=min(v.x for v in frame)*scale
    right=max(v.x for v in frame)*scale
    bottom=min(v.y for v in frame)*scale
    top=max(v.y for v in frame)*scale
    return (left+(right-left)*px/W,top-(top-bottom)*py/H,-depth)


def screen_mesh(name,points,depth,mat,coll,export_group=None):
    mesh=bpy.data.meshes.new(name+"_Mesh")
    mesh.from_pydata([camera_local(x,y,depth) for x,y in points],[],
                     [tuple(reversed(range(len(points))))])
    mesh.materials.append(mat)
    mesh.update()
    obj=bpy.data.objects.new(name,mesh)
    coll.objects.link(obj)
    obj.matrix_world=camera.matrix_world.copy()
    obj["export_group"] = export_group or ""
    return obj


def ellipse(name,cx,cy,rx,ry,depth,mat,coll,export_group=None,count=48):
    points=[(cx+math.cos(i*math.tau/count)*rx,cy+math.sin(i*math.tau/count)*ry)
            for i in range(count)]
    return screen_mesh(name,points,depth,mat,coll,export_group)


# Mint-to-cream sky mesh; no reuse of earlier environment art.
sky_coll=collections["PR_V04_Sky"]
sky=screen_mesh("PR_V04_Sky_Gradient",[(0,0),(W,0),(W,H),(0,H)],82,cream,sky_coll,"sky")
uv=sky.data.uv_layers.new(name="V04_Sky_UV")
for loop in sky.data.loops:
    idx=loop.vertex_index
    uv.data[loop.index].uv=((0 if idx in (0,3) else 1),(0 if idx in (0,1) else 1))
sky_shader=bpy.data.materials.new("PR_V04_Mint_Cream_Gradient")
sky_shader.use_nodes=True
nodes=sky_shader.node_tree.nodes
nodes.clear()
tc=nodes.new("ShaderNodeTexCoord")
sep=nodes.new("ShaderNodeSeparateXYZ")
ramp=nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].color=(.93,.76,.48,1)
ramp.color_ramp.elements[1].color=(.28,.62,.70,1)
mid=ramp.color_ramp.elements.new(.43)
mid.color=(.63,.78,.67,1)
em=nodes.new("ShaderNodeEmission")
out=nodes.new("ShaderNodeOutputMaterial")
links=sky_shader.node_tree.links
links.new(tc.outputs["UV"],sep.inputs[0]); links.new(sep.outputs["Y"],ramp.inputs[0])
links.new(ramp.outputs[0],em.inputs["Color"]); links.new(em.outputs[0],out.inputs[0])
sky.data.materials.clear(); sky.data.materials.append(sky_shader)

sun_coll=collections["PR_V04_Sun"]
ellipse("PR_V04_ANIM_Sun_Glow",610,132,88,88,78,sun_yellow,sun_coll,"sun")
ellipse("PR_V04_Sun_Cream_Core",610,132,59,59,77.8,sun_core,sun_coll,"sun")

cloud_coll=collections["PR_V04_Clouds"]
for idx,(cx,cy,rx,ry) in enumerate(((180,95,120,22),(805,88,112,21),(86,154,78,17))):
    ellipse(f"PR_V04_ANIM_Cloud_Group_{idx}",cx,cy,rx,ry,74-idx*.1,cloud_mat,cloud_coll,"clouds")

mount_coll=collections["PR_V04_Mountains"]
screen_mesh("PR_V04_Mountains_Far",[(0,246),(0,205),(120,153),(236,227),(356,184),(470,239),(590,172),(715,226),(835,166),(960,216),(960,260)],72,mountain_far,mount_coll,"mountains")
screen_mesh("PR_V04_Mountains_Near",[(0,269),(0,236),(156,197),(278,251),(408,216),(545,261),(696,205),(826,249),(960,220),(960,276)],71.7,mountain_near,mount_coll,"mountains")
for idx,(x,y) in enumerate(((120,136),(139,143),(836,126))):
    screen_mesh(f"PR_V04_Distant_Bird_{idx}_L",[(x-5,y),(x,y+2),(x,y)],70,ink,mount_coll,"mountains")
    screen_mesh(f"PR_V04_Distant_Bird_{idx}_R",[(x,y+2),(x+5,y),(x,y)],69.9,ink,mount_coll,"mountains")

# Tall four-level civic hall with a two-level tower extension.
hall=collections["PR_V04_Tall_Barangay_Hall"]
G="barangay_hall"
shadow_disc("PR_V04_Hall_Plaza_Shadow",(0,32.2,.025),(9.5,4.4),hall,G)
box("PR_V04_Hall_Plaza",(0,33.0,.28),(18.0,8.0,.55),concrete,hall,.12,G)
for step,(y,z,w) in enumerate(((29.1,.18,15.5),(29.6,.40,14.2),(30.1,.62,12.8))):
    box(f"PR_V04_Hall_Front_Step_{step}",(0,y,z),(w,1.05,.28),cream,hall,.04,G)
box("PR_V04_Hall_Four_Storey_Core",(0,35.0,5.15),(13.4,5.7,9.7),cream,hall,.12,G)
box("PR_V04_Hall_Teal_Shadow_Wing",(5.25,34.9,5.05),(2.7,5.8,9.5),deep_teal,hall,.08,G)
# Four deep veranda levels and vertical civic columns.
for level,z in enumerate((2.15,4.25,6.35,8.45)):
    box(f"PR_V04_Hall_Veranda_Slab_{level}",(0,31.85,z),(14.3,1.30,.25),teal,hall,.05,G)
    box(f"PR_V04_Hall_Veranda_Rail_{level}",(0,31.18,z+.55),(13.2,.08,.12),mango,hall,.02,G)
    for x in (-5.65,-2.85,0,2.85,5.65):
        cyl(f"PR_V04_Hall_Column_{level}_{x}",(x,31.40,z-.95),.105,2.05,cream,hall,12,export_group=G)
# Varied capiz panels, doors and patterned ventilation blocks.
for floor,z in enumerate((1.55,3.75,5.85,7.95)):
    for col,x in enumerate((-4.65,-2.05,2.05,4.65)):
        box(f"PR_V04_Hall_Capiz_{floor}_{col}",(x,32.07,z),(1.15,.09,1.20),capiz,hall,.03,G)
        if (floor+col)%2==0:
            box(f"PR_V04_Hall_Window_Shade_{floor}_{col}",(x,31.93,z+.74),(1.38,.32,.10),mango,hall,.03,G)
box("PR_V04_Hall_Main_Entry",(0,32.03,1.85),(1.75,.16,3.15),wood,hall,.05,G)
for row,z in enumerate((3.35,4.05,4.75)):
    for col,x in enumerate((5.15,5.65)):
        box(f"PR_V04_Vent_Block_{row}_{col}",(x,31.94,z),(.34,.10,.34),cream,hall,.02,G)
roof("PR_V04_Hall_Deep_Main_Roof",(0,35.0,10.0),14.9,6.8,2.05,clay_roof,hall,G)
# Central tower rises two storeys above main roof.
box("PR_V04_Hall_Tower",(0,35.25,12.25),(4.15,4.2,6.2),teal,hall,.10,G)
for z in (10.65,12.45,14.05):
    box(f"PR_V04_Tower_Capiz_Band_{z}",(0,33.10,z),(2.0,.10,.95),capiz,hall,.03,G)
roof("PR_V04_Tower_Tropical_Roof",(0,35.25,15.38),5.35,5.45,1.75,corrugated,hall,G)
cyl("PR_V04_Community_Sun_Emblem",(0,33.0,11.55),.66,.16,mango,hall,32,(math.radians(90),0,0),G)
box("PR_V04_Bell_Frame_Top",(0,34.9,16.95),(2.15,1.7,.18),wood,hall,.03,G)
for x in (-.85,.85):
    box(f"PR_V04_Bell_Frame_Post_{x}",(x,34.9,16.3),(.16,.18,1.35),wood,hall,.03,G)
cyl("PR_V04_Civic_Bell",(0,34.72,16.25),.34,.55,mango,hall,16,(math.radians(90),0,0),G)
box("PR_V04_Hall_Sign_Frame",(0,31.93,8.95),(7.0,.18,1.02),mango,hall,.04,G)
box("PR_V04_Hall_Sign_Panel",(0,31.80,8.95),(6.58,.08,.72),cream,hall,.02,G)
text_obj("PR_V04_Hall_Sign_Text","BARANGAY HALL",(0,31.72,8.90),.68,deep_teal,hall,G)
# Sparse parol geometry beneath veranda roof.
for side in (-1,1):
    emblem=box(f"PR_V04_Parol_Accent_{side}",(side*5.9,31.02,7.65),(.50,.08,.50),mango,hall,.02,G)
    emblem.rotation_euler.y=math.radians(45)

# Two-storey public market wing, clearly lower than the civic tower.
market=collections["PR_V04_Market"]
M="market"
shadow_disc("PR_V04_Market_Shadow",(9.5,34,.02),(5.2,3.7),market,M)
box("PR_V04_Market_Two_Storey_Core",(9.8,35.1,4.0),(7.4,5.6,7.4),coral,market,.10,M)
box("PR_V04_Market_Open_Ground",(9.8,32.17,1.75),(7.0,.26,3.0),deep_teal,market,.04,M)
box("PR_V04_ANIM_Market_Canopy",(9.8,31.70,3.30),(8.1,1.35,.24),mango,market,.06,M)
for x in (6.8,8.8,10.8,12.8):
    cyl(f"PR_V04_Market_Column_{x}",(x,31.95,1.65),.11,2.9,bamboo,market,12,export_group=M)
    box(f"PR_V04_Market_Stall_{x}",(x,31.55,.78),(1.55,.65,1.10),wood,market,.04,M)
    for p in (-.38,0,.38):
        ico(f"PR_V04_Market_Produce_{x}_{p}",(x+p,31.15,1.43),(.18,.16,.14),leaf_light if p else mango,market,1,M)
box("PR_V04_Market_Upper_Balcony",(9.8,32.0,5.25),(7.8,1.05,.25),cream,market,.04,M)
box("PR_V04_Market_Upper_Rail",(9.8,31.43,5.85),(7.25,.10,1.05),teal,market,.03,M)
for x in (7.2,8.5,9.8,11.1,12.4):
    box(f"PR_V04_Market_Vent_{x}",(x,32.10,5.98),(.58,.08,.82),capiz,market,.02,M)
roof("PR_V04_Market_Tall_Ventilated_Roof",(9.8,35.1,7.70),8.2,6.4,1.65,corrugated,market,M)
box("PR_V04_Market_Roof_Monitor",(9.8,35.1,8.95),(3.0,2.1,1.25),cream,market,.06,M)
roof("PR_V04_Market_Clerestory_Roof",(9.8,35.1,9.60),3.8,2.8,.72,clay_roof,market,M)
text_obj("PR_V04_Market_Entrance_Text","PALENGKE",(9.8,31.27,4.12),.42,cream,market,M)
for idx,x in enumerate((7.6,8.8,10.0,11.2,12.4)):
    cyl(f"PR_V04_ANIM_Woven_Basket_{idx}",(x,31.18,2.42),.25,.32,sawali,market,12,(math.radians(90),0,0),M)
for x in (7.2,12.4):
    box(f"PR_V04_Market_Shaded_Bench_{x}",(x,30.6,.62),(1.45,.42,.16),wood,market,.03,M)

# Fresh asymmetrical modular homes. All dimensions, façades and roofs differ.
left=collections["PR_V04_Houses_Left"]
right=collections["PR_V04_Houses_Right"]
HLF="houses_far"; HLM="houses_mid"

# 1 Concrete bungalow, left foreground.
shadow_disc("PR_V04_Bungalow_Shadow",(-9.0,2.8,.02),(3.2,2.2),left,HLM)
box("PR_V04_Bungalow_Core",(-9.0,3.3,1.65),(4.8,3.9,3.1),teal_light,left,.08,HLM)
roof("PR_V04_Bungalow_Roof",(-9.0,3.3,3.2),5.5,4.6,1.0,clay_roof,left,HLM)
box("PR_V04_Bungalow_Veranda",(-8.8,1.15,.56),(4.4,1.0,.16),cream,left,.04,HLM)
box("PR_V04_Bungalow_Door",(-10.0,1.30,1.42),(.82,.10,2.15),wood,left,.03,HLM)
for x in (-8.6,-7.55): box(f"PR_V04_Bungalow_Capiz_{x}",(x,1.29,1.75),(.72,.08,.86),capiz,left,.02,HLM)

# 2 Two-storey mixed-use, left middle.
box("PR_V04_MixedUse_Core",(-8.2,14.0,3.0),(4.1,4.0,5.7),coral,left,.08,HLM)
roof("PR_V04_MixedUse_Roof",(-8.2,14.0,5.85),4.8,4.7,.92,corrugated,left,HLM)
box("PR_V04_MixedUse_Shopfront",(-8.2,11.92,1.35),(3.45,.16,2.2),deep_teal,left,.03,HLM)
box("PR_V04_MixedUse_Awning",(-8.2,11.52,2.55),(3.9,.92,.18),mango,left,.04,HLM)
box("PR_V04_MixedUse_Balcony",(-8.2,11.55,4.05),(3.7,.80,.20),cream,left,.03,HLM)
box("PR_V04_MixedUse_Balcony_Rail",(-8.2,11.14,4.48),(3.5,.08,.74),teal,left,.02,HLM)

# 3 Community garden home, far left.
box("PR_V04_GardenHome_Core",(-8.7,24.0,2.05),(5.4,3.8,3.9),cream,left,.07,HLF)
roof("PR_V04_GardenHome_Roof",(-8.7,24.0,4.02),6.0,4.5,1.15,clay_roof,left,HLF)
box("PR_V04_GardenHome_Door",(-9.9,22.02,1.50),(.82,.10,2.35),deep_teal,left,.03,HLF)
for x in (-8.5,-7.45): box(f"PR_V04_GardenHome_Window_{x}",(x,22.01,2.15),(.74,.08,.90),capiz,left,.02,HLF)
box("PR_V04_Garden_Gate",(-6.7,20.75,.85),(1.45,.10,1.5),bamboo,left,.02,HLF)
box("PR_V04_Garden_Bench",(-10.0,20.65,.55),(1.8,.42,.16),wood,left,.03,HLF)

# 4 Raised sawali home, right foreground.
for x in (7.2,10.0): cyl(f"PR_V04_Sawali_Stilt_{x}",(x,5.8,1.0),.13,1.9,bamboo,right,12,export_group=HLM)
box("PR_V04_Sawali_Raised_Core",(8.6,6.0,2.65),(4.6,4.1,3.2),sawali,right,.06,HLM)
roof("PR_V04_Sawali_Deep_Roof",(8.6,6.0,4.27),5.8,5.4,1.35,corrugated,right,HLM)
box("PR_V04_Sawali_Stairs",(7.25,3.55,.75),(1.0,1.6,.22),wood,right,.02,HLM)
box("PR_V04_Sawali_Door",(9.35,3.90,2.55),(.78,.10,2.1),wood,right,.03,HLM)
box("PR_V04_Sawali_Capiz",(7.65,3.90,2.75),(.92,.08,.84),capiz,right,.02,HLM)

# 5 Narrow townhouse, far right with laundry balcony.
box("PR_V04_Townhouse_Core",(8.0,23.1,3.35),(3.1,3.5,6.4),teal,right,.07,HLF)
roof("PR_V04_Townhouse_Roof",(8.0,23.1,6.58),3.7,4.1,.82,mango,right,HLF)
box("PR_V04_Townhouse_Balcony",(8.0,21.25,4.30),(2.8,.72,.18),cream,right,.03,HLF)
box("PR_V04_Townhouse_Rail",(8.0,20.90,4.78),(2.65,.07,.75),deep_teal,right,.02,HLF)
box("PR_V04_Townhouse_Door",(8.6,21.30,1.55),(.72,.08,2.45),wood,right,.03,HLF)
for idx,(x,color) in enumerate(((7.25,coral),(8.0,cream),(8.75,mango))):
    box(f"PR_V04_ANIM_Balcony_Laundry_{idx}",(x,20.72,4.20),(.52,.06,.72),color,right,.01,HLF)

# Calm route milestone 1: a modest entry marker with an abstract sun motif.
# It carries no place name and stays beyond the left curb and drainage channel.
entry=collections["PR_V04_Landmark_Barangay_Entry"]
entry_id="barangay_entry"
mark_landmark(ico("PR_V04_Landmark_Entry_Back_Hedge",(-9.45,-4.1,1.45),(1.85,.72,1.05),leaf,entry,2),entry_id,"far")
mark_landmark(ico("PR_V04_Landmark_Entry_Back_Leaf",(-8.25,-4.0,1.68),(1.15,.55,.82),leaf_light,entry,1),entry_id,"far")
for idx,x in enumerate((-10.15,-7.55)):
    mark_landmark(cyl(f"PR_V04_Landmark_Entry_Post_{idx}",(x,-4.55,1.65),.16,3.15,bamboo,entry,12),entry_id,"mid")
mark_landmark(box("PR_V04_Landmark_Entry_Header",(-8.85,-4.55,3.05),(3.05,.28,.42),cream,entry,.06),entry_id,"mid")
mark_landmark(cyl("PR_V04_Landmark_Entry_Sun",(-8.85,-4.36,3.62),.48,.12,mango,entry,28,(math.radians(90),0,0)),entry_id,"mid")
for ray_idx,angle in enumerate(range(0,360,45)):
    radians=math.radians(angle)
    ray=box(f"PR_V04_Landmark_Entry_Sun_Ray_{ray_idx}",(-8.85+math.sin(radians)*.72,-4.34,3.62+math.cos(radians)*.72),(.12,.10,.30),coral,entry,.02)
    ray.rotation_euler.y=radians
    mark_landmark(ray,entry_id,"mid")
mark_landmark(shadow_disc("PR_V04_Landmark_Entry_Grounded_Shadow",(-8.85,-4.45,.025),(2.05,1.15),entry),entry_id,"near")
mark_landmark(box("PR_V04_Landmark_Entry_Curb_Detail",(-6.88,-4.25,.16),(.34,2.7,.28),mango,entry,.03),entry_id,"near")
for idx,x in enumerate((-9.85,-7.85)):
    mark_landmark(cyl(f"PR_V04_Landmark_Entry_Pot_{idx}",(x,-4.20,.32),.27,.50,coral,entry,10),entry_id,"near")
    mark_landmark(ico(f"PR_V04_Landmark_Entry_Plant_{idx}",(x,-4.20,.78),(.40,.32,.42),leaf_light,entry,1),entry_id,"near")

# Calm route milestone 2: original L01 sari-sari store. The entire footprint is
# set back beyond x=6.8, leaving the curb, drainage, road, and prompt corridor clear.
sari=collections["L01_SariSariStore"]
sari_id="sari_sari"
mark_landmark(shadow_disc("PR_V04_L01_SariSariStore_Grounded_Shadow",(9.20,14.55,.025),(2.95,2.35),sari),sari_id,"near")
mark_landmark(box("PR_V04_L01_SariSariStore_Cream_Core",(9.20,14.85,2.05),(4.55,4.0,3.9),cream,sari,.08),sari_id,"far")
mark_landmark(roof("PR_V04_L01_SariSariStore_Roof",(9.20,14.85,4.02),5.15,4.55,.92,clay_roof,sari),sari_id,"far")
for idx,x in enumerate((7.45,10.95)):
    mark_landmark(box(f"PR_V04_L01_SariSariStore_Capiz_Glint_{idx}",(x,12.82,2.42),(.48,.09,.70),capiz,sari,.02),sari_id,"far")

mark_landmark(box("PR_V04_L01_SariSariStore_Display_Opening",(9.20,12.80,1.90),(3.25,.18,1.82),deep_teal,sari,.04),sari_id,"mid")
mark_landmark(box("PR_V04_L01_SariSariStore_Counter",(9.20,12.48,1.02),(3.60,.62,.72),wood,sari,.05),sari_id,"mid")
mark_landmark(box("PR_V04_L01_SariSariStore_Coral_Awning",(9.20,12.18,2.92),(4.05,1.28,.20),coral,sari,.05),sari_id,"mid")
for rib_idx,x in enumerate((7.52,8.08,8.64,9.20,9.76,10.32,10.88)):
    mark_landmark(box(f"PR_V04_L01_SariSariStore_Awning_Rib_{rib_idx}",(x,12.15,2.94),(.08,1.32,.08),mango,sari,.015),sari_id,"mid")
for shelf_idx,z in enumerate((1.55,2.12)):
    mark_landmark(box(f"PR_V04_L01_SariSariStore_Shelf_{shelf_idx}",(9.20,12.63,z),(3.02,.16,.10),bamboo,sari,.015),sari_id,"mid")
    for product_idx,x in enumerate((8.05,8.52,8.99,9.46,9.93,10.40)):
        product_mat=(mango,teal,coral,capiz)[(shelf_idx+product_idx)%4]
        mark_landmark(box(f"PR_V04_L01_SariSariStore_Product_{shelf_idx}_{product_idx}",(x,12.52,z+.24),(.27,.12,.36),product_mat,sari,.015),sari_id,"mid")
mark_landmark(box("PR_V04_L01_SariSariStore_Sign_Frame",(9.20,12.77,3.66),(4.02,.20,.84),mango,sari,.05),sari_id,"mid")
mark_landmark(box("PR_V04_L01_SariSariStore_Sign_Panel",(9.20,12.64,3.66),(3.72,.08,.60),cream,sari,.02),sari_id,"mid")
mark_landmark(text_obj("PR_V04_L01_SariSariStore_Sign_Text","SARI-SARI",(9.20,12.57,3.62),.55,deep_teal,sari),sari_id,"mid")

mark_landmark(box("PR_V04_L01_SariSariStore_Front_Step",(9.20,12.25,.22),(4.05,1.05,.28),concrete,sari,.05),sari_id,"near")
mark_landmark(box("PR_V04_L01_SariSariStore_Curb_Detail",(6.82,13.45,.16),(.34,3.1,.28),mango,sari,.03),sari_id,"near")
for idx,x in enumerate((7.35,11.05)):
    mark_landmark(cyl(f"PR_V04_L01_SariSariStore_Pot_{idx}",(x,12.28,.36),.31,.58,coral if idx==0 else earth,sari,10),sari_id,"near")
    mark_landmark(ico(f"PR_V04_L01_SariSariStore_Plant_{idx}",(x,12.27,.88),(.47,.38,.52),leaf_light if idx==0 else leaf,sari,1),sari_id,"near")

# Ground and roadside life remain safely outside x +/-6.35.
road=collections["PR_V04_Road"]
road_mesh=bpy.data.meshes.new("PR_V04_Road_Mesh")
road_mesh.from_pydata([(-6.35,-14,0),(6.35,-14,0),(6.35,31,0),(-6.35,31,0)],[],[(0,1,2,3)])
road_mesh.materials.append(road_mat); road_mesh.update()
road_obj=bpy.data.objects.new("PR_V04_Three_Lane_Road",road_mesh); road.objects.link(road_obj); road_obj["export_group"]="road"
for idx,y in enumerate((-8,-2,5,12,20,27)):
    box(f"PR_V04_Road_Surface_Variation_{idx}",((-.9 if idx%2 else 1.1),y,.018),(1.3,.34,.02),road_variation,road,.01,"road")
for idx,y in enumerate((-5,7,17,26)):
    box(f"PR_V04_Road_Seam_{idx}",(0,y,.014),(12.2,.055,.016),road_variation,road,.005,"road")

lanes=collections["PR_V04_Lane_Overlay"]
for x,label in ((-2.12,"Left"),(2.12,"Right")):
    box(f"PR_V04_Lane_Separator_{label}",(x,8.5,.045),(.085,45,.025),teal,lanes,.01,"lane_overlay")
for x,label in ((-6.25,"Left"),(6.25,"Right")):
    box(f"PR_V04_Painted_Curb_{label}",(x,8.5,.10),(.20,45,.16),mango,lanes,.02,"lane_overlay")

street=collections["PR_V04_Street_Details"]
plants=collections["PR_V04_Roadside_Plants"]
for side in (-1,1):
    box(f"PR_V04_Earth_Verger_{side}",(side*9.2,8.5,-.08),(5.5,45,.10),earth,street,0,"roadside")
    box(f"PR_V04_Covered_Sidewalk_{side}",(side*6.85,8.5,.03),(1.0,45,.12),concrete,street,.02,"roadside")
    box(f"PR_V04_Drainage_Channel_{side}",(side*6.42,8.5,.045),(.22,45,.15),ink,street,.01,"roadside")
    # Concrete utility poles and restrained overhead wires outside prompt corridor.
    for idx,y in enumerate((-3,9,20)):
        x=side*7.55
        cyl(f"PR_V04_Utility_Pole_{side}_{idx}",(x,y,3.2),.13,6.2,concrete,street,12,export_group="roadside")
        box(f"PR_V04_Utility_Crossbar_{side}_{idx}",(x,y,5.75),(1.45,.12,.12),wood,street,.02,"roadside")
    # Concrete/bamboo fence mix.
    for idx,y in enumerate((-7,1,11,19)):
        x=side*7.15
        mat=bamboo if idx%2 else concrete
        cyl(f"PR_V04_Fence_Post_{side}_{idx}",(x,y,.80),.09,1.5,mat,street,10,export_group="roadside")
        if idx<3: box(f"PR_V04_Fence_Rail_{side}_{idx}",(x,y+2.0,1.0),(.08,3.9,.08),bamboo,street,.015,"roadside")
    # Potted bougainvillea and calamansi.
    for idx,y in enumerate((-8.0,1.7,10.2,19.0,26.0)):
        x=side*(7.35+.25*(idx%2))
        cyl(f"PR_V04_Plant_Pot_{side}_{idx}",(x,y,.34),.28,.54,coral,plants,10,export_group="roadside")
        ico(f"PR_V04_ANIM_Plant_{side}_{idx}",(x,y,.86),(.48,.40,.50),leaf_light if idx%2 else leaf,plants,1,"roadside")
        if idx in (1,3):
            for petal in range(3): ico(f"PR_V04_Bougainvillea_{side}_{idx}_{petal}",(x+(petal-1)*.18,y-.05,1.08+petal*.08),(.12,.10,.10),flower,plants,1,"roadside")
    # Banana cluster and coconut palm, staggered not mirrored.
    by=17.5 if side<0 else 8.2
    bx=side*8.1
    cyl(f"PR_V04_Banana_Stem_{side}",(bx,by,1.45),.13,2.8,bamboo,plants,10,export_group="roadside")
    for idx,ang in enumerate((-58,-22,22,58)):
        leaf_obj=ico(f"PR_V04_ANIM_Banana_Leaf_{side}_{idx}",(bx+math.sin(math.radians(ang))*.70,by,3.05+math.cos(math.radians(ang))*.15),(.22,1.0,.13),leaf_light,plants,1,"roadside")
        leaf_obj.rotation_euler.z=math.radians(ang)
    py=-1.5 if side<0 else 18.0
    px=side*8.6
    cyl(f"PR_V04_Coconut_Trunk_{side}",(px,py,3.0),.20,5.8,bamboo,plants,12,export_group="roadside")
    for idx,ang in enumerate((-70,-35,0,35,70)):
        frond=ico(f"PR_V04_ANIM_Palm_Frond_{side}_{idx}",(px+math.sin(math.radians(ang))*.95,py,5.95+math.cos(math.radians(ang))*.20),(.24,1.20,.14),leaf,plants,1,"roadside")
        frond.rotation_euler.z=math.radians(ang)

# Waiting shed landmark: a quiet covered pause point, not a reward station.
shed=collections["PR_V04_Landmark_Waiting_Shed"]
shed_id="waiting_shed"
mark_landmark(box("PR_V04_Landmark_Waiting_Back_Screen",(-8.80,9.20,1.45),(3.45,.20,2.35),cream,shed,.05),shed_id,"far")
mark_landmark(box("PR_V04_Landmark_Waiting_Capiz_Panel",(-8.80,9.06,1.58),(2.55,.08,.88),capiz,shed,.03),shed_id,"far")
mark_landmark(ico("PR_V04_Landmark_Waiting_Back_Plant",(-10.35,9.35,1.10),(.74,.58,.72),leaf,shed,1),shed_id,"far")
mark_landmark(box("PR_V04_Landmark_Waiting_Base",(-8.80,8.65,.24),(3.90,2.55,.32),concrete,shed,.06),shed_id,"mid")
for idx,x in enumerate((-10.35,-7.25)):
    mark_landmark(cyl(f"PR_V04_Landmark_Waiting_Post_{idx}",(x,8.45,1.72),.11,2.95,bamboo,shed,10),shed_id,"mid")
mark_landmark(box("PR_V04_Landmark_Waiting_Bench",(-8.80,7.92,.70),(2.65,.48,.18),wood,shed,.04),shed_id,"mid")
for idx,x in enumerate((-9.75,-7.85)):
    mark_landmark(box(f"PR_V04_Landmark_Waiting_Bench_Leg_{idx}",(x,7.94,.42),(.14,.25,.52),wood,shed,.02),shed_id,"mid")
mark_landmark(roof("PR_V04_Landmark_Waiting_Roof",(-8.80,8.55,3.18),4.55,3.20,.72,corrugated,shed),shed_id,"mid")
mark_landmark(shadow_disc("PR_V04_Landmark_Waiting_Grounded_Shadow",(-8.80,8.45,.025),(2.55,1.65),shed),shed_id,"near")
mark_landmark(box("PR_V04_Landmark_Waiting_Curb_Detail",(-6.82,8.10,.16),(.34,2.90,.28),mango,shed,.03),shed_id,"near")
mark_landmark(cyl("PR_V04_Landmark_Waiting_Pot",(-7.15,7.62,.34),.29,.54,coral,shed,10),shed_id,"near")
mark_landmark(ico("PR_V04_Landmark_Waiting_Potted_Plant",(-7.15,7.62,.82),(.42,.34,.48),leaf_light,shed,1),shed_id,"near")

# Route-completion landmark: a tiny community garden and plaza corner. Its
# bench and planting beds communicate arrival and rest without reward symbols.
garden=collections["PR_V04_Landmark_Garden_Plaza"]
garden_id="garden_or_plaza"
for idx,x in enumerate((-11.0,-7.65)):
    mark_landmark(cyl(f"PR_V04_Landmark_Garden_Trellis_Post_{idx}",(x,23.6,2.0),.12,3.65,bamboo,garden,10),garden_id,"far")
mark_landmark(box("PR_V04_Landmark_Garden_Trellis_Beam",(-9.32,23.6,3.72),(3.75,.24,.24),bamboo,garden,.04),garden_id,"far")
for idx,x in enumerate((-10.72,-9.78,-8.84,-7.90)):
    mark_landmark(ico(f"PR_V04_Landmark_Garden_Trellis_Leaf_{idx}",(x,23.48,3.66),(.52,.34,.38),leaf_light if idx%2 else leaf,garden,1),garden_id,"far")
mark_landmark(ico("PR_V04_Landmark_Garden_Back_Shrub",(-10.35,24.1,1.20),(1.20,.70,.82),leaf,garden,2),garden_id,"far")

mark_landmark(box("PR_V04_Landmark_Garden_Plaza_Base",(-9.30,22.8,.18),(4.85,3.7,.28),cream,garden,.07),garden_id,"mid")
for idx,x in enumerate((-10.48,-8.18)):
    mark_landmark(box(f"PR_V04_Landmark_Garden_Raised_Bed_{idx}",(x,22.25,.55),(1.75,1.05,.58),earth,garden,.05),garden_id,"mid")
    for plant_idx,px in enumerate((x-.48,x,x+.48)):
        mark_landmark(ico(f"PR_V04_Landmark_Garden_Plant_{idx}_{plant_idx}",(px,22.10,.94),(.28,.24,.34),leaf_light if plant_idx%2 else leaf,garden,1),garden_id,"mid")
        mark_landmark(ico(f"PR_V04_Landmark_Garden_Flower_{idx}_{plant_idx}",(px,22.02,1.15),(.08,.07,.08),flower if plant_idx%2 else mango,garden,1),garden_id,"mid")
mark_landmark(box("PR_V04_Landmark_Garden_Bench",(-9.30,24.10,.68),(2.65,.46,.18),wood,garden,.04),garden_id,"mid")
for idx,x in enumerate((-10.18,-8.42)):
    mark_landmark(box(f"PR_V04_Landmark_Garden_Bench_Leg_{idx}",(x,24.10,.40),(.14,.24,.50),wood,garden,.02),garden_id,"mid")

mark_landmark(shadow_disc("PR_V04_Landmark_Garden_Grounded_Shadow",(-9.30,22.8,.025),(3.0,2.0),garden),garden_id,"near")
mark_landmark(box("PR_V04_Landmark_Garden_Curb_Detail",(-6.88,22.15,.16),(.34,3.20,.28),mango,garden,.03),garden_id,"near")
for idx,(x,y) in enumerate(((-11.30,21.65),(-7.32,21.65))):
    mark_landmark(cyl(f"PR_V04_Landmark_Garden_Pot_{idx}",(x,y,.34),.29,.54,coral,garden,10),garden_id,"near")
    mark_landmark(ico(f"PR_V04_Landmark_Garden_Potted_Plant_{idx}",(x,y,.82),(.42,.34,.48),leaf_light,garden,1),garden_id,"near")

# Remaining civic details.
box("PR_V04_Notice_Board",(-7.45,18.0,1.35),(2.2,.18,1.8),wood,street,.04,"roadside")
box("PR_V04_Notice_Insert",(-7.45,17.87,1.38),(1.8,.06,1.40),cream,street,.02,"roadside")
# Decorative bicycle safely outside road.
for idx,x in enumerate((7.45,8.35)):
    cyl(f"PR_V04_Bicycle_Wheel_{idx}",(x,-5.6,.55),.42,.07,ink,street,20,(math.radians(90),0,0),"roadside")
box("PR_V04_Bicycle_Frame",(7.9,-5.60,.75),(.95,.08,.08),coral,street,.01,"roadside")
box("PR_V04_Bicycle_Handle",(8.30,-5.60,1.03),(.08,.08,.55),ink,street,.01,"roadside")
# Water containers, baskets and road leaves.
for idx,(x,y) in enumerate(((-7.3,-5.8),(7.25,3.0),(-7.4,15.0))):
    cyl(f"PR_V04_Water_Container_{idx}",(x,y,.55),.30,1.0,water_blue,street,12,export_group="roadside")
for idx,(x,y) in enumerate(((-6.9,4.2),(6.85,11.8),(-6.75,22.0))):
    ico(f"PR_V04_Road_Leaf_{idx}",(x,y,.08),(.16,.34,.04),leaf_light,street,1,"roadside")

# Dedicated vegetation and side-framing set. Static trunks, pots, fences, and
# inner foliage render separately from the leaf pieces intended for a very slow
# Godot sway. Every world-space plant remains outside x +/-7.0, and the two
# camera-space overlays are restricted to the outer 12.5 percent of the frame.
vegetation=collections["PR_V04_PlantsAndForeground"]
VEG_BASE="plants_foreground"
VEG_SWAY="plant_sway_overlay"

# Broadleaf trees use irregular clustered crowns rather than repeated balls.
for tree_idx,(x,y,height) in enumerate(((-9.7,9.5,5.0),(9.6,14.5,5.5),(-10.1,24.0,4.8))):
    cyl(f"PR_V04_PF_Broadleaf_Trunk_{tree_idx}",(x,y,height*.46),.20,height*.82,bamboo,vegetation,10,export_group=VEG_BASE)
    ico(f"PR_V04_PF_Broadleaf_Core_{tree_idx}",(x,y,height*.92),(1.18,.82,.82),leaf,vegetation,2,VEG_BASE)
    for leaf_idx,(dx,dz,sx,sz) in enumerate(((-.88,.12,.72,.48),(-.42,.62,.78,.54),(.30,.70,.84,.56),(.94,.18,.70,.46),(.20,-.08,.92,.50))):
        ico(f"PR_V04_ANIM_PF_Broadleaf_Leaf_{tree_idx}_{leaf_idx}",(x+dx,y-.03,height+dz),(sx,.32,sz),leaf_light if leaf_idx%2 else leaf,vegetation,1,VEG_SWAY)

# Two calm coconut silhouettes, deliberately staggered and kept below the
# tower sightline by their side placement.
for palm_idx,(x,y,height,lean) in enumerate(((-9.2,-.8,5.8,-.12),(9.8,22.0,6.1,.10))):
    trunk=cyl(f"PR_V04_PF_Coconut_Trunk_{palm_idx}",(x,y,height*.46),.18,height*.88,bamboo,vegetation,12,export_group=VEG_BASE)
    trunk.rotation_euler.y=lean
    ico(f"PR_V04_PF_Palm_Heart_{palm_idx}",(x,y,height*.91),(.42,.36,.34),leaf,vegetation,1,VEG_BASE)
    for frond_idx,angle in enumerate((-72,-38,-8,24,58,92)):
        radians=math.radians(angle)
        frond=ico(f"PR_V04_ANIM_PF_Palm_Frond_{palm_idx}_{frond_idx}",(x+math.sin(radians)*.86,y-.04,height+math.cos(radians)*.16),(.24,1.14,.13),leaf if frond_idx%2 else leaf_light,vegetation,1,VEG_SWAY)
        frond.rotation_euler.z=radians

# Banana clusters: each leaf is its own animation-ready object.
for banana_idx,(x,y) in enumerate(((-8.25,-5.3),(8.15,5.8),(-8.45,17.0))):
    for stem_idx,offset in enumerate((-.28,.0,.30)):
        cyl(f"PR_V04_PF_Banana_Stem_{banana_idx}_{stem_idx}",(x+offset,y,1.12+stem_idx*.08),.10,2.15,bamboo,vegetation,10,export_group=VEG_BASE)
    for leaf_idx,angle in enumerate((-70,-42,-15,18,48,76)):
        radians=math.radians(angle)
        blade=ico(f"PR_V04_ANIM_PF_Banana_Leaf_{banana_idx}_{leaf_idx}",(x+math.sin(radians)*.56,y-.03,2.28+math.cos(radians)*.17),(.17,.78,.10),leaf_light if leaf_idx%2 else leaf,vegetation,1,VEG_SWAY)
        blade.rotation_euler.z=radians

# Layered verge shrubs, calamansi-like plants, flowering pots, and garden pots.
for side in (-1,1):
    for shrub_idx,y in enumerate((-7.2,2.6,12.0,20.5,27.0)):
        x=side*(7.45+.30*((shrub_idx+1)%2))
        ico(f"PR_V04_PF_Shrub_{side}_{shrub_idx}",(x,y,.55),(.62,.48,.48),leaf if shrub_idx%2 else leaf_light,vegetation,2,VEG_BASE)
        if shrub_idx in (1,3):
            for fruit_idx,dx in enumerate((-.22,.0,.22)):
                ico(f"PR_V04_PF_Calamansi_{side}_{shrub_idx}_{fruit_idx}",(x+dx,y-.12,.76+abs(dx)),(.09,.08,.08),mango,vegetation,1,VEG_BASE)
    for pot_idx,y in enumerate((-4.2,7.0,16.1,25.0)):
        x=side*(7.18+.22*(pot_idx%2))
        cyl(f"PR_V04_PF_Garden_Pot_{side}_{pot_idx}",(x,y,.30),.29,.50,coral if pot_idx%2 else earth,vegetation,10,export_group=VEG_BASE)
        ico(f"PR_V04_PF_Potted_Plant_{side}_{pot_idx}",(x,y,.76),(.38,.31,.42),leaf_light,vegetation,1,VEG_BASE)
        for flower_idx,dx in enumerate((-.18,0,.18)):
            ico(f"PR_V04_PF_Flower_{side}_{pot_idx}_{flower_idx}",(x+dx,y-.05,.98+flower_idx*.05),(.08,.07,.08),flower if flower_idx%2 else mango,vegetation,1,VEG_BASE)

# Static camera-edge fence pieces provide depth without entering the road.
for side,label in ((-1,"Left"),(1,"Right")):
    x0=24 if side<0 else 936
    screen_mesh(f"PR_V04_PF_Foreground_Fence_Post_{label}",[(x0-9,365),(x0+9,365),(x0+11,540),(x0-11,540)],64.0,bamboo,vegetation,VEG_BASE)
    for rail_idx,y in enumerate((410,475)):
        if side<0:
            points=[(0,y-7),(112,y+18),(112,y+31),(0,y+5)]
        else:
            points=[(960,y-7),(848,y+18),(848,y+31),(960,y+5)]
        screen_mesh(f"PR_V04_PF_Foreground_Fence_Rail_{label}_{rail_idx}",points,63.9-rail_idx*.02,wood,vegetation,VEG_BASE)

# Independent transparent leaf overlays. Their screen bounds keep the centre
# 720 pixels completely clear for Peter, prompts, and active props.
for side,label in ((-1,"Left"),(1,"Right")):
    for leaf_idx,(edge_x,y,rx,ry) in enumerate(((22,382,42,13),(58,420,55,15),(92,486,47,14),(35,525,58,16))):
        cx=edge_x if side<0 else W-edge_x
        ellipse(f"PR_V04_ANIM_PF_Sway_Overlay_{label}_{leaf_idx}",cx,y,rx,ry,63.5-leaf_idx*.03,leaf_light if leaf_idx%2 else leaf,vegetation,VEG_SWAY,28)

# Foreground leaves and fence edges stay at extreme sides.
fg=collections["PR_V04_Foreground"]
for side in (-1,1):
    cyl(f"PR_V04_Foreground_Fence_{side}",(side*9.6,-10.5,1.8),.16,3.6,bamboo,fg,10,export_group="foreground")
    for idx,(z,ang) in enumerate(((1.0,55),(2.0,18),(3.0,-35))):
        obj=ico(f"PR_V04_ANIM_Foreground_Leaf_{side}_{idx}",(side*(8.6+idx*.35),-11.0,z),(.40,1.25,.18),leaf if idx%2 else leaf_light,fg,1,"foreground")
        obj.rotation_euler.y=math.radians(ang*side)

# Separate animation-ready light overlays.
ellipse("PR_V04_ANIM_Sun_Soft_Glow",610,132,115,115,69,glow_mat,light_coll,"light_overlay")
ellipse("PR_V04_ANIM_Landmark_Progress_Glow",480,210,175,105,68.8,glow_mat,light_coll,"light_overlay")
for idx,(x,y) in enumerate(((360,197),(430,190),(530,188),(595,200))):
    ellipse(f"PR_V04_ANIM_Window_Glint_{idx}",x,y,9,4,68.6,capiz,light_coll,"light_overlay",24)

# Keep the nearest ordinary homes comfortably below half the landmark's apparent
# height.  Scaling is around each home's own ground contact, so origins remain
# stable and the six-building street composition stays asymmetric.
def scale_named_group(prefixes, origin, factor):
    anchor=Vector(origin)
    for obj in bpy.data.objects:
        if any(obj.name.startswith(prefix) for prefix in prefixes):
            obj.location=anchor+(obj.location-anchor)*factor
            obj.scale*=factor

scale_named_group(("PR_V04_Bungalow_",),(-9.0,3.3,0),.62)
scale_named_group(("PR_V04_Sawali_",),(8.6,6.0,0),.64)

# Modular Godot house art is authored on an off-camera asset stage. Each
# collection contains a deliberately rearranged left- and right-facing model;
# export cameras provide far, mid, and near scale variants without duplicating
# geometry. Component tags create clean transparent layers for animation and
# parallax assembly.
HOUSE_STAGE_CENTERS = {
    ("concrete", "left"): (45.0, 0.0),
    ("concrete", "right"): (60.0, 0.0),
    ("sawali", "left"): (45.0, 12.0),
    ("sawali", "right"): (60.0, 12.0),
    ("coralroof", "left"): (45.0, 24.0),
    ("coralroof", "right"): (60.0, 24.0),
    ("residence", "left"): (45.0, 36.0),
    ("residence", "right"): (60.0, 36.0),
}


def build_concrete_house(facing, center):
    house_id="concrete"; coll=collections[HOUSE_COLLECTIONS[house_id]]
    cx,cy=center; side=-1 if facing=="left" else 1
    mark_house(shadow_disc(f"PR_House_Concrete_{facing}_Shadow",(cx,cy,.02),(3.25,2.15),coll),house_id,facing,"shadows")
    mark_house(box(f"PR_House_Concrete_{facing}_MainWall",(cx,cy,1.72),(4.75,3.55,3.20),cream,coll,.08),house_id,facing,"facade")
    mark_house(box(f"PR_House_Concrete_{facing}_SunlitSide",(cx-side*2.26,cy-.05,1.80),(.34,3.30,2.95),sunlit_cream,coll,.04),house_id,facing,"facade")
    mark_house(box(f"PR_House_Concrete_{facing}_CoolSide",(cx+side*2.27,cy+.08,1.76),(.32,3.22,2.88),cool_wall,coll,.04),house_id,facing,"facade")
    mark_house(roof(f"PR_House_Concrete_{facing}_LowRoof",(cx,cy,3.34),5.35,4.05,.62,corrugated,coll),house_id,facing,"roof")
    door_x=cx+side*1.22
    mark_house(box(f"PR_House_Concrete_{facing}_TealDoor",(door_x,cy-1.81,1.35),(.86,.12,2.22),deep_teal,coll,.04),house_id,facing,"facade")
    for idx,x in enumerate((cx-side*.25,cx-side*1.20)):
        mark_house(box(f"PR_House_Concrete_{facing}_CapizWindow_{idx}",(x,cy-1.82,1.85),(.72,.10,.92),capiz,coll,.025),house_id,facing,"windows")
        mark_house(box(f"PR_House_Concrete_{facing}_WindowShade_{idx}",(x,cy-1.92,2.40),(.88,.34,.10),mango,coll,.02),house_id,facing,"windows")
    mark_house(box(f"PR_House_Concrete_{facing}_Veranda",(cx,cy-2.03,.48),(4.45,.98,.20),concrete,coll,.05),house_id,facing,"veranda_fence")
    for idx,x in enumerate((cx-1.92,cx+1.92)):
        mark_house(cyl(f"PR_House_Concrete_{facing}_VerandaPost_{idx}",(x,cy-2.00,1.40),.08,1.72,bamboo,coll,10),house_id,facing,"veranda_fence")
    plant_x=cx-side*2.02
    mark_house(cyl(f"PR_House_Concrete_{facing}_Pot",(plant_x,cy-2.18,.34),.31,.56,coral,coll,10),house_id,facing,"plants")
    mark_house(ico(f"PR_House_Concrete_{facing}_Plant",(plant_x,cy-2.18,.86),(.48,.38,.52),leaf_light,coll,1),house_id,facing,"plants")


def build_sawali_house(facing, center):
    house_id="sawali"; coll=collections[HOUSE_COLLECTIONS[house_id]]
    cx,cy=center; side=-1 if facing=="left" else 1
    mark_house(shadow_disc(f"PR_House_Sawali_{facing}_Shadow",(cx,cy,.02),(3.25,2.15),coll),house_id,facing,"shadows")
    for idx,x in enumerate((cx-1.72,cx+1.72)):
        mark_house(cyl(f"PR_House_Sawali_{facing}_TimberSupport_{idx}",(x,cy,.88),.14,1.65,wood,coll,10),house_id,facing,"facade")
    mark_house(box(f"PR_House_Sawali_{facing}_RaisedCore",(cx,cy,2.25),(4.55,3.50,2.85),sawali,coll,.06),house_id,facing,"facade")
    # Large crossed strips remain legible after downscaling and suggest woven sawali.
    for idx,xoff in enumerate((-1.40,-.70,0,.70,1.40)):
        strip=box(f"PR_House_Sawali_{facing}_WeaveA_{idx}",(cx+xoff,cy-1.79,2.28),(1.05,.07,.11),bamboo,coll,.01)
        strip.rotation_euler.y=math.radians(38)
        mark_house(strip,house_id,facing,"facade")
        strip=box(f"PR_House_Sawali_{facing}_WeaveB_{idx}",(cx+xoff,cy-1.785,2.28),(1.05,.07,.11),wood,coll,.01)
        strip.rotation_euler.y=math.radians(-38)
        mark_house(strip,house_id,facing,"facade")
    mark_house(roof(f"PR_House_Sawali_{facing}_LightRoof",(cx,cy,3.70),5.35,4.20,.84,light_corrugated,coll),house_id,facing,"roof")
    door_x=cx+side*1.20
    window_x=cx-side*.72
    mark_house(box(f"PR_House_Sawali_{facing}_Door",(door_x,cy-1.80,2.05),(.82,.10,1.95),deep_teal,coll,.035),house_id,facing,"facade")
    mark_house(box(f"PR_House_Sawali_{facing}_Window",(window_x,cy-1.81,2.45),(1.18,.09,.82),capiz,coll,.025),house_id,facing,"windows")
    mark_house(box(f"PR_House_Sawali_{facing}_ClothAwning",(window_x,cy-2.04,3.02),(1.58,.72,.14),coral,coll,.04),house_id,facing,"windows")
    mark_house(box(f"PR_House_Sawali_{facing}_RaisedEntry",(door_x,cy-2.10,1.12),(1.38,.92,.18),wood,coll,.03),house_id,facing,"veranda_fence")
    for idx,z in enumerate((.30,.52,.74)):
        mark_house(box(f"PR_House_Sawali_{facing}_Step_{idx}",(door_x,cy-2.48-idx*.25,z),(1.12,.42,.18),wood,coll,.025),house_id,facing,"veranda_fence")
    plant_x=cx-side*2.05
    mark_house(cyl(f"PR_House_Sawali_{facing}_Pot",(plant_x,cy-2.02,.33),.29,.54,earth,coll,10),house_id,facing,"plants")
    mark_house(ico(f"PR_House_Sawali_{facing}_Plant",(plant_x,cy-2.02,.83),(.44,.35,.48),leaf,coll,1),house_id,facing,"plants")


def build_coral_house(facing, center):
    house_id="coralroof"; coll=collections[HOUSE_COLLECTIONS[house_id]]
    cx,cy=center; side=-1 if facing=="left" else 1
    mark_house(shadow_disc(f"PR_House_CoralRoof_{facing}_Shadow",(cx,cy,.02),(3.45,2.25),coll),house_id,facing,"shadows")
    mark_house(box(f"PR_House_CoralRoof_{facing}_PaleFacade",(cx,cy,1.82),(5.05,3.65,3.35),pale_green,coll,.09),house_id,facing,"facade")
    mark_house(box(f"PR_House_CoralRoof_{facing}_CreamTrim",(cx,cy-1.85,.52),(4.82,.18,.62),cream,coll,.03),house_id,facing,"facade")
    mark_house(roof(f"PR_House_CoralRoof_{facing}_MutedCoralRoof",(cx,cy,3.52),5.75,4.35,.90,coral,coll),house_id,facing,"roof")
    door_x=cx+side*1.62
    mark_house(box(f"PR_House_CoralRoof_{facing}_Door",(door_x,cy-1.88,1.40),(.82,.11,2.22),deep_teal,coll,.04),house_id,facing,"facade")
    for idx,x in enumerate((cx-side*.10,cx-side*1.20)):
        mark_house(box(f"PR_House_CoralRoof_{facing}_LargeWindow_{idx}",(x,cy-1.89,1.92),(1.00,.10,1.12),capiz,coll,.03),house_id,facing,"windows")
        mark_house(box(f"PR_House_CoralRoof_{facing}_WindowFrame_{idx}",(x,cy-1.95,1.92),(1.18,.08,1.30),deep_teal,coll,.025),house_id,facing,"windows")
        mark_house(box(f"PR_House_CoralRoof_{facing}_WindowInset_{idx}",(x,cy-2.00,1.92),(.92,.06,1.04),capiz,coll,.02),house_id,facing,"windows")
    fence_y=cy-2.28
    for idx,x in enumerate((cx-2.35,cx-1.55,cx-.75,cx+.75,cx+1.55,cx+2.35)):
        if abs(x-(cx+side*1.15))<.55:
            continue
        mark_house(cyl(f"PR_House_CoralRoof_{facing}_FencePost_{idx}",(x,fence_y,.70),.07,1.25,bamboo,coll,8),house_id,facing,"veranda_fence")
    mark_house(box(f"PR_House_CoralRoof_{facing}_FenceRail",(cx-side*.70,fence_y,.76),(3.45,.08,.10),bamboo,coll,.015),house_id,facing,"veranda_fence")
    gate_x=cx+side*1.15
    mark_house(box(f"PR_House_CoralRoof_{facing}_Gate",(gate_x,fence_y,.70),(1.02,.10,1.22),wood,coll,.025),house_id,facing,"veranda_fence")
    plant_x=cx-side*2.12
    mark_house(cyl(f"PR_House_CoralRoof_{facing}_BougainvilleaPot",(plant_x,cy-2.08,.36),.32,.58,coral,coll,10),house_id,facing,"plants")
    mark_house(ico(f"PR_House_CoralRoof_{facing}_BougainvilleaLeaf",(plant_x,cy-2.08,1.00),(.60,.44,.70),leaf,coll,2),house_id,facing,"plants")
    for idx,dx in enumerate((-.28,0,.28)):
        mark_house(ico(f"PR_House_CoralRoof_{facing}_BougainvilleaFlower_{idx}",(plant_x+dx,cy-2.16,1.25+abs(dx)),(.12,.10,.12),flower,coll,1),house_id,facing,"plants")


def build_residence(facing, center):
    house_id="residence"; coll=collections[HOUSE_COLLECTIONS[house_id]]
    cx,cy=center; side=-1 if facing=="left" else 1
    mark_house(shadow_disc(f"PR_House_Residence_{facing}_Shadow",(cx,cy,.02),(3.15,2.12),coll),house_id,facing,"shadows")
    mark_house(box(f"PR_House_Residence_{facing}_PaintedCore",(cx,cy,1.80),(4.45,3.45,3.30),painted_blue,coll,.08),house_id,facing,"facade")
    mark_house(box(f"PR_House_Residence_{facing}_ConcreteSide",(cx-side*1.78,cy-.05,1.75),(.88,3.25,3.08),cream,coll,.05),house_id,facing,"facade")
    mark_house(roof(f"PR_House_Residence_{facing}_Roof",(cx,cy,3.47),5.05,4.05,.72,corrugated,coll),house_id,facing,"roof")
    door_x=cx+side*1.28
    window_x=cx-side*.72
    mark_house(box(f"PR_House_Residence_{facing}_Door",(door_x,cy-1.77,1.40),(.82,.11,2.20),wood,coll,.04),house_id,facing,"facade")
    mark_house(box(f"PR_House_Residence_{facing}_Window",(window_x,cy-1.78,1.92),(1.22,.10,1.05),capiz,coll,.03),house_id,facing,"windows")
    mark_house(box(f"PR_House_Residence_{facing}_WindowAwning",(window_x,cy-2.02,2.58),(1.58,.72,.14),mango,coll,.04),house_id,facing,"windows")
    mark_house(box(f"PR_House_Residence_{facing}_Veranda",(cx,cy-1.98,.46),(4.05,.92,.18),concrete,coll,.04),house_id,facing,"veranda_fence")
    rail_x=cx-side*.62
    mark_house(box(f"PR_House_Residence_{facing}_VerandaRail",(rail_x,cy-2.38,1.02),(2.25,.09,.10),deep_teal,coll,.02),house_id,facing,"veranda_fence")
    for idx,x in enumerate((rail_x-1.03,rail_x,rail_x+1.03)):
        mark_house(box(f"PR_House_Residence_{facing}_RailPost_{idx}",(x,cy-2.37,.76),(.09,.09,.62),deep_teal,coll,.015),house_id,facing,"veranda_fence")
    bench_x=cx-side*1.28
    mark_house(box(f"PR_House_Residence_{facing}_OutdoorBench",(bench_x,cy-2.34,.58),(1.55,.42,.16),wood,coll,.03),house_id,facing,"veranda_fence")
    for idx,x in enumerate((bench_x-.55,bench_x+.55)):
        mark_house(box(f"PR_House_Residence_{facing}_BenchLeg_{idx}",(x,cy-2.34,.34),(.12,.20,.45),wood,coll,.02),house_id,facing,"veranda_fence")
    water_x=cx+side*2.06
    mark_house(cyl(f"PR_House_Residence_{facing}_WaterContainer",(water_x,cy-2.05,.58),.34,1.05,water_blue,coll,12),house_id,facing,"plants")
    plant_x=cx-side*2.02
    mark_house(cyl(f"PR_House_Residence_{facing}_Pot",(plant_x,cy-2.08,.33),.28,.52,earth,coll,10),house_id,facing,"plants")
    mark_house(ico(f"PR_House_Residence_{facing}_Plant",(plant_x,cy-2.08,.80),(.42,.34,.46),leaf_light,coll,1),house_id,facing,"plants")


for facing in ("left", "right"):
    build_concrete_house(facing,HOUSE_STAGE_CENTERS[("concrete",facing)])
    build_sawali_house(facing,HOUSE_STAGE_CENTERS[("sawali",facing)])
    build_coral_house(facing,HOUSE_STAGE_CENTERS[("coralroof",facing)])
    build_residence(facing,HOUSE_STAGE_CENTERS[("residence",facing)])

# Dedicated asset cameras and warm/cool light pairs produce transparent sprites
# with no viewport grid, grey editor background, or Blender UI.
HOUSE_CAMERAS={}
HOUSE_LIGHTS={}
for (house_id,facing),(cx,cy) in HOUSE_STAGE_CENTERS.items():
    target=Vector((cx,cy,1.65))
    for depth,distance in (("far",24.0),("mid",18.0),("near",16.0)):
        data=bpy.data.cameras.new(f"PR_House_{house_id}_{facing}_{depth}_Camera_Data")
        asset_camera=bpy.data.objects.new(f"PR_House_{house_id}_{facing}_{depth}_Camera",data)
        asset_camera.location=(cx,cy-distance,5.6)
        asset_camera.rotation_euler=(target-asset_camera.location).to_track_quat("-Z","Y").to_euler()
        data.lens=50
        data.sensor_width=36
        data.clip_end=150
        HOUSE_CAMERAS[(house_id,facing,depth)]=asset_camera
    key_data=bpy.data.lights.new(f"PR_House_{house_id}_{facing}_Key_Data","AREA")
    key_data.energy=1050; key_data.color=(1.0,.64,.36); key_data.size=6
    asset_key=bpy.data.objects.new(f"PR_House_{house_id}_{facing}_Key",key_data)
    asset_key.location=(cx-4.5,cy-7.0,10.5)
    asset_key.rotation_euler=(target-asset_key.location).to_track_quat("-Z","Y").to_euler()
    fill_data=bpy.data.lights.new(f"PR_House_{house_id}_{facing}_Fill_Data","AREA")
    fill_data.energy=520; fill_data.color=(.22,.56,.66); fill_data.size=7
    asset_fill=bpy.data.objects.new(f"PR_House_{house_id}_{facing}_Fill",fill_data)
    asset_fill.location=(cx+5.0,cy-4.0,7.0)
    asset_fill.rotation_euler=(target-asset_fill.location).to_track_quat("-Z","Y").to_euler()
    HOUSE_LIGHTS[(house_id,facing)]=(asset_key,asset_fill)

# Build independent aligned render scenes by object export tags.
support_lights=[key,fill]
all_source_objects=[obj for coll in collections.values() for obj in coll.objects]
for layer,filename in EXPORTS:
    render_scene=bpy.data.scenes.new("PR_V04_EXPORT_"+layer.upper())
    render_scene.render.engine="BLENDER_EEVEE"
    render_scene.render.resolution_x=W; render_scene.render.resolution_y=H
    render_scene.render.resolution_percentage=100
    render_scene.render.image_settings.file_format="PNG"
    render_scene.render.image_settings.color_mode="RGBA"
    render_scene.render.image_settings.compression=18
    render_scene.render.film_transparent=layer!="sky"
    render_scene.view_settings.view_transform=scene.view_settings.view_transform
    render_scene.view_settings.look=scene.view_settings.look
    render_scene.world=scene.world
    content=bpy.data.collections.new("PR_V04_EXPORT_CONTENT_"+layer.upper())
    render_scene.collection.children.link(content)
    landmark_rule=LANDMARK_LAYERS.get(layer)
    house_rule=HOUSE_LAYER_RULES.get(layer)
    for obj in all_source_objects:
        include=obj.get("export_group","")==layer
        if landmark_rule:
            landmark_id,parallax_depth=landmark_rule
            include=(obj.get("landmark_id")==landmark_id and
                     (parallax_depth is None or obj.get("parallax_depth")==parallax_depth))
        if house_rule:
            house_id,facing,component,depth=house_rule
            include=(obj.get("house_id")==house_id and
                     obj.get("house_facing")==facing and
                     (component is None or obj.get("house_component")==component))
        if include:
            content.objects.link(obj)
    support=bpy.data.collections.new("PR_V04_EXPORT_SUPPORT_"+layer.upper())
    render_scene.collection.children.link(support)
    if house_rule:
        house_id,facing,component,depth=house_rule
        render_camera=HOUSE_CAMERAS[(house_id,facing,depth)]
        render_lights=HOUSE_LIGHTS[(house_id,facing)]
        render_scene["asset_kind"]="house"
        render_scene["house_id"]=house_id
        render_scene["house_facing"]=facing
        render_scene["house_scale_variant"]=depth
        render_scene["house_component"]=component or "composite"
    else:
        render_camera=camera
        render_lights=support_lights
    support.objects.link(render_camera)
    for lamp in render_lights: support.objects.link(lamp)
    render_scene.camera=render_camera
    render_scene["output_filename"]=filename
    render_scene["transparent_background"]=layer!="sky"

scene["fresh_reset"]="No previous environment objects, proportions, colors, or layouts reused"
scene["lane_count"]=3
scene["base_canvas"]="480x270; authored at exact 2x 960x540"
scene["safe_zone"]="lower central road and prompt corridor clear"
scene["animation_ready"]="clouds, leaves, banana leaves, laundry, awning, sign, glints, sun glow, birds, market light"
scene["pause_contract"]="All Godot transforms/tweens must stop when Pause is active"
scene["route_landmark_sequence"]="barangay_entry -> sari_sari -> garden_or_plaza"
scene["route_landmark_support"]="waiting_shed is a calm completion-approach rest point"
scene["route_progression_contract"]="repetition-gated reveal/pass; neighbourhood continuation; no score, rank, streak, countdown, trophy, stars, or coins"
scene["house_asset_collections"]="PR_House_Concrete, PR_House_Sawali, PR_House_CoralRoof, PR_House_Residence"
scene["house_asset_variants"]="left/right modular arrangements; far/mid/near transparent renders; separated roof/facade/windows/veranda-fence/plants/shadows"

bpy.context.window.scene=scene
bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH,check_existing=False)
print("SAVED",BLEND_PATH)
print("COLLECTIONS",len(COLLECTION_NAMES))
print("OBJECTS",len(bpy.data.objects))
