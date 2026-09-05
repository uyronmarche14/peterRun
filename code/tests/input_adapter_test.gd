extends SceneTree

const InputAdapter = preload("res://scripts/input_adapter.gd")
const SessionConfig = preload("res://scripts/session_config.gd")

var failures: PackedStringArray = []


func _init() -> void:
	_test_right_side_preserves_named_actions()
	_test_left_side_inverts_only_lateral_actions()
	_test_held_action_and_cooldown_allow_one_event()
	_test_different_actions_remain_independent()
	_test_unknown_action_is_rejected()

	if failures.is_empty():
		print("PETER RUN input adapter test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _test_right_side_preserves_named_actions() -> void:
	var adapter := InputAdapter.new(SessionConfig.AffectedSide.RIGHT, 0.5)
	_expect_equal(adapter.accept_action(&"move_left", 0.0), &"move_left", "Right side keeps move_left")
	adapter.release_action(&"move_left")
	_expect_equal(adapter.accept_action(&"move_right", 0.0), &"move_right", "Right side keeps move_right")
	adapter.release_action(&"move_right")
	_expect_equal(adapter.accept_action(&"jump", 0.0), &"jump", "Jump stays semantic")
	adapter.release_action(&"jump")
	_expect_equal(adapter.accept_action(&"slide", 0.0), &"slide", "Slide stays semantic")
	adapter.release_action(&"slide")
	_expect_equal(adapter.accept_action(&"pause_session", 0.0), &"pause_session", "Pause stays semantic")


func _test_left_side_inverts_only_lateral_actions() -> void:
	var adapter := InputAdapter.new(SessionConfig.AffectedSide.LEFT, 0.5)
	_expect_equal(adapter.accept_action(&"move_left", 0.0), &"move_right", "Left side reverses move_left")
	adapter.release_action(&"move_left")
	_expect_equal(adapter.accept_action(&"move_right", 0.0), &"move_left", "Left side reverses move_right")
	adapter.release_action(&"move_right")
	_expect_equal(adapter.accept_action(&"jump", 0.0), &"jump", "Left side does not alter jump")
	adapter.release_action(&"jump")
	_expect_equal(adapter.accept_action(&"slide", 0.0), &"slide", "Left side does not alter slide")


func _test_held_action_and_cooldown_allow_one_event() -> void:
	var adapter := InputAdapter.new(SessionConfig.AffectedSide.RIGHT, 0.5)
	_expect_equal(adapter.accept_action(&"jump", 1.0), &"jump", "First press is accepted")
	_expect_equal(adapter.accept_action(&"jump", 1.1), &"", "Held action is ignored")
	adapter.release_action(&"jump")
	_expect_equal(adapter.accept_action(&"jump", 1.4), &"", "Released action inside cooldown is ignored")
	adapter.release_action(&"jump")
	_expect_equal(adapter.accept_action(&"jump", 1.5), &"jump", "Action is accepted when cooldown expires")


func _test_different_actions_remain_independent() -> void:
	var adapter := InputAdapter.new(SessionConfig.AffectedSide.RIGHT, 0.5)
	_expect_equal(adapter.accept_action(&"move_left", 2.0), &"move_left", "First lateral action is accepted")
	_expect_equal(adapter.accept_action(&"jump", 2.0), &"jump", "Different action is not blocked by lateral cooldown")


func _test_unknown_action_is_rejected() -> void:
	var adapter := InputAdapter.new(SessionConfig.AffectedSide.RIGHT, 0.5)
	_expect_equal(adapter.accept_action(&"unknown", 0.0), &"", "Unknown action is rejected")


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])
