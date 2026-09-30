extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v05_original_street_restore"
const SIZES := [Vector2i(960, 540), Vector2i(1024, 768), Vector2i(1920, 1080)]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("L01 visual capture requires a graphical Godot session.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.size = SIZES[0]
	await process_frame
	await process_frame
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	var world_motion := level.get_node(^"WorldMotion") as Node
	var route_motion := level.get_node(^"LevelWorld/L01BarangayLayers") as Node
	world_motion.set_process(false)
	route_motion.set_process(false)
	world_motion.call("_process", 3.0)
	route_motion.call("advance_layer_motion", 3.0)
	world_motion.call("begin_prompt_approach", 1, 2.5, 2.0)
	world_motion.call("_process", 1.3)
	level.call("_show_prompt", &"jump", "MOVE NOW", Color(0.35, 0.78, 0.66))
	for size in SIZES:
		root.size = size
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.get_size() != size:
			var framed := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
			framed.fill(Color(0.018, 0.048, 0.06, 1.0))
			framed.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), (size - image.get_size()) / 2)
			image = framed
		var filename := "l01_original_street_%dx%d.png" % [size.x, size.y]
		var result := image.save_png(OUTPUT + "/" + filename)
		print("CAPTURE %s: %s" % [filename, error_string(result)])
	level.free()
	quit(0)
