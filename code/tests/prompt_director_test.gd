extends SceneTree

const PROMPT_DIRECTOR_PATH := "res://scripts/prompt_director.gd"
const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	if not ResourceLoader.exists(PROMPT_DIRECTOR_PATH):
		failures.append("PromptDirector script is missing")
		_finish()
		return

	_test_prompt_state_transitions()
	_test_one_active_prompt_rule()
	_test_neutral_resolution_paths()
	_test_runner_level_contains_director()
	_finish()


func _test_prompt_state_transitions() -> void:
	var director: Variant = _new_director()
	_expect_equal(director.state, 0, "Director starts idle")
	_expect(director.schedule(&"jump"), "Known action can be scheduled")
	_expect_equal(director.state, 1, "Scheduled prompt enters warning")
	_expect_equal(director.current_action, &"jump", "Warning retains its action")
	_expect(director.open_response_window(), "Warning can become active")
	_expect_equal(director.state, 2, "Prompt enters active response state")
	_expect(director.receive_action(&"jump"), "Active prompt accepts a matching action")
	_expect_equal(director.state, 3, "Matching action resolves the prompt")
	_expect_equal(director.resolution, 1, "Matching action resolves as success")
	_expect(director.clear_resolved_prompt(), "Resolved prompt can be cleared")
	_expect_equal(director.state, 0, "Cleared prompt returns to idle")
	_expect_equal(director.current_action, &"", "Cleared prompt has no active action")


func _test_one_active_prompt_rule() -> void:
	var director: Variant = _new_director()
	_expect(not director.schedule(&"unknown"), "Unknown action cannot be scheduled")
	_expect(director.schedule(&"move_left"), "First prompt can be scheduled")
	_expect(not director.schedule(&"slide"), "Second prompt is rejected during warning")
	_expect(director.open_response_window(), "Prompt can become active")
	_expect(not director.schedule(&"slide"), "Second prompt is rejected during active response")
	_expect(director.expire_active_prompt(), "Active prompt can expire")
	_expect(not director.schedule(&"slide"), "Second prompt is rejected until resolved prompt is cleared")
	_expect(director.clear_resolved_prompt(), "Resolved prompt clears explicitly")
	_expect(director.schedule(&"slide"), "A new prompt can be scheduled only after clear")


func _test_neutral_resolution_paths() -> void:
	var wrong_action_director: Variant = _new_director()
	wrong_action_director.schedule(&"jump")
	wrong_action_director.open_response_window()
	_expect(wrong_action_director.receive_action(&"slide"), "Wrong action is received without error")
	_expect_equal(wrong_action_director.state, 3, "Wrong action resolves the prompt")
	_expect_equal(wrong_action_director.resolution, 2, "Wrong action resolves neutrally")

	var expired_director: Variant = _new_director()
	expired_director.schedule(&"move_right")
	expired_director.open_response_window()
	_expect(expired_director.expire_active_prompt(), "No-input prompt can expire")
	_expect_equal(expired_director.resolution, 2, "Expired prompt resolves neutrally")
	_expect(not expired_director.receive_action(&"move_right"), "Resolved prompt ignores later actions")


func _test_runner_level_contains_director() -> void:
	var packed_scene: PackedScene = load(RUNNER_LEVEL_PATH)
	var level := packed_scene.instantiate()
	var director := level.get_node_or_null(^"PromptDirector")
	_expect(director != null, "RunnerLevel includes a PromptDirector node")
	if director != null:
		_expect(director.has_method("schedule"), "RunnerLevel director can schedule a prompt")
		_expect(director.has_method("receive_action"), "RunnerLevel director receives named actions")
	level.queue_free()


func _new_director() -> Variant:
	var director_script: GDScript = load(PROMPT_DIRECTOR_PATH)
	return director_script.new()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN prompt director test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN prompt director test: FAIL (%d failures)" % failures.size())
	quit(1)
