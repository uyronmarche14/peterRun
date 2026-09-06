extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 540)
	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	var motion: Node = level.get_node("WorldMotion")
	motion.set_process(false)
	motion.call("begin_prompt_approach", 1, 2.5, 2.0)
	motion.call("_process", 4.1)
	var player: Node = level.get_node("Player")
	level.call("_show_prompt", &"jump", "MOVE NOW", Color(0.35, 0.78, 0.66))
	player.call("handle_action", &"jump")
	await create_timer(0.26).timeout
	player.call("set_gameplay_paused", true)
	await _capture("movement_high_jump.png")
	player.call("set_gameplay_paused", false)
	await create_timer(0.39).timeout
	player.call("set_gameplay_paused", true)
	await _capture("movement_landing.png")
	player.call("reset_for_practice")
	level.call("_show_prompt", &"slide", "MOVE NOW", Color(0.35, 0.78, 0.66))
	player.call("handle_action", &"slide")
	await create_timer(0.16).timeout
	player.call("set_gameplay_paused", true)
	await _capture("movement_slide.png")
	player.call("reset_for_practice")
	level.call("_show_prompt", &"move_left", "MOVE NOW", Color(0.35, 0.78, 0.66))
	player.call("handle_action", &"move_left")
	await create_timer(0.07).timeout
	player.call("set_gameplay_paused", true)
	await _capture("movement_lane_change.png")
	level.free()
	quit(0)


func _capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../test_evidence/" + filename))
	print("CAPTURE %s: %s" % [filename, error_string(result)])
