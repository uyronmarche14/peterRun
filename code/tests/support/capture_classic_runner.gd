extends SceneTree
## Graphical-only QA harness. Runs the real runner/player, not copied sprites.
## godot --path code -s res://tests/support/capture_classic_runner.gd
## Captures are native viewport readbacks; no image compositing/resizing.

const SpriteModel = preload("res://scripts/classic_runner_sprite.gd")
const Director = preload("res://scripts/prompt_director.gd")
const SIZES := [Vector2i(960, 540), Vector2i(1024, 768), Vector2i(1920, 1080)]
const OUTPUT := "res://../test_evidence/runner_classic_v01"
var level: Node
var player: Node
var captures: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("QA CAPTURE REFUSED: launch graphical Godot, never --headless.")
		quit(2)
		return
	for clip in SpriteModel.CLIPS:
		for index in SpriteModel.CLIPS[clip][0]:
			if not ResourceLoader.exists(SpriteModel.frame_path(clip, index)):
				printerr("QA CAPTURE BLOCKED: production frames absent/unimported. No placeholder capture created.")
				quit(3)
				return
	root.mode = Window.MODE_WINDOWED
	root.title = "PETER RUN — Classic adult sprite QA"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	level = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	level.set_process_unhandled_input(false)
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	level.get_node("WorldMotion").call("set_motion_paused", true)
	level.get_node("LevelWorld/L01BarangayLayers").call("set_motion_paused", true)
	level.get_node("ContactEffects").set_process(false)
	level.get_node("HUD/HUDRoot/FeedbackToast").visible = false
	player = level.get_node("Player")
	player.set_process(false)
	for size in SIZES:
		root.size = size
		await process_frame
		await process_frame
		for pose in [&"idle_ready", &"walk_forward", &"move_left", &"move_right", &"jump", &"slide", &"success_settle", &"neutral_clear", &"rest", &"paused"]:
			player.call("reset_for_practice")
			match pose:
				&"walk_forward":
					player.call("set_walking", true)
					_step(0.45)
				&"move_left", &"move_right":
					player.call("handle_action", pose)
					_step(0.11)
				&"jump", &"slide":
					player.call("handle_action", pose)
					_step(0.52 if pose == &"jump" else 0.32)
				&"success_settle", &"neutral_clear":
					level.call("_record_prompt_resolution", &"jump", Director.Resolution.SUCCESS if pose == &"success_settle" else Director.Resolution.SAFE_CLEAR)
					_step(0.4)
				&"rest", &"paused":
					player.call("set_resting_preview", pose == &"paused")
					_step(0.4)
				_:
					_step(0.7)
			player.call("set_gameplay_paused", true)
			if not await _capture(String(pose), size):
				level.free()
				quit(4)
				return
			if pose == &"jump":
				# Freeze and resume the real pause overlay while airborne.
				level.call("pause_gameplay")
				await create_timer(0.2).timeout
				await _capture("jump_pause_overlay", size)
				level.call("resume_gameplay")
				level.get_node("WorldMotion").call("set_motion_paused", true)
				level.get_node("LevelWorld/L01BarangayLayers").call("set_motion_paused", true)
				_step(0.1)
				player.call("set_gameplay_paused", true)
				await _capture("jump_resumed", size)
			level.get_node("HUD/HUDRoot/FeedbackToast").visible = false
			level.get_node("ContactEffects").call("set_effects_paused", true)
	var manifest := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify(captures, "\t"))
	manifest.close()
	level.free()
	print("CLASSIC QA COMPLETE: %d graphical viewport captures in %s" % [captures.size(), ProjectSettings.globalize_path(OUTPUT)])
	quit(0)

func _step(seconds: float) -> void:
	# Actual gameplay tweens and actual sprite clock, sampled deterministically.
	for key in [&"_lane_tween", &"_action_tween", &"_shadow_tween"]:
		var tween: Tween = player.get(key)
		if tween != null and tween.is_valid():
			tween.pause()
			tween.custom_step(seconds)
	player.call("_process", seconds)

func _capture(pose: String, requested_size: Vector2i) -> bool:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var sprite: Sprite2D = player.get_node("Visual/CharacterSprite")
	var filename := "%s_%dx%d.png" % [pose, requested_size.x, requested_size.y]
	var result := image.save_png(OUTPUT + "/" + filename)
	captures.append({"file": filename, "window_size": [root.size.x, root.size.y], "viewport_size": [image.get_width(), image.get_height()], "clip": String(sprite.get("animation")), "frame": sprite.call("get_clip_frame"), "player_position": [player.position.x, player.position.y], "result": error_string(result)})
	print("CAPTURE %s: %s viewport=%s" % [filename, error_string(result), image.get_size()])
	return result == OK
