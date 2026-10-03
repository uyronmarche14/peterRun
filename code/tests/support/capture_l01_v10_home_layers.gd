extends SceneTree

const OUTPUT := "res://../test_evidence/l01_v10_home_layers"
const CAPTURES := [
	[Vector2i(960, 540), "home_gameplay_960x540"],
	[Vector2i(1024, 768), "home_gameplay_1024x768"],
	[Vector2i(1920, 1080), "home_gameplay_1920x1080"],
]

var level: Node
var scenery: Node2D
var world_motion: Node
var records: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("L01 v10 capture requires graphical Godot.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.mode = Window.MODE_WINDOWED
	root.title = "PETER RUN - layered Home QA"
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
		await _capture(String(capture[1]), capture[0])
	scenery.call("set_route_progress", 1, true)
	scenery.call("advance_layer_motion", 0.6)
	await _capture("home_to_waiting_mid_reveal_960x540", Vector2i(960, 540))
	var before_pause := _snapshot()
	level.call("pause_gameplay")
	scenery.call("advance_layer_motion", 20.0)
	world_motion.call("_process", 20.0)
	var pause_ok := before_pause == _snapshot()
	await _capture("paused_mid_reveal_960x540", Vector2i(960, 540))
	var manifest := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"captures": records, "pause_freeze_verified": pause_ok}, "\t"))
	manifest.close()
	level.free()
	print("L01 V10 HOME QA COMPLETE: %d captures; pause freeze=%s" % [records.size(), pause_ok])
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


func _snapshot() -> Dictionary:
	var home := scenery.get_node(^"JourneyStages/StageHome") as Sprite2D
	var waiting := scenery.get_node(^"JourneyStages/StageWaitingShed") as Sprite2D
	return {
		"phase": scenery.get("motion_phase"),
		"home": [home.transform, home.modulate, home.visible, home.material],
		"waiting": [waiting.transform, waiting.modulate, waiting.visible, waiting.material],
	}


func _capture(label: String, requested_size: Vector2i) -> void:
	root.size = requested_size
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image.get_size() != requested_size:
		var framed := Image.create(requested_size.x, requested_size.y, false, Image.FORMAT_RGBA8)
		framed.fill(Color(0.024, 0.078, 0.106, 1.0))
		framed.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), (requested_size - image.get_size()) / 2)
		image = framed
	var filename := "l01_v10_%s.png" % label
	var result := image.save_png(OUTPUT + "/" + filename)
	records.append({"file": filename, "size": [image.get_width(), image.get_height()], "result": error_string(result)})
	print("CAPTURE %s: %s" % [filename, error_string(result)])
