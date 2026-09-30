extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v05"
const SIZES := [Vector2i(960, 540), Vector2i(1024, 768), Vector2i(1902, 1026), Vector2i(1920, 1080)]

var level: Node
var world_motion: Node
var route_motion: Node
var captures: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("L01 v05 capture requires graphical Godot.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.title = "PETER RUN - L01 v05 visual QA"
	level = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	world_motion = level.get_node(^"WorldMotion")
	route_motion = level.get_node(^"LevelWorld/L01BarangayLayers")
	world_motion.set_process(false)
	route_motion.set_process(false)

	for stage in [[0.15, "obstacle_small"], [2.55, "obstacle_medium"], [4.35, "obstacle_large"]]:
		_show_action(&"move_right", 2, float(stage[0]))
		route_motion.call("advance_layer_motion", 0.7)
		await _capture(String(stage[1]), Vector2i(960, 540))

	for stage in [[2.55, "formation_medium"], [4.35, "formation_large"]]:
		_show_two_crate_formation(float(stage[0]))
		route_motion.call("advance_layer_motion", 0.7)
		await _capture(String(stage[1]), Vector2i(960, 540))

	for requested_size in SIZES:
		_show_action(&"move_right", 2, 3.75)
		route_motion.call("advance_layer_motion", 1.4)
		await _capture("crate_approach", requested_size)

	for action_data in [[&"jump", "puddle_approach"], [&"slide", "laundry_approach"]]:
		_show_action(action_data[0], 1, 3.75)
		route_motion.call("advance_layer_motion", 1.25)
		await _capture(action_data[1], Vector2i(960, 540))

	_show_action(&"jump", 1, 3.25)
	route_motion.call("advance_layer_motion", 6.4)
	await _capture("ambient_motion_a", Vector2i(960, 540))
	route_motion.call("advance_layer_motion", 8.0)
	await _capture("ambient_motion_b", Vector2i(960, 540))

	level.call("pause_gameplay")
	var frozen := _ambient_snapshot()
	route_motion.call("advance_layer_motion", 3.0)
	world_motion.call("_process", 3.0)
	var pause_ok := frozen == _ambient_snapshot()
	await _capture("pause_freeze", Vector2i(960, 540))

	var manifest := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"captures": captures, "pause_freeze_verified": pause_ok}, "\t"))
	manifest.close()
	level.free()
	print("L01 V05 QA COMPLETE: %d captures; pause freeze=%s" % [captures.size(), pause_ok])
	quit(0 if pause_ok else 3)


func _show_action(action: StringName, lane: int, elapsed: float) -> void:
	level.call("_hide_props")
	var prop_nodes: Dictionary = level.get("_prop_nodes")
	var prop := prop_nodes.get(action) as Node2D
	assert(prop != null)
	prop.visible = true
	level.call("_update_prompt_card", action, "MOVE NOW", Color(0.35, 0.78, 0.66))
	world_motion.call("set_motion_paused", false)
	world_motion.call("begin_prompt_approach", lane, 2.5, 2.0)
	world_motion.call("_process", elapsed)
	world_motion.call("set_motion_paused", true)


func _show_two_crate_formation(elapsed: float) -> void:
	var formation: Dictionary = {}
	for candidate_value in level.get("_formation_library"):
		if candidate_value is Dictionary and candidate_value.get("pattern_id", &"") == &"l01_p01_move_left":
			formation = (candidate_value as Dictionary).duplicate(true)
			break
	assert(not formation.is_empty())
	level.set("_active_formation", formation)
	level.set("active_formation_id", &"l01_p01_move_left")
	level.call("_show_formation_prompt", &"move_left", "MOVE NOW", Color(0.35, 0.78, 0.66))
	var lanes: Array[int] = []
	for obstacle_value in formation.get("obstacles", []):
		lanes.append(int((obstacle_value as Dictionary).get("lane", 1)))
	world_motion.call("set_prompt_formation", level.call("get_active_formation_props"), lanes)
	world_motion.call("set_motion_paused", false)
	world_motion.call("begin_prompt_approach", 1, 2.5, 2.0)
	world_motion.call("_process", elapsed)
	world_motion.call("set_motion_paused", true)


func _ambient_snapshot() -> Dictionary:
	var snapshot := {}
	for node_name in [&"CloudsA", &"Birds", &"Laundry", &"ResidentWave", &"ForegroundLeavesLeft", &"ForegroundLeavesRight", &"HallGlints", &"MarketGlow", &"HangingSign"]:
		var item := route_motion.get_node(NodePath(node_name)) as Node2D
		var frame := (item as Sprite2D).frame if item is Sprite2D else -1
		snapshot[node_name] = [item.transform, frame, item.modulate.a]
	return snapshot


func _capture(label: String, requested_size: Vector2i) -> void:
	root.size = requested_size
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != requested_size:
		var framed := Image.create(requested_size.x, requested_size.y, false, Image.FORMAT_RGBA8)
		framed.fill(Color(0.024, 0.078, 0.106, 1.0))
		var inset := (requested_size - image.get_size()) / 2
		framed.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), inset)
		image = framed
	var filename := "l01_v05_%s_%dx%d.png" % [label, requested_size.x, requested_size.y]
	var result := image.save_png(OUTPUT + "/" + filename)
	captures.append({"file": filename, "size": [image.get_width(), image.get_height()], "result": error_string(result)})
	print("CAPTURE %s: %s" % [filename, error_string(result)])
