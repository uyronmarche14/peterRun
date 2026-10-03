extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const STAGES := ["StageHome", "StageWaitingShed", "StageSariSari", "StagePalengke", "StagePlaza"]
const ROAD_NAMES := ["l01_v10_home_road.png", "l01_v11_waiting_road.png", "l01_v11_sari_sari_road.png", "l01_v11_palengke_road.png", "l01_v11_plaza_road.png"]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.set_reduced_motion(false)
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "Runner level loads")
	if packed == null:
		_finish()
		return
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame
	var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	for index in STAGES.size():
		var stage := route.get_node("JourneyStages/" + STAGES[index]) as Sprite2D
		var left := stage.get_node(^"LeftStreet") as Sprite2D
		var right := stage.get_node(^"RightStreet") as Sprite2D
		var road := stage.get_node(^"Road") as Sprite2D
		_expect(left.visible and right.visible, "Fixed side buildings remain visible in " + STAGES[index])
		_expect(road.texture != null and road.texture.resource_path.ends_with(ROAD_NAMES[index]), "Stage keeps its registered original road: " + STAGES[index])
		var passing := stage.get_node_or_null(^"PassingStreet") as Node2D
		_expect(passing == null or not passing.visible, "Whole-building travel is inactive in " + STAGES[index])
		var life := stage.get_node_or_null(^"StreetLife") as Node2D
		_expect(life != null, "Stage has independent sidewalk animation: " + STAGES[index])
		if life != null:
			_expect(life.has_method("set_ambient_phase") and life.has_method("get_animated_parts"), "Sidewalk animation is inspectable: " + STAGES[index])
			if life.has_method("get_animated_parts"):
				_expect(not (life.call("get_animated_parts") as Array).is_empty(), "Stage has visible small-scale ambient parts: " + STAGES[index])
	var home := route.get_node_or_null(^"JourneyStages/StageHome/StreetLife") as Node2D
	if home != null and home.has_method("set_ambient_phase") and home.has_method("get_animated_parts"):
		var parts: Array = home.call("get_animated_parts")
		var original_positions: Array[Vector2] = []
		for part_value in parts:
			original_positions.append((part_value as Node2D).position)
		home.call("set_ambient_phase", 0.0)
		var rest := _snapshot(parts)
		home.call("set_ambient_phase", 6.0)
		_expect(_snapshot(parts) != rest, "Small sidewalk details animate without moving buildings")
		for index in parts.size():
			_expect((parts[index] as Node2D).position == original_positions[index], "Ambient part keeps its street anchor")
		route.call("set_motion_paused", true)
		var paused := _snapshot(parts)
		route.call("advance_layer_motion", 12.0)
		_expect(_snapshot(parts) == paused, "Pause freezes the small ambient parts")
		route.call("set_motion_paused", false)
	Settings.set_reduced_motion(true)
	route.call("advance_layer_motion", 0.1)
	if home != null and home.has_method("get_animated_parts"):
		for part_value in home.call("get_animated_parts"):
			var part := part_value as Sprite2D
			_expect(part.frame == 0 and is_zero_approx(part.rotation), "Reduced Motion rests the ambient sprite")
	Settings.set_reduced_motion(false)
	level.free()
	_finish()


func _snapshot(parts: Array) -> Array:
	var result := []
	for part_value in parts:
		var part := part_value as Sprite2D
		result.append([part.frame, part.rotation, part.visible])
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 fixed street life: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
