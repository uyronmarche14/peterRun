extends SceneTree

const LAYERS := [
	"sky",
	"far",
	"mid",
	"near",
	"foreground",
	"road",
	"lane_overlay",
]
const LayerMotion = preload("res://scripts/l01_layered_route_motion.gd")

var failures: PackedStringArray = []


func _init() -> void:
	for layer in LAYERS:
		_test_layer_asset(layer)
	_test_runner_scene_layer_stack()
	_test_layer_motion_pauses_deterministically()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 layered-route integration test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_layer_asset(layer: String) -> void:
	var path := "res://art/backgrounds/l01_barangay_v03_layers/l01_barangay_%s_v03.png" % layer
	_expect(ResourceLoader.exists(path), "Layer PNG exists: " + path)
	var texture := load(path) as Texture2D
	_expect(texture != null, "Layer PNG loads: " + path)
	if texture != null:
		_expect(texture.get_size() == Vector2(960, 540), "Layer is authored at exact 2x canvas size: " + path)


func _test_runner_scene_layer_stack() -> void:
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "Runner scene loads")
	if packed == null:
		return
	var runner := packed.instantiate()
	var stack := runner.get_node_or_null(^"LevelWorld/L01BarangayLayers") as Node2D
	_expect(stack != null, "Runner scene has an isolated L01 layered route stack")
	if stack != null:
		_expect(not stack.visible, "L01 layer stack starts hidden for non-L01 routes")
		for layer in LAYERS:
			var sprite := stack.get_node_or_null(NodePath(layer.to_pascal_case())) as Sprite2D
			_expect(sprite != null, "Layer stack contains " + layer)
			if sprite != null:
				_expect(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Layer uses crisp nearest filtering: " + layer)
				_expect(sprite.scale == Vector2(0.5, 0.5), "Layer aligns 960x540 art to the 480x270 canvas: " + layer)
	runner.free()


func _test_layer_motion_pauses_deterministically() -> void:
	var motion := LayerMotion.new()
	motion.advance_layer_motion(1.0)
	var moving_phase: float = motion.motion_phase
	_expect(moving_phase > 0.0, "L01 layered route advances gently while active")
	motion.set_motion_paused(true)
	motion.advance_layer_motion(1.0)
	_expect(is_equal_approx(motion.motion_phase, moving_phase), "L01 layered route freezes immediately during Pause")
	motion.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
