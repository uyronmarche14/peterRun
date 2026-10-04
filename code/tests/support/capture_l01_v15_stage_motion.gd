extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v15_stage_motion"
const RouteJourney = preload("res://scripts/route_journey.gd")
const STAGES := ["home", "waiting", "sari_sari", "palengke", "plaza"]

var level: Node
var route: Node2D
var records: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Visual capture requires graphical Godot")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 540)
	level = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	route = level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	level.get_node(^"WorldMotion").set_process(false)
	for index in STAGES.size():
		_set_completed_progress(index)
		route.call("configure_route", 41, index)
		await _capture(STAGES[index], "rest", Vector2i(960, 540))
		route.call("advance_layer_motion", 1.25)
		await _capture(STAGES[index], "gesture", Vector2i(960, 540))
		await _capture(STAGES[index], "gesture", Vector2i(1024, 768))
		await _capture(STAGES[index], "gesture", Vector2i(1920, 1080))
		route.call("advance_layer_motion", 1.25)
		await _capture(STAGES[index], "breeze", Vector2i(960, 540))
	var before_pause := _snapshot()
	level.call("pause_gameplay")
	route.call("advance_layer_motion", 5.0)
	var pause_ok := _snapshot() == before_pause
	level.call("resume_gameplay")
	var Settings = load("res://scripts/game_settings.gd")
	Settings.set_reduced_motion(true)
	route.call("advance_layer_motion", 0.5)
	var reduced_ok := true
	for stage_name in ["StageHome", "StageWaitingShed", "StageSariSari", "StagePalengke", "StagePlaza"]:
		var life := route.get_node("JourneyStages/%s/StreetLife" % stage_name) as Node2D
		for part_value in life.call("get_animated_parts"):
			var part := part_value as Sprite2D
			reduced_ok = reduced_ok and part.frame == 0 and is_zero_approx(part.rotation)
	Settings.set_reduced_motion(false)
	var file := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures": records, "pause_freeze_verified": pause_ok, "reduced_motion_verified": reduced_ok}, "\t"))
	file.close()
	level.free()
	print("L01 v15 five-stage motion QA: %d captures, pause=%s, reduced=%s" % [records.size(), pause_ok, reduced_ok])
	quit(0 if pause_ok and reduced_ok else 3)


func _set_completed_progress(stage: int) -> void:
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


func _snapshot() -> Array:
	var result := [route.get("motion_phase")]
	for stage_name in ["StageHome", "StageWaitingShed", "StageSariSari", "StagePalengke", "StagePlaza"]:
		var life := route.get_node("JourneyStages/%s/StreetLife" % stage_name) as Node2D
		for part_value in life.call("get_animated_parts"):
			var part := part_value as Sprite2D
			result.append([part.position, part.frame, part.rotation])
	return result


func _capture(stage: String, pose: String, requested_size: Vector2i) -> void:
	root.size = requested_size
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	if screenshot.get_size() != requested_size:
		var framed := Image.create(requested_size.x, requested_size.y, false, Image.FORMAT_RGBA8)
		framed.fill(Color(0.024, 0.078, 0.106, 1.0))
		framed.blit_rect(screenshot, Rect2i(Vector2i.ZERO, screenshot.get_size()), (requested_size - screenshot.get_size()) / 2)
		screenshot = framed
	var name := "l01_v15_%s_%s_%dx%d.png" % [stage, pose, requested_size.x, requested_size.y]
	var result := screenshot.save_png(OUTPUT + "/" + name)
	records.append({"file": name, "size": [screenshot.get_width(), screenshot.get_height()], "result": error_string(result)})
	print("CAPTURE " + name + ": " + error_string(result))
