extends SceneTree

const RoadProjectionModel = preload("res://scripts/road_projection.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_shared_projection_geometry()
	await _test_runtime_alignment()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 shared-road projection test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_shared_projection_geometry() -> void:
	_expect(RoadProjectionModel.PLAYER_LANE_X == [108.0, 240.0, 372.0], "Player lane centres match the v05 painted road")
	_expect(is_equal_approx(RoadProjectionModel.lane_center_at(1, 0.0), 240.0), "Far centre lane remains centred")
	_expect(is_equal_approx(RoadProjectionModel.lane_center_at(0, 1.0), 108.0), "Left lane reaches the painted player-depth centre")
	_expect(is_equal_approx(RoadProjectionModel.lane_center_at(2, 1.0), 372.0), "Right lane reaches the painted player-depth centre")
	_expect(RoadProjectionModel.road_edge_at(-1, 1.0) < RoadProjectionModel.lane_center_at(0, 1.0), "Left curb stays outside the left gameplay lane")
	_expect(RoadProjectionModel.road_edge_at(1, 1.0) > RoadProjectionModel.lane_center_at(2, 1.0), "Right curb stays outside the right gameplay lane")
	_expect(is_equal_approx(RoadProjectionModel.l01_road_edge_at(-1, 0.0), 208.0), "Far L01 road bound aligns to the painted vanishing point")
	_expect(is_equal_approx(RoadProjectionModel.road_edge_at(1, 1.0), 456.0), "Other routes keep their original road projection")
	_expect(is_equal_approx(RoadProjectionModel.l01_road_edge_at(1, 1.0), 408.0), "Near L01 road bound stays within its painted curb edge")
	_expect(RoadProjectionModel.lane_separator_at(0, 1.0) < RoadProjectionModel.lane_separator_at(1, 1.0), "Two separators define three stable lane centers")
	var far_scale := RoadProjectionModel.scale_at(0.0)
	var medium_scale := RoadProjectionModel.scale_at(0.65)
	var near_scale := RoadProjectionModel.scale_at(1.0)
	_expect(far_scale <= 0.4, "Incoming prompts begin clearly small")
	_expect(medium_scale > 0.65 and medium_scale < 1.0, "Incoming prompts pass through a readable medium scale")
	_expect(near_scale >= 1.4, "Incoming prompts finish with a clear large foreground scale")
	_expect(is_equal_approx(RoadProjectionModel.fraction_from_scale(medium_scale), 0.65), "Scale inversion preserves the shared road depth")
	for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
		_expect(RoadProjectionModel.lane_center_at(0, fraction) < RoadProjectionModel.lane_center_at(1, fraction), "Left-to-centre ordering remains stable at depth %.2f" % fraction)
		_expect(RoadProjectionModel.lane_center_at(1, fraction) < RoadProjectionModel.lane_center_at(2, fraction), "Centre-to-right ordering remains stable at depth %.2f" % fraction)


func _test_runtime_alignment() -> void:
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	level.set_script(null)
	root.add_child(level)
	await process_frame
	var player := level.get_node(^"Player") as Node2D
	_expect(is_equal_approx(player.position.x, RoadProjectionModel.PLAYER_LANE_X[1]), "Peter starts on the shared centre lane")
	var motion := level.get_node(^"WorldMotion")
	motion.set_process(false)
	var anchor := level.get_node(^"LevelWorld/PromptWorldAnchor") as Node2D
	for lane in 3:
		motion.call("begin_prompt_approach", lane, 2.5, 2.0)
		motion.call("_process", 4.5)
		_expect(is_equal_approx(anchor.position.x, RoadProjectionModel.PLAYER_LANE_X[lane]), "Prompt reaches the same player-depth lane centre: %d" % lane)
		_expect(is_equal_approx(anchor.position.y, RoadProjectionModel.PLAYER_CONTACT_Y), "Prompt reaches the shared ground-contact line")
	_test_prop_ground_origin("res://scenes/props/crate.tscn", -42.5)
	_test_prop_ground_origin("res://scenes/props/puddle.tscn", -9.75)
	_test_prop_ground_origin("res://scenes/props/laundry_line.tscn", -31.2)
	level.free()


func _test_prop_ground_origin(scene_path: String, expected_art_y: float) -> void:
	var prop := (load(scene_path) as PackedScene).instantiate()
	var art := prop.get_node(^"ArtSprite") as Sprite2D
	_expect(is_equal_approx(art.position.y, expected_art_y), "Prop art is offset above its stable bottom-centre origin: " + scene_path)
	prop.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
