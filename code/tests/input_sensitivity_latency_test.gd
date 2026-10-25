extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const InputAdapterModel = preload("res://scripts/input_adapter.gd")
const LatencyTest = preload("res://scripts/latency_test.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.settings_path = "user://test_settings.cfg"
	DirAccess.remove_absolute(Settings.settings_path)
	_test_sensitivity_model()
	_test_adapter_reasons()
	_test_latency_stats()
	await _test_controller_check_panel()
	_test_runner_uses_sensitivity()
	DirAccess.remove_absolute(Settings.settings_path)
	Settings.set_input_sensitivity(Settings.SENSITIVITY_NORMAL)
	if failures.is_empty():
		print("PETER RUN input sensitivity and latency test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("FAIL: " + failure)
	quit(1)


func _test_sensitivity_model() -> void:
	_expect(Settings.input_sensitivity == Settings.SENSITIVITY_NORMAL, "Sensitivity starts at Normal")
	_expect(is_equal_approx(Settings.input_cooldown_seconds(), 0.35) and is_equal_approx(Settings.stick_threshold(), 0.5), "Normal keeps today's 0.35 s lockout and 0.5 stick threshold")
	Settings.set_input_sensitivity(Settings.SENSITIVITY_LOW)
	_expect(is_equal_approx(Settings.input_cooldown_seconds(), 0.5) and is_equal_approx(Settings.stick_threshold(), 0.65), "Low is slower to repeat and needs a firmer push")
	Settings.set_input_sensitivity(Settings.SENSITIVITY_HIGH)
	_expect(is_equal_approx(Settings.input_cooldown_seconds(), 0.15) and is_equal_approx(Settings.stick_threshold(), 0.35), "High repeats sooner and reacts to a lighter push")
	_expect(is_equal_approx(InputMap.action_get_deadzone(&"move_left"), 0.35), "The stick threshold is applied to the move actions")
	Settings.set_input_sensitivity(7)
	_expect(Settings.input_sensitivity == Settings.SENSITIVITY_HIGH, "An unknown sensitivity is ignored")
	# Saved to a settings file and read back.
	Settings.input_sensitivity = Settings.SENSITIVITY_NORMAL
	Settings.load_saved_settings()
	_expect(Settings.input_sensitivity == Settings.SENSITIVITY_HIGH, "The chosen sensitivity is remembered after a restart")


func _test_adapter_reasons() -> void:
	var adapter = InputAdapterModel.new(0, 0.35)
	_expect(adapter.accept_action(&"jump", 1.0) == &"jump" and adapter.last_rejection == &"", "An accepted press has no rejection")
	_expect(adapter.accept_action(&"jump", 1.1) == &"" and adapter.last_rejection == &"held", "A repeat while still held is reported as held")
	adapter.release_action(&"jump")
	_expect(adapter.accept_action(&"jump", 1.2) == &"" and adapter.last_rejection == &"cooldown", "A press right after the last is reported as too soon")
	adapter.release_action(&"jump")
	_expect(adapter.accept_action(&"jump", 1.5) == &"jump", "A press after the lockout is accepted")
	_expect(adapter.accept_action(&"unknown", 2.0) == &"" and adapter.last_rejection == &"unknown", "An unknown input is reported")


func _test_latency_stats() -> void:
	var latency = LatencyTest.new()
	_expect(latency.average_ms() < 0.0 and latency.best_ms() < 0.0, "No results before any press")
	latency.cue_shown(10.0)
	_expect(is_equal_approx(latency.record_press(10.2), 200.0), "A press 0.2 s after the cue is 200 ms")
	_expect(latency.record_press(10.3) < 0.0, "A second press for the same cue is not counted")
	for ms in [300.0, 100.0, 400.0, 500.0, 600.0]:
		latency.cue_shown(20.0)
		latency.record_press(20.0 + ms / 1000.0)
	_expect(is_equal_approx(latency.average_ms(), 380.0), "Average uses the last five results (got %.0f)" % latency.average_ms())
	_expect(is_equal_approx(latency.best_ms(), 100.0), "Best is the lowest result")
	_expect(latency.record_press(30.0) < 0.0, "A press with no cue is not a result")
	latency.reset()
	_expect(latency.count() == 0, "Reset clears the results")


func _test_controller_check_panel() -> void:
	Settings.set_input_sensitivity(Settings.SENSITIVITY_NORMAL)
	var check: Node = (load("res://scenes/controller_check.tscn") as PackedScene).instantiate()
	root.add_child(check)
	await process_frame
	var option := check.get_node_or_null(^"%SensitivityOption") as OptionButton
	var button := check.get_node_or_null(^"%DelayTestButton") as Button
	var readout := check.get_node_or_null(^"%DelayReadout") as Label
	_expect(option != null and button != null and readout != null, "Controller check has a sensitivity choice, a delay test and a readout")
	if option == null or button == null or readout == null:
		check.free()
		return
	_expect(option.item_count == 3 and option.selected == Settings.SENSITIVITY_NORMAL, "Sensitivity offers Low, Normal and High")
	option.select(Settings.SENSITIVITY_HIGH)
	option.item_selected.emit(Settings.SENSITIVITY_HIGH)
	_expect(Settings.input_sensitivity == Settings.SENSITIVITY_HIGH, "Choosing High changes the setting")
	_expect(is_equal_approx(check.input_adapter.cooldown_seconds, 0.15), "The check screen uses the chosen lockout straight away")
	Settings.set_input_sensitivity(Settings.SENSITIVITY_NORMAL)

	check.start_delay_test()
	_expect(button.disabled and readout.text.contains("Wait"), "The delay test asks the player to wait for the cue")
	check.receive_test_action(&"jump", true, 50.0)
	check.receive_test_action(&"jump", false, 50.05)
	_expect(readout.text.contains("early"), "Pressing before the cue is answered kindly, not counted")
	check.show_delay_cue(100.0)
	_expect(readout.text.contains("NOW"), "The cue says to press now")
	check.receive_test_action(&"move_left", true, 100.2)
	_expect(readout.text.contains("200 ms"), "The readout shows the delay (got '%s')" % readout.text)
	_expect(not button.disabled, "The test can be run again")
	check.free()


func _test_runner_uses_sensitivity() -> void:
	Settings.set_input_sensitivity(Settings.SENSITIVITY_LOW)
	Settings.start_countdown_pending = false
	var level: Node = (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	_expect(is_equal_approx(level.input_adapter.cooldown_seconds, 0.5), "A run uses the chosen sensitivity")
	level.free()
	Settings.set_input_sensitivity(Settings.SENSITIVITY_NORMAL)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
