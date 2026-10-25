extends SceneTree

const Geometry = preload("res://scripts/l01_visual_geometry.gd")
const NEW_PREFIX := "l01_v6_"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var library: Array = level.get("_formation_library")
	var new_count := 0
	for candidate in library:
		if not String(candidate.get("pattern_id", &"")).begins_with(NEW_PREFIX):
			continue
		new_count += 1
		_test_formation(level, candidate)
	_expect(new_count == 19, "All 19 new Jump/Slide formations received an integration check")
	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 new formation integration: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_formation(level: Node, formation: Dictionary) -> void:
	var id := String(formation.get("pattern_id", &""))
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	var player: Node = level.get_node(^"Player")
	player.call("reset_for_practice")
	var entry_lane := int(formation.get("entry_lanes", [1])[0])
	if entry_lane == 0:
		player.call("handle_action", &"move_left")
	elif entry_lane == 2:
		player.call("handle_action", &"move_right")
	_expect(player.get("lane_index") == entry_lane, id + " reaches its declared entry lane")
	var director: Node = level.get_node(^"PromptDirector")
	director.call("_set_state", 0)
	level.set("_active_formation", formation.duplicate(true))
	level.set("_pending_response_action", &"")
	var lanes: Array[int] = []
	for lane in formation.get("action_lanes", [formation.get("action_lane", entry_lane)]):
		lanes.append(int(lane))
	var action := StringName(formation.get("required_action", &""))
	director.call("schedule_with_action_lanes", action, lanes)
	var props: Array = level.call("get_active_formation_props")
	_expect(props.size() == formation.get("obstacles", []).size(), id + " renders every authored prop")
	var motion: Node = level.get_node(^"WorldMotion")
	motion.set_process(false)
	for fraction in [0.0, 0.5, 1.0]:
		motion.call("_process", 0.0 if fraction == 0.0 else 2.25)
		var laundry_heights: Array[float] = []
		for prop_value in props:
			var prop := prop_value as Node2D
			var lane := int(prop.get_meta(&"formation_lane", -1))
			var expected_x: float = motion.call("lane_center_for", lane, GameSettings.approach_fraction(fraction))
			var footprint: Vector2 = prop.get_meta(&"projection_footprint", Vector2.ZERO)
			var half_width := footprint.x * prop.global_scale.x * 0.5
			if String(prop.name).begins_with("Formation_laundry_line"):
				laundry_heights.append(footprint.y * prop.global_scale.y)
			_expect(absf(prop.global_position.x - expected_x) <= 8.1, "%s lane %d projects near its centre at %.1f" % [id, lane, fraction])
			if lane != 1:
				var side := -1 if lane == 0 else 1
				var curb := Geometry.painted_curb_x(side, prop.global_position.y)
				var clearance := prop.global_position.x - half_width - curb if side < 0 else curb - prop.global_position.x - half_width
				_expect(clearance >= 2.0, "%s lane %d stays inside painted curb at %.1f (%.1f px)" % [id, lane, fraction, clearance])
		if laundry_heights.size() > 1:
			_expect(absf(laundry_heights.max() - laundry_heights.min()) <= 1.0, "%s same-depth laundry lines keep equal readable height at %.1f" % [id, fraction])
	director.call("open_response_window")
	var before: int = int(level.get("session_result").get_completed(action))
	level.call("receive_input", action, true, 1000.0 + float(before))
	level.call("_on_response_timer_timeout")
	_expect(level.get("session_result").get_completed(action) == before + 1, id + " awards exactly one prescribed repetition")
	_expect(not level.get("is_session_ended"), id + " resolves without physical contact")
	level.call("receive_input", action, false, 1000.01 + float(before))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
