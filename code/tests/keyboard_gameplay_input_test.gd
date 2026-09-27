extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene: PackedScene = load(RUNNER_LEVEL_PATH)
	var level := packed_scene.instantiate()
	root.add_child(level)
	await process_frame

	var player := level.get_node_or_null(^"Player") as Node2D
	_expect(player != null, "RunnerLevel has a player")
	if player != null:
		level.call("_input", _keyboard_event(KEY_A, true))
		_expect_equal(player.get("lane_index"), 0, "Real A key moves player one lane left")
		level.call("_input", _keyboard_event(KEY_A, false))

		level.call("_input", _keyboard_event(KEY_W, true))
		_expect_equal(player.get("action_state"), 1, "Real W key starts the jump action")
		await create_timer(0.08).timeout
		var visual := player.get_node_or_null(^"Visual") as Node2D
		_expect(visual != null and visual.position.y < -1.0, "Jump visibly rises above the running position")
		level.call("_input", _keyboard_event(KEY_W, false))

	level.free()
	_finish()


func _keyboard_event(physical_key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = physical_key
	event.pressed = pressed
	return event


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN keyboard gameplay input test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN keyboard gameplay input test: FAIL (%d failures)" % failures.size())
	quit(1)
