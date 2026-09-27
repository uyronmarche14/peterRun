extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const CONTROLLER_CHECK_SCENE_PATH := "res://scenes/controller_check.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	_test_keyboard_and_gamepad_bindings()
	_test_settings_exposes_control_help_and_check_route()
	_test_controller_check_describes_keyboard_and_hid_support()
	_finish()


func _test_keyboard_and_gamepad_bindings() -> void:
	_expect_action_has_joypad_button(&"move_left", JOY_BUTTON_DPAD_LEFT)
	_expect_action_has_joypad_button(&"move_right", JOY_BUTTON_DPAD_RIGHT)
	_expect_action_has_joypad_button(&"jump", JOY_BUTTON_A)
	_expect_action_has_joypad_button(&"slide", JOY_BUTTON_B)
	_expect_action_has_joypad_button(&"pause_session", JOY_BUTTON_START)


func _test_settings_exposes_control_help_and_check_route() -> void:
	var dashboard: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	_expect_node(dashboard, ^"SettingsOverlay/Panel/Margin/Content/EffectsLabel", "effects preference in Settings")
	_expect_node(dashboard, ^"SettingsOverlay/Panel/Margin/Content/EffectsOption", "effects intensity selector in Settings")
	_expect_node(dashboard, ^"SettingsOverlay/Panel/Margin/Content/ReducedMotionToggle", "reduced-motion preference in Settings")
	_expect_node(dashboard, ^"SettingsOverlay/Panel/Margin/Content/ControlsLabel", "controls heading in Settings")
	_expect_node(dashboard, ^"SettingsOverlay/Panel/Margin/Content/ControlsDetail", "keyboard and controller help in Settings")
	_expect_button(dashboard, ^"SettingsOverlay/Panel/Margin/Content/ControllerCheckButton", "Check controller")
	_expect(dashboard.has_method("get_controller_check_scene_path"), "dashboard exposes the Controller Check route")
	if dashboard.has_method("get_controller_check_scene_path"):
		_expect_equal(dashboard.call("get_controller_check_scene_path"), CONTROLLER_CHECK_SCENE_PATH, "Settings control check targets Controller Check")
	dashboard.queue_free()


func _test_controller_check_describes_keyboard_and_hid_support() -> void:
	var controller_check: Node = (load(CONTROLLER_CHECK_SCENE_PATH) as PackedScene).instantiate()
	_expect(controller_check.has_method("get_control_support_summary"), "Controller Check exposes supported-input guidance")
	if controller_check.has_method("get_control_support_summary"):
		var summary := String(controller_check.call("get_control_support_summary", 0))
		_expect(summary.contains("Keyboard"), "control guidance keeps keyboard fallback visible")
		_expect(summary.to_lower().contains("controller"), "control guidance explains controller support")
		_expect(summary.contains("HID"), "control guidance explains MOVE HID support")
	controller_check.queue_free()


func _expect_action_has_joypad_button(action_name: StringName, expected_button: JoyButton) -> void:
	var has_expected_button := false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton and event.button_index == expected_button:
			has_expected_button = true
			break
	_expect(has_expected_button, "%s has its expected gamepad binding" % action_name)


func _expect_node(root_node: Node, path: NodePath, description: String) -> void:
	_expect(root_node.get_node_or_null(path) != null, "Dashboard includes %s" % description)


func _expect_button(root_node: Node, path: NodePath, expected_text: String) -> void:
	var button := root_node.get_node_or_null(path) as Button
	_expect(button != null, "Dashboard includes %s button" % expected_text)
	if button != null:
		_expect_equal(button.text, expected_text, "%s button has the expected label" % expected_text)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN controls and settings test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN controls and settings test: FAIL (%d failures)" % failures.size())
	quit(1)
