extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"
const Review = preload("res://scripts/session_review_store.gd")
const RoadProjectionModel = preload("res://scripts/road_projection.gd")

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
	_test_idle_safe_lane_does_not_award_progress(safe_clear_level)
	safe_clear_level.free()
	var collision_level: Node = (load(RUNNER_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(collision_level)
	await process_frame
	await process_frame
	_test_collision_ends_the_run(collision_level)
	collision_level.free()
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
		var footprint: Vector2 = prop.get_meta(&"projection_footprint", Vector2.ZERO)
		var expected_fit := RoadProjectionModel.prop_fit_scale(footprint, 1.0)
		_expect(is_equal_approx(prop.global_scale.x, anchor.global_scale.x * expected_fit), "Every formation obstacle shares the lane-safe approach scale")
	var sorted_props := props.duplicate()
	sorted_props.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.global_position.x < b.global_position.x)
	for index in range(1, sorted_props.size()):
		var left := sorted_props[index - 1] as Node2D
		var right := sorted_props[index] as Node2D
		var left_width := float((left.get_meta(&"projection_footprint", Vector2.ZERO) as Vector2).x) * left.global_scale.x
		var right_width := float((right.get_meta(&"projection_footprint", Vector2.ZERO) as Vector2).x) * right.global_scale.x
		_expect(right.global_position.x - left.global_position.x > (left_width + right_width) * 0.5, "Adjacent obstacle silhouettes remain visibly separated inside their lanes")

	var director: Node = level.get_node("PromptDirector")
	_configure_open_left_gate(level)
	director.call("open_response_window")
	level.call("receive_input", &"move_left", true, 10.0)
	_expect(level.get("session_result").get_completed(&"move_left") == 0, "A response waits for the contact line before earning a repetition")
	level.call("_on_response_timer_timeout")
	_expect(director.get("state") == 3, "The formation resolves when its response window reaches contact")
	_expect(level.get("session_result").get_completed(&"move_left") == 1, "Moving into the open lane earns one matching repetition")
	_expect(not level.get("is_session_ended"), "A correct safe-lane response does not end the run")


func _test_idle_safe_lane_does_not_award_progress(level: Node) -> void:
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	_configure_open_left_gate(level)
	# Peter arrives in the open lane from the preceding formation. This is not
	# a new warning-phase response for the current formation.
	level.get_node("Player").call("handle_action", &"move_left")
	level.set("_pending_response_action", &"")
	level.set("_pending_response_movement_accepted", false)
	var director: Node = level.get_node("PromptDirector")
	director.call("open_response_window")
	level.call("_on_response_timer_timeout")
	_expect(not _has_property(level.get("session_result"), &"route_clear_points"), "Session results do not contain route points")
	_expect(level.get("session_result").get_completed(&"move_left") == 0, "No movement in an already-open lane adds no therapy repetition")
	_expect(level.get("session_result").neutral_misses == 0, "An already-open lane remains a safe passage, not a miss")
	var toast: Control = level.get_node("HUD/HUDRoot/FeedbackToast")
	_expect(toast.get_node("Message").text == "Path is clear.", "Idle safe passage receives non-reward wording")
	_expect(level.has_node("HUD/HUDRoot/JourneyLabel"), "Gameplay shows a calm journey landmark")
	if level.has_node("HUD/HUDRoot/JourneyLabel"):
		var journey_label: Label = level.get_node("HUD/HUDRoot/JourneyLabel")
		_expect(journey_label.text == "Journey: Home", "No movement does not advance the journey landmark")
		_expect(not journey_label.text.contains("Clear") and not journey_label.text.contains("Score"), "Gameplay does not label journey progress as a score")


func _test_collision_ends_the_run(level: Node) -> void:
	Review.reset()
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	_configure_open_left_gate(level)
	var director: Node = level.get_node("PromptDirector")
	director.call("open_response_window")
	level.call("_on_response_timer_timeout")
	_expect(level.get("is_session_ended"), "A blocked-lane contact ends the run")
	_expect(level.get_node("EndSessionOverlay").visible, "Collision shows the end-of-run overlay")
	_expect(level.get("session_result").neutral_misses == 0, "Obstacle contact is not counted as a neutral miss")
	_expect(Review.get_end_reason() == &"collision", "Obstacle contact has a distinct review outcome")


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


func _has_property(instance: Object, property_name: StringName) -> bool:
	for property in instance.get_property_list():
		if StringName(property.get("name", &"")) == property_name:
			return true
	return false
