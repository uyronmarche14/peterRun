extends SceneTree

const ASSETS := {
	"environment": Vector2i(960, 540),
	"clouds": Vector2i(960, 320),
	"foreground_leaves_strip": Vector2i(1024, 256),
	"laundry_strip": Vector2i(1024, 192),
	"resident_wave_strip": Vector2i(1536, 256),
	"birds_strip": Vector2i(768, 96),
}
const ANIMATED_NODES := [
	&"CloudsA",
	&"Birds",
	&"Laundry",
	&"ResidentWave",
	&"ForegroundLeavesLeft",
	&"ForegroundLeavesRight",
]
const ACCENT_NODES := [&"HallGlints", &"MarketGlow", &"HangingSign"]
const LayerMotion = preload("res://scripts/l01_layered_route_motion.gd")
const Settings = preload("res://scripts/game_settings.gd")

var failures: PackedStringArray = []


func _init() -> void:
	for asset_name in ASSETS:
		_test_asset(asset_name, ASSETS[asset_name])
	_test_runner_scene_v05_stack()
	_test_motion_pause_and_reduced_motion()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 v05 animated-route integration test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_asset(asset_name: String, expected_size: Vector2i) -> void:
	var path := "res://art/backgrounds/l01_barangay_v05_layers/l01_v05_%s.png" % asset_name
	_expect(ResourceLoader.exists(path), "v05 asset exists: " + path)
	var texture := load(path) as Texture2D
	_expect(texture != null, "v05 asset loads: " + path)
	if texture != null:
		_expect(texture.get_size() == Vector2(expected_size), "v05 asset uses its stable authored canvas: " + path)


func _test_runner_scene_v05_stack() -> void:
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "Runner scene loads")
	if packed == null:
		return
	var runner := packed.instantiate()
	var stack := runner.get_node_or_null(^"LevelWorld/L01BarangayLayers") as Node2D
	_expect(stack != null, "Runner scene has the isolated L01 animated route stack")
	if stack != null:
		_expect(not stack.visible, "L01 route stack starts hidden for non-L01 routes")
		var environment := stack.get_node_or_null(^"Environment") as Sprite2D
		_expect(environment != null, "v05 environment master is present")
		if environment != null:
			_expect(environment.scale == Vector2(0.5, 0.5), "960x540 environment maps exactly to the 480x270 canvas")
		for node_name in ANIMATED_NODES:
			_expect(stack.get_node_or_null(NodePath(node_name)) is Sprite2D, "Animated overlay is present: " + String(node_name))
		_expect(not stack.has_node(^"CloudsB"), "Cloud motion uses one aligned sheet without a wrapping duplicate")
		_expect(not stack.has_node(^"LaundryRight"), "Laundry animation exists only where the environment has a real clothesline")
		var clouds := stack.get_node_or_null(^"CloudsA") as Sprite2D
		_expect(clouds != null and clouds.scale == Vector2(0.5, 0.5) and not clouds.centered, "Cloud sheet stays aligned to the 480x270 composition")
		var laundry := stack.get_node_or_null(^"Laundry") as Sprite2D
		_expect(laundry != null and laundry.position == Vector2(68, 139) and laundry.scale == Vector2(0.23, 0.23), "Laundry overlay is registered to the painted left clothesline")
		var resident := stack.get_node_or_null(^"ResidentWave") as Sprite2D
		_expect(resident != null and resident.position == Vector2(424, 168) and resident.scale == Vector2(0.25, 0.25), "Resident is larger and keeps a stable sidewalk contact point")
		_expect((stack.get_node(^"Birds") as Sprite2D).hframes == 4, "Bird strip exposes four frames")
		_expect((stack.get_node(^"Laundry") as Sprite2D).hframes == 4, "Laundry strip exposes four frames")
		_expect((stack.get_node(^"ResidentWave") as Sprite2D).hframes == 6, "Resident wave exposes six frames")
		for node_name in ACCENT_NODES:
			_expect(stack.get_node_or_null(NodePath(node_name)) is Node2D, "Animated roadside/light accent is present: " + String(node_name))
	runner.free()


func _test_motion_pause_and_reduced_motion() -> void:
	Settings.set_reduced_motion(false)
	var motion := LayerMotion.new()
	for node_name in ANIMATED_NODES:
		var sprite := Sprite2D.new()
		sprite.name = node_name
		sprite.hframes = 6 if node_name == &"ResidentWave" else 4
		sprite.position = Vector2(20.0, 20.0)
		motion.add_child(sprite)
	for node_name in ACCENT_NODES:
		var accent := Polygon2D.new() if node_name == &"MarketGlow" else Node2D.new()
		accent.name = node_name
		accent.position = Vector2(30.0, 30.0)
		motion.add_child(accent)
	root.add_child(motion)
	var environment := Sprite2D.new()
	environment.name = &"Environment"
	motion.add_child(environment)
	var initial_positions := _snapshot(motion)
	motion.advance_layer_motion(1.1)
	_expect(motion.motion_phase > 0.0, "Ambient motion advances while active")
	_expect(environment.position == Vector2.ZERO, "Road, buildings, and landmark remain visually locked")
	var moving_positions := _snapshot(motion)
	_expect(moving_positions != initial_positions, "Independent cloud, cloth, bird, and leaf overlays visibly change over time")
	motion.set_motion_paused(true)
	motion.advance_layer_motion(2.0)
	_expect(_snapshot(motion) == moving_positions, "Pause freezes every ambient overlay immediately")
	motion.set_motion_paused(false)
	Settings.set_reduced_motion(true)
	var phase_before := motion.motion_phase
	motion.advance_layer_motion(2.0)
	_expect(is_equal_approx(motion.motion_phase, phase_before), "Reduced motion stops ambient timeline advancement")
	for node_name in ANIMATED_NODES:
		_expect((motion.get_node(NodePath(node_name)) as Sprite2D).frame == 0, "Reduced motion uses the stable first frame: " + String(node_name))
	Settings.set_reduced_motion(false)
	motion.free()


func _snapshot(motion: Node) -> Dictionary:
	var result := {}
	for node_name in ANIMATED_NODES + ACCENT_NODES:
		var item := motion.get_node(NodePath(node_name)) as Node2D
		var frame := (item as Sprite2D).frame if item is Sprite2D else -1
		result[node_name] = [item.transform, frame, item.modulate.a]
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
