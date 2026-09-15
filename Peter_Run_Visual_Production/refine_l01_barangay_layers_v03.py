"""Final visual pass on the separately renderable L01 v03 Blender scenes."""

import math
import os

import bpy


ROOT = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(ROOT, "L01_Barangay_Morning_Layered_Final_v03b.blend")
if os.path.exists(OUTPUT):
    raise RuntimeError("Final layered source already exists; refusing to overwrite")

sky = bpy.data.scenes["L01_LAYER_SKY"]
far = bpy.data.scenes["L01_LAYER_FAR"]
mid = bpy.data.scenes["L01_LAYER_MID"]
camera = sky.camera
W, H = 960, 540

sky_ramp = bpy.data.materials["L01V03_Morning_Sky_Gradient"].node_tree.nodes.get("Color Ramp")
if sky_ramp:
    sky_ramp.color_ramp.elements[0].color = (.74,.70,.59,1)
    sky_ramp.color_ramp.elements[1].color = (.48,.65,.72,1)
    sky_ramp.color_ramp.elements[2].color = (.76,.74,.64,1)


def matte(name, rgb):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*rgb, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    bsdf.inputs["Roughness"].default_value = .94
    return mat


def screen_point(px, py, depth):
    frame = camera.data.view_frame(scene=sky)
    z = abs(frame[0].z)
    left = min(v.x for v in frame) * depth / z
    right = max(v.x for v in frame) * depth / z
    bottom = min(v.y for v in frame) * depth / z
    top = max(v.y for v in frame) * depth / z
    return (left+(right-left)*px/W, top-(top-bottom)*py/H, -depth)


def screen_mesh(name, points, mat, depth, scene):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata([screen_point(x,y,depth) for x,y in points], [],
                     [tuple(range(len(points)))])
    mesh.materials.append(mat)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.data.collections["L01V03_EXPORT_" + scene["export_layer"].upper()].objects.link(obj)
    obj.matrix_world = camera.matrix_world.copy()
    return obj


# The first draft inherited nine crystalline hills. Replace them with three
# broad, rounded, quiet silhouettes so the skyline reads at 480x270.
for obj in list(sky.objects):
    if obj.name.startswith("Far_Hill_"):
        obj.hide_render = True
hill_colours = (
    matte("L01V03_Rounded_Hill_Sage", (.49,.65,.56)),
    matte("L01V03_Rounded_Hill_Haze", (.56,.68,.61)),
    matte("L01V03_Rounded_Hill_Leaf", (.45,.60,.52)),
)
for i, (center, width, crest, base) in enumerate((
        (115, 410, 113, 192), (490, 530, 120, 192), (865, 450, 107, 192))):
    points = []
    for j in range(25):
        x = center-width/2+width*j/24
        t = (x-center)/(width/2)
        y = base-(base-crest)*math.sqrt(max(0,1-t*t))
        points.append((x,y))
    points += [(center+width/2,base+8),(center-width/2,base+8)]
    screen_mesh(f"L01V03_Rounded_Distant_Hill_{i}", points,
                hill_colours[i], 104-i*.07, sky)

# Four separated, faded roof clusters are enough to establish a barangay
# horizon. Remove the repeated middle five boxes, not the authored model.
for obj in list(far.objects):
    if obj.name.startswith("Far_"):
        tail = obj.name.rsplit("_", 1)[-1]
        if tail.isdecimal() and int(tail) not in {2,4,6}:
            obj.hide_render = True

# The inherited market stalls and bystanders sat half outside the camera.
# Keep the complete houses and sari-sari frontage; omit cropped figures.
for obj in list(mid.objects):
    if obj.name.startswith(("Palengke_", "Vendor_", "Neighbor_")):
        obj.hide_render = True

master = bpy.data.scenes["L01_Barangay_Morning_Master_v03"]
master["v03_visual_refinement"] = "three rounded hills; four roof clusters; no cropped roadside figures"
bpy.context.window.scene = master
bpy.ops.wm.save_as_mainfile(filepath=OUTPUT, check_existing=False)
print("SAVED_FINAL_LAYERED_SOURCE", OUTPUT)
