extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v13_street_life"
const RouteJourney = preload("res://scripts/route_journey.gd")
const STAGES := ["home", "waiting", "sari_sari", "palengke", "plaza"]

var level: Node
var route: Node2D
var records: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Street-life capture requires graphical Godot")
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
	route = level.get_node(^"LevelWorld/L01BarangayLayers")
	route.set_process(false)
	level.get_node(^"WorldMotion").set_process(false)
	_show_jump_prompt()
	for index in STAGES.size():
		_set_completed_progress(index)
		route.call("configure_route", index + 1, index)
		await _capture("%s_rest_960x540" % STAGES[index], Vector2i(960, 540))
		route.call("advance_layer_motion", 6.0)
		await _capture("%s_life_960x540" % STAGES[index], Vector2i(960, 540))
		if index == 2:
			await _capture("sari_sari_life_1024x768", Vector2i(1024, 768))
		if index == 4:
			await _capture("plaza_life_1920x1080", Vector2i(1920, 1080))
	var before_pause := _snapshot()
	level.call("pause_gameplay")
	route.call("advance_layer_motion", 12.0)
	var pause_ok := before_pause == _snapshot()
	await _capture("paused_960x540", Vector2i(960, 540))
	level.call("resume_gameplay")
	var Settings = load("res://scripts/game_settings.gd")
	Settings.set_reduced_motion(true)
	route.call("advance_layer_motion", 0.1)
	await _capture("reduced_motion_960x540", Vector2i(960, 540))
	Settings.set_reduced_motion(false)
	var file := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures": records, "pause_freeze_verified": pause_ok}, "\t"))
	file.close()
	level.free()
	print("L01 v13 street-life QA: %d captures, pause freeze=%s" % [records.size(), pause_ok])
	quit(0 if pause_ok else 3)


func _show_jump_prompt() -> void:
	level.call("_hide_props")
	var props: Dictionary = level.get("_prop_nodes")
	var prop := props.get(&"jump") as Node2D
	prop.visible = true
	level.call("_update_prompt_card", &"jump", "MOVE NOW", Color(0.35, 0.78, 0.66))
	var world := level.get_node(^"WorldMotion")
	world.call("begin_prompt_approach", 1, 2.5, 2.0)
	world.call("_process", 3.45)
	world.call("set_motion_paused", true)


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
		var stage := route.get_node("JourneyStages/" + stage_name) as Sprite2D
		var life := stage.get_node(^"StreetLife") as Node2D
		for part_value in life.call("get_animated_parts"):
			var part := part_value as Sprite2D
			result.append([part.position, part.frame, part.rotation])
	return result


func _capture(label: String, requested_size: Vector2i) -> void:
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
	var name := "l01_v13_" + label + ".png"
	var result := screenshot.save_png(OUTPUT + "/" + name)
	records.append({"file": name, "size": [screenshot.get_width(), screenshot.get_height()], "result": error_string(result)})
	print("CAPTURE " + name + ": " + error_string(result))
