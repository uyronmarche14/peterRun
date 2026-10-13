extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v16_review"
const RouteJourney = preload("res://scripts/route_journey.gd")
const STAGES := ["home", "waiting", "sari_sari", "palengke", "plaza"]
const SIZES := [Vector2i(480, 270), Vector2i(960, 540), Vector2i(1024, 768), Vector2i(1920, 1080)]

var captures: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("L01 visual review requires graphical Godot")
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
	level.get_node(^"WorldMotion").set_process(false)
	for index in STAGES.size():
		_set_completed_progress(level, index)
		route.call("configure_route", 41, index)
		for size in SIZES:
			await _capture(STAGES[index], "rest", size)
		route.call("advance_layer_motion", 1.25)
		await _capture(STAGES[index], "gesture", Vector2i(960, 540))
	level.call("pause_gameplay")
	await _capture("plaza", "paused", Vector2i(960, 540))
	level.call("resume_gameplay")
	var Settings = load("res://scripts/game_settings.gd")
	Settings.set_reduced_motion(true)
	route.call("advance_layer_motion", 0.5)
	await _capture("plaza", "reduced", Vector2i(960, 540))
	Settings.set_reduced_motion(false)
	var output := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(captures, "\t"))
	output.close()
	level.free()
	print("L01 v16 visual review: %d captures" % captures.size())
	quit(0)


func _set_completed_progress(level: Node, stage: int) -> void:
	var config: Variant = level.get("session_config")
	var result: Variant = level.get("session_result")
	var target := 0
	for action in config.ACTIONS:
		target += config.get_target(action)
	var desired := 0
	while desired < target and RouteJourney.get_progress(desired, target) < stage:
		desired += 1
	var completed := 0
	for action in config.ACTIONS:
		completed += result.get_completed(action)
	var index := 0
	while completed < desired:
		var action: StringName = config.ACTIONS[index % config.ACTIONS.size()]
		if result.get_completed(action) < config.get_target(action):
			result.record_success(action)
			completed += 1
		index += 1
	level.call("_update_progress_hud", false)


func _capture(stage: String, pose: String, size: Vector2i) -> void:
	root.size = size
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	if screenshot.get_size() != size:
		var framed := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		framed.fill(Color(0.024, 0.078, 0.106, 1.0))
		framed.blit_rect(screenshot, Rect2i(Vector2i.ZERO, screenshot.get_size()), (size - screenshot.get_size()) / 2)
		screenshot = framed
	var name := "l01_v16_%s_%s_%dx%d.png" % [stage, pose, size.x, size.y]
	var result := screenshot.save_png(OUTPUT + "/" + name)
	captures.append({"file": name, "result": error_string(result), "size": [size.x, size.y]})
	print("CAPTURE %s: %s" % [name, error_string(result)])
