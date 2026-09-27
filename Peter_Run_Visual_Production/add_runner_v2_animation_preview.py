"""Add a playable Blender viewport preview of the exported Runner V2 PNG frames."""

from __future__ import annotations

from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "code" / "art" / "characters" / "runner_v2"
SOURCE_PATH = Path(bpy.data.filepath)
PREVIEW_SCENE_NAME = "RUNNER_V2_ANIMATION_PREVIEW"

ANIMATIONS = (
    ("idle_ready", 8),
    ("walk_forward", 10),
    ("move_left", 8),
    ("move_right", 8),
    ("jump_low", 10),
    ("slide_duck", 10),
    ("success_settle", 8),
    ("neutral_clear", 6),
    ("rest", 6),
    ("paused", 1),
)

assert SOURCE_PATH.name == "RunnerV2_Character_Source_v01.blend"
assert bpy.data.scenes.get(PREVIEW_SCENE_NAME) is None

preview = bpy.data.scenes.new(PREVIEW_SCENE_NAME)
preview["preview_kind"] = "sprite_sequence"
preview["asset_id"] = "runner_v2_original_adult_sprite_set"
preview.frame_start = 1
preview.render.fps = 10
preview.render.resolution_x = 512
preview.render.resolution_y = 512
preview.render.resolution_percentage = 100

collection = bpy.data.collections.new("RUNNER_V2_PLAYABLE_FRAME_PREVIEW")
preview.collection.children.link(collection)

camera_data = bpy.data.cameras.new("RunnerV2_Preview_Camera")
camera_data.type = "ORTHO"
camera_data.ortho_scale = 4.4
camera = bpy.data.objects.new("RunnerV2_Preview_Camera", camera_data)
collection.objects.link(camera)
camera.location = (0.0, 0.0, 10.0)
camera.rotation_euler = (0.0, 0.0, 0.0)
preview.camera = camera

frame_number = 1
for animation, count in ANIMATIONS:
    preview.timeline_markers.new(animation.upper(), frame=frame_number)
    for index in range(count):
        frame_path = ASSET_ROOT / animation / f"runner_v2_{animation}_{index:02d}.png"
        assert frame_path.is_file(), frame_path
        image = bpy.data.images.load(str(frame_path), check_existing=True)
        image.alpha_mode = "STRAIGHT"

        sprite = bpy.data.objects.new(f"RunnerV2_Preview_{animation}_{index:02d}", None)
        sprite.empty_display_type = "IMAGE"
        sprite.empty_display_size = 4.2
        sprite.color = (1.0, 1.0, 1.0, 1.0)
        sprite.data = image
        collection.objects.link(sprite)

        sprite.hide_viewport = True
        sprite.hide_render = True
        sprite.keyframe_insert(data_path="hide_viewport", frame=1)
        sprite.keyframe_insert(data_path="hide_render", frame=1)
        sprite.hide_viewport = False
        sprite.hide_render = False
        sprite.keyframe_insert(data_path="hide_viewport", frame=frame_number)
        sprite.keyframe_insert(data_path="hide_render", frame=frame_number)
        sprite.hide_viewport = True
        sprite.hide_render = True
        sprite.keyframe_insert(data_path="hide_viewport", frame=frame_number + 1)
        sprite.keyframe_insert(data_path="hide_render", frame=frame_number + 1)
        frame_number += 1

preview.frame_end = frame_number - 1
preview.frame_set(1)
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE_PATH))
print(f"RUNNER_V2_ANIMATION_PREVIEW_PASS {preview.frame_end} frames {len(preview.timeline_markers)} markers")
