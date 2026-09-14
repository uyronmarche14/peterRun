"""Build and render original L01 2.5D source layers from the authored Blender route.

Run with Blender opened on Peter_Run_L01_2p5D_Obstacle_Source.blend.
Raw renders stay in generated/; this script does not modify the game.
"""
import bpy
import math
import os
from mathutils import Vector


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "Peter_Run_Visual_Production", "generated", "l01_v03_raw")
BLEND = os.path.join(ROOT, "Peter_Run_Visual_Production", "L01_Barangay_Morning_Visual_Source_v03.blend")
os.makedirs(RAW, exist_ok=True)
scene = bpy.context.scene
camera = bpy.data.objects["RouteCamera_Export"]
scene.camera = camera
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = 960
scene.render.resolution_y = 540
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.film_transparent = True
scene.view_settings.view_transform = "Standard"
scene.view_settings.look = "Medium High Contrast"
scene.render.image_settings.compression = 20

source = bpy.data.collections["PETER_RUN_L01_ROUTE_3D"]
details = bpy.data.collections.new("L01_V03_Illustrated_Details")
scene.collection.children.link(details)
sky_collection = bpy.data.collections.new("L01_V03_Sky")
scene.collection.children.link(sky_collection)
landmarks = {}
for name in ("entrance", "store", "waiting_shed", "market", "garden"):
    coll = bpy.data.collections.new("L01_V03_Landmark_" + name)
    scene.collection.children.link(coll)
    landmarks[name] = coll


def mat(name, rgb, emission=False):
    material = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    material.diffuse_color = (*rgb, 1.0)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.9
        if emission:
            bsdf.inputs["Emission Color"].default_value = (*rgb, 1.0)
            bsdf.inputs["Emission Strength"].default_value = 0.35
    return material


cream = mat("L01V03_Cream_Painted_Concrete", (0.81, 0.70, 0.52))
white = mat("L01V03_Capiz_Glow", (1.0, 0.87, 0.59), True)
teal = mat("L01V03_Muted_Teal", (0.16, 0.39, 0.39))
wood = mat("L01V03_Warm_Wood", (0.45, 0.25, 0.15))
bamboo = mat("L01V03_Bamboo", (0.64, 0.50, 0.27))
coral = mat("L01V03_Coral", (0.67, 0.33, 0.27))
leaf = mat("L01V03_Leaf", (0.19, 0.43, 0.33))
leaf_light = mat("L01V03_Sunlit_Leaf", (0.32, 0.55, 0.38))
earth = mat("L01V03_Road_Earth", (0.48, 0.51, 0.43))
earth_light = mat("L01V03_Road_Patch", (0.54, 0.56, 0.47))
ink = mat("L01V03_Outline", (0.14, 0.22, 0.22))
haze = mat("L01V03_Atmospheric_Hill", (0.48, 0.62, 0.52))


def cube(name, loc, dims, material, layer="mid", collection=details):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    for old in tuple(obj.users_collection):
        old.objects.unlink(obj)
    collection.objects.link(obj)
    obj["l01_layer"] = layer
    bevel = obj.modifiers.new("Soft_Edge", "BEVEL")
    bevel.width = 0.025
    bevel.segments = 1
    obj.modifiers.new("Weighted_Normal", "WEIGHTED_NORMAL")
    return obj


def ico(name, loc, scale, material, layer="roadside", collection=details):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    obj.data.materials.append(material)
    for old in tuple(obj.users_collection):
        old.objects.unlink(obj)
    collection.objects.link(obj)
    obj["l01_layer"] = layer
    return obj


# Pull the original oversized near houses back into a small-place scale.
for side in (-1, 1):
    for index in (0, 1):
        house = bpy.data.objects[f"Route_House_{side}_{index}"]
        pivot = Vector((house.location.x, house.location.y, 0.0))
        factor = 0.76 if index == 0 else 0.82
        for part in (f"Route_House_{side}_{index}", f"Route_Roof_{side}_{index}", f"Route_Window_{side}_{index}"):
            obj = bpy.data.objects[part]
            obj.location = pivot + (obj.location - pivot) * factor
            obj.scale *= factor
        x = house.location.x
        y = house.location.y
        front = y + 1.33 * factor
        # A complete front with door, capiz window, sill, shaded veranda and
        # sparse sawali strips remains legible after downsampling to 480x270.
        cube(f"House_{side}_{index}_Door", (x - side * 0.54, front + 0.02, 0.73),
             (0.47, 0.075, 1.43), teal)
        cube(f"House_{side}_{index}_DoorSill", (x - side * 0.54, front + 0.085, 0.08),
             (0.58, 0.18, 0.12), bamboo)
        cube(f"House_{side}_{index}_CapizWindow", (x + side * 0.43, front + 0.04, 1.43),
             (0.66, 0.07, 0.65), white)
        for offset in (-0.22, 0.0, 0.22):
            cube(f"House_{side}_{index}_CapizGrid_{offset}", (x + side * 0.43 + offset, front + 0.11, 1.43),
                 (0.035, 0.04, 0.69), wood)
        cube(f"House_{side}_{index}_WindowSill", (x + side * 0.43, front + 0.13, 1.08),
             (0.76, 0.22, 0.09), bamboo)
        cube(f"House_{side}_{index}_Veranda", (x, front + 0.36, 0.13),
             (2.3 * factor, 0.7, 0.16), cream)
        for row in (0, 1, 2):
            cube(f"House_{side}_{index}_Sawali_{row}", (x + side * 0.9, front + 0.07, 0.85 + row * 0.27),
                 (0.32, 0.035, 0.035), bamboo)
        # No microscopic readable text: shop identity is in awning and baskets.
        if side == -1 and index == 1:
            cube("SariSari_Awning", (x, front + 0.5, 2.1), (2.1, 0.88, 0.13), coral)
            cube("SariSari_Fascia", (x, front + 0.93, 2.01), (2.1, 0.08, 0.20), cream)
            for i in range(3):
                cube(f"SariSari_Shelf_{i}", (x + (i-1)*0.55, front + 0.82, 0.84),
                     (0.45, 0.30, 0.12), bamboo)

# Road material is visible but quiet. These marks do not read as hazards.
for i, (x, y, width) in enumerate((
    (-2.6, -19, .38), (2.2, -16, .43), (-.5, -12, .5), (2.9, -8, .4),
    (-2.8, -4, .45), (1.3, 0, .38), (-1.7, 3, .55))):
    cube(f"Road_Quiet_Material_{i}", (x, y, 0.133), (width, 0.58, 0.006),
         earth_light if i % 2 else earth, "road")
for side in (-1, 1):
    for i in range(7):
        cube(f"Sidewalk_Paver_{side}_{i}", (side * 4.79, -21 + i * 4.0, 0.158),
             (0.58, 0.045, 0.008), cream, "road")
    for i, y in enumerate((-1.8, -6.5, -12.0, -17.5)):
        x = side * (5.45 + (i % 2) * .27)
        cube(f"Roadside_Pot_{side}_{i}", (x, y, 0.35), (.4, .4, .58), coral, "roadside")
        ico(f"Roadside_Plant_{side}_{i}", (x, y, .87), (.32, .36, .5),
            leaf_light if i % 2 else leaf)

# A side laundry rail is a domestic cue, not an obstacle; keep it off the road.
for side in (-1, 1):
    x = side * 6.2
    y = -14.0 if side == -1 else -3.0
    cube(f"Side_Laundry_Rail_{side}", (x, y, 2.3), (.045, 2.1, .045), bamboo, "roadside")
    for i in range(3):
        cube(f"Side_Laundry_Cloth_{side}_{i}", (x, y - .7 + i*.65, 1.93),
             (.045, .48, .67), (cream, teal, coral)[i], "roadside")

# New roof clusters and low hills replace the flat dark horizon strip.
for obj in source.objects:
    if obj.name in ("Barangay_Wire", "Barangay_Wire.001", "Route_Distant_Green"):
        obj.hide_render = True
for i in range(9):
    x = -19.0 + i*4.75
    y = -27.0 - (i % 3)*1.5
    height = 1.25 + (i % 4)*.25
    cube(f"Far_Roof_Block_{i}", (x, y, height*.5),
         (2.25, 1.7, height), cream if i % 2 else teal, "far")
    roof_mesh = bpy.data.meshes.new(f"Far_Pitched_Roof_Mesh_{i}")
    rw, rd = 1.28 + (i % 2)*.18, 1.08
    roof_mesh.from_pydata([
        (x-rw,y-rd,height),(x+rw,y-rd,height),(x,y-rd,height+.44),
        (x-rw,y+rd,height),(x+rw,y+rd,height),(x,y+rd,height+.44)],
        [],[(0,1,2),(3,5,4),(0,2,5,3),(1,4,5,2)])
    roof_mesh.materials.append(coral if i % 3 else wood)
    roof_obj = bpy.data.objects.new(f"Far_Pitched_Roof_{i}",roof_mesh)
    details.objects.link(roof_obj)
    roof_obj["l01_layer"]="far"
    cube(f"Far_Door_{i}", (x-.43,y+.88,.44),
         (.36,.04,.85), teal if i % 2 else wood, "far")
    cube(f"Far_Capiz_{i}", (x+.47,y+.88,.83),
         (.39,.04,.42), white, "far")
    cube(f"Far_Window_Sill_{i}", (x+.47,y+.93,.59),
         (.45,.11,.06), wood, "far")
    if i in (2, 6):
        cube(f"Far_Shop_Awning_{i}", (x,y+1.12,height*.82),
             (1.85,.65,.13), coral if i == 2 else teal, "far")
for i in range(9):
    x = -20 + i*5
    ico(f"Far_Hill_{i}", (x, -36, .35), (4.0, 1.6, 1.35 + (i % 3)*.28),
        haze if i % 2 else leaf_light, "far")

# Give the named houses breathing room inside the frame without encroaching
# on the lane edge. Market tables retain their road-safe original placement.
for obj in list(source.objects) + list(details.objects):
    if obj.name.startswith(("Route_House_", "Route_Roof_", "Route_Window_", "House_", "SariSari_")):
        obj.location.x += 1.05 if obj.location.x < 0 else -1.05
        side = -1 if obj.location.x < 0 else 1
        obj.location.x -= side*.75
        is_near_house = obj.name.startswith(("Route_House_-1_0", "Route_Roof_-1_0", "Route_Window_-1_0",
                                             "Route_House_1_0", "Route_Roof_1_0", "Route_Window_1_0",
                                             "House_-1_0", "House_1_0"))
        obj.location.y -= 5.0 if is_near_house else 3.0

# Five original low-poly silhouettes are authored in the source and exported
# separately. Godot reveals them only at repetition milestones.
cube("Landmark_Entrance_Post", (-5.2, -11.0, 1.45), (.18, .18, 2.9), wood,
     collection=landmarks["entrance"])
cube("Landmark_Entrance_Board", (-5.2, -11.0, 2.82), (1.8, .20, .48), cream,
     collection=landmarks["entrance"])
cube("Landmark_Entrance_Roof", (-5.2, -11.0, 3.15), (2.08, .35, .18), teal,
     collection=landmarks["entrance"])
for i in range(3):
    cube(f"Landmark_Store_Basket_{i}", (-5.4, -10.0-i*.58, .55), (.62, .47, .5),
         bamboo, collection=landmarks["store"])
    ico(f"Landmark_Store_Produce_{i}", (-5.4, -10.0-i*.58, .91),
        (.27, .25, .18), (coral, leaf_light, cream)[i], collection=landmarks["store"])
cube("Landmark_Shed_Roof", (5.5, -12.0, 2.28), (2.4, 1.3, .18), teal,
     collection=landmarks["waiting_shed"])
for x in (4.55, 6.45):
    cube(f"Landmark_Shed_Post_{x}", (x, -12.0, 1.1), (.11, .12, 2.15), bamboo,
         collection=landmarks["waiting_shed"])
cube("Landmark_Shed_Bench", (5.5, -11.6, .66), (2.1, .35, .18), wood,
     collection=landmarks["waiting_shed"])
for i in range(4):
    cube(f"Landmark_Market_Crate_{i}", (5.35+(i%2)*.7, -10.0+(i//2)*.65, .42),
         (.55, .48, .56), bamboo, collection=landmarks["market"])
    ico(f"Landmark_Market_Produce_{i}", (5.35+(i%2)*.7, -10.0+(i//2)*.65, .82),
        (.25, .25, .18), leaf_light if i%2 else coral, collection=landmarks["market"])
for i in range(5):
    x = -5.4 - (i%2)*.55
    y = -11.0 + i*.52
    ico(f"Landmark_Garden_Shrub_{i}", (x,y,.7), (.32,.32,.55),
        leaf_light if i%2 else leaf, collection=landmarks["garden"])
cube("Landmark_Garden_Rim", (-5.7,-10.0,.24), (1.8,2.6,.27), bamboo,
     collection=landmarks["garden"])

# Camera-local 2D planes are still Blender meshes, allowing a true source-art
# sky with a vertical gradient and very slow decorative cloud silhouettes.
frame = camera.data.view_frame(scene=scene)
factor = 120.0
left = min(v.x for v in frame)*factor
right = max(v.x for v in frame)*factor
bottom = min(v.y for v in frame)*factor
top = max(v.y for v in frame)*factor
depth = -max(abs(v.z) for v in frame)*factor
sky_mesh = bpy.data.meshes.new("L01V03_Sky_Gradient_Mesh")
sky_mesh.from_pydata([(left,bottom,depth),(right,bottom,depth),
                      (right,top,depth),(left,top,depth)], [], [(0,1,2,3)])
sky_mesh.update()
sky_obj = bpy.data.objects.new("L01V03_Sky_Gradient", sky_mesh)
sky_collection.objects.link(sky_obj)
sky_obj.matrix_world = camera.matrix_world
uv = sky_mesh.uv_layers.new()
for loop in sky_mesh.loops:
    idx = loop.vertex_index
    uv.data[loop.index].uv = ((0 if idx in (0,3) else 1),
                              (0 if idx in (0,1) else 1))
sky_mat = bpy.data.materials.new("L01V03_Morning_Sky_Gradient")
sky_mat.use_nodes = True
nodes = sky_mat.node_tree.nodes
nodes.clear()
tex = nodes.new("ShaderNodeTexCoord")
sep = nodes.new("ShaderNodeSeparateXYZ")
ramp = nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].position = 0.0
ramp.color_ramp.elements[0].color = (.54,.66,.55,1)
ramp.color_ramp.elements[1].position = 1.0
ramp.color_ramp.elements[1].color = (.36,.62,.72,1)
mid = ramp.color_ramp.elements.new(.37)
mid.color = (.64,.72,.62,1)
emit = nodes.new("ShaderNodeEmission")
out = nodes.new("ShaderNodeOutputMaterial")
links = sky_mat.node_tree.links
links.new(tex.outputs["UV"],sep.inputs[0])
links.new(sep.outputs["Y"],ramp.inputs[0])
links.new(ramp.outputs[0],emit.inputs["Color"])
links.new(emit.outputs[0],out.inputs[0])
sky_mesh.materials.append(sky_mat)
cloud_mat = mat("L01V03_Cloud_Cream", (.96,.92,.77), True)
cloud_mat.node_tree.nodes.get("Principled BSDF").inputs["Emission Strength"].default_value = .7
for i, (u,v,size) in enumerate(((.19,.78,.055),(.34,.89,.038),(.72,.77,.052),(.84,.91,.034))):
    for j,(dx,dy,scale) in enumerate(((-.4,0,.82),(0,.08,1.0),(.42,-.02,.75))):
        mesh = bpy.data.meshes.new(f"CloudMesh_{i}_{j}")
        cx = left+(right-left)*(u+dx*size)
        cy = bottom+(top-bottom)*(v+dy*size)
        rx = (right-left)*size*scale
        ry = (top-bottom)*size*.34*scale
        verts = [(cx+rx*math.cos(k*math.tau/12),
                  cy+ry*math.sin(k*math.tau/12),depth+.01) for k in range(12)]
        mesh.from_pydata(verts,[],[tuple(range(12))])
        mesh.materials.append(cloud_mat)
        obj=bpy.data.objects.new(f"Cloud_{i}_{j}",mesh)
        sky_collection.objects.link(obj)
        obj.matrix_world=camera.matrix_world

for i, (u,v,rx,ry) in enumerate(((.025,.13,.037,.019),(.064,.07,.028,.014),
                                  (.972,.17,.036,.018),(.944,.08,.027,.013))):
    mesh=bpy.data.meshes.new(f"ForegroundLeafMesh_{i}")
    cx=left+(right-left)*u
    cy=bottom+(top-bottom)*v
    vertices=[(cx+(right-left)*rx*math.cos(k*math.tau/8),
               cy+(top-bottom)*ry*math.sin(k*math.tau/8),depth+.02)
              for k in range(8)]
    mesh.from_pydata(vertices,[],[tuple(range(8))])
    mesh.materials.append(leaf_light if i%2 else leaf)
    obj=bpy.data.objects.new(f"Foreground_Leaf_{i}",mesh)
    details.objects.link(obj)
    obj.matrix_world=camera.matrix_world
    obj["l01_layer"]="foreground"


def route_layer(obj):
    name = obj.name
    if obj.get("l01_layer"):
        return obj["l01_layer"]
    if obj.name not in source.objects:
        return None
    if name.startswith(("Route_Road","Route_Sidewalk","Route_Curb","RouteLanePaint")):
        return "road"
    if name.startswith(("Route_House","Route_Roof","Route_Window","Palengke","Vendor","Neighbor","Trike")):
        return "mid"
    if name.startswith(("Route_Trunk","Route_Canopy","Route_Fence")):
        return "roadside"
    return None


# Keep older prop/showcase collections available for inspection, but open the
# new source blend on the route instead of displaying all three kits at once.
for old_name in ("Collection", "PETER_RUN_L01_PROP_KIT", "PETER_RUN_L01_LANE_FORMATIONS"):
    old_collection = bpy.data.collections.get(old_name)
    if old_collection:
        old_collection.hide_viewport = True
        old_collection.hide_render = True
for coll in landmarks.values():
    coll.hide_viewport = True
    coll.hide_render = True

# Save a clear, editable source. Only the named new blend is written.
bpy.ops.wm.save_as_mainfile(filepath=BLEND)
all_renderables = [o for o in bpy.data.objects if o.type not in ("CAMERA", "LIGHT")]
for layer in ("sky","clouds","far","mid","road","roadside","foreground"):
    for obj in all_renderables:
        visible = (
            (layer == "sky" and obj == sky_obj) or
            (layer == "clouds" and obj.name.startswith("Cloud_")) or
            (layer not in ("sky","clouds") and route_layer(obj) == layer
             and obj.name not in ("Route_Distant_Green",))
        )
        obj.hide_render = not visible
    # Clouds and backdrop remain opaque only on sky; all other layers retain alpha.
    scene.render.film_transparent = layer != "sky"
    scene.render.filepath = os.path.join(RAW, f"l01_v03_{layer}.png")
    bpy.ops.render.render(write_still=True)
    print("RENDERED",scene.render.filepath)
for name, coll in landmarks.items():
    coll.hide_render = False
    for obj in all_renderables:
        obj.hide_render = obj.name not in coll.objects
    scene.render.film_transparent = True
    scene.render.filepath = os.path.join(RAW, f"l01_v03_landmark_{name}.png")
    bpy.ops.render.render(write_still=True)
    print("RENDERED",scene.render.filepath)
    coll.hide_render = True
