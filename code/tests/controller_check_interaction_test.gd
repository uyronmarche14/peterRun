extends SceneTree

const CONTROLLER_CHECK_PATH := "res://scenes/controller_check.tscn"
const TILE_PATHS := {
	"MoveLeft": "MoveLeft",
	"MoveRight": "MoveRight",
	"Jump": "Jump",
	"Slide": "Slide",
	"Pause": "Pause",
}

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var controller_check: Control = load(CONTROLLER_CHECK_PATH).instantiate()
	root.add_child(controller_check)
	await process_frame
	_expect(controller_check.has_method("receive_test_action"), "Controller Check receives named actions for an interactive preflight")
	for tile_name in TILE_PATHS:
		var tile_path: String = "Panel/Margin/Content/ActionTiles/" + String(TILE_PATHS[tile_name])
		_expect(controller_check.has_node(tile_path), "Controller Check includes the %s action tile" % tile_name)
		_expect(controller_check.has_node(tile_path + "/Content/Status"), "%s status uses the responsive tile content layout" % tile_name)
	var pause_tile := controller_check.get_node_or_null("Panel/Margin/Content/ActionTiles/Pause") as PanelContainer
	_expect(pause_tile != null and pause_tile.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "Pause shares the equal-width tile row")
	if controller_check.has_method("receive_test_action"):
		controller_check.call("receive_test_action", &"move_left", true, 1.0)
		_expect(_tile_status(controller_check, "MoveLeft") == "✓ Detected", "Move Left tile confirms a named action")
		controller_check.call("receive_test_action", &"move_left", false, 1.1)
		controller_check.call("receive_test_action", &"pause_session", true, 2.0)
		_expect(_tile_status(controller_check, "Pause") == "✓ Detected", "Pause tile confirms a named action")
		_expect(controller_check.get_node("%ControllerStatus").text.contains("2 of 5"), "Controller Check reports the number of confirmed actions")
	controller_check.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN controller check interaction test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _tile_status(controller_check: Control, tile_name: String) -> String:
	var status := controller_check.get_node_or_null("Panel/Margin/Content/ActionTiles/%s/Content/Status" % TILE_PATHS[tile_name]) as Label
	return status.text if status != null else ""


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
