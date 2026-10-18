extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const STAGE := "res://scenes/levels/runner_level.tscn"
const Guide = preload("res://scripts/l01_visual_geometry.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.set_reduced_motion(false)
	var scene := (load(STAGE) as PackedScene).instantiate()
	scene.set_script(null)
	root.add_child(scene)
	await process_frame
	var world := scene.get_node(^"WorldMotion") as Node
	var route := scene.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	world.set_process(false)
	route.set_process(false)
	var home := route.get_node(^"JourneyStages/StageHome") as Sprite2D
	var passing := home.get_node_or_null(^"PassingFrontages") as Node2D
	_expect(passing != null, "Home has curb-locked passing frontage node")
	if passing != null:
		_expect(not (home.get_node(^"LeftStreet") as Sprite2D).visible, "Moving Home has no duplicate fixed left buildings")
		_expect(not (home.get_node(^"RightStreet") as Sprite2D).visible, "Moving Home has no duplicate fixed right buildings")
		var sprites: Array = passing.call("get_module_sprites")
		_expect(sprites.size() == 4, "Home has four distinct passing frontages")
		if sprites.size() == 4:
			var before: Vector2 = sprites[0].position
			passing.call("set_travel_distance", 1.8)
			_expect(sprites[0].position.distance_to(before) > 1.0, "Shared travel moves frontage in perspective")
			var moved: Vector2 = sprites[0].position
			passing.call("set_motion_paused", true)
			passing.call("set_travel_distance", 3.0)
			_expect(sprites[0].position.is_equal_approx(moved), "Paused frontage freezes its pose")
			passing.call("set_motion_paused", false)
			passing.call("set_travel_distance", 3.0)
			_expect(sprites[0].position.distance_to(moved) > 1.0, "Frontage resumes from shared distance")
			var contacts: Array = passing.call("get_contact_points")
			_expect(contacts.size() == 4, "Every frontage exposes a measured ground contact")
			for contact in contacts:
				var side: int = contact["side"]
				var point: Vector2 = contact["point"]
				_expect(absf(point.x - Guide.roadside_contact_x(side, point.y, 2.0)) <= 0.5,
					"Frontage contact stays registered to the painted curb")
		passing.call("set_reduced_motion", true)
		_expect(not passing.visible, "Reduced Motion hides the passing frontages")
		_expect((home.get_node(^"LeftStreet") as Sprite2D).visible and (home.get_node(^"RightStreet") as Sprite2D).visible,
			"Reduced Motion restores approved fixed street")
		passing.call("set_reduced_motion", false)
		_expect(passing.visible, "Normal Motion restores passing frontages")
	scene.free()
	Settings.set_reduced_motion(false)
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 Home pass-by runtime: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
