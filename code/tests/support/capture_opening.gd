extends SceneTree

var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	var menu: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await create_timer(1.4).timeout
	_check_bounds(menu, Rect2(0, 0, 480, 270))
	await _capture("opening_1920x1080")
	menu.call("open_settings")
	await process_frame
	_check_bounds(menu, Rect2(0, 0, 480, 270))
	await _capture("opening_settings")
	menu.call("close_overlays")
	menu.call("request_quit")
	await _capture("opening_quit_confirmation")
	menu.call("close_overlays")
	for window_size in [Vector2i(960, 540), Vector2i(1024, 768)]:
		root.size = window_size
		await process_frame
		await process_frame
		_check_bounds(menu, Rect2(0, 0, 480, 270))
		await _capture("opening_%dx%d" % [window_size.x, window_size.y])
	menu.free()
	await create_timer(0.15).timeout
	print("Opening rendered layout: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)


func _check_bounds(node: Node, bounds: Rect2) -> void:
	if node is Control and node.is_visible_in_tree():
		if not bounds.grow(1).encloses(node.get_global_rect()):
			failures += 1
			printerr("OVERFLOW: " + str(node.get_path()) + " " + str(node.get_global_rect()))
	for child in node.get_children():
		_check_bounds(child, bounds)


func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var result := frame.save_png(ProjectSettings.globalize_path("res://../test_evidence/" + name + ".png"))
	if result != OK:
		failures += 1
	print("CAPTURE %s: %s" % [name, error_string(result)])
