extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const Guide = preload("res://scripts/l01_visual_geometry.gd")
const MANIFEST := "res://art/backgrounds/l01_roadside_v12/l01_v12_passing_street.json"
const STAGES := [^"StageHome", ^"StageWaitingShed", ^"StageSariSari", ^"StagePalengke", ^"StagePlaza"]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.set_reduced_motion(false)
	_test_asset_manifest()
	_test_clean_road_masks()
	await _test_scene_and_motion()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 v12 passing street: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_asset_manifest() -> void:
	_expect(FileAccess.file_exists(MANIFEST), "Passing-street manifest exists")
	if not FileAccess.file_exists(MANIFEST):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	_expect(parsed is Dictionary and parsed.has("stages"), "Manifest maps assets by journey stage")
	if not parsed is Dictionary or not parsed.has("stages"):
		return
	var stages: Dictionary = parsed["stages"]
	_expect(stages.size() == 5, "All five stages have independent roadside subjects")
	for slug in ["home", "waiting", "sari_sari", "palengke", "plaza"]:
		var items: Array = stages.get(slug, [])
		_expect(items.size() >= 2, "At least one subject on each side of " + slug)
		var sides := []
		for item in items:
			if not item is Dictionary:
				continue
			sides.append(item.get("side", ""))
			var path: String = item.get("texture", "")
			_expect(FileAccess.file_exists(path), "Movable asset exists: " + path)
			if FileAccess.file_exists(path):
				var image := Image.load_from_file(ProjectSettings.globalize_path(path))
				_expect(image != null and image.get_size() == Vector2i(512, 512), "Movable art has fixed 512px canvas: " + path)
				if image != null:
					_expect(image.get_pixel(0, 0).a < 0.05, "Movable art has transparent exterior: " + path)
		_expect(sides.has("left") and sides.has("right"), "Both verges populated in " + slug)


func _test_clean_road_masks() -> void:
	for slug in ["home", "waiting", "sari_sari", "palengke", "plaza"]:
		var path := "res://art/backgrounds/l01_roadside_v12/l01_v12_%s_clean_road.png" % slug
		_expect(FileAccess.file_exists(path), "Clean original-pixel road exists: " + slug)
		if not FileAccess.file_exists(path):
			continue
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		_expect(image != null and image.get_size() == Vector2i(960, 540), "Road stays registered to 960x540")
		if image != null:
			_expect(image.get_pixel(480, 380).a > 0.99, "Centre asphalt remains opaque")
			_expect(image.get_pixel(120, 380).a < 0.01 and image.get_pixel(840, 380).a < 0.01, "Old sidewalk subjects cannot ride with the road")


func _test_scene_and_motion() -> void:
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "Runner scene loads")
	if packed == null:
		return
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame
	var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	var world := level.get_node(^"WorldMotion") as Node
	world.set_process(false)
	route.set_process(false)
	for index in STAGES.size():
		var stage := route.get_node("JourneyStages/" + String(STAGES[index])) as Sprite2D
		var road := stage.get_node(^"Road") as Sprite2D
		_expect(road.texture != null and road.texture.resource_path.ends_with("l01_v12_%s_clean_road.png" % ["home", "waiting", "sari_sari", "palengke", "plaza"][index]), "Stage renders its clean registered road")
		var passing := stage.get_node_or_null(^"PassingStreet") as Node2D
		_expect(passing != null, "Stage has a travel layer: " + String(STAGES[index]))
		if passing == null:
			continue
		_expect(passing.has_method("get_module_sprites"), "Travel layer exposes inspectable grounded subjects")
		if not passing.has_method("get_module_sprites"):
			continue
		var sprites: Array = passing.call("get_module_sprites")
		_expect(sprites.size() >= 2, "Stage has independent moving art on each side")
		var left := stage.get_node(^"LeftStreet") as Sprite2D
		var right := stage.get_node(^"RightStreet") as Sprite2D
		_expect(not left.visible and not right.visible, "Static duplicate streets hidden during travel")
		passing.call("set_travel_distance", 2.0)
		_check_curb_bounds(passing, String(STAGES[index]))
		passing.call("set_travel_distance", 7.0)
		_check_curb_bounds(passing, String(STAGES[index]))
	var active := route.get_node_or_null(^"JourneyStages/StageSariSari/PassingStreet") as Node2D
	if active != null:
		route.call("set_route_progress", 2, false)
		var before := _snapshot(active)
		world.call("_process", 3.0)
		_expect(_snapshot(active) != before, "Buildings and shop advance from the shared travel clock")
		level.call("pause_gameplay")
		var paused := _snapshot(active)
		world.call("_process", 5.0)
		route.call("advance_layer_motion", 5.0)
		_expect(_snapshot(active) == paused, "Pause freezes travel and ambient transforms")
		world.call("set_motion_paused", false)
		route.call("set_motion_paused", false)
		world.call("_process", 1.0)
		_expect(_snapshot(active) != paused, "Resume continues travel from the held position")
	Settings.set_reduced_motion(true)
	world.call("_process", 0.1)
	route.call("advance_layer_motion", 0.1)
	for name in STAGES:
		var stage := route.get_node("JourneyStages/" + String(name)) as Sprite2D
		var passing := stage.get_node_or_null(^"PassingStreet") as Node2D
		if passing != null:
			_expect(not passing.visible and (stage.get_node(^"LeftStreet") as Sprite2D).visible and (stage.get_node(^"RightStreet") as Sprite2D).visible, "Reduced motion restores original registered streets")
	Settings.set_reduced_motion(false)
	level.free()


func _check_curb_bounds(passing: Node2D, stage_name: String) -> void:
	if not passing.has_method("get_module_bounds"):
		_expect(false, "Travel layer exposes bounds for " + stage_name)
		return
	var bounds: Array = passing.call("get_module_bounds")
	for item in bounds:
		if not item is Dictionary:
			continue
		var rect: Rect2 = item.get("rect", Rect2())
		var side: int = item.get("side", 0)
		var y: float = item.get("ground_y", 0.0)
		var curb := Guide.painted_curb_x(side, y)
		_expect(rect.end.x <= curb - 2.0 if side < 0 else rect.position.x >= curb + 2.0, "Visible art stays outside painted curb in " + stage_name)


func _snapshot(passing: Node2D) -> Array:
	var snapshot: Array = []
	for sprite_value in passing.call("get_module_sprites"):
		var sprite := sprite_value as Sprite2D
		snapshot.append([sprite.position, sprite.scale, sprite.modulate, sprite.visible])
	return snapshot


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
