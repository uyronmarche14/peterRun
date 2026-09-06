extends SceneTree

const SCREEN_SPECS := [
	{
		"scene": "res://scenes/main.tscn",
		"panel": ^"Dashboard",
		"minimal_group": ^"Dashboard/Margin/Content/SecondaryActions",
	},
	{
		"scene": "res://scenes/controller_check.tscn",
		"panel": ^"Panel",
		"minimal_group": ^"Panel/Margin/Content/ControllerSummary",
	},
	{
		"scene": "res://scenes/tutorial.tscn",
		"panel": ^"Panel",
		"minimal_group": ^"Panel/Margin/Content/NavigationRow",
	},
	{
		"scene": "res://scenes/ready.tscn",
		"panel": ^"Panel",
		"minimal_group": ^"Panel/Margin/Content/SessionSummary",
	},
]

var failures: PackedStringArray = []


func _init() -> void:
	for spec: Dictionary in SCREEN_SPECS:
		_test_screen(spec)
	_finish()


func _test_screen(spec: Dictionary) -> void:
	var scene_path: String = spec["scene"]
	_expect(ResourceLoader.exists(scene_path), "%s exists" % scene_path)
	if not ResourceLoader.exists(scene_path):
		return
	var screen: Control = (load(scene_path) as PackedScene).instantiate()
	_expect_equal(screen.anchor_left, 0.0, "%s fills from the left edge" % scene_path)
	_expect_equal(screen.anchor_top, 0.0, "%s fills from the top edge" % scene_path)
	_expect_equal(screen.anchor_right, 1.0, "%s responds to viewport width" % scene_path)
	_expect_equal(screen.anchor_bottom, 1.0, "%s responds to viewport height" % scene_path)
	var panel := screen.get_node_or_null(spec["panel"]) as Control
	_expect(panel != null, "%s has a centred panel" % scene_path)
	if panel != null:
		_expect(panel.anchor_left > 0.0 and panel.anchor_right < 1.0, "%s keeps a readable outer margin" % scene_path)
		_expect(panel.anchor_bottom > panel.anchor_top, "%s panel has responsive height" % scene_path)
	_expect(screen.get_node_or_null(spec["minimal_group"]) is Container, "%s groups secondary information or choices" % scene_path)
	screen.free()


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s (expected %s, got %s)" % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN minimal UI layout test: PASS")
		quit(0)
		return
	for failure: String in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN minimal UI layout test: FAIL (%d failures)" % failures.size())
	quit(1)
