extends SceneTree

var overflow_count := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 540)
	for name in ["main", "patient_setup", "controller_check", "tutorial", "ready"]:
		var screen: Control = load("res://scenes/%s.tscn" % name).instantiate()
		root.add_child(screen)
		await process_frame
		await process_frame
		var panel: Control = screen.get_node("Dashboard" if name == "main" else "Panel")
		print("LAYOUT %s panel=%s viewport=%s" % [name, panel.get_global_rect(), screen.size])
		_check_visible_controls(screen, Rect2(Vector2.ZERO, screen.size))
		await _capture("compact_" + name + ".png")
		if name == "tutorial":
			screen.call("show_action_index", 2)
			screen.call("demonstrate_action")
			await create_timer(0.18).timeout
			await _capture("tutorial_show_me_jump.png")
			screen.call("toggle_tutorial_pause")
			await _capture("tutorial_show_me_paused.png")
			screen.call("toggle_tutorial_pause")
			await create_timer(1.1).timeout
			screen.call("show_action_index", 0)
			screen.call("receive_practice_input", &"move_left", true, 1.0)
			await create_timer(0.3).timeout
			await _capture("guided_tutorial_success.png")
			screen.call("show_action_index", 2)
			screen.call("receive_practice_input", &"jump", true, 2.0)
			await create_timer(0.18).timeout
			await _capture("guided_tutorial_jump.png")
			screen.call("show_action_index", 3)
			screen.call("receive_practice_input", &"slide", true, 3.0)
			await create_timer(0.18).timeout
			await _capture("guided_tutorial_slide.png")
		screen.free()
	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	level.get_node("PromptDirector").call("open_response_window")
	level.call("receive_input", &"move_left", true, 10.0)
	await create_timer(0.3).timeout
	await _capture("compact_hud_toast.png")
	level.call("pause_gameplay")
	await _capture("compact_pause.png")
	level.call("end_session_neutrally")
	await _capture("compact_end.png")
	level.free()
	quit(0 if overflow_count == 0 else 1)


func _check_visible_controls(node: Node, bounds: Rect2) -> void:
	if node is Control and node.is_visible_in_tree():
		if not bounds.grow(1.0).encloses(node.get_global_rect()):
			overflow_count += 1
			printerr("OVERFLOW: " + str(node.get_path()) + " " + str(node.get_global_rect()))
	for child in node.get_children():
		_check_visible_controls(child, bounds)


func _capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../test_evidence/" + filename))
	print("CAPTURE %s: %s" % [filename, error_string(result)])
