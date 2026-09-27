"""Build a complete Blender-authored PETER RUN dashboard composition.

The UI artwork is baked into the Blender render; Godot retains transparent,
accessible interaction targets only.
"""
import math
import os
import runpy
import bpy
from mathutils import Vector

ROOT = os.path.dirname(os.path.abspath(__file__))
runpy.run_path(os.path.join(ROOT, "build_dashboard_barangay_hero_v01.py"))
scene = bpy.context.scene
scene.name = "PETER_RUN_DASHBOARD_COMPLETE_V02"
scene.render.filepath = os.path.normpath(os.path.join(ROOT, "..", "code", "art", "backgrounds", "dashboard_barangay_complete_v02.png"))
output_blend = os.path.join(ROOT, "Dashboard_Barangay_Complete_V02.blend")
ui = bpy.data.collections.new("Dashboard_Complete_UI")
scene.collection.children.link(ui)


def mat(name, rgba, emission=0.0):
    value = bpy.data.materials.new(name)
    value.diffuse_color = rgba
    value.use_nodes = True
    node = value.node_tree.nodes.get("Principled BSDF")
    node.inputs["Base Color"].default_value = rgba
    node.inputs["Roughness"].default_value = 0.76
    if emission:
        node.inputs["Emission Color"].default_value = rgba
        node.inputs["Emission Strength"].default_value = emission
    return value

ink = mat("UI_Ink", (0.035, 0.12, 0.12, 1))
teal = mat("UI_Deep_Teal", (0.025, 0.19, 0.20, 1))
cream = mat("UI_Cream", (1.0, 0.91, 0.70, 1))
mango = mat("UI_Mango", (1.0, 0.52, 0.07, 1), 0.12)
green = mat("UI_Leaf", (0.55, 0.72, 0.55, 1))
coral = mat("UI_Coral", (0.80, 0.29, 0.19, 1))

camera = scene.camera
rotation = camera.rotation_euler.copy()
right = camera.matrix_world.to_3x3() @ Vector((1, 0, 0))
up = camera.matrix_world.to_3x3() @ Vector((0, 1, 0))
forward = -(camera.matrix_world.to_3x3() @ Vector((0, 0, 1)))
origin = camera.location + forward * 20.0


def pos(x, y, depth=0.0):
    # Positive depth is farther away, so stacked panel content remains visible.
    return origin + right * x + up * y + forward * depth


def panel(name, x, y, width, height, depth, material, radius=0.10):
    bpy.ops.mesh.primitive_cube_add(location=pos(x, y, depth), rotation=rotation)
    obj = bpy.context.object
    for old in tuple(obj.users_collection): old.objects.unlink(obj)
    ui.objects.link(obj)
    obj.name = name
    obj.dimensions = (width, height, 0.08)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    bevel = obj.modifiers.new("Soft_Corner", "BEVEL")
    bevel.width = radius
    bevel.segments = 3
    return obj


def label(name, body, x, y, size, material, depth=-0.08):
    curve = bpy.data.curves.new(name + "_Curve", "FONT")
    curve.body = body
    curve.align_x = "CENTER"
    curve.align_y = "CENTER"
    curve.size = size
    curve.extrude = 0.006
    curve.bevel_depth = 0.002
    curve.materials.append(material)
    obj = bpy.data.objects.new(name, curve)
    ui.objects.link(obj)
    obj.location = pos(x, y, depth)
    obj.rotation_euler = rotation
    return obj

# New compact card composition at left; this deliberately replaces the runtime menu art.
panel("Card_Shadow", -4.40, -0.25, 7.25, 9.20, 0.27, ink, 0.22)
panel("Route_Card", -4.40, -0.15, 7.10, 9.00, 0.16, cream, 0.22)
panel("Route_Ticket", -4.40, 1.55, 5.90, 1.35, 0.08, teal, 0.15)
panel("Route_Ticket_Edge", -4.40, 1.55, 6.04, 1.48, 0.07, mango, 0.17)
panel("Route_Ticket_Inner", -4.40, 1.55, 5.88, 1.32, 0.06, teal, 0.14)
label("Dashboard_Title", "PETER RUN", -4.40, 3.35, 1.08, ink)
label("Dashboard_Subtitle", "One step at a time.", -4.40, 2.55, 0.38, ink)
label("Ticket_Route", "BARANGAY MORNING", -4.40, 1.78, 0.52, cream)
label("Ticket_Detail", "L01  ·  GUIDED MOVEMENT ROUTE", -4.40, 1.30, 0.25, mango)
label("Journey", "Start  →  Sari-sari  →  Shed  →  Hall", -4.40, 0.55, 0.27, ink)
panel("Journey_Divider", -4.40, 0.10, 5.90, 0.05, 0.07, ink, 0.01)
panel("Start_Button", -4.40, -0.85, 5.95, 1.05, 0.07, teal, 0.15)
label("Start_Label", "▶  Start Session", -4.40, -0.85, 0.46, cream)
for x, text in [(-7.10, "?  Tutorial"), (-5.25, "⚙  Settings"), (-3.40, "↗  Quit")]:
    panel("Secondary_" + text[-4:], x, -2.05, 1.65, 0.78, 0.07, green, 0.13)
    label("Secondary_Label_" + text[-4:], text, x, -2.05, 0.25, teal)
label("Support_Note", "Supervised session  ·  Keyboard mode available", -5.25, -2.85, 0.26, ink)
# Top greeting and woven divider are also Blender geometry.
label("Welcome", "MABUHAY!  /  WELCOME", -7.55, 5.05, 0.30, ink)
for i in range(9):
    panel("Banig_%02d" % i, -8.65 + i * 0.27, 4.62, 0.16, 0.07, 0.05, mango if i % 2 == 0 else green, 0.01)
# Quiet top-right music pill.
panel("Music_Pill", 7.35, 4.72, 2.30, 0.62, 0.07, cream, 0.18)
label("Music_Label", "♫  Music: On", 7.35, 4.72, 0.25, teal)

# A distinctive woven route-promise plaque gives the Filipino line its own
# authored moment rather than treating it as ordinary helper text.
panel("Promise_Shadow", 5.55, 1.92, 4.72, 1.78, 0.24, ink, 0.18)
panel("Promise_Mango_Edge", 5.40, 2.05, 4.68, 1.70, 0.16, mango, 0.17)
panel("Promise_Woven_Plaque", 5.55, 1.92, 4.48, 1.55, 0.08, teal, 0.15)
for index in range(8):
    panel("Promise_Weave_%02d" % index, 3.67 + index * 0.52, 1.23, 0.28, 0.06, 0.01, cream if index % 2 == 0 else mango, 0.01)
label("Promise_Line_One", "Sa bawat hakbang,", 5.55, 2.24, 0.38, cream)
label("Promise_Line_Two", "may bagong simula.", 5.55, 1.68, 0.46, cream)
label("Promise_Route_Mark", "✦", 3.72, 2.00, 0.30, mango)

scene["asset_id"] = "dashboard_barangay_complete_v02"
scene["runtime_contract"] = "Blender is the complete visible dashboard; Godot retains accessible transparent controls."
bpy.ops.wm.save_as_mainfile(filepath=output_blend)
bpy.ops.render.render(write_still=True)
print("PETER_RUN_DASHBOARD_COMPLETE_V02_PASS", output_blend, scene.render.filepath)
