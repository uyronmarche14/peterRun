extends SceneTree

## Controller safety: a disconnect pauses play with a therapist-facing message,
## gameplay inputs never drive menu focus, the left stick changes lanes, and
## hints follow the connected gamepad's face-button layout.

const Store = preload("res://scripts/session_setup_store.gd")
const Hints = preload("res://scripts/control_hints.gd")
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Store.reset()
	await _test_runner_disconnect_pause()
	await _test_runner_focus_and_stick()
	await _test_tutorial_disconnect_pause()
	await _test_controller_check_hotplug()
	_test_face_button_styles()
	Store.reset()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN controller safety test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_runner_disconnect_pause() -> void:
	var runner: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(runner)
	await process_frame
	var title: Label = runner.get_node("PauseOverlay/Panel/Title")
	var message: Label = runner.get_node("PauseOverlay/Panel/Message")
	var normal_title := title.text
	var normal_message := message.text
	runner.call("_on_joy_connection_changed", 0, false)
	_expect(runner.is_gameplay_paused and runner.pause_overlay.visible, "Controller disconnect pauses gameplay")
	_expect(title.text.to_lower().contains("disconnected"), "Pause title tells the therapist the controller disconnected")
	_expect(title.get_minimum_size().x <= title.size.x + 0.5, "Disconnect title fits its label")
	_expect(message.text.contains("Resume"), "Pause message explains how to continue")
	runner.call("_on_joy_connection_changed", 0, true)
	_expect(runner.is_gameplay_paused, "Reconnecting never resumes automatically")
	runner.call("resume_gameplay")
	_expect(title.text == normal_title and message.text == normal_message, "Resume restores the normal pause wording")
	runner.call("pause_gameplay")
	_expect(title.text == normal_title, "A normal pause keeps the normal wording")
	runner.call("resume_gameplay")
	runner.call("end_session_neutrally")
	runner.call("_on_joy_connection_changed", 0, false)
	_expect(not runner.pause_overlay.visible, "A disconnect after the session ends does not reopen Pause")
	runner.free()


func _test_runner_focus_and_stick() -> void:
	var runner: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(runner)
	await process_frame
	var player: Node = runner.get_node("Player")
	var pause_button: Button = runner.get_node("HUD/HUDRoot/PauseButton")
	pause_button.grab_focus()
	await process_frame
	await _press_pad(JOY_BUTTON_DPAD_LEFT)
	_expect(player.lane_index == 0, "D-pad Left moves Peter while the Pause button has focus")
	_expect(root.gui_get_focus_owner() == pause_button, "D-pad Left does not move HUD focus")
	await create_timer(0.4).timeout
	await _move_stick(1.0)
	_expect(player.lane_index == 1, "Left stick right moves Peter one lane")
	await create_timer(0.4).timeout
	await _move_stick(1.0)
	_expect(player.lane_index == 2, "A fresh stick push moves one more lane")
	runner.call("pause_gameplay")
	var resume: Button = runner.get_node("PauseOverlay/Panel/Actions/ResumeButton")
	resume.grab_focus()
	await process_frame
	await _press_pad(JOY_BUTTON_DPAD_LEFT)
	await _press_pad(JOY_BUTTON_DPAD_RIGHT)
	_expect(root.gui_get_focus_owner() == resume, "Gameplay lane buttons do not move Pause-menu focus")
	runner.free()


func _test_tutorial_disconnect_pause() -> void:
	var tutorial: Node = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	await process_frame
	if tutorial.has_method("start_practice"):
		tutorial.call("start_practice")
	tutorial.call("_on_joy_connection_changed", 0, false)
	_expect(tutorial.is_tutorial_paused, "Controller disconnect pauses tutorial practice")
	tutorial.call("_on_joy_connection_changed", 0, true)
	_expect(tutorial.is_tutorial_paused, "Reconnecting does not resume practice automatically")
	tutorial.free()


func _test_controller_check_hotplug() -> void:
	var check: Node = load("res://scenes/controller_check.tscn").instantiate()
	root.add_child(check)
	await process_frame
	_expect(check.has_method("_on_joy_connection_changed") and Input.joy_connection_changed.is_connected(Callable(check, "_on_joy_connection_changed")), "Controller Check refreshes when a controller is plugged in")
	check.free()


func _test_face_button_styles() -> void:
	_expect(Hints.gamepad_style("Nintendo Switch Pro Controller") == &"nintendo", "Recognises a Nintendo layout")
	_expect(Hints.gamepad_style("PS5 Controller") == &"playstation", "Recognises a PlayStation layout")
	_expect(Hints.gamepad_style("Xbox Series Controller") == &"xbox", "Defaults to the Xbox layout")
	_expect(Hints.input_name(&"jump", true, "Nintendo Switch Pro Controller").contains("B"), "Nintendo Jump names the B button")
	_expect(Hints.input_name(&"slide", true, "Nintendo Switch Pro Controller").contains("A"), "Nintendo Slide names the A button")
	_expect(Hints.input_name(&"jump", true, "PS5 Controller").contains("Cross"), "PlayStation Jump names Cross")
	_expect(Hints.input_name(&"jump", true, "Xbox Series Controller").contains("A"), "Xbox Jump names A")
	_expect(Hints.footer_text(true, "PS5 Controller").contains("Options"), "PlayStation footer names Options for pause")


func _press_pad(button: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		root.push_input(event)
		await process_frame


func _move_stick(value: float) -> void:
	for axis_value in [value, 0.0]:
		var event := InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_LEFT_X
		event.axis_value = axis_value
		root.push_input(event)
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
