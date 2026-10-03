extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v12_passing_street"
const STAGES := ["home", "waiting", "sari_sari", "palengke", "plaza"]
const RouteJourney = preload("res://scripts/route_journey.gd")

var level: Node
var route: Node2D
var world: Node
var records: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("L01 passing-street capture requires graphical Godot")
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
	world = level.get_node(^"WorldMotion")
	route.set_process(false)
	world.set_process(false)
	_show_jump_prompt()
	for index in STAGES.size():
		_set_completed_progress(index)
		for distance in [0.0, 8.0, 16.0]:
			_set_distance(distance)
			await _capture("%s_d%02d_960x540" % [STAGES[index], int(distance)], Vector2i(960, 540))
		if index == 2:
			_set_distance(10.0)
			await _capture("sari_sari_1024x768", Vector2i(1024, 768))
		if index == 4:
			await _capture("plaza_1920x1080", Vector2i(1920, 1080))
	route.call("set_route_progress", 3, false)
	route.call("set_route_progress", 4, true)
	route.call("advance_layer_motion", 0.6)
	await _capture("market_to_plaza_reveal_960x540", Vector2i(960, 540))
	var before_pause := _snapshot()
	level.call("pause_gameplay")
	world.call("_process", 12.0)
	route.call("advance_layer_motion", 12.0)
	var pause_ok := before_pause == _snapshot()
	await _capture("paused_960x540", Vector2i(960, 540))
	level.call("resume_gameplay")
	var Settings = load("res://scripts/game_settings.gd")
	Settings.set_reduced_motion(true)
	world.call("set_motion_paused", false)
	route.call("set_motion_paused", false)
	route.call("advance_layer_motion", 0.1)
	await _capture("reduced_motion_960x540", Vector2i(960, 540))
	Settings.set_reduced_motion(false)
	var file := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures": records, "pause_freeze_verified": pause_ok}, "\t"))
	file.close()
	level.free()
	print("L01 v12 QA: %d captures, pause freeze=%s" % [records.size(), pause_ok])
	quit(0 if pause_ok else 3)


func _set_distance(distance: float) -> void:
	world.set("motion_distance", distance)
	world.call("_update_road")
	route.call("set_roadside_distance", distance)


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
	route.call("set_route_progress", stage, false)


func _show_jump_prompt() -> void:
	level.call("_hide_props")
	var props: Dictionary = level.get("_prop_nodes")
	var prop := props.get(&"jump") as Node2D
	prop.visible = true
	level.call("_update_prompt_card", &"jump", "MOVE NOW", Color(0.35, 0.78, 0.66))
	world.call("begin_prompt_approach", 1, 2.5, 2.0)
	world.call("_process", 3.45)
	world.call("set_motion_paused", true)


func _snapshot() -> Array:
	var result := [world.get("motion_distance"), route.get("motion_phase")]
	for index in STAGES.size():
		var stage := route.get_node("JourneyStages/" + ["StageHome", "StageWaitingShed", "StageSariSari", "StagePalengke", "StagePlaza"][index]) as Sprite2D
		var passing := stage.get_node(^"PassingStreet") as Node2D
		for sprite_value in passing.call("get_module_sprites"):
			var sprite := sprite_value as Sprite2D
			result.append([sprite.position, sprite.scale, sprite.modulate, sprite.visible])
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
	var name := "l01_v12_" + label + ".png"
	var result := screenshot.save_png(OUTPUT + "/" + name)
	records.append({"file": name, "size": [screenshot.get_width(), screenshot.get_height()], "result": error_string(result)})
	print("CAPTURE " + name + ": " + error_string(result))
