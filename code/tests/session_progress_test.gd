extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene: PackedScene = load(RUNNER_LEVEL_PATH)
	var level: Node = packed_scene.instantiate()
	root.add_child(level)
	await process_frame

	_expect_node(level, ^"HUD/HUDRoot/ProgressLabel", "repetition progress label")
	_expect_node(level, ^"HUD/HUDRoot/NeutralMissLabel", "neutral miss label")

	var config: Variant = level.get("session_config")
	var result: Variant = level.get("session_result")
	_expect(config != null, "Runner level owns a session configuration")
	_expect(result != null, "Runner level owns a session result")
	if config != null and result != null:
		for action_name in [&"move_left", &"move_right", &"jump", &"slide"]:
			config.set_target(action_name, 1)

		level.call("_on_prompt_state_changed", 3, &"jump", 1)
		_expect_equal(result.get_completed(&"jump"), 1, "Matching prompt action increments its repetition")
		_expect_equal(level.get_node(^"HUD/HUDRoot/ProgressLabel").text, "Reps: 1 / 4", "Progress displays completed planned repetitions")

		level.call("_on_prompt_state_changed", 3, &"slide", 2)
		_expect_equal(result.get_completed(&"slide"), 0, "Wrong action records no repetition")
		_expect_equal(result.neutral_misses, 1, "Wrong action records one neutral miss")
		_expect_equal(level.get_node(^"HUD/HUDRoot/NeutralMissLabel").text, "Misses: 1", "Miss count is visible")

		level.call("_on_prompt_state_changed", 3, &"move_left", 1)
		level.call("_on_prompt_state_changed", 3, &"move_right", 1)
		level.call("_on_prompt_state_changed", 3, &"slide", 1)
		_expect(result.has_met_targets(config), "All planned action targets can complete")
		_expect(level.get("is_session_ended"), "Completing targets ends L01 safely")
		_expect_equal(level.get_node(^"EndSessionOverlay/Panel/Title").text, "L01 complete", "Completion shows a calm L01 completion state")

	level.queue_free()
	await process_frame
	_finish()


func _expect_node(root_node: Node, path: NodePath, description: String) -> void:
	_expect(root_node.get_node_or_null(path) != null, "RunnerLevel includes %s" % description)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN session progress test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN session progress test: FAIL (%d failures)" % failures.size())
	quit(1)
