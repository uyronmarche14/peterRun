extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v07_forward_travel"
const CAPTURES := [
	[Vector2i(960, 540), "l01_v07_960x540.png"],
	[Vector2i(1024, 768), "l01_v07_1024x768.png"],
	[Vector2i(1920, 1080), "l01_v07_1920x1080.png"],
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("L01 v07 visual capture requires a graphical Godot session.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 540)
	root.title = "PETER RUN - L01 v07 forward-travel QA"
	await process_frame
	await process_frame
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	var world_motion: Node = level.get_node(^"WorldMotion")
	var route_motion: Node = level.get_node(^"LevelWorld/L01BarangayLayers")
	world_motion.set_process(false)
	route_motion.set_process(false)
	world_motion.call("_process", 8.0)
	route_motion.call("advance_layer_motion", 1.25)
	world_motion.call("begin_prompt_approach", 1, 2.5, 2.0)
	world_motion.call("_process", 1.3)
	level.call("_show_prompt", &"jump", "MOVE NOW", Color(0.35, 0.78, 0.66))
	for capture in CAPTURES:
		var target_size: Vector2i = capture[0]
		root.size = target_size
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.get_size() != target_size:
			var framed := Image.create(target_size.x, target_size.y, false, Image.FORMAT_RGBA8)
			framed.fill(Color(0.018, 0.048, 0.06, 1.0))
			var inset: Vector2i = (target_size - image.get_size()) / 2
			framed.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), inset)
			image = framed
		var result := image.save_png(OUTPUT + "/" + String(capture[1]))
		print("CAPTURE %s: %s (%dx%d)" % [String(capture[1]), error_string(result), image.get_width(), image.get_height()])
	level.free()
	quit(0)
