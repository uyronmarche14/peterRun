extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"
const CONTROLLER_CHECK_SCENE_PATH := "res://scenes/controller_check.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"
const READY_SCENE_PATH := "res://scenes/ready.tscn"
const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"
const SESSION_SETUP_STORE_PATH := "res://scripts/session_setup_store.gd"
const SessionConfigModel = preload("res://scripts/session_config.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(ResourceLoader.exists(PATIENT_SETUP_SCENE_PATH), "Patient Setup scene exists")
	_expect(ResourceLoader.exists(CONTROLLER_CHECK_SCENE_PATH), "Controller Check scene exists")
	_expect(ResourceLoader.exists(TUTORIAL_SCENE_PATH), "Tutorial scene exists")
	_expect(ResourceLoader.exists(READY_SCENE_PATH), "Ready scene exists")
	_expect(ResourceLoader.exists(SESSION_SETUP_STORE_PATH), "Session setup store exists")
	if not failures.is_empty():
		_finish()
		return

	var store_script: GDScript = load(SESSION_SETUP_STORE_PATH)
	store_script.call("reset")
	_test_main_menu_route()
	await _test_setup_persists_supervised_session_config(store_script)
	await _test_controller_check_tutorial_ready_routes(store_script)
	_finish()


func _test_main_menu_route() -> void:
	var dashboard: Control = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
	_expect_button(dashboard, ^"Dashboard/Margin/Content/StartSessionButton", "▶  Start Session")
	_expect(dashboard.has_method("open_patient_setup"), "Main Menu opens Patient Setup")
	_expect(dashboard.has_method("get_patient_setup_scene_path"), "Main Menu exposes the Patient Setup route")
	if dashboard.has_method("get_patient_setup_scene_path"):
		_expect_equal(dashboard.call("get_patient_setup_scene_path"), PATIENT_SETUP_SCENE_PATH, "Start Session routes to Patient Setup")
	_expect(dashboard.has_method("get_tutorial_scene_path"), "Main Menu exposes the Tutorial route")
	if dashboard.has_method("get_tutorial_scene_path"):
		_expect_equal(dashboard.call("get_tutorial_scene_path"), TUTORIAL_SCENE_PATH, "Tutorial button routes to Tutorial")
	dashboard.free()


func _test_setup_persists_supervised_session_config(store_script: GDScript) -> void:
	var setup: Control = (load(PATIENT_SETUP_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(setup)
	await process_frame
	_expect_node(setup, ^"Panel/Margin/Content/AffectedSideOption", "affected-side selector")
	_expect_node(setup, ^"Panel/Margin/Content/TargetRepetitionsSpinBox", "target repetition selector")
	var repetition_stepper := setup.get_node("Panel/Margin/Content/TargetRepetitionsSpinBox") as SpinBox
	_expect(repetition_stepper.min_value == 1, "Target repetitions can be lowered to one per action")
	_expect(repetition_stepper.max_value == 15, "Target repetitions retain the approved maximum")
	if setup.has_method("set_target_repetitions"):
		setup.call("set_target_repetitions", 1)
		_expect_label(setup, ^"Panel/Margin/Content/SessionSummary", "1 per action · 4 total · right side", "Setup shows a four-movement minimum session")
	_expect_button(setup, ^"Panel/Margin/Content/ContinueButton", "Review session")
	_expect_button(setup, ^"Panel/Margin/Content/ControlsRow/TestControlsButton", "Test controls")
	_expect_button(setup, ^"Panel/Margin/Content/ControlsRow/PracticeButton", "Practise movements")
	_expect_button(setup, ^"Panel/Margin/Content/BackButton", "Back")
	_expect(setup.has_method("get_ready_scene_path"), "Patient Setup exposes the direct Ready route")
	if setup.has_method("get_ready_scene_path"):
		_expect_equal(setup.call("get_ready_scene_path"), READY_SCENE_PATH, "Review session bypasses optional control and practice screens")
	_expect(setup.has_method("save_session_settings"), "Patient Setup saves session settings")
	if setup.has_method("save_session_settings"):
		setup.call("set_affected_side", SessionConfigModel.AffectedSide.LEFT)
		setup.call("set_target_repetitions", 12)
		setup.call("save_session_settings")
		var config: Variant = store_script.call("get_session_config")
		_expect_equal(config.affected_side, SessionConfigModel.AffectedSide.LEFT, "Selected affected side persists")
		_expect_equal(config.selected_level_id, &"l01_barangay", "L01 is selected for this build")
		for action_name in SessionConfigModel.ACTIONS:
			_expect_equal(config.get_target(action_name), 12, "Selected target persists for %s" % action_name)
	setup.queue_free()
	await process_frame


func _test_controller_check_tutorial_ready_routes(store_script: GDScript) -> void:
	var controller_check: Control = (load(CONTROLLER_CHECK_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(controller_check)
	await process_frame
	_expect(controller_check.get_node("Panel/Margin/Content/ControllerSummary/ControllerStatus").text.contains("Keyboard fallback ready"), "honest keyboard fallback status")
	_expect_button(controller_check, ^"Panel/Margin/Content/KeyboardFallbackButton", "Continue to ready")
	_expect_button(controller_check, ^"Panel/Margin/Content/BackButton", "Back")
	_expect(controller_check.has_method("get_ready_scene_path"), "Controller Check exposes the Ready route")
	if controller_check.has_method("get_ready_scene_path"):
		_expect_equal(controller_check.call("get_ready_scene_path"), READY_SCENE_PATH, "Controller Check returns to Ready instead of forcing practice")
	controller_check.queue_free()
	await process_frame

	var tutorial: Control = (load(TUTORIAL_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(tutorial)
	await process_frame
	_expect_node(tutorial, ^"Panel/Margin/Content/Welcome", "Tutorial welcome")
	_expect_button(tutorial, ^"Panel/Margin/Content/Welcome/Actions/StartPracticeButton", "Start practice")
	tutorial.call("start_practice")
	_expect_label(tutorial, ^"Panel/Margin/Content/ActionCard/ActionLabel", "MOVE LEFT", "Tutorial begins with one action")
	_expect_node(tutorial, ^"Panel/Margin/Content/ActionCard/ActionIconLabel", "Tutorial action icon")
	_expect_button(tutorial, ^"Panel/Margin/Content/NavigationRow/PreviousButton", "Back")
	_expect_button(tutorial, ^"Panel/Margin/Content/NavigationRow/NextButton", "Next")
	_expect_button(tutorial, ^"Panel/Margin/Content/UtilityRow/SkipButton", "Skip Tutorial")
	_expect_button(tutorial, ^"Panel/Margin/Content/UtilityRow/PauseTutorialButton", "Pause Tutorial")
	_expect(tutorial.has_method("show_action_index"), "Tutorial can show one planned action at a time")
	if tutorial.has_method("show_action_index"):
		tutorial.call("show_action_index", 2)
		_expect_label(tutorial, ^"Panel/Margin/Content/ActionCard/ActionLabel", "JUMP", "Tutorial can preview Jump without a countdown")
		tutorial.call("toggle_tutorial_pause")
		_expect_equal(tutorial.get("is_tutorial_paused"), true, "Tutorial pauses visibly without automatic progression")
		_expect_button(tutorial, ^"Panel/Margin/Content/UtilityRow/PauseTutorialButton", "Resume Tutorial")
		tutorial.call("toggle_tutorial_pause")
	_expect(tutorial.has_method("get_ready_scene_path"), "Tutorial exposes the Ready route")
	if tutorial.has_method("get_ready_scene_path"):
		_expect_equal(tutorial.call("get_ready_scene_path"), READY_SCENE_PATH, "Tutorial continues to Ready")
	tutorial.queue_free()
	await process_frame

	var ready: Control = (load(READY_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(ready)
	await process_frame
	_expect_label(ready, ^"Panel/Margin/Content/SessionSummary/SessionDetails", "L01 Barangay Morning • 12 reps/action • Left affected side", "Ready screen shows selected session settings")
	_expect_button(ready, ^"Panel/Margin/Content/StartSessionButton", "Start L01 Session")
	_expect_button(ready, ^"Panel/Margin/Content/ControlsRow/TestControlsButton", "Test controls")
	_expect_button(ready, ^"Panel/Margin/Content/ControlsRow/PracticeButton", "Practise movements")
	_expect_button(ready, ^"Panel/Margin/Content/BackButton", "Edit session")
	_expect(ready.has_method("get_runner_scene_path"), "Ready screen exposes the L01 route")
	if ready.has_method("get_runner_scene_path"):
		_expect_equal(ready.call("get_runner_scene_path"), RUNNER_LEVEL_PATH, "Ready screen starts L01")
	ready.queue_free()
	await process_frame

	var runner: Node = (load(RUNNER_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(runner)
	await process_frame
	var saved_config: Variant = store_script.call("get_session_config")
	_expect_equal(runner.get("session_config").affected_side, saved_config.affected_side, "L01 receives the selected affected side")
	_expect_equal(runner.get("session_config").get_target(&"jump"), 12, "L01 receives the selected target")
	_expect_equal(runner.get("input_adapter").affected_side, SessionConfigModel.AffectedSide.LEFT, "Input adapter receives left-side mapping")
	runner.queue_free()
	await process_frame


func _expect_node(root_node: Node, path: NodePath, description: String) -> void:
	_expect(root_node.get_node_or_null(path) != null, "Screen includes %s" % description)


func _expect_button(root_node: Node, path: NodePath, expected_text: String) -> void:
	var button := root_node.get_node_or_null(path) as Button
	_expect(button != null, "Screen includes %s button" % expected_text)
	if button != null:
		_expect(button.visible, "%s button is visible" % expected_text)
		_expect_equal(button.text, expected_text, "%s button has the expected label" % expected_text)


func _expect_label(root_node: Node, path: NodePath, expected_text: String, description: String) -> void:
	var label := root_node.get_node_or_null(path) as Label
	_expect(label != null, "Screen includes %s" % description)
	if label != null:
		_expect_equal(label.text, expected_text, "%s has the expected text" % description)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN session setup flow test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN session setup flow test: FAIL (%d failures)" % failures.size())
	quit(1)
