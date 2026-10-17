extends SceneTree

const Geometry = preload("res://scripts/l01_visual_geometry.gd")
const RoadModel = preload("res://scripts/road_projection.gd")
const STAGES := ["StageHome", "StageWaitingShed", "StageSariSari", "StagePalengke", "StagePlaza"]
const ROWS := [
	# Native y, left/right edges of the opaque road/sidewalk PNG, measured at source y * 2.
	Vector3(120.0, 187.0, 314.5),
	Vector3(150.0, 130.0, 350.5),
	Vector3(190.0, 47.0, 433.0),
	Vector3(210.0, 20.5, 462.0),
	Vector3(218.0, 8.0, 472.0),
	Vector3(241.0, 1.0, 479.0),
]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	level.set_script(null)
	root.add_child(level)
	await process_frame
	level.get_node(^"WorldMotion").set_process(false)
	var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	var home_spans: Array[Vector2] = []
	for stage_name in STAGES:
		var road := route.get_node("JourneyStages/%s/Road" % stage_name) as Sprite2D
		_expect(road != null and road.texture != null, "%s has a road layer" % stage_name)
		if road == null or road.texture == null:
			continue
		var image := road.texture.get_image()
		_expect(image.get_size() == Vector2i(960, 540), "%s road is 960x540" % stage_name)
		_expect(road.global_position.distance_to(Vector2.ZERO) <= 0.01, "%s road origin is screen zero" % stage_name)
		_expect(road.global_scale.distance_to(Vector2.ONE * 0.5) <= 0.01, "%s road maps to native canvas" % stage_name)
		_expect(image.get_pixel(480, 224).a < 0.01, "%s road has no paint at far y=112" % stage_name)
		for index in ROWS.size():
			var row: Vector3 = ROWS[index]
			var span := _opaque_span(image, int(row.x) * 2)
			_expect(span.distance_to(Vector2(row.y, row.z)) <= 0.75,
				"%s road outer edge at native y=%d matches measured guide" % [stage_name, int(row.x)])
			if stage_name == STAGES[0]:
				home_spans.append(span)
			else:
				_expect(span.distance_to(home_spans[index]) <= 0.5,
					"%s road outer edge matches Home at y=%d" % [stage_name, int(row.x)])
			if row.x >= 150.0:
				var painted_left := Geometry.painted_curb_x(-1, row.x)
				var painted_right := Geometry.painted_curb_x(1, row.x)
				_expect(painted_left > span.x and painted_right < span.y,
					"%s painted curb is inside opaque sidewalk at y=%d" % [stage_name, int(row.x)])
				var fraction := pow((row.x - RoadModel.HORIZON_Y) / (RoadModel.PLAYER_CONTACT_Y - RoadModel.HORIZON_Y), 1.0 / 1.85)
				for lane in 3:
					var centre := RoadModel.lane_center_at(lane, fraction)
					_expect(centre >= painted_left + 2.0 and centre <= painted_right - 2.0,
						"%s lane %d stays inside painted curb at y=%d" % [stage_name, lane, int(row.x)])
	_expect(is_equal_approx(Geometry.roadside_contact_x(-1, 190.0, 2.0), 99.0), "Left roadside edge anchors two pixels outside painted curb")
	_expect(is_equal_approx(Geometry.roadside_contact_x(1, 190.0, 2.0), 383.0), "Right roadside edge anchors two pixels outside painted curb")
	_expect(is_equal_approx(Geometry.roadside_contact_x(-1, 190.0, -5.0), 101.0), "Negative roadside clearance cannot enter the road")
	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 composition contract: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _opaque_span(image: Image, source_y: int) -> Vector2:
	var left := -1
	var right := -1
	for x in image.get_width():
		if image.get_pixel(x, source_y).a >= 0.94:
			if left < 0:
				left = x
			right = x
	return Vector2(float(left) * 0.5, float(right) * 0.5)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
