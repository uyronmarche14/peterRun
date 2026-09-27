"""Validate the Blender source contract for the Runner V2 original adult sprite set."""

import bpy


scene = bpy.context.scene
assert scene.name == "RUNNER_V2_SPRITE_MASTER", scene.name
assert scene.get("asset_id") == "runner_v2_original_adult_sprite_set"
assert scene.get("frame_canvas") == "512x512 transparent RGBA"
assert list(scene.get("pivot")) == [256, 416]
assert scene.camera is not None and scene.camera.data.type == "ORTHO"
assert scene.render.film_transparent

character = bpy.data.collections.get("RUNNER_V2_ORIGINAL_ADULT_CHARACTER")
shadow = bpy.data.collections.get("RUNNER_V2_SEPARATE_GROUND_SHADOW")
lighting = bpy.data.collections.get("RUNNER_V2_WARM_MORNING_LIGHTING")
assert character is not None and shadow is not None and lighting is not None
assert len(character.all_objects) >= 20
assert any(obj.name == "RunnerV2_Coral_Top" for obj in character.all_objects)
assert any(obj.name == "RunnerV2_Subtle_Habi_Teal_Band" for obj in character.all_objects)
assert any(obj.name == "RunnerV2_Adult_Head" for obj in character.all_objects)
assert any(obj.name == "RunnerV2_Soft_Oval_Ground_Shadow" for obj in shadow.all_objects)
assert not any(obj.type == "FONT" for obj in character.all_objects)
assert all("Peter" not in obj.name for obj in character.all_objects)

preview = bpy.data.scenes.get("RUNNER_V2_ANIMATION_PREVIEW")
assert preview is not None
assert preview.get("preview_kind") == "sprite_sequence"
assert preview.frame_start == 1
assert preview.frame_end == 75
assert len(preview.timeline_markers) == 10
preview_images = [obj for obj in preview.objects if obj.type == "EMPTY" and obj.empty_display_type == "IMAGE"]
assert len(preview_images) == 75, len(preview_images)

print("RUNNER_V2_CHARACTER_SOURCE_VALIDATION_PASS", len(character.all_objects), "character objects")
