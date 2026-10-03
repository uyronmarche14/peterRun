extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v09_scenery"
const RouteJourney = preload("res://scripts/route_journey.gd")
const CAPTURES := [
	[Vector2i(960, 540), 0, "home_dawn_960x540"],
	[Vector2i(960, 540), 1, "waiting_morning_960x540"],
	[Vector2i(960, 540), 2, "sari_sari_late_morning_960x540"],
	[Vector2i(960, 540), 3, "palengke_afternoon_960x540"],
	[Vector2i(1024, 768), 3, "palengke_afternoon_1024x768"],
	[Vector2i(960, 540), 4, "plaza_golden_960x540"],
	[Vector2i(1920, 1080), 4, "plaza_golden_1920x1080"],
]

var level: Node
var scenery: Node2D
var world_motion: Node
var records: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("L01 v09 capture requires graphical Godot.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.title = "PETER RUN - L01 v09 scenery QA"
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

	for capture in CAPTURES:
		_set_completed_progress(int(capture[1]))
		scenery.call("advance_layer_motion", 1.3)
		await _capture(String(capture[2]), capture[0])

	scenery.call("set_route_progress", 3, false)
	scenery.call("set_route_progress", 4, true)
	scenery.call("advance_layer_motion", 0.6)
	await _capture("market_to_plaza_midfade_960x540", Vector2i(960, 540))
	var before_pause := _snapshot()
	level.call("pause_gameplay")
	scenery.call("advance_layer_motion", 30.0)
	world_motion.call("_process", 30.0)
	var pause_ok := before_pause == _snapshot()
	await _capture("paused_midfade_960x540", Vector2i(960, 540))

	var manifest := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"captures": records, "pause_freeze_verified": pause_ok}, "\t"))
	manifest.close()
	level.free()
	print("L01 V09 QA COMPLETE: %d captures; pause freeze=%s" % [records.size(), pause_ok])
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
	var total_target := 0
	for action in config.ACTIONS:
		total_target += config.get_target(action)
	var desired := 0
	while desired < total_target and RouteJourney.get_progress(desired, total_target) < stage:
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
	var snapshot := {"phase": scenery.get("motion_phase")}
	for path in [
		^"JourneyStages/StageHome", ^"JourneyStages/StageWaitingShed",
		^"JourneyStages/StageSariSari", ^"JourneyStages/StagePalengke",
		^"JourneyStages/StagePlaza", ^"CloudsA", ^"Birds",
		^"BananaLeavesLeft", ^"BananaLeavesRight",
	]:
		var item := scenery.get_node(path) as Node2D
		snapshot[String(path)] = [item.transform, item.modulate, item.visible, (item as Sprite2D).frame if item is Sprite2D else -1]
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
	var filename := "l01_v09_%s.png" % label
	var result := image.save_png(OUTPUT + "/" + filename)
	records.append({"file": filename, "size": [image.get_width(), image.get_height()], "result": error_string(result)})
	print("CAPTURE %s: %s" % [filename, error_string(result)])
