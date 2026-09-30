extends SceneTree

const CAPTURES := [
	[&"move_left", "l01_prompt_crates_v03_960x540.png"],
	[&"jump", "l01_prompt_puddle_v03_960x540.png"],
	[&"slide", "l01_prompt_laundry_v03_960x540.png"],
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	root.size = Vector2i(960, 540)
	await process_frame
	await process_frame
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	var motion: Node = level.get_node("WorldMotion")
	motion.set_process(false)
	var prop_nodes: Dictionary = level.get("_prop_nodes")
	for capture in CAPTURES:
		level.call("_hide_props")
		var action: StringName = capture[0]
		var prop := prop_nodes.get(action) as Node2D
		assert(prop != null)
		prop.visible = true
		level.call("_update_prompt_card", action, "MOVE NOW", Color(0.35, 0.78, 0.66))
		motion.call("begin_prompt_approach", 1, 2.5, 2.0)
		motion.call("_process", 3.6)
		motion.call("set_motion_paused", true)
		level.get_node("LevelWorld/L01BarangayLayers").call("set_motion_paused", true)
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		var path := ProjectSettings.globalize_path("res://../test_evidence/" + String(capture[1]))
		var result := image.save_png(path)
		print("CAPTURE %s: %s (%dx%d)" % [capture[1], error_string(result), image.get_width(), image.get_height()])
		motion.call("set_motion_paused", false)
	level.free()
	quit(0)
