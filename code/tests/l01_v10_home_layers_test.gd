extends SceneTree

const ROOT := "res://art/backgrounds/l01_home_v10_layers/"
const LAYERS := [
	"l01_v10_home_sky.png",
	"l01_v10_home_far.png",
	"l01_v10_home_landmark.png",
	"l01_v10_home_left_street.png",
	"l01_v10_home_right_street.png",
	"l01_v10_home_road.png",
	"l01_v10_home_foreground.png",
]
const STAGE_CHILDREN := [
	^"Far",
	^"Landmark",
	^"LeftStreet",
	^"RightStreet",
	^"Road",
	^"Foreground",
]

var failures: PackedStringArray = []


func _init() -> void:
	_test_art_and_road_registration()
	_test_home_stage_composition()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 v10 layered Home test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_art_and_road_registration() -> void:
	for index in LAYERS.size():
		var path: String = ROOT + LAYERS[index]
		_expect(FileAccess.file_exists(path), "Missing aligned Home layer: " + path)
		if not FileAccess.file_exists(path):
			continue
		var art := _runtime_image(path)
		_expect(art != null and art.get_size() == Vector2i(960, 540), "Home layer has a 960x540 canvas: " + path)
		if art != null and index > 0:
			var transparent_points := [
				Vector2i.ZERO, Vector2i(0, 0), Vector2i(959, 539),
				Vector2i(0, 539), Vector2i(30, 100), Vector2i(480, 270),
			]
			_expect(art.get_pixelv(transparent_points[index - 1]).a < 0.01, "Non-sky layer has transparency: " + path)
	var road_path := ROOT + "l01_v10_home_road.png"
	if not FileAccess.file_exists(road_path):
		return
	var road := _runtime_image(road_path)
	var reference := _runtime_image("res://art/backgrounds/l01_barangay_v09_journey/l01_v09_home_dawn.png")
	for point in [
		Vector2i(480, 380), Vector2i(202, 380), Vector2i(763, 380),
		Vector2i(480, 420), Vector2i(130, 420), Vector2i(832, 420),
		Vector2i(480, 436), Vector2i(100, 436), Vector2i(860, 436),
		Vector2i(480, 500),
	]:
		_expect(road.get_pixelv(point).a > 0.99, "Original road covers gameplay sample " + str(point))
		_expect(_rgb_distance(road.get_pixelv(point), reference.get_pixelv(point)) < 0.012, "Road pixels remain registered at " + str(point))
	for point in [Vector2i(30, 100), Vector2i(930, 100)]:
		_expect(road.get_pixelv(point).a < 0.01, "Road does not cover houses at " + str(point))
	var landmark := _runtime_image(ROOT + "l01_v10_home_landmark.png")
	_expect(landmark.get_pixel(490, 180).a > 0.99 and landmark.get_pixel(10, 180).a < 0.01, "Barangay Hall occupies its own centered transparent layer")


func _test_home_stage_composition() -> void:
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "Runner scene loads")
	if packed == null:
		return
	var runner := packed.instantiate()
	var home := runner.get_node_or_null(^"LevelWorld/L01BarangayLayers/JourneyStages/StageHome") as Sprite2D
	_expect(home != null, "Home stage exists")
	if home != null:
		_expect(home.texture != null and home.texture.resource_path.ends_with(LAYERS[0]), "Home stage uses the separate sky")
		_expect(home.scale == Vector2(0.5, 0.5) and not home.centered, "Home layers share the 480x270 registration")
		for index in STAGE_CHILDREN.size():
			var child := home.get_node_or_null(STAGE_CHILDREN[index]) as Sprite2D
			_expect(child != null, "Home stage includes " + String(STAGE_CHILDREN[index]))
			if child != null:
				var expected_name: String = LAYERS[index + 1]
				_expect(child.texture != null and child.texture.resource_path.ends_with(expected_name), "Home stage uses the correct layer art")
				_expect(child.position == Vector2.ZERO and child.scale == Vector2.ONE and not child.centered, "Layer has no registration offset")
				_expect(child.use_parent_material, "Stage reveal also masks the layer")
	runner.free()


func _rgb_distance(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))


func _runtime_image(path: String) -> Image:
	var texture := load(path) as Texture2D
	return texture.get_image() if texture != null else null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
