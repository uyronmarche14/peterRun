extends SceneTree

const SessionConfig = preload("res://scripts/session_config.gd")
const SessionResult = preload("res://scripts/session_result.gd")

var failures: PackedStringArray = []


func _init() -> void:
	_test_config_defaults_and_customisation()
	_test_config_rejects_invalid_targets()
	_test_result_tracks_successes_and_neutral_misses()
	_test_result_completes_only_when_every_target_is_met()
	_test_result_validates_rpe()

	if failures.is_empty():
		print("PETER RUN session models test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr(failure)
	quit(1)


func _test_config_defaults_and_customisation() -> void:
	var config := SessionConfig.new()
	_expect_equal(config.affected_side, SessionConfig.AffectedSide.RIGHT, "Default affected side is right")
	_expect_equal(config.selected_level_id, &"l01_barangay", "Default level is L01")

	for action_name in SessionConfig.ACTIONS:
		_expect_equal(config.get_target(action_name), 10, "Default target is 10 for %s" % action_name)

	config.affected_side = SessionConfig.AffectedSide.LEFT
	config.selected_level_id = &"l02_palengke"
	_expect(config.set_target(&"jump", 15), "A valid target can be changed")
	_expect_equal(config.affected_side, SessionConfig.AffectedSide.LEFT, "Affected side can be configured")
	_expect_equal(config.selected_level_id, &"l02_palengke", "Selected level can be configured")
	_expect_equal(config.get_target(&"jump"), 15, "Changed target is retained")


func _test_config_rejects_invalid_targets() -> void:
	var config := SessionConfig.new()
	_expect(not config.set_target(&"jump", 0), "Zero target is rejected")
	_expect(not config.set_target(&"unknown", 10), "Unknown action target is rejected")
	_expect_equal(config.get_target(&"jump"), 10, "Rejected target leaves prior value unchanged")


func _test_result_tracks_successes_and_neutral_misses() -> void:
	var result := SessionResult.new()
	_expect(result.record_success(&"jump"), "Known action success is recorded")
	_expect_equal(result.get_completed(&"jump"), 1, "Matching action increments exactly once")
	_expect_equal(result.get_completed(&"slide"), 0, "Unrelated action is unchanged")
	_expect(not result.record_success(&"unknown"), "Unknown action success is rejected")

	result.record_neutral_miss()
	_expect_equal(result.neutral_misses, 1, "Neutral miss is recorded")
	_expect_equal(result.get_completed(&"jump"), 1, "Neutral miss does not remove completed repetitions")


func _test_result_completes_only_when_every_target_is_met() -> void:
	var config := SessionConfig.new()
	for action_name in SessionConfig.ACTIONS:
		_expect(config.set_target(action_name, 1), "One-rep fixture target is accepted for %s" % action_name)

	var result := SessionResult.new()
	for action_name in SessionConfig.ACTIONS:
		if action_name != &"slide":
			result.record_success(action_name)
	_expect(not result.has_met_targets(config), "Result is incomplete while one target remains")

	result.record_success(&"slide")
	_expect(result.has_met_targets(config), "Result completes when every action target is met")


func _test_result_validates_rpe() -> void:
	var result := SessionResult.new()
	_expect(not result.set_rpe(0), "RPE below range is rejected")
	_expect(not result.set_rpe(11), "RPE above range is rejected")
	_expect(not result.set_rpe(5.5), "Non-integer RPE is rejected")
	_expect(result.set_rpe(1), "Minimum RPE is accepted")
	_expect_equal(result.rpe, 1, "Minimum RPE is retained")
	_expect(result.set_rpe(10), "Maximum RPE is accepted")
	_expect_equal(result.rpe, 10, "Maximum RPE is retained")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])
