extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const MANIFEST := "res://art/backgrounds/l01_roadside_v12/l01_v12_passing_street.json"
const STAGES := [^"StageHome", ^"StageWaitingShed", ^"StageSariSari", ^"StagePalengke", ^"StagePlaza"]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.set_reduced_motion(false)
	_test_asset_manifest()
	_test_clean_road_masks()
	await _test_archived_passing_street_is_inactive()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 v12 source art preserved but inactive: " + ("PASS" if failures.is_empty() else "FAIL"))
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


func _test_archived_passing_street_is_inactive() -> void:
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "Runner scene loads")
	if packed == null:
		return
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame
	var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	for index in STAGES.size():
		var stage := route.get_node("JourneyStages/" + String(STAGES[index])) as Sprite2D
		var road := stage.get_node(^"Road") as Sprite2D
		_expect(road.texture != null and not road.texture.resource_path.contains("l01_roadside_v12"), "Archived V12 road is not active")
		var passing := stage.get_node_or_null(^"PassingStreet") as Node2D
		_expect(passing == null or not passing.visible, "Archived V12 whole-building travel is not active")
		var left := stage.get_node(^"LeftStreet") as Sprite2D
		var right := stage.get_node(^"RightStreet") as Sprite2D
		_expect(left.visible and right.visible, "Fixed scenery is used instead of V12 travel")
	level.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
