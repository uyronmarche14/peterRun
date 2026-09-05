extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var _failures: Array[String] = []


func _init() -> void:
	if not ResourceLoader.exists(RUNNER_LEVEL_PATH):
		_failures.append("RunnerLevel scene is missing: %s" % RUNNER_LEVEL_PATH)
		_finish()
		return

	var packed_scene: PackedScene = load(RUNNER_LEVEL_PATH)
	var level := packed_scene.instantiate()

	_expect(level is Node2D, "RunnerLevel uses a 2D root")
	_expect_node(level, ^"LevelWorld", "LevelWorld")
	_expect_node(level, ^"LevelWorld/RoadAndLanes", "RoadAndLanes")
	_expect_node(level, ^"LevelWorld/RoadAndLanes/LaneLeft", "left lane marker")
	_expect_node(level, ^"LevelWorld/RoadAndLanes/LaneCenter", "centre lane marker")
	_expect_node(level, ^"LevelWorld/RoadAndLanes/LaneRight", "right lane marker")
	_expect_node(level, ^"LevelWorld/PromptWorldAnchor", "PromptWorldAnchor")
	_expect_node(level, ^"Player", "player placeholder")
	_expect_node(level, ^"HUD", "HUD canvas")
	_expect_node(level, ^"HUD/HUDRoot", "HUD root")

	var player := level.get_node_or_null(^"Player") as Node2D
	if player != null:
		_expect(player.position.y >= 180.0, "player placeholder starts in the lower play area")

	var hud := level.get_node_or_null(^"HUD")
	_expect(hud is CanvasLayer, "HUD stays in a CanvasLayer")

	var pause_button := level.get_node_or_null(^"HUD/HUDRoot/PauseButton") as Button
	_expect(pause_button != null, "a Pause button is always present")
	if pause_button != null:
		_expect(pause_button.visible, "Pause button is visible")
		_expect(pause_button.text == "Pause", "Pause button has a clear label")

	level.queue_free()
	_finish()


func _expect_node(root: Node, path: NodePath, description: String) -> void:
	_expect(root.get_node_or_null(path) != null, "RunnerLevel includes %s" % description)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)


func _finish() -> void:
	if _failures.is_empty():
		print("PETER RUN runner level smoke test: PASS")
		quit(0)
		return

	for failure in _failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN runner level smoke test: FAIL (%d failures)" % _failures.size())
	quit(1)
