extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_active_formation_keeps_its_world_layout()
	await _test_response_can_be_corrected_until_contact()
	await _test_correct_warning_phase_movement_counts_at_contact()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN formation response integrity test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _make_level() -> Node:
	var level: Node = (load(RUNNER_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	return level


func _test_active_formation_keeps_its_world_layout() -> void:
	var level := await _make_level()
	var motion: Node = level.get_node("WorldMotion")
	motion.set_process(false)
	motion.call("_process", 1.0)
	var before_positions: Array[Vector2] = []
	for prop in level.call("get_active_formation_props"):
		before_positions.append(prop.position)
	var director: Node = level.get_node("PromptDirector")
	director.call("open_response_window")
	var active_props: Array = level.call("get_active_formation_props")
	_expect(active_props.size() == before_positions.size(), "Opening MOVE NOW keeps the same obstacle formation")
	for index in mini(active_props.size(), before_positions.size()):
		_expect(active_props[index].position.is_equal_approx(before_positions[index]), "Opening MOVE NOW does not reset obstacle %d to the centre" % index)
	level.free()


func _test_response_can_be_corrected_until_contact() -> void:
	var level := await _make_level()
	var director: Node = level.get_node("PromptDirector")
	_configure_open_left_gate(level)
	director.call("open_response_window")
	level.call("receive_input", &"move_left", true, 10.0)
	level.call("receive_input", &"move_left", false, 10.01)
	var player: Node = level.get_node("Player")
	var lane_after_first_input: int = player.get("lane_index")
	level.call("receive_input", &"move_right", true, 10.5)
	_expect(player.get("lane_index") != lane_after_first_input, "Later response inputs can correct Peter before contact")
	level.call("receive_input", &"move_left", true, 11.0)
	_expect(player.get("lane_index") == lane_after_first_input, "The final contact position can return to the correct lane")
	level.call("_on_response_timer_timeout")
	_expect(level.get("session_result").get_completed(&"move_left") == 1, "One final valid response awards exactly one matching repetition")
	_expect(level.get("session_result").neutral_misses == 0, "A corrected response remains a valid repetition")
	level.free()


func _test_correct_warning_phase_movement_counts_at_contact() -> void:
	var level := await _make_level()
	_configure_open_left_gate(level)
	level.call("receive_input", &"move_left", true, 20.0)
	level.call("receive_input", &"move_left", false, 20.01)
	_expect(level.get_node("Player").get("lane_index") == 0, "Correct warning-phase movement reaches the safe left lane")
	var director: Node = level.get_node("PromptDirector")
	director.call("open_response_window")
	_expect(level.get_node("HUD/HUDRoot/PromptStateLabel").text == "ACTION READY", "Early correct movement is acknowledged without asking for a second press")
	level.call("_on_response_timer_timeout")
	_expect(level.get("session_result").get_completed(&"move_left") == 1, "Correct warning-phase movement earns one repetition at contact")
	_expect(level.get("session_result").neutral_misses == 0, "Correct warning-phase movement is not logged as a miss")
	level.free()


func _configure_open_left_gate(level: Node) -> void:
	var formation: Dictionary = {}
	for candidate_value in level.get("_formation_library"):
		if candidate_value is Dictionary and candidate_value.get("pattern_id", &"") == &"l01_p01_move_left":
			formation = (candidate_value as Dictionary).duplicate(true)
			break
	var director: Node = level.get_node("PromptDirector")
	director.call("_set_state", 0)
	level.set("_active_formation", formation)
	level.set("active_formation_id", &"l01_p01_move_left")
	director.call("schedule", &"move_left", 1, 0, true)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
