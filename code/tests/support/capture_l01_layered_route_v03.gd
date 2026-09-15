extends SceneTree

const CAPTURES := [
	[Vector2i(960, 540), "l01_barangay_v03_960x540.png"],
	[Vector2i(1024, 768), "l01_barangay_v03_1024x768.png"],
	[Vector2i(1920, 1080), "l01_barangay_v03_1920x1080.png"],
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = CAPTURES[0][0]
	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	var motion: Node = level.get_node("WorldMotion")
	motion.call("begin_prompt_approach", 1, 2.5, 2.0)
	motion.call("_process", 2.8)
	level.call("_show_prompt", &"jump", "MOVE NOW", Color(0.35, 0.78, 0.66))
	motion.call("set_motion_paused", true)
	level.get_node("LevelWorld/L01BarangayLayers").call("set_motion_paused", true)
	for capture in CAPTURES:
		root.size = capture[0]
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var picture := root.get_texture().get_image()
		var requested_size: Vector2i = capture[0]
		if picture.get_size() != requested_size:
			# Preserve the 16:9 canvas and document the expected letterbox at 4:3.
			var framed := Image.create(requested_size.x, requested_size.y, false, Image.FORMAT_RGBA8)
			framed.fill(Color(0.024, 0.078, 0.106, 1.0))
			var inset := (requested_size - picture.get_size()) / 2
			framed.blit_rect(picture, Rect2i(Vector2i.ZERO, picture.get_size()), inset)
			picture = framed
		var path := ProjectSettings.globalize_path("res://../test_evidence/" + capture[1])
		var result := picture.save_png(path)
		print("CAPTURE %s: %s (%dx%d)" % [capture[1], error_string(result), picture.get_width(), picture.get_height()])
	level.free()
	quit(0)
