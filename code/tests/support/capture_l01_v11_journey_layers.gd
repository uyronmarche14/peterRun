extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v11_journey_layers"
const RouteJourney = preload("res://scripts/route_journey.gd")
const CAPTURES := [
	[Vector2i(960, 540), 0, "home_960x540"],
	[Vector2i(960, 540), 1, "waiting_960x540"],
	[Vector2i(960, 540), 2, "sari_sari_960x540"],
	[Vector2i(960, 540), 3, "palengke_960x540"],
	[Vector2i(1024, 768), 3, "palengke_1024x768"],
	[Vector2i(960, 540), 4, "plaza_960x540"],
	[Vector2i(1920, 1080), 4, "plaza_1920x1080"],
]
const STAGES := [
	^"JourneyStages/StageHome", ^"JourneyStages/StageWaitingShed",
	^"JourneyStages/StageSariSari", ^"JourneyStages/StagePalengke",
	^"JourneyStages/StagePlaza",
]

var level: Node
var scenery: Node2D
var world_motion: Node
var records: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("L01 v11 capture requires graphical Godot")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.title = "PETER RUN - L01 layered journey QA"
	level = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	scenery = level.get_node(^"LevelWorld/L01BarangayLayers")
	world_motion = level.get_node(^"WorldMotion")
	scenery.set_process(false)
	world_motion.set_process(false)
	scenery.call("configure_route", 4242, 0)
	_show_jump_prompt()
	root.size = Vector2i(960, 540)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	for capture in CAPTURES:
		_set_completed_progress(int(capture[1]))
		await _capture(String(capture[2]), capture[0])
	scenery.call("set_route_progress", 3, false)
	scenery.call("set_route_progress", 4, true)
	scenery.call("advance_layer_motion", 0.6)
	await _capture("market_to_plaza_mid_reveal_960x540", Vector2i(960, 540))
	var before_pause := _snapshot()
	level.call("pause_gameplay")
	scenery.call("advance_layer_motion", 20.0)
	world_motion.call("_process", 20.0)
	var pause_ok := before_pause == _snapshot()
	await _capture("paused_mid_reveal_960x540", Vector2i(960, 540))
	var file := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures": records, "pause_freeze_verified": pause_ok}, "\t"))
	file.close()
	level.free()
	print("L01 v11 QA: %d captures; pause freeze=%s" % [records.size(), pause_ok])
	quit(0 if pause_ok else 3)


func _show_jump_prompt() -> void:
	level.call("_hide_props")
	var props: Dictionary = level.get("_prop_nodes")
	var prop := props.get(&"jump") as Node2D
	assert(prop != null)
	prop.visible = true
	level.call("_update_prompt_card", &"jump", "MOVE NOW", Color(0.35, 0.78, 0.66))
	world_motion.call("begin_prompt_approach", 1, 2.5, 2.0)
	world_motion.call("_process", 3.45)
	world_motion.call("set_motion_paused", true)


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
	scenery.call("set_route_progress", stage, false)


func _snapshot() -> Dictionary:
	var snapshot := {"phase": scenery.get("motion_phase"), "road_distance": world_motion.get("motion_distance")}
	for path in STAGES:
		var stage := scenery.get_node(path) as Sprite2D
		snapshot[String(path)] = [stage.transform, stage.modulate, stage.visible, stage.material]
	return snapshot


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
	var filename := "l01_v11_%s.png" % label
	var result := screenshot.save_png(OUTPUT + "/" + filename)
	records.append({"file": filename, "size": [screenshot.get_width(), screenshot.get_height()], "result": error_string(result)})
	print("CAPTURE %s: %s" % [filename, error_string(result)])
