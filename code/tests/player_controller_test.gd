extends SceneTree

const LANE_STATE_PATH := "res://scripts/player_lane_state.gd"
const PLAYER_CONTROLLER_PATH := "res://scripts/player_controller.gd"
const RUNNER_CONTROLLER_PATH := "res://scripts/runner_level_controller.gd"
const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _required_resources_exist():
		_finish()
		return

	_test_lane_state_bounds_and_action_recovery()
	await _test_runner_scene_named_action_bridge()
	await _test_clear_slide_pose()
	_finish()


func _required_resources_exist() -> bool:
	var required_paths := [LANE_STATE_PATH, PLAYER_CONTROLLER_PATH, RUNNER_CONTROLLER_PATH, RUNNER_LEVEL_PATH]
	var all_exist := true
	for resource_path in required_paths:
		if not ResourceLoader.exists(resource_path):
			failures.append("Missing PR-04 resource: %s" % resource_path)
			all_exist = false
	return all_exist


func _test_lane_state_bounds_and_action_recovery() -> void:
	var lane_state_script: GDScript = load(LANE_STATE_PATH)
	var state: Variant = lane_state_script.new()

	_expect_equal(state.lane_index, 1, "Player begins in the centre lane")
	_expect(state.handle_action(&"move_left"), "Centre player can move left")
	_expect_equal(state.lane_index, 0, "Left action changes exactly one lane")
	_expect(not state.handle_action(&"move_left"), "Player cannot leave the left lane")
	_expect_equal(state.lane_index, 0, "Left boundary keeps player in left lane")
	_expect(state.handle_action(&"move_right"), "Left player can move right")
	_expect_equal(state.lane_index, 1, "Right action returns player to centre")
	_expect(state.handle_action(&"move_right"), "Centre player can move right")
	_expect_equal(state.lane_index, 2, "Right action changes exactly one lane")
	_expect(not state.handle_action(&"move_right"), "Player cannot leave the right lane")
	_expect_equal(state.lane_index, 2, "Right boundary keeps player in right lane")

	_expect(state.handle_action(&"jump"), "Idle player starts a jump action")
	_expect_equal(state.action_state, 1, "Jump enters the jump action state")
	_expect(not state.handle_action(&"slide"), "A second action cannot overlap an active action")
	state.finish_action()
	_expect_equal(state.action_state, 0, "Finished jump returns to idle")
	_expect(state.handle_action(&"slide"), "Idle player starts a slide action")
	_expect_equal(state.action_state, 2, "Slide enters the slide action state")
	state.finish_action()
	_expect_equal(state.action_state, 0, "Finished slide returns to idle")
	_expect(not state.handle_action(&"unknown"), "Unknown action does not change player state")


func _test_runner_scene_named_action_bridge() -> void:
	var packed_scene: PackedScene = load(RUNNER_LEVEL_PATH)
	var level := packed_scene.instantiate()
	root.add_child(level)
	await process_frame

	var player := level.get_node_or_null(^"Player")
	_expect(player != null and player.has_method("handle_action"), "RunnerLevel Player has a controller")
	_expect(level.has_method("receive_input"), "RunnerLevel receives named actions through an input bridge")
	if player != null and level.has_method("receive_input"):
		_expect_equal(player.get("lane_index"), 1, "Scene player starts in centre lane")
		level.call("receive_input", &"move_left", true, 1.0)
		_expect_equal(player.get("lane_index"), 0, "Named left action moves the scene player left")
		level.call("receive_input", &"move_left", false, 1.1)
		level.call("receive_input", &"move_right", true, 2.0)
		_expect_equal(player.get("lane_index"), 1, "Named right action moves the scene player one lane")
		level.call("receive_input", &"move_right", false, 2.1)
		level.call("receive_input", &"jump", true, 3.0)
		_expect_equal(player.get("action_state"), 1, "Named jump starts the neutral jump animation")
		level.call("receive_input", &"jump", false, 3.1)
		# 0.24s rise + 0.06s apex + 0.32s descent, with a frame margin.
		await create_timer(0.7).timeout
		_expect_equal(player.get("action_state"), 0, "Neutral jump animation returns the scene player to idle")

	level.queue_free()


func _test_clear_slide_pose() -> void:
	var packed_scene: PackedScene = load(RUNNER_LEVEL_PATH)
	var level := packed_scene.instantiate()
	root.add_child(level)
	await process_frame

	var player := level.get_node_or_null(^"Player") as Node2D
	var slide_streak := level.get_node_or_null(^"Player/SlideStreak") as Line2D
	_expect(slide_streak != null, "Player includes a slide motion streak")
	if player != null:
		_expect(player.call("handle_action", &"slide"), "Player accepts a slide action from idle")
		await create_timer(0.16).timeout
		var visual := player.get_node_or_null(^"Visual") as Node2D
		_expect(visual != null and visual.position.x >= 4.0, "Slide pose moves forward clearly")
		_expect(visual != null and visual.position.y >= 5.0, "Slide pose stays low and grounded")
		_expect(visual != null and visual.rotation <= -0.05, "Slide pose leans forward")
		_expect(slide_streak != null and slide_streak.visible, "Slide streak is visible during the glide")
		await create_timer(0.4).timeout
		_expect_equal(player.get("action_state"), 0, "Slide animation returns to idle")
		_expect(visual != null and is_zero_approx(visual.rotation), "Slide pose resets its rotation")
		_expect(slide_streak != null and not slide_streak.visible, "Slide streak hides after the glide")

	level.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN player controller test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN player controller test: FAIL (%d failures)" % failures.size())
	quit(1)
