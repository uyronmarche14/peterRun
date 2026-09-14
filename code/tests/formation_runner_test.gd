extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level: Node = (load(RUNNER_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	_test_first_formation_renders_and_resolves_at_contact(level)
	level.free()
	var safe_clear_level: Node = (load(RUNNER_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(safe_clear_level)
	await process_frame
	await process_frame
	_test_safe_lane_clear_is_positive_without_a_repetition(safe_clear_level)
	safe_clear_level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN formation runner test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_first_formation_renders_and_resolves_at_contact(level: Node) -> void:
	_expect(level.has_method("get_active_formation_props"), "Runner exposes the active formation props")
	_expect(level.get("active_formation_id") != &"", "L01 begins with a reachable shuffled formation")
	var props: Array = level.call("get_active_formation_props") if level.has_method("get_active_formation_props") else []
	var formation: Dictionary = level.get("_active_formation")
	_expect(props.size() == formation.get("obstacles", []).size(), "The opening formation renders every authored obstacle")
	var lanes: Array[int] = []
	for prop in props:
		lanes.append(int(prop.get_meta("formation_lane", -1)))
	_expect(lanes.size() == lanes.duplicate().size(), "Each opening obstacle occupies a distinct lane")

	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	var motion: Node = level.get_node("WorldMotion")
	motion.set_process(false)
	motion.call("begin_prompt_approach", 1, 2.5, 2.0)
	motion.call("_process", 4.5)
	var anchor: Node2D = level.get_node("LevelWorld/PromptWorldAnchor")
	_expect(is_equal_approx(anchor.position.y, 218.0), "The formation reaches the player contact line")
	for prop in props:
		_expect(is_equal_approx(prop.global_scale.x, anchor.global_scale.x), "Every formation obstacle shares the approach depth scale")

	var director: Node = level.get_node("PromptDirector")
	_configure_open_left_gate(level)
	director.call("open_response_window")
	level.call("receive_input", &"move_left", true, 10.0)
	_expect(level.get("session_result").get_completed(&"move_left") == 0, "A response waits for the contact line before earning a repetition")
	level.call("_on_response_timer_timeout")
	_expect(director.get("state") == 3, "The formation resolves when its response window reaches contact")
	_expect(level.get("session_result").get_completed(&"move_left") == 1, "Moving into the open lane earns one matching repetition")


func _test_safe_lane_clear_is_positive_without_a_repetition(level: Node) -> void:
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	_configure_open_left_gate(level)
	level.call("receive_input", &"move_left", true, 20.0)
	var director: Node = level.get_node("PromptDirector")
	director.call("open_response_window")
	level.call("_on_response_timer_timeout")
	_expect(level.get("session_result").route_clear_points == 1, "Already occupying the open lane records route progress")
	_expect(level.get("session_result").get_completed(&"move_left") == 0, "Already-safe route progress does not add a therapy repetition")
	var toast: Control = level.get_node("HUD/HUDRoot/FeedbackToast")
	_expect(toast.get_node("Message").text != "Take your time.", "Safe route progress receives positive feedback")
	_expect(level.has_node("HUD/HUDRoot/JourneyLabel"), "Gameplay shows a calm journey landmark")
	if level.has_node("HUD/HUDRoot/JourneyLabel"):
		var journey_label: Label = level.get_node("HUD/HUDRoot/JourneyLabel")
		_expect(journey_label.text == "Journey: Waiting Shed", "Safe route progress advances the journey landmark")
		_expect(not journey_label.text.contains("Clear") and not journey_label.text.contains("Score"), "Gameplay does not label journey progress as a score")


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
