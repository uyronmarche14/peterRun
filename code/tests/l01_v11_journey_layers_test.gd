extends SceneTree

const ROOT := "res://art/backgrounds/l01_journey_v11_layers/"
const STAGES := ["waiting", "sari_sari", "palengke", "plaza"]
const LAYERS := ["sky", "far", "landmark", "left_street", "right_street", "road", "foreground"]
const CHILDREN := [^"Far", ^"Landmark", ^"LeftStreet", ^"RightStreet", ^"Road", ^"Foreground"]
const ORIGINALS := [
	"l01_v09_waiting_early_morning.png",
	"l01_v09_sari_sari_late_morning.png",
	"l01_v09_palengke_early_afternoon.png",
	"l01_v09_plaza_golden_afternoon.png",
]
const STAGE_NODES := [^"StageWaitingShed", ^"StageSariSari", ^"StagePalengke", ^"StagePlaza"]
const MODULE_STAGES := ["home", "waiting", "sari_sari", "palengke", "plaza"]

var failures: PackedStringArray = []


func _init() -> void:
	_test_stage_art_and_registration()
	_test_motion_ready_modules()
	_test_painted_curb_guide()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 v11 complete journey layers: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_stage_art_and_registration() -> void:
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "Runner scene loads")
	if packed == null:
		return
	var runner := packed.instantiate()
	for index in STAGES.size():
		var slug: String = STAGES[index]
		var stage := runner.get_node_or_null(NodePath("LevelWorld/L01BarangayLayers/JourneyStages/" + String(STAGE_NODES[index]))) as Sprite2D
		_expect(stage != null, "Stage exists: " + slug)
		var reference := _image("res://art/backgrounds/l01_barangay_v09_journey/" + ORIGINALS[index])
		for layer_index in LAYERS.size():
			var file_name: String = "l01_v11_%s_%s.png" % [slug, LAYERS[layer_index]]
			var path: String = ROOT + file_name
			_expect(FileAccess.file_exists(path), "Missing layer: " + path)
			if not FileAccess.file_exists(path):
				continue
			var art := _image(path)
			_expect(art != null and art.get_size() == Vector2i(960, 540), "Layer has aligned 960x540 canvas: " + path)
			if art == null:
				continue
			if layer_index == 5 and reference != null:
				for sample in [Vector2i(480, 380), Vector2i(480, 420), Vector2i(480, 436), Vector2i(480, 500)]:
					_expect(art.get_pixelv(sample).a > 0.99, "Road covers native lane sample " + str(sample))
					_expect(_rgb_distance(art.get_pixelv(sample), reference.get_pixelv(sample)) < 0.012, "Road is unchanged at " + str(sample))
			if layer_index == 6:
				_expect(art.get_pixel(480, 420).a < 0.01, "Foreground leaves centre lanes clear: " + slug)
		if stage != null:
			_expect(stage.texture != null and stage.texture.resource_path.ends_with("l01_v11_%s_sky.png" % slug), "Stage uses separate sky: " + slug)
			_expect(stage.scale == Vector2(0.5, 0.5) and not stage.centered, "Stage top-left registration: " + slug)
			for child_index in CHILDREN.size():
				var child := stage.get_node_or_null(CHILDREN[child_index]) as Sprite2D
				_expect(child != null, "Missing stage child: %s/%s" % [slug, CHILDREN[child_index]])
				if child != null:
					_expect(child.texture != null and child.texture.resource_path.ends_with("l01_v11_%s_%s.png" % [slug, LAYERS[child_index + 1]]), "Correct stage child texture: " + slug)
					_expect(child.position == Vector2.ZERO and child.scale == Vector2.ONE and not child.centered and child.use_parent_material, "Child shares full-frame reveal registration: " + slug)
	runner.free()


func _test_motion_ready_modules() -> void:
	var manifest_path := ROOT + "l01_v11_roadside_modules.json"
	_expect(FileAccess.file_exists(manifest_path), "Roadside module manifest exists")
	if not FileAccess.file_exists(manifest_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	_expect(parsed is Dictionary and parsed.has("modules"), "Module manifest parses")
	if not parsed is Dictionary or not parsed.has("modules"):
		return
	var modules: Array = parsed["modules"]
	_expect(modules.size() == 20, "Five stages have four separate roadside modules each")
	for slug in MODULE_STAGES:
		var matching := 0
		for item in modules:
			if not item is Dictionary or item.get("stage", "") != slug:
				continue
			matching += 1
			var path: String = ROOT + String(item.get("file", ""))
			_expect(FileAccess.file_exists(path), "Module art exists: " + path)
			_expect(item.has("side") and item.has("depth") and item.has("contact_px"), "Module records side, depth and contact point")
			if FileAccess.file_exists(path):
				var art := _image(path)
				_expect(art != null and art.get_size() == Vector2i(960, 540), "Motion module retains registration canvas")
				if art != null:
					_expect(art.get_pixel(480, 420).a < 0.01, "Module does not cover the centre road")
		_expect(matching == 4, "Four modules prepared for " + slug)


func _test_painted_curb_guide() -> void:
	var guide := load("res://scripts/l01_visual_geometry.gd")
	_expect(guide != null, "Painted-curb visual geometry exists")
	if guide == null:
		return
	for entry in [[190.0, 101.0, 381.0], [210.0, 66.0, 416.0], [218.0, 52.0, 429.0]]:
		_expect(absf(float(guide.call("painted_curb_x", -1, entry[0])) - entry[1]) <= 2.0, "Left curb matches source at y=" + str(entry[0]))
		_expect(absf(float(guide.call("painted_curb_x", 1, entry[0])) - entry[2]) <= 2.0, "Right curb matches source at y=" + str(entry[0]))


func _image(path: String) -> Image:
	var texture := load(path) as Texture2D
	return texture.get_image() if texture != null else null


func _rgb_distance(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
