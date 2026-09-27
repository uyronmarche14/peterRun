extends SceneTree

const Setup = preload("res://scripts/session_setup_store.gd")
const Config = preload("res://scripts/session_config.gd")
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Setup.reset()
	var setup: Node = load("res://scenes/patient_setup.tscn").instantiate()
	root.add_child(setup)
	await process_frame
	_expect(setup.get_node("%RouteCaption").text == "Route" and setup.get_node("%LevelLabel").text == "L01 · Barangay Morning", "Setup describes a route, not a difficulty level")
	setup.free()
	var tutorial: Node = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	current_scene = tutorial
	await process_frame
	_expect(tutorial.has_method("demonstrate_action"), "Tutorial has an on-demand demonstration")
	if tutorial.has_method("demonstrate_action"):
		await _test_demonstration(tutorial)
	tutorial.free()
	Setup.reset()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN tutorial demo test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_demonstration(tutorial: Node) -> void:
	tutorial.call("start_practice")
	var button: Button = tutorial.get_node("Panel/Margin/Content/NavigationRow/DemoButton")
	var next: Button = tutorial.get_node("Panel/Margin/Content/NavigationRow/NextButton")
	var player: Node2D = tutorial.get("practice_player")
	button.pressed.emit()
	_expect(tutorial.get("is_demonstrating") and player.get("lane_index") == 0, "Show me demonstrates the current named action")
	_expect(not tutorial.get("step_completed") and next.disabled, "Demonstration cannot count as completed practice")
	tutorial.call("receive_practice_input", &"move_left", true, 1.0)
	_expect(not tutorial.get("step_completed"), "Input during a demonstration does not acknowledge practice")
	tutorial.call("receive_practice_input", &"move_left", false, 1.1)
	tutorial.call("show_next_action")
	tutorial.call("show_previous_action")
	tutorial.call("repeat_action")
	_expect(tutorial.get("current_action_index") == 0 and tutorial.get("is_demonstrating"), "Navigation cannot interrupt or bypass a demonstration")
	tutorial.call("toggle_tutorial_pause")
	var pose := player.transform
	var remaining: float = tutorial.get_node("DemoTimer").time_left
	await create_timer(0.12).timeout
	_expect(player.transform == pose and is_equal_approx(remaining, tutorial.get_node("DemoTimer").time_left), "Pause freezes demonstration motion and its return timer")
	tutorial.call("demonstrate_action")
	_expect(button.disabled and next.disabled, "Paused demo cannot restart or advance")
	tutorial.call("toggle_tutorial_pause")
	await create_timer(1.15).timeout
	_expect(not tutorial.get("is_demonstrating") and player.get("lane_index") == 1, "Demo returns to a fresh practice pose automatically")
	_expect(not tutorial.get("step_completed") and next.disabled, "The player must still practise after watching")
	tutorial.call("receive_practice_input", &"move_left", true, 3.0)
	_expect(tutorial.get("step_completed") and not next.disabled, "A fresh manual action completes practice after the demo")
	for index in [1, 2, 3]:
		tutorial.call("show_action_index", index)
		tutorial.call("demonstrate_action")
		_expect(not tutorial.get("step_completed"), "Demo never acknowledges action %d" % index)
		if index == 1:
			_expect(player.get("lane_index") == 2, "Right demonstration moves to the right lane")
		else:
			var tween: Tween = player.get("_action_tween")
			tween.pause()
			tween.custom_step(0.20)
			player.call("_process", 0.20)
			_expect(player.character_sprite.animation == (&"jump_low" if index == 2 else &"slide_duck") and player.character_sprite.get_clip_frame() > 0, "Jump/slide demonstration advances real authored action frames")
			_expect(player.get_node("Visual").transform == Transform2D.IDENTITY, "Demo never adds duplicate lift or squash to authored poses")
		tutorial.get_node("DemoTimer").stop()
		tutorial.call("_on_demo_finished")
	_expect(Setup.get_session_config().get_target(&"jump") == 10, "Demonstrations never change session targets")
	# Affected side is recorded for review; practice directions remain literal.
	tutorial.get("input_adapter").affected_side = Config.AffectedSide.LEFT
	tutorial.call("show_action_index", 0)
	tutorial.call("demonstrate_action")
	_expect(player.get("lane_index") == 0, "Left-affected demo still shows logical left")
	tutorial.get_node("DemoTimer").stop()
	tutorial.call("_on_demo_finished")
	tutorial.call("receive_practice_input", &"move_left", false, 4.9)
	tutorial.call("receive_practice_input", &"move_left", true, 5.0)
	_expect(tutorial.get("step_completed"), "Literal left input completes the demonstrated action")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
