extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const OUTPUT := "res://../test_evidence/l01_home_passby_v16"

var level: Node
var world: Node
var passing: Node2D
var captures: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Home pass-by capture requires graphical Godot")
		quit(2)
		return
	Settings.set_reduced_motion(false)
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
	world.set_process(false)
	level.get_node(^"LevelWorld/L01BarangayLayers").set_process(false)
	passing = level.get_node_or_null(^"LevelWorld/L01BarangayLayers/JourneyStages/StageHome/PassingFrontages") as Node2D
	if passing == null:
		printerr("V16 passing-building pilot is archived and inactive; use capture_l01_v15_stage_motion.gd for the fixed street")
		level.free()
		quit(2)
		return
	for distance in [0.0, 8.0, 16.0, 24.0, 32.0]:
		world.set("motion_distance", distance)
		world.call("_process", 0.0)
		await _capture("d%02d" % int(distance), Vector2i(960, 540))
	world.set("motion_distance", 16.0)
	world.call("_process", 0.0)
	await _capture("d16", Vector2i(480, 270))
	await _capture("d16", Vector2i(1024, 768))
	await _capture("d16", Vector2i(1920, 1080))
	level.call("pause_gameplay")
	var frozen := _snapshot()
	world.call("_process", 9.0)
	var pause_ok := _snapshot() == frozen
	await _capture("paused", Vector2i(960, 540))
	level.call("resume_gameplay")
	Settings.set_reduced_motion(true)
	world.call("_process", 0.0)
	var home := passing.get_parent() as Node2D
	var reduced_ok := not passing.visible and (home.get_node(^"LeftStreet") as Sprite2D).visible and (home.get_node(^"RightStreet") as Sprite2D).visible
	await _capture("reduced_motion", Vector2i(960, 540))
	Settings.set_reduced_motion(false)
	var evidence := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	evidence.store_string(JSON.stringify({"captures": captures, "pause_freeze_verified": pause_ok, "reduced_motion_verified": reduced_ok}, "\t"))
	evidence.close()
	level.free()
	print("L01 Home pass-by v16 QA: %d captures, pause=%s, reduced=%s" % [captures.size(), pause_ok, reduced_ok])
	quit(0 if pause_ok and reduced_ok else 3)


func _snapshot() -> Array:
	var values := [world.get("motion_distance")]
	for sprite_value in passing.call("get_module_sprites"):
		var sprite := sprite_value as Sprite2D
		values.append([sprite.position, sprite.scale, sprite.modulate.a])
	return values


func _capture(label: String, requested_size: Vector2i) -> void:
	root.size = requested_size
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	if screenshot.get_size() != requested_size:
		var framed := Image.create_empty(requested_size.x, requested_size.y, false, Image.FORMAT_RGBA8)
		framed.fill(Color(0.024, 0.078, 0.106, 1.0))
		framed.blit_rect(screenshot, Rect2i(Vector2i.ZERO, screenshot.get_size()), (requested_size - screenshot.get_size()) / 2)
		screenshot = framed
	var name := "l01_home_passby_v16_%s_%dx%d.png" % [label, requested_size.x, requested_size.y]
	var result := screenshot.save_png(OUTPUT + "/" + name)
	captures.append({"file": name, "size": [screenshot.get_width(), screenshot.get_height()], "result": error_string(result)})
	print("CAPTURE " + name + ": " + error_string(result))
