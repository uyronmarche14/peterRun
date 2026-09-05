extends SceneTree

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	_expect_equal(ProjectSettings.get_setting("application/run/main_scene", ""), MAIN_SCENE_PATH, "F5 opens the main dashboard")

	if not ResourceLoader.exists(MAIN_SCENE_PATH):
		failures.append("Main dashboard scene is missing")
		_finish()
		return

	var packed_scene: PackedScene = load(MAIN_SCENE_PATH)
	var dashboard := packed_scene.instantiate()

	_expect(dashboard is Control, "Main dashboard uses a responsive Control root")
	_expect_node(dashboard, ^"Dashboard", "dashboard panel")
	_expect_label(dashboard, ^"Dashboard/Margin/Content/Title", "PETER RUN", "clear game title")
	_expect_node(dashboard, ^"Dashboard/Margin/Content/SessionStatus", "session status")
	_expect_button(dashboard, ^"Dashboard/Margin/Content/PlayL01PreviewButton", "Play L01 Preview")
	_expect_button(dashboard, ^"Dashboard/Margin/Content/TutorialButton", "Tutorial")
	_expect_button(dashboard, ^"Dashboard/Margin/Content/SettingsButton", "Settings")
	_expect_button(dashboard, ^"Dashboard/Margin/Content/QuitButton", "Quit")
	_expect(dashboard.has_method("open_l01_preview"), "dashboard has an L01 preview route")
	_expect(dashboard.has_method("get_l01_preview_scene_path"), "dashboard exposes the preview route for verification")
	if dashboard.has_method("get_l01_preview_scene_path"):
		_expect_equal(dashboard.call("get_l01_preview_scene_path"), RUNNER_LEVEL_PATH, "Preview route targets RunnerLevel")

	dashboard.queue_free()
	_finish()


func _expect_node(root_node: Node, path: NodePath, description: String) -> void:
	_expect(root_node.get_node_or_null(path) != null, "Dashboard includes %s" % description)


func _expect_label(root_node: Node, path: NodePath, expected_text: String, description: String) -> void:
	var label := root_node.get_node_or_null(path) as Label
	_expect(label != null, "Dashboard includes %s" % description)
	if label != null:
		_expect_equal(label.text, expected_text, "%s has the expected text" % description)


func _expect_button(root_node: Node, path: NodePath, expected_text: String) -> void:
	var button := root_node.get_node_or_null(path) as Button
	_expect(button != null, "Dashboard includes %s button" % expected_text)
	if button != null:
		_expect(button.visible, "%s button is visible" % expected_text)
		_expect_equal(button.text, expected_text, "%s button has the expected label" % expected_text)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN main dashboard smoke test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN main dashboard smoke test: FAIL (%d failures)" % failures.size())
	quit(1)
