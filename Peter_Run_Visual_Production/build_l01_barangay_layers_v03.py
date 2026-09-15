"""Build a camera-aligned, layered Blender source for L01 Barangay Morning.

Run against L01_Barangay_Morning_Models_v04.blend. This saves a NEW .blend;
the input source and Godot project are not modified. Each export layer is a
separate Blender scene sharing the exact route camera and 960x540 framing.
"""

import math
import os

import bpy
from mathutils import Vector


ROOT = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(ROOT, "L01_Barangay_Morning_Layered_Source_v03.blend")
if os.path.exists(OUTPUT):
    raise RuntimeError("Layered source already exists; refusing to overwrite")
master = bpy.data.scenes["L01_Barangay_Route_Source"]
master.name = "L01_Barangay_Morning_Master_v03"
bpy.context.window.scene = master
bpy.context.view_layer.update()
camera = master.camera
assert camera is not None and camera.data.type == "PERSP"
W, H = 960, 540
master.render.resolution_x = W
master.render.resolution_y = H
master.render.resolution_percentage = 100
master.render.image_settings.file_format = "PNG"
master.render.image_settings.color_mode = "RGBA"
master.render.engine = "BLENDER_EEVEE"
master.view_settings.view_transform = "Standard"
master.view_settings.look = "Medium High Contrast"


def material(name, rgb, alpha=1.0, roughness=.88):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, alpha)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    bsdf.inputs["Alpha"].default_value = alpha
    bsdf.inputs["Roughness"].default_value = roughness
    if alpha < 1 and hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "DITHERED"
    return mat


road_grey = material("L01V03_Warm_Grey_Road", (.48,.51,.46))
road_patch = material("L01V03_Quiet_Asphalt_Variation", (.53,.55,.49), .45)
road_seam = material("L01V03_Subtle_Road_Seam", (.35,.42,.39), .23)
teal_line = material("L01V03_Teal_Lane_Separator", (.24,.52,.50), .93)
mango_curb = material("L01V03_Mango_Curb_Edge", (.76,.60,.34), .91)
marker_cream = material("L01V03_Quiet_Side_Marker", (.86,.80,.60), .62)
leaf_dark = material("L01V03_Foreground_Leaf", (.21,.41,.33), .66)
verge_shadow = material("L01V03_Foreground_Verge_Shadow", (.14,.31,.27), .24)
faded_green = material("L01V03_Faded_Banana_Silhouette", (.41,.58,.48), .68)
bird_ink = material("L01V03_Tiny_Bird_Silhouette", (.31,.45,.43), .68)
wall_sand = material("L01V03_Sand_Painted_Concrete", (.77,.68,.51))
wall_coral = material("L01V03_Faded_Coral_Concrete", (.67,.49,.41))
wall_blue = material("L01V03_Faded_Teal_Concrete", (.46,.62,.59))
wall_cream = material("L01V03_Cream_Sawali_Wall", (.80,.73,.58))
roof_clay = material("L01V03_Clay_Roof", (.48,.31,.25))
roof_teal = material("L01V03_Painted_Teal_Roof", (.25,.42,.42))
bamboo = material("L01V03_Roadside_Bamboo", (.63,.49,.27))
bench_wood = material("L01V03_Waiting_Shed_Bench", (.41,.29,.20))


def new_layer_scene(layer):
    scene = bpy.data.scenes.new("L01_LAYER_" + layer.upper())
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = W
    scene.render.resolution_y = H
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.compression = 18
    scene.render.film_transparent = layer != "sky"
    scene.view_settings.view_transform = master.view_settings.view_transform
    scene.view_settings.look = master.view_settings.look
    scene.view_settings.exposure = master.view_settings.exposure
    scene.world = master.world
    coll = bpy.data.collections.new("L01V03_EXPORT_" + layer.upper())
    scene.collection.children.link(coll)
    master.collection.children.link(coll)
    support = bpy.data.collections.new("L01V03_" + layer.upper() + "_CAMERA_LIGHT_ONLY")
    scene.collection.children.link(support)
    support.objects.link(camera)
    for light in (o for o in master.objects if o.type == "LIGHT"):
        if light.name not in support.objects:
            support.objects.link(light)
    scene.camera = camera
    scene["export_layer"] = layer
    scene["shared_camera"] = camera.name
    scene["canvas_px"] = "960x540; downsample by exactly 2 to Godot 480x270"
    return scene, coll


layers = {name: new_layer_scene(name) for name in
          ("sky", "far", "mid", "near", "foreground", "road", "lane_overlay")}
source_objects = tuple(master.objects)

# Draw the existing four houses back into the frame. Nearby roofs become
# complete places rather than giant cropped edge blocks. Shift all authored
# doors, capiz windows, verandas, trim and sari-sari details with each house.
for side in (-1, 1):
    for index in (0, 1):
        dy = -2.5 if index == 0 else -3.4
        old = (f"Route_House_{side}_{index}", f"Route_Roof_{side}_{index}",
               f"Route_Window_{side}_{index}", f"House_{side}_{index}_",
               f"RouteV04_House_{side}_{index}_")
        for obj in source_objects:
            if obj.name in old[:3] or obj.name.startswith(old[3:]):
                obj.location.y += dy
for obj in source_objects:
    if obj.name.startswith(("SariSari_", "RouteV04_Store_")):
        obj.location.y -= 3.4

# Distinct roof/wall colours preserve a coherent muted palette while making
# the four small houses recognisably different at 480x270.
house_colours = ((-1,0,wall_sand,roof_clay),(-1,1,wall_cream,roof_teal),
                 (1,0,wall_blue,roof_teal),(1,1,wall_coral,roof_clay))
for side,index,wall,roof in house_colours:
    for prefix,mat in (("Route_House",wall),("Route_Roof",roof)):
        obj = bpy.data.objects.get(f"{prefix}_{side}_{index}")
        if obj and obj.type == "MESH":
            obj.data = obj.data.copy()
            obj.data.materials.clear()
            obj.data.materials.append(mat)

# Old single-pass road pieces are superseded by pixel-registered ground and
# lines below. Roadside sidewalks remain independent near-layer scenery.
old_road_prefixes = ("Route_Road_Surface", "Route_Curb_", "RouteLanePaint_",
                     "Road_Quiet_Material_", "Sidewalk_Paver_")
for obj in source_objects:
    if obj.name.startswith(old_road_prefixes):
        obj.hide_render = True


def source_layer(obj):
    name = obj.name
    if obj.type in {"CAMERA","LIGHT"} or obj.hide_render:
        return None
    collection_names = {c.name for c in obj.users_collection}
    allowed = {"PETER_RUN_L01_ROUTE_3D", "L01_V03_Illustrated_Details",
               "L01_V03_Sky", "L01_V04_Route_Architectural_Accents"}
    if not collection_names & allowed:
        return None
    if name == "L01V03_Sky_Gradient" or name.startswith("Cloud_"):
        return "sky"
    if name.startswith("Far_Hill_"):
        return "sky"
    if name.startswith(("Far_",)):
        return "far"
    if name.startswith("Foreground_Leaf_") or obj.get("l01_layer") == "foreground":
        return "foreground"
    if name.startswith(("Route_House_", "Route_Roof_", "Route_Window_",
                        "House_", "SariSari_", "Palengke_", "Vendor_", "Neighbor_",
                        "RouteV04_House_", "RouteV04_Store_")):
        return "mid"
    if name.startswith(("Route_Trunk_", "Route_Canopy_", "Route_Fence_",
                        "Route_Sidewalk_", "Roadside_", "Side_Laundry_",
                        "RouteV04_Drainage_", "RouteV04_Quiet_Curb_")):
        return "near"
    layer = obj.get("l01_layer")
    return {"far":"far","mid":"mid","roadside":"near"}.get(layer)


counts = {name: 0 for name in layers}
for obj in source_objects:
    layer = source_layer(obj)
    if layer:
        layers[layer][1].objects.link(obj)
        counts[layer] += 1


def cube(name, position, dimensions, mat, coll, bevel=.018):
    sx,sy,sz = (v/2 for v in dimensions)
    vertices = [(dx*sx,dy*sy,dz*sz)
                for dx in (-1,1) for dy in (-1,1) for dz in (-1,1)]
    faces = [(0,4,6,2),(1,3,7,5),(0,1,5,4),
             (2,6,7,3),(0,2,3,1),(4,5,7,6)]
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(vertices,[],faces)
    mesh.update()
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name,mesh)
    coll.objects.link(obj)
    obj.location = position
    if bevel:
        mod = obj.modifiers.new("Illustrated_Edge", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        obj.modifiers.new("Weighted_Normals", "WEIGHTED_NORMAL")
    return obj


def camera_local(px, py, depth):
    frame = camera.data.view_frame(scene=master)
    frame_depth = abs(frame[0].z)
    factor = depth/frame_depth
    left = min(v.x for v in frame)*factor
    right = max(v.x for v in frame)*factor
    bottom = min(v.y for v in frame)*factor
    top = max(v.y for v in frame)*factor
    return (left+(right-left)*px/W, top-(top-bottom)*py/H, -depth)


def screen_mesh(name, pixel_points, depth, mat, coll):
    verts = [camera_local(x,y,depth) for x,y in pixel_points]
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(verts,[],[tuple(range(len(verts)))])
    mesh.update()
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name,mesh)
    coll.objects.link(obj)
    obj.matrix_world = camera.matrix_world.copy()
    return obj


# Sparse route-scale birds and banana silhouettes add place without filling
# the horizon. These are Blender meshes in the common camera's image plane.
sky = layers["sky"][1]
far = layers["far"][1]
for i,(x,y) in enumerate(((737,91),(753,100),(766,88))):
    screen_mesh(f"L01V03_Tiny_Bird_{i}_Left",[(x-4,y),(x,y+2),(x+1,y+1),(x-4,y-1)],
                105,bird_ink,sky)
    screen_mesh(f"L01V03_Tiny_Bird_{i}_Right",[(x,y+2),(x+5,y-1),(x+5,y),(x+1,y+1)],
                105,bird_ink,sky)
for side,(x,y) in enumerate(((132,187),(835,179))):
    screen_mesh(f"L01V03_Banana_{side}_Stem",[(x-2,y+21),(x+2,y+21),(x+1,y-11),(x-1,y-11)],
                45,faded_green,far)
    for dx,dy,sign in ((-22,-17,-1),(0,-25,0),(22,-18,1)):
        screen_mesh(f"L01V03_Banana_{side}_Leaf_{dx}",
                    [(x,y-7),(x+dx,y+dy),(x+dx+sign*5,y+dy+7),(x+sign*4,y-5)],
                    44.8,faded_green,far)

# A compact waiting shed sits well beyond the curb. Its roof, two posts and
# bench remain a readable destination; no person or vehicle enters a lane.
mid = layers["mid"][1]
sx,sy = 7.25,-16.5
cube("L01V03_Waiting_Shed_Floor",(sx,sy,.10),(1.90,1.24,.17),wall_sand,mid)
for dx in (-.77,.77):
    cube(f"L01V03_Waiting_Shed_Post_{dx}",(sx+dx,sy+.38,1.07),
         (.09,.10,2.04),bamboo,mid)
cube("L01V03_Waiting_Shed_Roof",(sx,sy,2.17),(2.12,1.42,.14),roof_teal,mid)
cube("L01V03_Waiting_Shed_Bench",(sx,sy+.17,.57),(1.48,.31,.12),bench_wood,mid)
for dx in (-.58,.58):
    cube(f"L01V03_Waiting_Shed_Bench_Leg_{dx}",(sx+dx,sy+.17,.33),
         (.09,.10,.42),bench_wood,mid)

# Near-road homes and practical small details frame, but never enter, the road.
near = layers["near"][1]
for side in (-1,1):
    for i,(y,depth) in enumerate(((-6.2,.50),(-14.0,.39),(-21.7,.30))):
        x = side * (6.25 + .18*(i%2))
        cube(f"L01V03_Concrete_Roadside_Post_{side}_{i}",
             (x,y,depth*.58),(.18,.20,depth+.13),wall_sand,near)
        cube(f"L01V03_Concrete_Post_Cap_{side}_{i}",
             (x,y,depth+.10),(.22,.24,.07),mango_curb,near)
    # Distinct veranda rails and quiet household fence rhythm.
    for i in range(3):
        y = -7.2 - i*4.6
        x = side * 6.55
        cube(f"L01V03_Bamboo_Fence_Post_{side}_{i}",(x,y,.55),
             (.075,.08,1.05),bamboo,near)
        if i < 2:
            cube(f"L01V03_Bamboo_Fence_Rail_{side}_{i}",
                 (x,y-2.3,.70),(.055,4.55,.06),bamboo,near)
    bx = side*7.05
    cube(f"L01V03_Roadside_Bench_{side}",(bx,-12.4,.52),
         (1.05,.29,.12),bench_wood,near)
    for dx in (-.38,.38):
        cube(f"L01V03_Roadside_Bench_Leg_{side}_{dx}",
             (bx+dx,-12.4,.27),(.09,.10,.44),bench_wood,near)

# Exact 480x270 composition doubled to 960x540. Solid road is isolated from
# two teal separators and mango curb edges so motion can affect them later.
road = layers["road"][1]
lane = layers["lane_overlay"][1]
screen_mesh("L01V03_Three_Lane_Road_Surface",
            [(368,156),(592,156),(898,540),(62,540)],38.0,road_grey,road)
for i,(cx,y,width,height) in enumerate((
        (420,236,15,4),(547,269,14,5),(365,320,20,6),
        (611,356,19,6),(455,401,26,7),(700,438,22,7),
        (281,478,27,9),(533,492,29,9))):
    screen_mesh(f"L01V03_Road_Material_Patch_{i}",
                [(cx-width,y-height),(cx+width,y-height),
                 (cx+width+3,y+height),(cx-width-3,y+height)],
                37.94,road_patch,road)
for i,(y,left,right,thick) in enumerate(((244,316,644,1.4),
                                        (343,236,724,2.0),
                                        (447,150,810,2.8))):
    screen_mesh(f"L01V03_Subtle_Depth_Seam_{i}",
                [(left,y),(right,y),(right+2,y+thick),(left-2,y+thick)],
                37.91,road_seam,road)


def tapered_line(name, a, b, far_width, near_width, mat):
    ax,ay = a
    bx,by = b
    direction = Vector((bx-ax,by-ay)).normalized()
    normal = Vector((-direction.y,direction.x))
    far = normal * far_width/2
    near_width_vec = normal * near_width/2
    screen_mesh(name,[(ax-far.x,ay-far.y),(ax+far.x,ay+far.y),
                      (bx+near_width_vec.x,by+near_width_vec.y),
                      (bx-near_width_vec.x,by-near_width_vec.y)],
                37.80,mat,lane)


tapered_line("L01V03_Teal_Lane_Separator_Left",(442,156),(340,540),2.0,4.0,teal_line)
tapered_line("L01V03_Teal_Lane_Separator_Right",(518,156),(620,540),2.0,4.0,teal_line)
tapered_line("L01V03_Mango_Curb_Left",(368,156),(62,540),2.2,6.0,mango_curb)
tapered_line("L01V03_Mango_Curb_Right",(592,156),(898,540),2.2,6.0,mango_curb)
for i,(y,left,right,width) in enumerate(((251,303,657,4),
                                        (351,223,737,6),
                                        (460,136,824,9))):
    for side,x in ((-1,left),(1,right)):
        screen_mesh(f"L01V03_Road_Edge_Marker_{side}_{i}",
                    [(x-width/2,y),(x+width/2,y),
                     (x+width/2+side*1.5,y+width*2),
                     (x-width/2+side*1.5,y+width*2)],
                    37.76,marker_cream,lane)

foreground = layers["foreground"][1]
for side in (-1,1):
    if side < 0:
        screen_mesh("L01V03_Left_Verge_Soft_Shadow",
                    [(0,442),(61,501),(84,540),(0,540)],6.0,verge_shadow,foreground)
        screen_mesh("L01V03_Left_Fence_Edge",
                    [(0,372),(7,372),(18,540),(0,540)],5.8,leaf_dark,foreground)
    else:
        screen_mesh("L01V03_Right_Verge_Soft_Shadow",
                    [(960,442),(899,501),(876,540),(960,540)],6.0,verge_shadow,foreground)
        screen_mesh("L01V03_Right_Fence_Edge",
                    [(960,372),(953,372),(942,540),(960,540)],5.8,leaf_dark,foreground)

master["l01_route_layers"] = "sky,far,mid,near,foreground,road,lane_overlay"
master["lane_count"] = 3
master["player_safe_zone"] = "lower central road remains free of scenery"
master["godot_base_canvas"] = "480x270"
master["export_scale"] = 2
master.camera = camera
master.render.film_transparent = False
bpy.context.window.scene = master
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == "VIEW_3D":
            area.spaces.active.region_3d.view_perspective = "CAMERA"
            area.spaces.active.shading.type = "MATERIAL"
bpy.ops.wm.save_as_mainfile(filepath=OUTPUT,check_existing=False)
print("SAVED_LAYERED_SOURCE",OUTPUT)
print("SOURCE_OBJECT_LAYER_COUNTS",counts)
