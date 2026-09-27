extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_player_can_correct_before_contact()
	await _test_safe_lane_uses_clear_wording()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN contact response test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _make_level() -> Node:
	var level: Node = (load(RUNNER_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	_configure_open_left_gate(level)
	return level


func _test_player_can_correct_before_contact() -> void:
	var level := await _make_level()
	var director: Node = level.get_node("PromptDirector")
	director.call("open_response_window")
	level.call("receive_input", &"move_left", true, 10.0)
	level.call("receive_input", &"move_left", false, 10.01)
	level.call("receive_input", &"move_right", true, 10.5)
	level.call("receive_input", &"move_right", false, 10.51)
	_expect(level.get_node("Player").get("lane_index") == 1, "Peter can correct back to the centre before contact")
	level.call("receive_input", &"move_left", true, 11.0)
	_expect(level.get_node("Player").get("lane_index") == 0, "Peter can make the final correct lane choice before contact")
	level.call("_on_response_timer_timeout")
	_expect(level.get("session_result").get_completed(&"move_left") == 1, "Final valid contact response earns exactly one repetition")
	level.free()


func _test_safe_lane_uses_clear_wording() -> void:
	var level := await _make_level()
	# This is a lane carried over from the preceding formation, not a new
	# warning-phase movement for the current formation.
	level.get_node("Player").call("handle_action", &"move_left")
	level.set("_pending_response_action", &"")
	level.set("_pending_response_movement_accepted", false)
	var director: Node = level.get_node("PromptDirector")
	director.call("open_response_window")
	_expect(level.get_node("HUD/HUDRoot/PromptActionLabel").text == "SAFE PATH", "Already-open lane uses safe-path wording instead of a movement demand")
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
