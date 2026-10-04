extends SceneTree

## A therapist can run a whole session from a gamepad: A/Cross confirms the
## highlighted button, B/Circle goes back, the D-pad moves the highlight, and
## Y/Triangle continues on screens where A/B are practised. The patient's MOVE
## controller (keyboard A/D/W/S/P) never confirms or leaves a menu screen.

const Setup = preload("res://scripts/session_setup_store.gd")
const Config = preload("res://scripts/session_config.gd")
const Review = preload("res://scripts/session_review_store.gd")
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Setup.reset()
	await _test_main_menu()
	await _test_patient_setup()
	await _test_ready()
	await _test_controller_check()
	await _test_tutorial()
	await _test_runner_overlays()
	await _test_summary()
	await _test_move_controller_cannot_navigate()
	_test_menu_hints()
	Setup.reset()
	await create_timer(0.15).timeout
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN gamepad menu navigation test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_main_menu() -> void:
	var menu := await _open("res://scenes/main.tscn")
	_expect_focus(menu, "Dashboard/Margin/Content/StartSessionButton", "Main menu highlights Start Session")
	await _pad(JOY_BUTTON_DPAD_DOWN)
	_expect(root.gui_get_focus_owner() != menu.get_node("Dashboard/Margin/Content/StartSessionButton"), "D-pad Down moves the highlight")
	menu.get_node("Dashboard/Margin/Content/StartSessionButton").grab_focus()
	await _pad(JOY_BUTTON_B)
	_expect(menu.get_node("QuitOverlay").visible, "B on the main menu asks before quitting")
	_expect_focus(menu, "QuitOverlay/Panel/Margin/Content/CancelButton", "Quit confirmation highlights Stay here")
	await _pad(JOY_BUTTON_B)
	_expect(not menu.get_node("QuitOverlay").visible, "B closes the quit confirmation")
	_expect_focus(menu, "Dashboard/Margin/Content/StartSessionButton", "Closing an overlay returns the highlight")
	await _pad(JOY_BUTTON_A)
	await _settle()
	_expect_scene("res://scenes/patient_setup.tscn", "A on Start Session opens Patient Setup")
	_free_current()


func _test_patient_setup() -> void:
	var setup := await _open("res://scenes/patient_setup.tscn")
	_expect_focus(setup, "%ContinueButton", "Setup highlights Review session")
	await _pad(JOY_BUTTON_B)
	await _settle()
	_expect_scene("res://scenes/main.tscn", "B on Setup returns to the main menu")
	_free_current()
	await _open("res://scenes/patient_setup.tscn")
	await _pad(JOY_BUTTON_A)
	await _settle()
	_expect_scene("res://scenes/ready.tscn", "A on Review session opens Ready")
	_free_current()


func _test_ready() -> void:
	var ready := await _open("res://scenes/ready.tscn")
	_expect_focus(ready, "%StartSessionButton", "Ready highlights Start")
	await _pad(JOY_BUTTON_B)
	await _settle()
	_expect_scene("res://scenes/patient_setup.tscn", "B on Ready returns to Setup")
	_free_current()


func _test_controller_check() -> void:
	var check := await _open("res://scenes/controller_check.tscn")
	await _pad(JOY_BUTTON_A)
	await _settle()
	_expect_scene("res://scenes/controller_check.tscn", "A is tested as Jump, not used to leave Controller Check")
	_expect(check.detected_actions.has(&"jump"), "A marks Jump as detected")
	await _pad(JOY_BUTTON_B)
	await _settle()
	_expect_scene("res://scenes/controller_check.tscn", "B is tested as Slide, not used to leave Controller Check")
	await _pad(JOY_BUTTON_Y)
	await _settle()
	_expect_scene("res://scenes/ready.tscn", "Y continues from Controller Check to Ready")
	_free_current()


func _test_tutorial() -> void:
	var tutorial := await _open("res://scenes/tutorial.tscn")
	_expect_focus(tutorial, "Panel/Margin/Content/Welcome/Actions/StartPracticeButton", "Tutorial welcome highlights Start practice")
	await _pad(JOY_BUTTON_A)
	_expect(tutorial.tutorial_started, "A on Start practice begins practice")
	await _pad(JOY_BUTTON_A)
	_expect(tutorial.current_action_index == 0 and not tutorial.step_completed, "During practice A is Jump practice, not Next")
	await _pad(JOY_BUTTON_Y)
	_expect(tutorial.current_action_index == 0, "Y cannot skip an unpractised lesson")
	await _pad(JOY_BUTTON_DPAD_LEFT)
	_expect(tutorial.step_completed, "D-pad Left completes the Move Left lesson")
	await create_timer(0.4).timeout
	await _pad(JOY_BUTTON_Y)
	_expect(tutorial.current_action_index == 1, "Y advances to the next lesson once practised")
	_free_current()


func _test_runner_overlays() -> void:
	var runner := await _open("res://scenes/levels/runner_level.tscn")
	await _pad(JOY_BUTTON_START)
	_expect(runner.is_gameplay_paused, "Start pauses the run")
	_expect_focus(runner, "PauseOverlay/Panel/Actions/ResumeButton", "Pause menu highlights Resume")
	await _pad(JOY_BUTTON_A)
	_expect(not runner.is_gameplay_paused, "A on Resume resumes the run")
	await create_timer(0.4).timeout
	await _pad(JOY_BUTTON_START)
	await _pad(JOY_BUTTON_B)
	_expect(not runner.is_gameplay_paused, "B in the pause menu resumes the run")
	await create_timer(0.4).timeout
	await _pad(JOY_BUTTON_START)
	runner.call("request_end_session")
	await process_frame
	_expect_focus(runner, "EndConfirmation/Panel/Actions/CancelButton", "End confirmation highlights Keep paused")
	await _pad(JOY_BUTTON_B)
	_expect(not runner.end_confirmation.visible and runner.pause_overlay.visible, "B cancels ending and returns to the pause menu")
	runner.call("request_end_session")
	runner.call("confirm_end")
	await process_frame
	_expect_focus(runner, "EndSessionOverlay/Panel/ReturnButton", "End overlay highlights Review Summary")
	await _pad(JOY_BUTTON_A)
	await _settle()
	_expect_scene("res://scenes/session_summary.tscn", "A on Review Summary opens the summary")
	_free_current()


func _test_summary() -> void:
	var result: Variant = (load("res://scripts/session_result.gd") as GDScript).new()
	Review.capture(Config.new(), result, &"session_ended")
	var summary := await _open("res://scenes/session_summary.tscn")
	_expect_focus(summary, "Panel/Margin/Content/Ratings/Rating1", "Summary highlights the first effort rating")
	await _pad(JOY_BUTTON_DPAD_RIGHT)
	await _pad(JOY_BUTTON_A)
	_expect(Review.get_result().rpe == 2, "D-pad Right then A records an effort of 2")
	_expect(not summary.retry_button.disabled, "Retry becomes available after rating")
	await _pad(JOY_BUTTON_B)
	await _settle()
	_expect_scene("res://scenes/main.tscn", "B on the summary finishes to the main menu")
	_free_current()


func _test_move_controller_cannot_navigate() -> void:
	for path in ["res://scenes/main.tscn", "res://scenes/patient_setup.tscn", "res://scenes/ready.tscn"]:
		await _open(path)
		for key in [KEY_W, KEY_S, KEY_A, KEY_D, KEY_P]:
			await _key(key)
		await _settle()
		_expect_scene(path, "MOVE keys (A/D/W/S/P) never leave %s" % path.get_file())
		_free_current()


func _test_menu_hints() -> void:
	var Hints: GDScript = load("res://scripts/control_hints.gd")
	_expect(Hints.call("menu_hint", true, "Xbox Series Controller") == "A Select · B Back", "Xbox menu hint names A and B")
	_expect(Hints.call("menu_hint", true, "PS5 Controller") == "Cross Select · Circle Back", "PlayStation menu hint names Cross and Circle")
	_expect(Hints.call("menu_hint", true, "Nintendo Switch Pro Controller") == "B Select · A Back", "Nintendo menu hint follows button positions")
	_expect(Hints.call("menu_hint", false, "") == "Enter Select · Esc Back", "Keyboard menu hint names Enter and Esc")
	_expect(Hints.call("continue_hint", true, "Xbox Series Controller") == "Y Continue", "Practice screens name Y as Continue")
	_expect(Hints.call("continue_hint", true, "PS5 Controller") == "Triangle Continue", "PlayStation names Triangle as Continue")


func _open(path: String) -> Node:
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	return scene


func _settle() -> void:
	await process_frame
	await process_frame


func _free_current() -> void:
	if current_scene != null:
		current_scene.free()
	await process_frame


func _pad(button: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		event.pressed = pressed
		root.push_input(event)
		await process_frame


func _key(physical: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = physical
		event.pressed = pressed
		root.push_input(event)
		await process_frame


func _expect_focus(scene: Node, path: String, message: String) -> void:
	var target := scene.get_node_or_null(path)
	var owner := root.gui_get_focus_owner()
	_expect(target != null and owner == target, "%s (focus on %s)" % [message, owner.name if owner != null else "nothing"])


func _expect_scene(path: String, message: String) -> void:
	var actual := current_scene.scene_file_path if current_scene != null else "none"
	_expect(actual == path, "%s (on %s)" % [message, actual.get_file()])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
