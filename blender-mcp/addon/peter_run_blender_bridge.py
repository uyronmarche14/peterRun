bl_info = {
    "name": "Peter Run Blender Bridge",
    "author": "Peter Run",
    "version": (0, 1, 0),
    "blender": (5, 2, 0),
    "location": "View3D > Sidebar > Peter Run",
    "description": "Narrow local bridge for Peter Run source character sprites",
    "category": "Development",
}

import bpy
from bpy_extras.anim_utils import animdata_get_channelbag_for_assigned_slot
import json
import math
import queue
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = 9876
COLLECTION_NAME = "PETER_RUN_GENERATED"
ANIMATIONS = {"idle", "run", "lane_left", "lane_right", "jump", "slide", "land", "success"}
REQUESTS = queue.Queue()
SERVER = None
SERVER_THREAD = None
TIMER_REGISTERED = False


def bridge_root():
    return Path(__file__).resolve().parents[1]


def output_directory(animation):
    root = bridge_root() / "generated" / animation
    root.mkdir(parents=True, exist_ok=True)
    return root


def collection():
    existing = bpy.data.collections.get(COLLECTION_NAME)
    if existing is None:
        existing = bpy.data.collections.new(COLLECTION_NAME)
        bpy.context.scene.collection.children.link(existing)
    return existing


def clear_generated_collection():
    existing = bpy.data.collections.get(COLLECTION_NAME)
    if existing is None:
        return
    for item in list(existing.objects):
        bpy.data.objects.remove(item, do_unlink=True)


def material(name, color):
    value = bpy.data.materials.get(name)
    if value is None:
        value = bpy.data.materials.new(name)
    value.use_nodes = True
    value.diffuse_color = color
    principled = value.node_tree.nodes.get("Principled BSDF")
    if principled is not None:
        principled.inputs["Base Color"].default_value = color
        principled.inputs["Roughness"].default_value = 0.62
    return value


def link_only(obj, target):
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    target.objects.link(obj)


def rounded_cube(name, location, scale, color, bevel=0.08):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(color)
    modifier = obj.modifiers.new("Soft edges", "BEVEL")
    modifier.width = bevel
    modifier.segments = 3
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    link_only(obj, collection())
    return obj


def sphere(name, location, scale, color):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(color)
    link_only(obj, collection())
    return obj


def cylinder(name, location, radius, depth, color):
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(color)
    bevel = obj.modifiers.new("Soft edges", "BEVEL")
    bevel.width = min(radius * 0.45, 0.08)
    bevel.segments = 3
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    link_only(obj, collection())
    return obj


def add_area_light(name, location, energy, color, size):
    light_data = bpy.data.lights.new(name, "AREA")
    light_data.energy = energy
    light_data.color = color
    light_data.shape = "DISK"
    light_data.size = size
    light = bpy.data.objects.new(name, light_data)
    light.location = location
    light.rotation_euler = (math.radians(35), 0, math.radians(180 if location[0] < 0 else 135))
    collection().objects.link(light)
    return light


def add_pivot(name, location, parent):
    pivot = bpy.data.objects.new(name, None)
    pivot.location = location
    collection().objects.link(pivot)
    if parent is not None:
        parent_keep_world(pivot, parent)
    return pivot


def parent_keep_world(child, parent):
    world_matrix = child.matrix_world.copy()
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()
    child.matrix_world = world_matrix


def remember_rest_location(obj):
    obj["peter_rest_location"] = tuple(obj.location)


def ensure_camera():
    camera = bpy.data.objects.get("PeterSpriteCamera")
    if camera is None:
        bpy.ops.object.camera_add(location=(0, -12, 3.1))
        camera = bpy.context.object
        camera.name = "PeterSpriteCamera"
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 5.2
    # The camera looks toward +Y; Peter is intentionally back-facing toward it.
    camera.rotation_euler = (math.radians(90), 0, 0)
    bpy.context.scene.camera = camera
    return camera


def create_character():
    clear_generated_collection()
    root = bpy.data.objects.new("Peter_Root", None)
    collection().objects.link(root)
    ground_anchor = bpy.data.objects.new("Peter_GroundAnchor", None)
    ground_anchor.location = (0, 0, 0)
    collection().objects.link(ground_anchor)
    # Clean, original visual language: warm runner, coral jacket, teal kit,
    # and one connected hair silhouette. The face sits on the forward side;
    # the exported gameplay camera deliberately sees Peter's back.
    skin = material("PeterSkin", (0.47, 0.16, 0.065, 1))
    skin_highlight = material("PeterSkinHighlight", (0.89, 0.42, 0.2, 1))
    shirt = material("PeterCoralShirt", (0.78, 0.09, 0.055, 1))
    shirt_highlight = material("PeterShirtHighlight", (1.0, 0.37, 0.14, 1))
    pants = material("PeterTealPants", (0.018, 0.13, 0.18, 1))
    pants_highlight = material("PeterPantsHighlight", (0.04, 0.34, 0.37, 1))
    shoes = material("PeterShoes", (0.008, 0.015, 0.025, 1))
    hair = material("PeterHair", (0.075, 0.028, 0.012, 1))
    eye_white = material("PeterEyeWhite", (0.98, 0.94, 0.84, 1))
    iris = material("PeterIris", (0.03, 0.24, 0.27, 1))
    bag = material("PeterBag", (0.025, 0.25, 0.27, 1))
    trim = material("PeterTrim", (1.0, 0.64, 0.16, 1))
    parts = [
        rounded_cube("Peter_Torso", (0, 0.04, 2.1), (0.56, 0.28, 0.7), shirt, 0.14),
        rounded_cube("Peter_ShirtHem", (0, -0.02, 1.48), (0.58, 0.3, 0.12), shirt_highlight, 0.05),
        rounded_cube("Peter_BackStripe", (0, -0.285, 2.15), (0.06, 0.025, 0.57), shirt_highlight, 0.02),
        rounded_cube("Peter_Hood", (0, -0.29, 2.67), (0.38, 0.1, 0.2), shirt, 0.1),
        sphere("Peter_Head", (0, 0.02, 3.18), (0.45, 0.34, 0.48), skin),
        sphere("Peter_Ear_L", (-0.43, 0.01, 3.18), (0.08, 0.07, 0.12), skin_highlight),
        sphere("Peter_Ear_R", (0.43, 0.01, 3.18), (0.08, 0.07, 0.12), skin_highlight),
        sphere("Peter_Eye_L", (-0.16, 0.335, 3.2), (0.11, 0.035, 0.13), eye_white),
        sphere("Peter_Eye_R", (0.16, 0.335, 3.2), (0.11, 0.035, 0.13), eye_white),
        sphere("Peter_Iris_L", (-0.16, 0.37, 3.2), (0.045, 0.02, 0.06), iris),
        sphere("Peter_Iris_R", (0.16, 0.37, 3.2), (0.045, 0.02, 0.06), iris),
        sphere("Peter_HairCap", (0, -0.15, 3.43), (0.48, 0.23, 0.22), hair),
        rounded_cube("Peter_HairBack", (0, -0.31, 3.3), (0.4, 0.055, 0.22), hair, 0.08),
        rounded_cube("Peter_HairTuft", (0.08, -0.19, 3.7), (0.16, 0.11, 0.16), hair, 0.1),
        rounded_cube("Peter_Backpack", (0, -0.34, 2.15), (0.47, 0.15, 0.57), bag, 0.12),
        rounded_cube("Peter_BackpackTrim", (0, -0.5, 2.15), (0.3, 0.025, 0.05), trim, 0.02),
        rounded_cube("Peter_BackpackBadge", (0, -0.505, 2.42), (0.075, 0.018, 0.075), trim, 0.02),
        cylinder("Peter_UpperArm_L", (-0.7, 0.02, 2.24), 0.16, 0.6, shirt),
        cylinder("Peter_UpperArm_R", (0.7, 0.02, 2.24), 0.16, 0.6, shirt),
        cylinder("Peter_Forearm_L", (-0.7, 0.02, 1.76), 0.125, 0.48, skin),
        cylinder("Peter_Forearm_R", (0.7, 0.02, 1.76), 0.125, 0.48, skin),
        sphere("Peter_Hand_L", (-0.7, -0.03, 1.49), (0.15, 0.13, 0.17), skin_highlight),
        sphere("Peter_Hand_R", (0.7, -0.03, 1.49), (0.15, 0.13, 0.17), skin_highlight),
        cylinder("Peter_Thigh_L", (-0.28, 0.03, 1.17), 0.22, 0.66, pants),
        cylinder("Peter_Thigh_R", (0.28, 0.03, 1.17), 0.22, 0.66, pants),
        cylinder("Peter_Shin_L", (-0.28, 0.03, 0.52), 0.18, 0.64, pants_highlight),
        cylinder("Peter_Shin_R", (0.28, 0.03, 0.52), 0.18, 0.64, pants_highlight),
        rounded_cube("Peter_Shoe_L", (-0.28, -0.16, 0.15), (0.28, 0.38, 0.15), shoes, 0.08),
        rounded_cube("Peter_Shoe_R", (0.28, -0.16, 0.15), (0.28, 0.38, 0.15), shoes, 0.08),
        rounded_cube("Peter_Sole_L", (-0.28, -0.23, 0.035), (0.3, 0.4, 0.035), trim, 0.02),
        rounded_cube("Peter_Sole_R", (0.28, -0.23, 0.035), (0.3, 0.4, 0.035), trim, 0.02),
    ]
    for part in parts:
        parent_keep_world(part, root)

    arm_l = add_pivot("Peter_ArmPivot_L", (-0.7, 0.02, 2.54), root)
    arm_r = add_pivot("Peter_ArmPivot_R", (0.7, 0.02, 2.54), root)
    elbow_l = add_pivot("Peter_ElbowPivot_L", (-0.7, 0.02, 1.94), arm_l)
    elbow_r = add_pivot("Peter_ElbowPivot_R", (0.7, 0.02, 1.94), arm_r)
    leg_l = add_pivot("Peter_LegPivot_L", (-0.28, 0.03, 1.5), root)
    leg_r = add_pivot("Peter_LegPivot_R", (0.28, 0.03, 1.5), root)
    knee_l = add_pivot("Peter_KneePivot_L", (-0.28, 0.03, 0.84), leg_l)
    knee_r = add_pivot("Peter_KneePivot_R", (0.28, 0.03, 0.84), leg_r)
    ankle_l = add_pivot("Peter_AnklePivot_L", (-0.28, 0.03, 0.2), knee_l)
    ankle_r = add_pivot("Peter_AnklePivot_R", (0.28, 0.03, 0.2), knee_r)

    for child, parent in (
        ("Peter_UpperArm_L", arm_l), ("Peter_UpperArm_R", arm_r),
        ("Peter_Forearm_L", elbow_l), ("Peter_Forearm_R", elbow_r),
        ("Peter_Hand_L", elbow_l), ("Peter_Hand_R", elbow_r),
        ("Peter_Thigh_L", leg_l), ("Peter_Thigh_R", leg_r),
        ("Peter_Shin_L", knee_l), ("Peter_Shin_R", knee_r),
        ("Peter_Shoe_L", ankle_l), ("Peter_Shoe_R", ankle_r),
        ("Peter_Sole_L", ankle_l), ("Peter_Sole_R", ankle_r),
    ):
        parent_keep_world(bpy.data.objects[child], parent)
    for pivot in (arm_l, arm_r, elbow_l, elbow_r, leg_l, leg_r, knee_l, knee_r, ankle_l, ankle_r):
        remember_rest_location(pivot)
    ensure_camera()
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 192
    scene.render.resolution_y = 256
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    scene.render.fps = 24
    scene.world.color = (0.045, 0.08, 0.1)
    add_area_light("Peter_KeyLight", (-4, -5, 6), 650, (1.0, 0.68, 0.47), 5.0)
    add_area_light("Peter_FillLight", (4, -3, 4), 420, (0.36, 0.82, 0.78), 4.0)
    add_area_light("Peter_RimLight", (0, 4, 5), 520, (1.0, 0.88, 0.62), 3.0)
    return {"character": "Peter", "collection": COLLECTION_NAME, "camera": "PeterSpriteCamera", "size": [192, 256]}


def require_character():
    root = bpy.data.objects.get("Peter_Root")
    if root is None:
        raise ValueError("Create Peter before posing or rendering.")
    return root


def set_rotation(name, x=0, y=0, z=0):
    part = bpy.data.objects.get(name)
    if part is not None:
        part.rotation_euler = (x, y, z)
        part.keyframe_insert(data_path="rotation_euler", frame=bpy.context.scene.frame_current)


def set_location_offset(name, x=0, y=0, z=0):
    part = bpy.data.objects.get(name)
    if part is None:
        return
    rest = part.get("peter_rest_location")
    if rest is None:
        rest = tuple(part.location)
        part["peter_rest_location"] = rest
    part.location = (rest[0] + x, rest[1] + y, rest[2] + z)
    part.keyframe_insert(data_path="location", frame=bpy.context.scene.frame_current)


def key_root(root, z=0, lean_x=0, lean_y=0):
    root.location = (0, 0, z)
    root.rotation_euler = (lean_x, lean_y, 0)
    root.keyframe_insert(data_path="location", frame=bpy.context.scene.frame_current)
    root.keyframe_insert(data_path="rotation_euler", frame=bpy.context.scene.frame_current)


def smooth_animation_curves():
    for item in collection().objects:
        if item.animation_data is None:
            continue
        channelbag = animdata_get_channelbag_for_assigned_slot(item.animation_data)
        if channelbag is None:
            continue
        for curve in channelbag.fcurves:
            for point in curve.keyframe_points:
                point.interpolation = "BEZIER"
                point.handle_left_type = "AUTO_CLAMPED"
                point.handle_right_type = "AUTO_CLAMPED"


def pose(animation):
    if animation not in ANIMATIONS:
        raise ValueError("Unsupported animation.")
    root = require_character()
    scene = bpy.context.scene
    for obj in collection().objects:
        if obj.animation_data:
            obj.animation_data_clear()
    ranges = {"idle": 4, "run": 12, "lane_left": 6, "lane_right": 6, "jump": 15, "slide": 12, "land": 6, "success": 10}
    scene.frame_start = 1
    scene.frame_end = ranges[animation]
    for frame in range(scene.frame_start, scene.frame_end + 1):
        scene.frame_set(frame)
        phase = (frame - 1) / max(1, scene.frame_end - 1)
        swing = math.sin(phase * math.tau)
        root_z = 0
        lean_x = 0
        lean_y = 0
        if animation == "run":
            # A real in-place run: opposing thighs, bent knees, lifted ankles,
            # and counter-swinging elbows. Keep Y rotation at zero so limbs do
            # not sweep horizontally across the rear-view sprite.
            left_lift = max(0.0, swing)
            right_lift = max(0.0, -swing)
            set_rotation("Peter_LegPivot_L", x=0.48 * swing)
            set_rotation("Peter_LegPivot_R", x=-0.48 * swing)
            set_rotation("Peter_KneePivot_L", x=-0.92 * left_lift + 0.16 * right_lift)
            set_rotation("Peter_KneePivot_R", x=-0.92 * right_lift + 0.16 * left_lift)
            set_location_offset("Peter_AnklePivot_L", z=0.38 * left_lift)
            set_location_offset("Peter_AnklePivot_R", z=0.38 * right_lift)
            set_rotation("Peter_AnklePivot_L", x=0.34 * left_lift - 0.12 * right_lift)
            set_rotation("Peter_AnklePivot_R", x=0.34 * right_lift - 0.12 * left_lift)
            set_rotation("Peter_ArmPivot_L", x=-0.46 * swing)
            set_rotation("Peter_ArmPivot_R", x=0.46 * swing)
            set_rotation("Peter_ElbowPivot_L", x=0.68 * max(0.0, -swing))
            set_rotation("Peter_ElbowPivot_R", x=0.68 * max(0.0, swing))
            root_z = 0.045 + 0.085 * (left_lift + right_lift)
            lean_x = math.radians(-8)
        elif animation in {"lane_left", "lane_right"}:
            direction = -1 if animation == "lane_left" else 1
            lean_y = direction * math.sin(phase * math.pi) * 0.22
        elif animation == "jump":
            root_z = math.sin(phase * math.pi) * 1.0
            set_rotation("Peter_ArmPivot_L", y=-0.55)
            set_rotation("Peter_ArmPivot_R", y=0.55)
        elif animation == "slide":
            root_z = -math.sin(phase * math.pi) * 0.5
            lean_y = math.sin(phase * math.pi) * 0.38
        elif animation == "land":
            root_z = -math.sin(phase * math.pi) * 0.16
        elif animation == "success":
            set_rotation("Peter_ArmPivot_L", y=-1.25 * math.sin(phase * math.pi))
            set_rotation("Peter_ArmPivot_R", y=1.25 * math.sin(phase * math.pi))
        key_root(root, root_z, lean_x, lean_y)
    smooth_animation_curves()
    scene.frame_set(1)
    return {"animation": animation, "frames": scene.frame_end, "fps": scene.render.fps}


def render(animation):
    require_character()
    if animation not in ANIMATIONS:
        raise ValueError("Unsupported animation.")
    scene = bpy.context.scene
    output = output_directory(animation)
    for image in output.glob("*.png"):
        image.unlink()
    for frame in range(scene.frame_start, scene.frame_end + 1):
        scene.frame_set(frame)
        scene.render.filepath = str(output / f"peter_{animation}_{frame:03d}.png")
        bpy.ops.render.render(write_still=True)
    return {"animation": animation, "directory": str(output), "frames": scene.frame_end - scene.frame_start + 1, "size": [192, 256]}


def validate(animation):
    output = output_directory(animation)
    frames = sorted(output.glob("*.png"))
    if not frames:
        raise ValueError("No rendered PNG frames found for this animation.")
    checked = []
    for path in frames:
        image = bpy.data.images.load(str(path), check_existing=False)
        checked.append({"file": path.name, "size": [image.size[0], image.size[1]]})
        bpy.data.images.remove(image)
    invalid = [item for item in checked if item["size"] != [192, 256]]
    if invalid:
        raise ValueError("Unexpected frame dimensions: " + json.dumps(invalid))
    return {"animation": animation, "valid": True, "frames": checked}


def execute(command):
    if command == "status":
        return {"blender": bpy.app.version_string, "bridge": "ready", "port": PORT}
    if command == "create_character":
        return create_character()
    if command == "pose":
        return pose(command_data["animation"])
    if command == "render":
        return render(command_data["animation"])
    if command == "validate":
        return validate(command_data["animation"])
    raise ValueError("Unknown command.")


def process_requests():
    while True:
        try:
            request = REQUESTS.get_nowait()
        except queue.Empty:
            break
        global command_data
        command_data = request["payload"]
        try:
            request["result"] = {"ok": True, "result": execute(command_data["command"])}
        except Exception as error:
            request["result"] = {"ok": False, "error": str(error)}
        request["done"].set()
    return 0.05


class BridgeHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/command":
            self.send_error(404)
            return
        try:
            length = int(self.headers.get("content-length", "0"))
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
            request = {"payload": payload, "done": threading.Event(), "result": None}
            REQUESTS.put(request)
            if not request["done"].wait(120):
                raise TimeoutError("Blender did not complete the request in time.")
            response = request["result"]
            encoded = json.dumps(response).encode("utf-8")
            self.send_response(200 if response["ok"] else 400)
            self.send_header("content-type", "application/json")
            self.send_header("content-length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)
        except Exception as error:
            encoded = json.dumps({"ok": False, "error": str(error)}).encode("utf-8")
            self.send_response(500)
            self.send_header("content-type", "application/json")
            self.send_header("content-length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)

    def log_message(self, format, *args):
        return


def start_server():
    global SERVER, SERVER_THREAD, TIMER_REGISTERED
    if SERVER is not None:
        return
    SERVER = ThreadingHTTPServer(("127.0.0.1", PORT), BridgeHandler)
    SERVER_THREAD = threading.Thread(target=SERVER.serve_forever, daemon=True)
    SERVER_THREAD.start()
    if not TIMER_REGISTERED:
        bpy.app.timers.register(process_requests, persistent=True)
        TIMER_REGISTERED = True


def stop_server():
    global SERVER, SERVER_THREAD, TIMER_REGISTERED
    if SERVER is not None:
        SERVER.shutdown()
        SERVER.server_close()
        SERVER = None
    SERVER_THREAD = None
    if TIMER_REGISTERED and bpy.app.timers.is_registered(process_requests):
        bpy.app.timers.unregister(process_requests)
    TIMER_REGISTERED = False


class PETER_RUN_OT_start_bridge(bpy.types.Operator):
    bl_idname = "peter_run.start_bridge"
    bl_label = "Start Peter Run Bridge"
    def execute(self, context):
        try:
            start_server()
            self.report({"INFO"}, "Peter Run bridge listening on 127.0.0.1:9876")
            return {"FINISHED"}
        except Exception as error:
            self.report({"ERROR"}, str(error))
            return {"CANCELLED"}


class PETER_RUN_OT_stop_bridge(bpy.types.Operator):
    bl_idname = "peter_run.stop_bridge"
    bl_label = "Stop Peter Run Bridge"
    def execute(self, context):
        stop_server()
        return {"FINISHED"}


class PETER_RUN_PT_panel(bpy.types.Panel):
    bl_label = "Peter Run"
    bl_idname = "PETER_RUN_PT_panel"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Peter Run"
    def draw(self, context):
        layout = self.layout
        layout.label(text="Codex asset bridge")
        layout.operator("peter_run.start_bridge")
        layout.operator("peter_run.stop_bridge")


CLASSES = (PETER_RUN_OT_start_bridge, PETER_RUN_OT_stop_bridge, PETER_RUN_PT_panel)

def register():
    # A Text Editor rerun replaces the previous local bridge without requiring
    # the artist to restart Blender.
    try:
        bpy.ops.peter_run.stop_bridge()
    except (AttributeError, RuntimeError):
        pass
    for cls in CLASSES:
        existing = getattr(bpy.types, cls.__name__, None)
        if existing is not None:
            bpy.utils.unregister_class(existing)
        bpy.utils.register_class(cls)


def unregister():
    stop_server()
    for cls in reversed(CLASSES):
        bpy.utils.unregister_class(cls)


if __name__ == "__main__":
    register()
