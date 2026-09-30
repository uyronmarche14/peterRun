extends SceneTree

const RoadProjectionModel = preload("res://scripts/road_projection.gd")
const Settings = preload("res://scripts/game_settings.gd")
const ROADSIDES_SCRIPT := "res://scripts/l01_roadside_travel.gd"
const ROAD_PRESENTATION_SCRIPT := "res://scripts/l01_road_presentation.gd"
const ROAD_ASSET_ROOT := "res://art/backgrounds/l01_barangay_v08/"
const SIDE_ASSETS := [
	"l01_v08_left_bungalow.png",
	"l01_v08_left_mixed_home.png",
	"l01_v08_right_sari_sari.png",
	"l01_v08_right_waiting_shed.png",
]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_new_art_and_scene_hooks()
	_test_recycling_motion_and_pause()
	await _test_shared_motion_clock_pause_and_reduced_motion()
	_test_road_definition()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 forward-travel and road-readability test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_new_art_and_scene_hooks() -> void:
	for asset_name: String in SIDE_ASSETS:
		var path: String = ROAD_ASSET_ROOT + asset_name
		_expect(ResourceLoader.exists(path), "approaching roadside cutout exists: " + path)
		var texture := load(path) as Texture2D if ResourceLoader.exists(path) else null
		_expect(texture != null and texture.get_size() == Vector2(512, 512), "roadside cutout has a stable 512px canvas: " + path)
		var image := Image.load_from_file(ProjectSettings.globalize_path(path)) if ResourceLoader.exists(path) else null
		_expect(image != null and image.get_format() == Image.FORMAT_RGBA8, "roadside cutout exports transparent RGBA: " + path)
		if image != null:
			_expect(image.get_pixel(0, 0).a < 0.05 and image.get_pixel(511, 0).a < 0.05, "roadside cutout retains clear transparent top padding: " + path)
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "runner scene loads for L01 presentation checks")
	if packed == null:
		return
	var runner := packed.instantiate()
	runner.set_script(null)
	root.add_child(runner)
	await process_frame
	var roadside := runner.get_node_or_null(^"LevelWorld/RoadsideMotion")
	_expect(roadside != null and roadside.get_script() != null, "RoadsideMotion is an authored L01 travel layer")
	var road := runner.get_node_or_null(^"LevelWorld/RoadAndLanes/RoadPresentation")
	_expect(road != null and road.get_script() != null, "road surface and lane overlay have a dedicated presentation node")
	if roadside != null and roadside.has_method("get_module_sprites"):
		var modules: Array = roadside.call("get_module_sprites")
		_expect(modules.size() == 4, "two grounded street sections are pooled on each road side")
	if road != null and road.has_method("get_lane_separator_count"):
		_expect(int(road.call("get_lane_separator_count")) == 0, "painted road is not covered by duplicate continuous separators")
	runner.free()


func _test_recycling_motion_and_pause() -> void:
	var script := load(ROADSIDES_SCRIPT) as Script if ResourceLoader.exists(ROADSIDES_SCRIPT) else null
	_expect(script != null, "roadside approach/recycle controller script exists")
	if script == null:
		return
	var travel := script.new() as Node2D
	if travel == null:
		_expect(false, "roadside travel controller is a Node2D")
		return
	root.add_child(travel)
	var modules: Array = travel.call("get_module_sprites") if travel.has_method("get_module_sprites") else []
	_expect(modules.size() == 4, "runtime creates a two-by-two roadside module pool")
	if modules.size() < 4:
		travel.free()
		return
	var initial := _snapshot(modules)
	var initial_near_scale := (modules[0] as Sprite2D).scale.x
	travel.call("set_travel_distance", 4.0)
	var advanced := _snapshot(modules)
	_expect(advanced != initial, "roadside buildings approach and scale up as world travel advances")
	_expect((modules[0] as Sprite2D).scale.x > initial_near_scale, "an individual building grows as it approaches the player")
	var side_values: Array = travel.call("get_module_sides")
	var depths: Array = travel.call("get_module_depth_fractions")
	_expect(side_values.count(-1) == 2 and side_values.count(1) == 2, "two sections stay assigned to each roadside")
	var bounds: Array = travel.call("get_module_visible_bounds")
	var ground_points: Array = travel.call("get_module_ground_points")
	for index in modules.size():
		var sprite := modules[index] as Sprite2D
		var side := int(side_values[index])
		var ground := ground_points[index] as Vector2
		var edge := float(travel.call("painted_curb_x", side, ground.y))
		var rect := bounds[index] as Rect2
		_expect(rect.end.x <= edge - 2.0 if side < 0 else rect.position.x >= edge + 2.0, "entire street section stays outside the painted curb")
	var before_pause := _snapshot(modules)
	travel.call("set_motion_paused", true)
	travel.call("set_travel_distance", 8.0)
	_expect(_snapshot(modules) == before_pause, "pause freezes building positions, scales, and visibility")
	travel.call("set_motion_paused", false)
	travel.call("set_travel_distance", 18.3)
	var before_recycle := (modules[0] as Sprite2D).scale.x
	travel.call("set_travel_distance", 18.5)
	_expect((modules[0] as Sprite2D).scale.x < before_recycle, "each building recycles smoothly to its distant horizon size")
	travel.call("set_reduced_motion", true)
	var reduced_snapshot := _snapshot(modules)
	travel.call("set_travel_distance", 22.0)
	_expect(_snapshot(modules) == reduced_snapshot, "reduced motion keeps scenery static")
	travel.free()


func _test_road_definition() -> void:
	var path := ROAD_PRESENTATION_SCRIPT
	var script := load(path) as Script if ResourceLoader.exists(path) else null
	_expect(script != null, "road presentation script exists")
	if script == null:
		return
	var road := script.new() as Node2D
	root.add_child(road)
	if road.has_method("get_lane_separator_count"):
		_expect(int(road.call("get_lane_separator_count")) == 0, "no duplicate lane dividers are painted over the base art")
	if road.has_method("get_projected_lane_separators"):
		var lines: Array = road.call("get_projected_lane_separators")
		_expect(lines.is_empty(), "continuous road overlay is absent; base art retains two painted dashed dividers")
	road.free()


func _test_shared_motion_clock_pause_and_reduced_motion() -> void:
	Settings.set_reduced_motion(false)
	var runner := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(runner)
	await process_frame
	var world_motion: Node = runner.get_node(^"WorldMotion")
	var route_motion: Node = runner.get_node(^"LevelWorld/L01BarangayLayers")
	var roadside: Node = runner.get_node(^"LevelWorld/RoadsideMotion")
	world_motion.set_process(false)
	route_motion.set_process(false)
	world_motion.call("_process", 5.0)
	var moving := _snapshot(roadside.call("get_module_sprites"))
	var distance := float(world_motion.get("motion_distance"))
	world_motion.call("set_motion_paused", true)
	world_motion.call("_process", 4.0)
	_expect(is_equal_approx(float(world_motion.get("motion_distance")), distance), "shared travel clock stops immediately on Pause")
	_expect(_snapshot(roadside.call("get_module_sprites")) == moving, "shared Pause holds the exact roadside transforms")
	world_motion.call("set_motion_paused", false)
	Settings.set_reduced_motion(true)
	world_motion.call("_process", 2.0)
	_expect(_snapshot(roadside.call("get_module_sprites")) == moving, "Reduced Motion leaves passing buildings still")
	_expect(not (runner.get_node(^"LevelWorld/RoadAndLanes/RoadMotionDashes") as Node2D).visible, "Reduced Motion suppresses moving road seams while preserving static lane guides")
	Settings.set_reduced_motion(false)
	runner.free()


func _snapshot(modules: Array) -> Array:
	var result: Array = []
	for item in modules:
		var sprite := item as Sprite2D
		result.append([sprite.position, sprite.scale, sprite.visible, sprite.modulate.a])
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
