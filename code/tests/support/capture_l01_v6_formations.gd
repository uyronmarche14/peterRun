extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v6_formations"
const RoadGuide = preload("res://scripts/road_projection.gd")
const IDS := ["l01_p03_jump_center", "l01_v6_j09_pco", "l01_v6_j18_pcp", "l01_v6_s10_lco", "l01_v6_s16_llo"]
const SIZES := [Vector2i(960, 540), Vector2i(1024, 768), Vector2i(1920, 1080)]

var records: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Formation captures require graphical Godot")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	var motion: Node = level.get_node(^"WorldMotion")
	motion.set_process(false)
	for pattern_id in IDS:
		var formation := _find_formation(level, pattern_id)
		if formation.is_empty():
			printerr("Missing formation: " + pattern_id)
			quit(3)
			return
		_configure(level, formation)
		motion.call("_process", 3.8)
		for size in SIZES:
			await _capture(pattern_id, "near", size)
		motion.call("_process", 0.7)
		await _capture(pattern_id, "contact", Vector2i(960, 540))
	var file := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(records, "\t"))
	file.close()
	level.free()
	print("L01 formation visual review: %d captures" % records.size())
	quit(0)


func _find_formation(level: Node, pattern_id: String) -> Dictionary:
	for candidate in level.get("_formation_library"):
		if String(candidate.get("pattern_id", &"")) == pattern_id:
			return candidate.duplicate(true)
	return {}


func _configure(level: Node, formation: Dictionary) -> void:
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	var player: Node2D = level.get_node(^"Player") as Node2D
	player.call("reset_for_practice")
	var entry := int(formation.get("entry_lanes", [1])[0])
	if entry == 0:
		player.call("handle_action", &"move_left")
	elif entry == 2:
		player.call("handle_action", &"move_right")
	player.position.x = RoadGuide.PLAYER_LANE_X[entry]
	var director: Node = level.get_node(^"PromptDirector")
	director.call("_set_state", 0)
	level.set("_active_formation", formation)
	level.set("_pending_response_action", &"")
	var lanes: Array[int] = []
	for lane in formation.get("action_lanes", [formation.get("action_lane", entry)]):
		lanes.append(int(lane))
	director.call("schedule_with_action_lanes", StringName(formation.get("required_action", &"")), lanes)
	director.call("open_response_window")
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()


func _capture(pattern_id: String, moment: String, size: Vector2i) -> void:
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
	var name := "%s_%s_%dx%d.png" % [pattern_id, moment, size.x, size.y]
	var result := screenshot.save_png(OUTPUT + "/" + name)
	records.append({"file": name, "result": error_string(result), "size": [size.x, size.y]})
	print("CAPTURE %s: %s" % [name, error_string(result)])
