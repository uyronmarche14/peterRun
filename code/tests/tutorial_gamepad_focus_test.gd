extends SceneTree

## Regression: after a therapist clicks a tutorial button, that button keeps GUI
## focus. Gamepad D-pad presses must still reach practice, not move focus.

const Store = preload("res://scripts/session_setup_store.gd")
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Store.reset()
	var tutorial: Control = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	await process_frame
	if tutorial.has_method("start_practice"):
		tutorial.call("start_practice")
		await process_frame

	var repeat: Button = tutorial.get_node("Panel/Margin/Content/NavigationRow/RepeatButton")
	repeat.grab_focus()
	await process_frame
	await _press_pad(JOY_BUTTON_DPAD_LEFT)
	_expect(tutorial.step_completed, "D-pad Left completes the left lesson while a button has focus")
	_expect(tutorial.practice_player.lane_index == 0, "D-pad Left moves the practice player while a button has focus")
	_expect(root.gui_get_focus_owner() == repeat, "D-pad Left does not move menu focus")

	tutorial.call("show_next_action")
	await process_frame
	repeat.grab_focus()
	await process_frame
	await _press_pad(JOY_BUTTON_DPAD_RIGHT)
	_expect(tutorial.step_completed and tutorial.practice_player.lane_index == 2, "D-pad Right completes the right lesson while a button has focus")
	_expect(root.gui_get_focus_owner() == repeat, "D-pad Right does not move menu focus")

	tutorial.free()
	Store.reset()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN tutorial gamepad focus test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _press_pad(button: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		root.push_input(event)
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
