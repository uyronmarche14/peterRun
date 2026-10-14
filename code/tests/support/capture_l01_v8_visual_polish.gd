extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v8_visual_polish"
const STAGES := ["home", "waiting", "sari_sari", "palengke", "plaza"]
const SIZES := [Vector2i(480, 270), Vector2i(960, 540), Vector2i(1024, 768), Vector2i(1920, 1080)]

var captures: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("V8 visual capture requires graphical Godot")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	var motion := level.get_node(^"WorldMotion")
	motion.set_process(false)
	level.call("_update_prompt_card", &"jump", "GET READY", Color(1.0, 0.855, 0.51))
	for stage_index in STAGES.size():
		route.call("configure_route", 41, stage_index)
		for size in SIZES:
			await _capture(STAGES[stage_index], "rest", size)
		route.call("advance_layer_motion", 2.5)
		await _capture(STAGES[stage_index], "gesture", Vector2i(960, 540))
	route.call("configure_route", 41, 0)
	route.call("set_route_progress", 1, true)
	route.call("advance_layer_motion", 0.6)
	await _capture("home_to_waiting", "mid_reveal", Vector2i(960, 540))
	route.call("advance_layer_motion", 0.6)
	await _capture("waiting", "reveal_complete", Vector2i(960, 540))
	route.call("configure_route", 41, 0)
	level.call("_hide_props")
	level.call("_update_prompt_card", &"slide", "GET READY", Color(1.0, 0.855, 0.51))
	var laundry := (load("res://scenes/props/laundry_line.tscn") as PackedScene).instantiate() as Node2D
	level.get_node(^"LevelWorld/PromptWorldAnchor/PromptProps").add_child(laundry)
	motion.call("begin_prompt_approach", 0, 2.5, 2.0)
	for fraction in [0.25, 0.6, 1.0]:
		motion.set("_prompt_elapsed", fraction * 4.5)
		motion.call("_apply_prompt_projection")
		await _capture("laundry_left", "depth_%02d" % int(round(fraction * 100.0)), Vector2i(960, 540))
	laundry.free()
	level.call("pause_gameplay")
	await _capture("home", "paused", Vector2i(960, 540))
	level.free()
	var output := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(captures, "\t"))
	output.close()
	print("L01 v8 visual capture: %d images" % captures.size())
	quit(0)


func _capture(stage: String, pose: String, size: Vector2i) -> void:
	root.size = size
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var name := "l01_v8_%s_%s_%dx%d.png" % [stage, pose, size.x, size.y]
	var result := screenshot.save_png(OUTPUT + "/" + name)
	captures.append({"file": name, "result": error_string(result), "size": [size.x, size.y]})
	print("CAPTURE %s: %s" % [name, error_string(result)])
