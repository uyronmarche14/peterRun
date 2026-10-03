extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v14_visual_clearance"
const RouteJourney = preload("res://scripts/route_journey.gd")

var level: Node
var world: Node
var route: Node2D
var records: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("L01 visual-clearance capture needs graphical Godot")
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
	world = level.get_node(^"WorldMotion")
	route = level.get_node(^"LevelWorld/L01BarangayLayers")
	world.set_process(false)
	route.set_process(false)
	route.call("configure_route", 11, 0)
	route.call("advance_layer_motion", 6.0)

	_show_formation(&"l01_p01_move_right", &"move_right", 3.9)
	await _capture("home_crates_outer_960x540", Vector2i(960, 540))
	await _capture("home_crates_outer_1024x768", Vector2i(1024, 768))
	_show_formation(&"l01_p01_move_right", &"move_right", 4.5)
	await _capture("home_crates_contact_960x540", Vector2i(960, 540))
	_show_single(&"jump", 0, 4.2)
	await _capture("home_puddle_left_960x540", Vector2i(960, 540))
	_show_single(&"slide", 2, 4.2)
	await _capture("home_laundry_right_960x540", Vector2i(960, 540))
	for stage_data in [[1, "waiting"], [2, "sari_sari"]]:
		var stage := int(stage_data[0])
		_set_completed_progress(stage)
		route.call("configure_route", 11 + stage, stage)
		route.call("advance_layer_motion", 6.0)
		_show_single(&"jump", 1, 3.45)
		await _capture("%s_street_life_960x540" % String(stage_data[1]), Vector2i(960, 540))

	_set_completed_progress(3)
	route.call("configure_route", 17, 3)
	route.call("advance_layer_motion", 6.0)
	_show_formation(&"l01_p10_jump_gate_center", &"jump", 4.0)
	await _capture("palengke_mixed_960x540", Vector2i(960, 540))
	await _capture("palengke_mixed_1920x1080", Vector2i(1920, 1080))
	_set_completed_progress(4)
	route.call("configure_route", 19, 4)
	route.call("advance_layer_motion", 6.0)
	_show_single(&"jump", 1, 3.45)
	await _capture("plaza_street_life_960x540", Vector2i(960, 540))

	var manifest := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"captures": records}, "\t"))
	manifest.close()
	level.free()
	print("L01 v14 visual clearance: %d graphical captures" % records.size())
	quit(0)


func _show_single(action: StringName, lane: int, elapsed: float) -> void:
	level.call("_hide_props")
	var props: Dictionary = level.get("_prop_nodes")
	(props.get(action) as Node2D).visible = true
	level.call("_update_prompt_card", action, "MOVE NOW", Color(0.35, 0.78, 0.66))
	var no_nodes: Array[Node2D] = []
	var no_lanes: Array[int] = []
	world.call("set_prompt_formation", no_nodes, no_lanes)
	world.call("set_prompt_companions", no_nodes, no_lanes)
	world.call("set_motion_paused", false)
	world.call("begin_prompt_approach", lane, 2.5, 2.0)
	world.call("_process", elapsed)
	world.call("set_motion_paused", true)


func _show_formation(pattern_id: StringName, action: StringName, elapsed: float) -> void:
	var formation: Dictionary = {}
	for candidate_value in level.get("_formation_library"):
		if candidate_value is Dictionary and candidate_value.get("pattern_id", &"") == pattern_id:
			formation = (candidate_value as Dictionary).duplicate(true)
			break
	assert(not formation.is_empty())
	level.set("_active_formation", formation)
	level.call("_show_formation_prompt", action, "MOVE NOW", Color(0.35, 0.78, 0.66))
	var lanes: Array[int] = []
	for obstacle_value in formation.get("obstacles", []):
		lanes.append(int((obstacle_value as Dictionary).get("lane", 1)))
	world.call("set_prompt_formation", level.call("get_active_formation_props"), lanes)
	var no_nodes: Array[Node2D] = []
	var no_lanes: Array[int] = []
	world.call("set_prompt_companions", no_nodes, no_lanes)
	world.call("set_motion_paused", false)
	world.call("begin_prompt_approach", 1, 2.5, 2.0)
	world.call("_process", elapsed)
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
	var filename := "l01_v14_" + label + ".png"
	var result := screenshot.save_png(OUTPUT + "/" + filename)
	records.append({"file": filename, "size": [screenshot.get_width(), screenshot.get_height()], "result": error_string(result)})
	print("CAPTURE %s: %s" % [filename, error_string(result)])
