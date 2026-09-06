extends SceneTree

# Developer-only rendered evidence. Run with a graphics driver, not --headless.
func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	var motion: Node = level.get_node("WorldMotion")
	motion.set_process(false)
	motion.call("begin_prompt_approach", 1, 2.5, 2.0)
	motion.call("_process", 4.0)
	level.call("_show_prompt", &"move_left", "MOVE NOW", Color(0.35, 0.78, 0.66))
	var player: Node = level.get_node("Player")
	player.call("handle_action", &"move_left")
	await create_timer(0.13).timeout
	player.call("set_gameplay_paused", true)
	await _capture("runner_polish_1080.png")
	player.call("set_gameplay_paused", false)
	await create_timer(0.2).timeout
	motion.call("begin_prompt_approach", 0, 2.5, 2.0)
	motion.call("_process", 4.1)
	level.call("_show_prompt", &"jump", "MOVE NOW", Color(0.35, 0.78, 0.66))
	player.call("handle_action", &"jump")
	await create_timer(0.18).timeout
	player.call("set_gameplay_paused", true)
	root.size = Vector2i(480, 270)
	await _capture("runner_polish_native.png")
	level.free()
	quit(0)


func _capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://../test_evidence/" + filename)
	var result := picture.save_png(path)
	print("CAPTURE %s: %s (%dx%d)" % [filename, error_string(result), picture.get_width(), picture.get_height()])
