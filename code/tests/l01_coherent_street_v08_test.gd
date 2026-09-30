extends SceneTree

const SIDE_ASSETS := [
	"res://art/backgrounds/l01_barangay_v08/l01_v08_left_bungalow.png",
	"res://art/backgrounds/l01_barangay_v08/l01_v08_left_mixed_home.png",
	"res://art/backgrounds/l01_barangay_v08/l01_v08_right_sari_sari.png",
	"res://art/backgrounds/l01_barangay_v08/l01_v08_right_waiting_shed.png",
]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_art()
	await _test_street_motion()
	_test_road_presentation()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN coherent L01 street v08 test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_art() -> void:
	for path in SIDE_ASSETS:
		_expect(ResourceLoader.exists(path), "street-section sprite exists: " + path)
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		_expect(texture != null and texture.get_size() == Vector2(512, 512), "street section uses fixed 512px canvas: " + path)
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		_expect(image != null and image.get_format() == Image.FORMAT_RGBA8, "street section has RGBA pixels: " + path)
		if image != null:
			_expect(image.get_pixel(0, 0).a < 0.05 and image.get_pixel(511, 0).a < 0.05, "street section has transparent padding: " + path)


func _test_street_motion() -> void:
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "runner scene loads")
	if packed == null:
		return
	var runner := packed.instantiate()
	runner.set_script(null)
	root.add_child(runner)
	await process_frame
	var travel: Node2D = runner.get_node_or_null(^"LevelWorld/RoadsideMotion")
	_expect(travel != null, "L01 roadside motion node exists")
	if travel == null:
		runner.free()
		return
	var modules: Array = travel.call("get_module_sprites")
	_expect(modules.size() == 4, "two coherent architectural sections per side")
	_expect(travel.has_method("get_module_visible_bounds"), "street controller exposes visible sprite bounds for curb checks")
	_expect(travel.has_method("get_module_ground_points"), "street controller exposes ground anchors")
	if modules.size() != 4 or not travel.has_method("get_module_visible_bounds") or not travel.has_method("get_module_ground_points"):
		runner.free()
		return
	for distance in [0.0, 2.0, 4.0, 7.0, 12.0, 17.0]:
		travel.call("set_travel_distance", distance)
		var bounds: Array = travel.call("get_module_visible_bounds")
		var grounds: Array = travel.call("get_module_ground_points")
		var sides: Array = travel.call("get_module_sides")
		_expect(bounds.size() == 4 and grounds.size() == 4 and sides.size() == 4, "all street sections report bounds, ground and side")
		if bounds.size() != 4 or grounds.size() != 4 or sides.size() != 4:
			continue
		var readable_sections := 0
		for index in 4:
			var sprite := modules[index] as Sprite2D
			if not sprite.visible:
				continue
			var rect := bounds[index] as Rect2
			var ground := grounds[index] as Vector2
			var side := int(sides[index])
			var curb := _painted_curb_x(side, ground.y)
			if rect.size.y >= 80.0 and sprite.modulate.a >= 0.35:
				readable_sections += 1
			_expect(rect.size.y <= 155.0, "near building is not an oversized cropped block")
			_expect(ground.y >= 116.0 and ground.y <= 270.0, "building contact stays on the roadside ground path")
			_expect(rect.end.x <= curb - 2.0 if side < 0 else rect.position.x >= curb + 2.0, "entire building remains outside the painted curb")
			if distance == 0.0 and sprite.modulate.a >= 0.35:
				_expect(rect.position.x >= -2.0 and rect.end.x <= 482.0, "starting street avoids cropped architectural blocks")
		if distance == 0.0:
			_expect(readable_sections >= 1, "the starting street has a readable architectural section, not dollhouses")
			_expect((modules[0] as Sprite2D).modulate.a <= 0.1 and (modules[2] as Sprite2D).modulate.a <= 0.1, "tiny incoming homes do not crowd the Hall plaza")
	for paused_distance in [0.0, 4.0, 8.0, 12.0, 17.0]:
		travel.call("set_travel_distance", paused_distance)
		var paused_snapshot := _snapshot(modules)
		travel.call("set_motion_paused", true)
		travel.call("set_travel_distance", paused_distance + 2.0)
		_expect(_snapshot(modules) == paused_snapshot, "Pause freezes all street sections at travel distance %.1f" % paused_distance)
		travel.call("set_motion_paused", false)
	var before_pause := _snapshot(modules)
	travel.call("set_reduced_motion", true)
	travel.call("set_travel_distance", 20.0)
	_expect(_snapshot(modules) == before_pause, "Reduced Motion holds the street view")
	runner.free()


func _test_road_presentation() -> void:
	var script := load("res://scripts/l01_road_presentation.gd") as Script
	var road := script.new() as Node2D
	root.add_child(road)
	_expect(road.call("get_lane_separator_count") == 0, "no continuous lane lines compete with painted dashes")
	road.free()


func _painted_curb_x(side: int, ground_y: float) -> float:
	var fraction := clampf((ground_y - 120.0) / 150.0, 0.0, 1.0)
	var left := lerpf(195.0, 0.0, fraction)
	return left if side < 0 else 480.0 - left


func _snapshot(modules: Array) -> Array:
	var snapshot: Array = []
	for item in modules:
		var sprite := item as Sprite2D
		snapshot.append([sprite.position, sprite.scale, sprite.visible, sprite.modulate.a])
	return snapshot


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
