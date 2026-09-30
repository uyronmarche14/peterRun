extends SceneTree

const RoadProjectionModel = preload("res://scripts/road_projection.gd")
const SpriteModel = preload("res://scripts/classic_runner_sprite.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_stronger_approach_perspective()
	_test_lane_safe_prompt_footprints()
	await _test_runtime_approach_and_removed_side_cones()
	await _test_stronger_jump_and_slide_presentation()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN motion and perspective upgrade test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_stronger_approach_perspective() -> void:
	var far_scale := RoadProjectionModel.scale_at(0.0)
	var quarter_scale := RoadProjectionModel.scale_at(0.25)
	var medium_scale := RoadProjectionModel.scale_at(0.65)
	var three_quarter_scale := RoadProjectionModel.scale_at(0.75)
	var near_scale := RoadProjectionModel.scale_at(1.0)
	_expect(far_scale <= 0.26, "Obstacles begin very small at the horizon")
	_expect(medium_scale >= 0.58 and medium_scale <= 0.80, "Obstacles pass through a readable medium size")
	_expect(near_scale >= 1.55, "Obstacles finish clearly large near Peter")
	_expect(near_scale - three_quarter_scale > (quarter_scale - far_scale) * 3.0, "Perspective growth accelerates naturally near the camera")


func _test_lane_safe_prompt_footprints() -> void:
	# These are the visible alpha footprints after each prop scene's authored
	# child-sprite scale. The projection must keep them inside one lane even
	# though the shared world anchor continues its strong approach growth.
	var footprints := {
		&"crate": Vector2(61.5, 85.0),
		&"puddle": Vector2(89.25, 17.625),
		&"laundry": Vector2(98.8, 64.8),
	}
	for prop_name in footprints:
		var previous_width := 0.0
		for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var size: Vector2 = RoadProjectionModel.projected_prop_size(footprints[prop_name], fraction)
			var lane_limit := RoadProjectionModel.lane_span_at(fraction) * RoadProjectionModel.PROP_LANE_FILL_RATIO
			_expect(size.x <= lane_limit + 0.01, "%s stays within its projected lane at depth %.2f" % [prop_name, fraction])
			_expect(size.x > previous_width, "%s grows continuously from small to large" % prop_name)
			previous_width = size.x
	var near_crate := RoadProjectionModel.projected_prop_size(footprints[&"crate"], 1.0)
	_expect(near_crate.y <= RoadProjectionModel.PROP_MAX_SCREEN_HEIGHT + 0.01, "Near crate stack remains proportional to Peter instead of towering over him")
	_expect(near_crate.y <= 75.2 * 1.35, "Two-crate stack stays within 135% of Peter's measured standing sprite height")


func _test_runtime_approach_and_removed_side_cones() -> void:
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	level.set_script(null)
	root.add_child(level)
	var initial_dashes := level.get_node(^"LevelWorld/RoadAndLanes/RoadMotionDashes") as Node2D
	for dash_value in initial_dashes.get_children():
		var dash := dash_value as Line2D
		_expect(dash != null and dash.modulate.a * dash.default_color.a <= 0.181, "Road-depth seams begin subtle before the first process frame")
	await process_frame
	var roadside := level.get_node(^"LevelWorld/RoadsideMotion") as Node2D
	_expect(roadside.get_child_count() == 4, "Four grounded street-section sprites replace the empty side-marker layer")
	for module in roadside.get_children():
		var building := module as Sprite2D
		_expect(building != null and building.texture != null, "Only transparent building sprites populate the roadside layer")
	var route_layers := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	_expect(not route_layers.has_node(^"RoadsideLeavesLeft"), "Left leaf-tip overlay cannot render as a side cone")
	_expect(not route_layers.has_node(^"RoadsideLeavesRight"), "Right leaf-tip overlay cannot render as a side cone")
	route_layers.set_process(false)
	var clouds := route_layers.get_node(^"CloudsA") as Sprite2D
	var laundry := route_layers.get_node(^"Laundry") as Sprite2D
	var resident := route_layers.get_node(^"ResidentWave") as Sprite2D
	var cloud_start := clouds.position
	var laundry_anchor := laundry.position
	var resident_anchor := resident.position
	route_layers.call("advance_layer_motion", 6.2)
	_expect(clouds.position.x != cloud_start.x and clouds.position.x >= -9.1 and clouds.position.x <= 1.1, "Clouds drift visibly inside bounded horizontal alignment limits without wrapping")
	_expect(is_equal_approx(clouds.position.y, cloud_start.y) and clouds.position.y <= -34.0, "Moving cloud sheet stays locked to the upper sky instead of crossing the landmark horizon")
	_expect(clouds.position.y + 216.0 * clouds.scale.y <= 75.0, "Lowest visible cloud pixel remains in the upper cloud band")
	_expect(laundry.position == laundry_anchor and laundry.frame != 0, "Laundry cloth changes pose while its line endpoints remain fixed")
	_expect(resident.position == resident_anchor and resident.frame > 0, "Larger resident waves without sliding off the sidewalk contact")
	var motion := level.get_node(^"WorldMotion")
	motion.set_process(false)
	var anchor := level.get_node(^"LevelWorld/PromptWorldAnchor") as Node2D
	motion.call("begin_prompt_approach", 2, 2.5, 2.0)
	var small_scale := anchor.scale.x
	var small_alpha := anchor.modulate.a
	motion.call("_process", 2.55)
	var medium_scale := anchor.scale.x
	motion.call("_process", 1.80)
	var large_scale := anchor.scale.x
	_expect(small_scale < medium_scale and medium_scale < large_scale, "Runtime obstacle grows continuously from small to medium to large")
	_expect(large_scale / maxf(small_scale, 0.001) >= 5.5, "Runtime approach has a strong foreground depth ratio")
	_expect(small_alpha < anchor.modulate.a, "Distant obstacle fades gently into full foreground clarity")
	level.free()


func _test_stronger_jump_and_slide_presentation() -> void:
	var player := (load("res://scenes/player.tscn") as PackedScene).instantiate()
	root.add_child(player)
	player.set_process(false)
	var visual := player.get_node(^"Visual") as Node2D
	_expect(player.character_sprite.scale == Vector2(0.40, 0.40), "Peter is large enough to read against the detailed environment")

	player.call("handle_action", &"jump")
	var jump_tween: Tween = player.get("_action_tween")
	jump_tween.pause()
	player.call("_process", 0.34)
	jump_tween.custom_step(0.34)
	_expect(player.character_sprite.duration >= 0.90, "New eight-pose jump presentation lingers long enough to read")
	_expect(SpriteModel.CLIPS[&"jump_low"][0] == 8, "Jump uses all eight new preparation-to-recovery poses")
	_expect(visual.position.y <= -18.0, "Jump reaches a clearly higher apex while the shadow stays grounded")
	jump_tween.custom_step(0.6)
	player.call("_process", 0.6)
	_expect(player.action_state == 0 and visual.position == Vector2.ZERO, "Longer jump still lands and recovers cleanly")

	player.call("reset_for_practice")
	player.call("handle_action", &"slide")
	var slide_tween: Tween = player.get("_action_tween")
	slide_tween.pause()
	player.call("_process", 0.32)
	slide_tween.custom_step(0.32)
	_expect(player.character_sprite.duration >= 0.64, "Slide presentation has a stronger readable hold")
	_expect(visual.position.y >= 3.0, "Slide settles into a visibly deeper grounded pose")
	_expect(player.get_node(^"SlideDust").modulate.a >= 0.70, "Slide ground feedback is strong enough to read without screen shake")
	slide_tween.custom_step(0.4)
	player.call("_process", 0.4)
	_expect(player.action_state == 0 and visual.position == Vector2.ZERO, "Longer slide exits cleanly back to locomotion")
	player.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
