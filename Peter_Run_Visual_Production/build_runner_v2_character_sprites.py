"""Create an original, Blender-authored 2.5D sprite-animation source for PETER RUN.

This creates a new fictional adult protagonist from procedural low-poly meshes.
It never opens, edits, or reuses an existing Peter Run character source.
Run in background Blender from this directory. It creates one new .blend source and
transparent 512x512 PNG frames only; sprite sheets/contact previews are composed by
the companion compose_runner_v2_character_sheets.py script.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parent
SOURCE_BLEND = ROOT / "RunnerV2_Character_Source_v01.blend"
ASSET_ROOT = ROOT.parent / "code" / "art" / "characters" / "runner_v2"
FRAME_SIZE = 512
PIVOT = [256, 416]
ANIMATIONS = {
    "idle_ready": (8, 8, True),
    "walk_forward": (10, 10, True),
    "move_left": (8, 10, False),
    "move_right": (8, 10, False),
    "jump_low": (10, 12, False),
    "slide_duck": (10, 10, False),
    "success_settle": (8, 8, False),
    "neutral_clear": (6, 8, False),
    "rest": (6, 6, True),
}

if SOURCE_BLEND.exists():
    raise RuntimeError(f"Refusing to overwrite existing source: {SOURCE_BLEND}")
if ASSET_ROOT.exists():
    raise RuntimeError(f"Refusing to overwrite existing sprite root: {ASSET_ROOT}")


# Warm morning palette: coral top, charcoal trousers, skin, short dark hair,
# teal habi band, and a small mango sun accent. No text, logos, flags, or brands.
def make_material(name: str, color: tuple[float, float, float], alpha: float = 1.0, roughness: float = 0.76):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, alpha)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Alpha"].default_value = alpha
    if alpha < 1.0 and hasattr(mat, "surface_render_method"):
        mat.surface_render_method = "DITHERED"
    return mat


INK = make_material("RunnerV2_Quiet_Outline", (0.055, 0.10, 0.12), 1.0, 0.9)
SKIN = make_material("RunnerV2_Warm_Brown_Skin", (0.45, 0.22, 0.13), 1.0, 0.7)
SKIN_LIGHT = make_material("RunnerV2_Sunlit_Skin", (0.61, 0.34, 0.20), 1.0, 0.68)
HAIR = make_material("RunnerV2_Textured_Dark_Hair", (0.035, 0.045, 0.052), 1.0, 0.92)
CORAL = make_material("RunnerV2_Coral_Comfort_Top", (0.78, 0.20, 0.18), 1.0, 0.72)
CORAL_LIGHT = make_material("RunnerV2_Coral_Sunlit_Plane", (0.95, 0.38, 0.27), 1.0, 0.68)
NAVY = make_material("RunnerV2_Charcoal_Navy_Joggers", (0.075, 0.13, 0.18), 1.0, 0.84)
NAVY_LIGHT = make_material("RunnerV2_Jogger_Highlight", (0.13, 0.24, 0.30), 1.0, 0.8)
TEAL = make_material("RunnerV2_Habi_Teal_Trim", (0.06, 0.40, 0.39), 1.0, 0.7)
MANGO = make_material("RunnerV2_Mango_Sun_Accent", (0.95, 0.54, 0.16), 1.0, 0.68)
SHOE = make_material("RunnerV2_Walking_Shoe", (0.72, 0.71, 0.63), 1.0, 0.88)
SHOE_SOLE = make_material("RunnerV2_Shoe_Sole", (0.14, 0.18, 0.19), 1.0, 0.9)
SHADOW = make_material("RunnerV2_Soft_Ground_Shadow", (0.035, 0.09, 0.085), 0.34, 1.0)


# Use a clean new scene; background Blender has no user document to preserve.
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)

# Blender keeps one local scene alive in a background startup file, so reuse
# that clean scene instead of attempting to delete the final local scene.
scene = bpy.context.scene
scene.name = "RUNNER_V2_SPRITE_MASTER"
scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x = FRAME_SIZE
scene.render.resolution_y = FRAME_SIZE
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.compression = 15
scene.render.film_transparent = True
scene.view_settings.view_transform = "AgX"
scene.view_settings.look = "AgX - Medium High Contrast"
scene.view_settings.exposure = 0.10

character_collection = bpy.data.collections.new("RUNNER_V2_ORIGINAL_ADULT_CHARACTER")
lighting_collection = bpy.data.collections.new("RUNNER_V2_WARM_MORNING_LIGHTING")
shadow_collection = bpy.data.collections.new("RUNNER_V2_SEPARATE_GROUND_SHADOW")
scene.collection.children.link(character_collection)
scene.collection.children.link(lighting_collection)
scene.collection.children.link(shadow_collection)


def link_new_object(obj, collection):
    for linked in list(obj.users_collection):
        linked.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def rounded_box(name: str, dimensions: tuple[float, float, float], material, collection, bevel: float = 0.05):
    bpy.ops.mesh.primitive_cube_add(size=1)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        modifier = obj.modifiers.new("Soft_2p5D_Bevel", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    obj.data.materials.append(material)
    return link_new_object(obj, collection)


def sphere(name: str, radius: float, material, collection, scale=(1.0, 1.0, 1.0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=radius)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return link_new_object(obj, collection)


def disc(name: str, x_radius: float, y_radius: float, material, collection):
    bpy.ops.mesh.primitive_circle_add(vertices=48, radius=1.0, fill_type="NGON")
    obj = bpy.context.object
    obj.name = name
    obj.scale = (x_radius, y_radius, 1.0)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    return link_new_object(obj, collection)


def set_location(obj, position: tuple[float, float, float]):
    obj.location = position


def point_limb(obj, start: Vector, end: Vector, width: float, depth: float):
    direction = end - start
    obj.location = (start + end) * 0.5
    obj.dimensions = (width, depth, max(0.03, direction.length))
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(direction.normalized())


# New fictional adult: independent body proportions and outfit, deliberately not
# based on any prior project player source or commercial character.
root = bpy.data.objects.new("RunnerV2_Pivot_Between_Feet", None)
character_collection.objects.link(root)
root["pivot_px"] = PIVOT
root["view"] = "rear_three_quarter_toward_barangay_hall"
root["originality"] = "procedural fictional adult; no reference mesh or copied character"

parts = {}
parts["torso"] = rounded_box("RunnerV2_Coral_Top", (1.00, 0.52, 1.06), CORAL, character_collection, 0.13)
parts["torso_plane"] = rounded_box("RunnerV2_Sunlit_Coral_Plane", (0.30, 0.035, 0.62), CORAL_LIGHT, character_collection, 0.025)
parts["habi_band"] = rounded_box("RunnerV2_Subtle_Habi_Teal_Band", (0.96, 0.055, 0.095), TEAL, character_collection, 0.018)
parts["habi_mango"] = rounded_box("RunnerV2_Habi_Mango_Accent", (0.13, 0.062, 0.105), MANGO, character_collection, 0.018)
parts["neck"] = rounded_box("RunnerV2_Neck", (0.28, 0.26, 0.24), SKIN, character_collection, 0.06)
parts["head"] = sphere("RunnerV2_Adult_Head", 0.43, SKIN, character_collection, (0.93, 0.90, 1.06))
parts["ear"] = sphere("RunnerV2_Visible_Ear", 0.09, SKIN_LIGHT, character_collection, (0.7, 0.35, 1.0))
parts["hair_cap"] = sphere("RunnerV2_Short_Textured_Hair", 0.45, HAIR, character_collection, (0.98, 0.94, 0.45))
parts["hair_back"] = rounded_box("RunnerV2_Hair_Nape_Texture", (0.40, 0.08, 0.08), HAIR, character_collection, 0.035)
for index, x in enumerate((-0.22, -0.11, 0.0, 0.11, 0.22)):
    parts[f"hair_texture_{index}"] = sphere(f"RunnerV2_Hair_Texture_{index}", 0.045, HAIR, character_collection, (0.8, 0.45, 0.42))

parts["left_arm"] = rounded_box("RunnerV2_Left_Arm", (0.20, 0.20, 0.80), CORAL, character_collection, 0.075)
parts["right_arm"] = rounded_box("RunnerV2_Right_Arm", (0.20, 0.20, 0.80), CORAL_LIGHT, character_collection, 0.075)
parts["left_hand"] = sphere("RunnerV2_Left_Hand", 0.14, SKIN, character_collection, (0.72, 0.70, 1.0))
parts["right_hand"] = sphere("RunnerV2_Right_Hand", 0.14, SKIN_LIGHT, character_collection, (0.72, 0.70, 1.0))
parts["left_leg"] = rounded_box("RunnerV2_Left_Jogger_Leg", (0.29, 0.31, 1.05), NAVY, character_collection, 0.085)
parts["right_leg"] = rounded_box("RunnerV2_Right_Jogger_Leg", (0.29, 0.31, 1.05), NAVY_LIGHT, character_collection, 0.085)
parts["left_shoe"] = rounded_box("RunnerV2_Left_Walking_Shoe", (0.38, 0.64, 0.20), SHOE, character_collection, 0.07)
parts["right_shoe"] = rounded_box("RunnerV2_Right_Walking_Shoe", (0.38, 0.64, 0.20), SHOE, character_collection, 0.07)
parts["left_sole"] = rounded_box("RunnerV2_Left_Shoe_Sole", (0.40, 0.66, 0.055), SHOE_SOLE, character_collection, 0.02)
parts["right_sole"] = rounded_box("RunnerV2_Right_Shoe_Sole", (0.40, 0.66, 0.055), SHOE_SOLE, character_collection, 0.02)

shadow = disc("RunnerV2_Soft_Oval_Ground_Shadow", 0.68, 0.30, SHADOW, shadow_collection)
shadow.location = (0.0, 0.05, 0.012)

for obj in character_collection.objects:
    if obj != root:
        obj.parent = root
for obj in shadow_collection.objects:
    obj.parent = root

# Orthographic rear three-quarter camera: the forward road direction is +Y, so
# this sees the character's back and right shoulder without a background scene.
camera_data = bpy.data.cameras.new("RunnerV2_RearThreeQuarter_OrthographicCamera")
camera = bpy.data.objects.new(camera_data.name, camera_data)
lighting_collection.objects.link(camera)
camera.location = (4.8, -9.4, 4.2)
target = Vector((0.0, 0.0, 1.33))
camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
camera_data.type = "ORTHO"
camera_data.ortho_scale = 4.65
scene.camera = camera

world = bpy.data.worlds.new("RunnerV2_Transparent_Warm_Morning_World")
world.use_nodes = True
world.node_tree.nodes.get("Background").inputs["Color"].default_value = (0.85, 0.72, 0.52, 1.0)
world.node_tree.nodes.get("Background").inputs["Strength"].default_value = 0.38
scene.world = world

key_data = bpy.data.lights.new("RunnerV2_Warm_Morning_Key", "AREA")
key_data.energy = 470
key_data.shape = "DISK"
key_data.size = 4.5
key = bpy.data.objects.new(key_data.name, key_data)
lighting_collection.objects.link(key)
key.location = (-3.8, -4.8, 7.2)
key.rotation_euler = (Vector((0.0, 0.0, 1.25)) - key.location).to_track_quat("-Z", "Y").to_euler()
fill_data = bpy.data.lights.new("RunnerV2_Soft_Teal_Fill", "AREA")
fill_data.energy = 120
fill_data.size = 5.0
fill = bpy.data.objects.new(fill_data.name, fill_data)
lighting_collection.objects.link(fill)
fill.location = (4.0, 1.0, 4.0)
fill.rotation_euler = (Vector((0.0, 0.0, 1.50)) - fill.location).to_track_quat("-Z", "Y").to_euler()


def ease(value: float) -> float:
    value = max(0.0, min(1.0, value))
    return value * value * (3.0 - 2.0 * value)


def put_shoe(side: str, position: Vector, lift: float, toe: float = 0.0):
    shoe = parts[f"{side}_shoe"]
    sole = parts[f"{side}_sole"]
    shoe.location = (position.x, position.y + toe, 0.10 + lift)
    shoe.rotation_mode = "XYZ"
    shoe.rotation_euler = (toe * 0.22, 0.0, 0.0)
    sole.location = (position.x, position.y + toe + 0.006, 0.018 + lift)
    sole.rotation_mode = "XYZ"
    sole.rotation_euler = (toe * 0.22, 0.0, 0.0)


def set_pose(animation: str, index: int, count: int):
    phase = index / float(count if animation in {"idle_ready", "walk_forward", "rest"} else max(1, count - 1))
    loop_phase = math.tau * index / float(count)
    breath = 0.026 * math.sin(loop_phase) if animation in {"idle_ready", "rest"} else 0.0
    torso_z = 1.62 + breath
    head_z = 2.55 + breath * 1.25
    body_lean = 0.0
    hip_left = Vector((-0.24, 0.0, 1.20 + breath))
    hip_right = Vector((0.24, 0.0, 1.20 + breath))
    foot_left = Vector((-0.24, 0.0, 0.10))
    foot_right = Vector((0.24, 0.0, 0.10))
    lift_left = 0.0
    lift_right = 0.0
    arm_left_swing = 0.0
    arm_right_swing = 0.0
    shoulder_turn = 0.0
    hand_open = 0.0

    if animation == "walk_forward":
        stride = math.sin(loop_phase)
        lift_left = max(0.0, -stride) * 0.20
        lift_right = max(0.0, stride) * 0.20
        foot_left.y = 0.22 * stride
        foot_right.y = -0.22 * stride
        arm_left_swing = -0.20 * stride
        arm_right_swing = 0.20 * stride
        torso_z += 0.012 * math.sin(loop_phase * 2.0)
    elif animation in {"move_left", "move_right"}:
        side = -1.0 if animation == "move_left" else 1.0
        step = math.sin(math.pi * phase)
        settle = ease(phase)
        foot_left.x += side * (0.28 * step if side < 0.0 else 0.08 * step)
        foot_right.x += side * (0.28 * step if side > 0.0 else 0.08 * step)
        foot_left.y += 0.06 * step
        foot_right.y -= 0.04 * step
        lift_left = 0.11 * math.sin(math.pi * min(1.0, phase * 1.35)) if side < 0.0 else 0.05 * step
        lift_right = 0.11 * math.sin(math.pi * min(1.0, phase * 1.35)) if side > 0.0 else 0.05 * step
        torso_z += 0.035 * step
        body_lean = side * 0.10 * step
        shoulder_turn = side * 0.12 * step
        arm_left_swing = -side * 0.08 * step
        arm_right_swing = side * 0.08 * step
        if phase > 0.78:
            # End at the neutral local sprite pose; the Godot node performs lane travel.
            foot_left.x = -0.24
            foot_right.x = 0.24
            lift_left = 0.0
            lift_right = 0.0
            body_lean = side * 0.02 * (1.0 - settle)
    elif animation == "jump_low":
        rise = math.sin(math.pi * phase)
        torso_z += 0.35 * rise
        head_z += 0.35 * rise
        foot_left.z += 0.31 * rise
        foot_right.z += 0.31 * rise
        lift_left = 0.0
        lift_right = 0.0
        foot_left.y = 0.06 * rise
        foot_right.y = 0.06 * rise
        arm_left_swing = 0.12 * rise
        arm_right_swing = 0.12 * rise
        if phase < 0.20:
            torso_z -= 0.08 * math.sin(math.pi * phase / 0.20)
            head_z -= 0.08 * math.sin(math.pi * phase / 0.20)
        if phase > 0.78:
            torso_z += 0.04 * math.sin(math.pi * (phase - 0.78) / 0.22)
            head_z += 0.04 * math.sin(math.pi * (phase - 0.78) / 0.22)
    elif animation == "slide_duck":
        duck = math.sin(math.pi * phase)
        # A visibly lowered but still upright crouch: it reads under a high
        # marker without suggesting a floor slide or unsafe deep flexion.
        torso_z -= 0.54 * duck
        head_z -= 0.78 * duck
        hip_left.z -= 0.34 * duck
        hip_right.z -= 0.34 * duck
        body_lean = -0.18 * duck
        foot_left.y += 0.10 * duck
        foot_right.y -= 0.08 * duck
        lift_left = 0.03 * duck
        lift_right = 0.03 * duck
        arm_left_swing = -0.12 * duck
        arm_right_swing = -0.12 * duck
    elif animation == "success_settle":
        gesture = math.sin(math.pi * phase)
        hand_open = gesture
        arm_right_swing = -0.16 * gesture
        shoulder_turn = 0.04 * gesture
        head_z += 0.035 * math.sin(math.pi * phase * 2.0)
    elif animation == "neutral_clear":
        acknowledgement = math.sin(math.pi * phase)
        shoulder_turn = 0.035 * acknowledgement
        head_z += 0.018 * acknowledgement
        arm_right_swing = -0.035 * acknowledgement
    elif animation == "rest":
        breath = 0.020 * math.sin(loop_phase)
        torso_z = 1.60 + breath
        head_z = 2.53 + breath
        arm_left_swing = 0.035 * math.sin(loop_phase)
        arm_right_swing = -0.035 * math.sin(loop_phase)

    # Stable main body planes.
    parts["torso"].location = (body_lean * 0.45, 0.0, torso_z)
    parts["torso"].rotation_mode = "XYZ"
    parts["torso"].rotation_euler = (0.0, shoulder_turn, body_lean)
    parts["torso_plane"].location = (0.27 + body_lean * 0.45, -0.275, torso_z + 0.08)
    parts["habi_band"].location = (body_lean * 0.45, -0.292, torso_z + 0.18)
    parts["habi_mango"].location = (0.22 + body_lean * 0.45, -0.300, torso_z + 0.18)
    parts["neck"].location = (body_lean * 0.25, 0.0, torso_z + 0.66)
    parts["head"].location = (body_lean * 0.22, 0.01, head_z)
    parts["hair_cap"].location = (body_lean * 0.22, 0.055, head_z + 0.29)
    parts["hair_back"].location = (body_lean * 0.20, -0.35, head_z + 0.03)
    parts["ear"].location = (0.41 + body_lean * 0.2, -0.02, head_z + 0.02)
    for texture_index, x in enumerate((-0.22, -0.11, 0.0, 0.11, 0.22)):
        parts[f"hair_texture_{texture_index}"].location = (x + body_lean * 0.2, -0.27, head_z + 0.33 + 0.035 * abs(x))

    shoulder_left = Vector((-0.54 + body_lean * 0.2, -0.01, torso_z + 0.34))
    shoulder_right = Vector((0.54 + body_lean * 0.2, -0.02, torso_z + 0.34))
    hand_left = Vector((-0.62, arm_left_swing, torso_z - 0.38))
    hand_right = Vector((0.62, arm_right_swing - 0.01, torso_z - 0.38 + 0.08 * hand_open))
    point_limb(parts["left_arm"], shoulder_left, hand_left, 0.20, 0.20)
    point_limb(parts["right_arm"], shoulder_right, hand_right, 0.20, 0.20)
    parts["left_hand"].location = hand_left
    parts["right_hand"].location = hand_right

    foot_left.z += lift_left
    foot_right.z += lift_right
    point_limb(parts["left_leg"], hip_left, foot_left + Vector((0.0, 0.0, 0.05)), 0.29, 0.31)
    point_limb(parts["right_leg"], hip_right, foot_right + Vector((0.0, 0.0, 0.05)), 0.29, 0.31)
    put_shoe("left", foot_left, 0.0, foot_left.y * 0.35)
    put_shoe("right", foot_right, 0.0, foot_right.y * 0.35)


def render_frame(animation: str, index: int, count: int, destination: Path):
    set_pose(animation, index, count)
    destination.parent.mkdir(parents=True, exist_ok=True)
    scene.render.filepath = str(destination)
    bpy.ops.render.render(scene=scene.name, write_still=True)
    image = bpy.data.images.load(str(destination), check_existing=False)
    if tuple(image.size) != (FRAME_SIZE, FRAME_SIZE) or image.channels != 4:
        raise RuntimeError(f"Invalid render: {destination}")
    bpy.data.images.remove(image)


ASSET_ROOT.mkdir(parents=True)
metadata: dict[str, dict[str, object]] = {}
for animation, (count, fps, seamless) in ANIMATIONS.items():
    for index in range(count):
        filename = f"runner_v2_{animation}_{index:02d}.png"
        destination = ASSET_ROOT / animation / filename
        render_frame(animation, index, count, destination)
        metadata[destination.relative_to(ASSET_ROOT).as_posix()] = {
            "animation": animation,
            "frame": index,
            "pivot": PIVOT,
            "fps": fps,
            "loop": "seamless" if seamless else "one-shot",
        }

# Stable one-pose pause export.
paused_path = ASSET_ROOT / "paused" / "runner_v2_paused_00.png"
render_frame("idle_ready", 0, 8, paused_path)
metadata[paused_path.relative_to(ASSET_ROOT).as_posix()] = {
    "animation": "paused",
    "frame": 0,
    "pivot": PIVOT,
    "fps": 0,
    "loop": "pose",
}

# Render only the separate soft oval shadow; it is never baked into character frames.
for obj in character_collection.objects:
    obj.hide_render = True
for obj in shadow_collection.objects:
    obj.hide_render = False
shadow_path = ASSET_ROOT / "shadow" / "runner_v2_ground_shadow.png"
shadow_path.parent.mkdir(parents=True, exist_ok=True)
scene.render.filepath = str(shadow_path)
bpy.ops.render.render(scene=scene.name, write_still=True)
for obj in character_collection.objects:
    obj.hide_render = False

manifest_lines = [
    "RUNNER V2 — original fictional adult 2.5D sprite animation manifest",
    "Canvas: 512 x 512 RGBA PNG; transparent padding; pivot: [256, 416] between the feet.",
    "View: rear three-quarter toward the Barangay Hall route; warm morning lighting; separate ground shadow.",
    "No text, logos, copied characters, medical devices, scores, enemies, or baked backgrounds.",
    "",
]
for animation, (count, fps, seamless) in ANIMATIONS.items():
    manifest_lines.append(f"{animation}: {fps} fps")
    manifest_lines.append(f"{animation} loop: {'seamless' if seamless else 'one-shot'}")
    manifest_lines.append(f"{animation} frames: {count}")
manifest_lines.extend(["paused: 1 pose", "ground_shadow: separate soft oval RGBA sprite"])
(ASSET_ROOT / "animation_manifest.txt").write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")
(ASSET_ROOT / "frame_metadata.json").write_text(json.dumps(metadata, indent=2, sort_keys=True) + "\n", encoding="utf-8")

scene["asset_id"] = "runner_v2_original_adult_sprite_set"
scene["frame_canvas"] = "512x512 transparent RGBA"
scene["pivot"] = PIVOT
scene["animation_counts"] = {name: spec[0] for name, spec in ANIMATIONS.items()}
scene["lighting"] = "warm morning key from camera-left with soft teal fill"
scene["integration_status"] = "exports authored; Godot integration intentionally pending explicit approval"
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_BLEND), check_existing=False)
print("RUNNER_V2_CHARACTER_BUILD_PASS", SOURCE_BLEND, ASSET_ROOT)
