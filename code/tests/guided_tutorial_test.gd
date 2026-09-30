extends SceneTree

const Store = preload("res://scripts/session_setup_store.gd")
const Config = preload("res://scripts/session_config.gd")
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Store.reset()
	var tutorial: Control = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	await process_frame
	_expect(tutorial.has_method("start_practice"), "Tutorial has an intentional practice start")
	_expect(tutorial.has_node("Panel/Margin/Content/Welcome"), "Tutorial explains practice before asking for a movement")
	_expect(not tutorial.get("tutorial_started"), "Tutorial begins with an unpressured welcome state")
	if tutorial.has_method("start_practice"):
		tutorial.call("start_practice")
	_expect(tutorial.has_method("receive_practice_input"), "Tutorial accepts named practice actions")
	if tutorial.has_method("receive_practice_input"):
		var next: Button = tutorial.get_node("Panel/Margin/Content/NavigationRow/NextButton")
		_expect(next.disabled, "Next waits for the demonstrated action")
		tutorial.call("show_next_action")
		_expect(tutorial.current_action_index == 0, "Next cannot bypass an unpractised step")
		tutorial.call("receive_practice_input", &"jump", true, 1.0)
		_expect(not tutorial.step_completed, "Another action does not complete a left lesson")
		tutorial.call("receive_practice_input", &"jump", false, 1.1)
		tutorial.call("receive_practice_input", &"move_left", true, 2.0)
		_expect(tutorial.step_completed and not next.disabled, "Correct movement acknowledges the lesson")
		_expect(tutorial.practice_player.lane_index == 0, "Practice moves the real animated player to the left lane")
		tutorial.call("repeat_action")
		_expect(not tutorial.step_completed and tutorial.practice_player.lane_index == 1, "Repeat resets the player and lesson")
		tutorial.call("receive_practice_input", &"move_left", true, 3.0)
		_expect(not tutorial.step_completed, "A held key cannot complete a repeated lesson")
		tutorial.call("receive_practice_input", &"move_left", false, 3.1)
		tutorial.call("receive_practice_input", &"move_left", true, 3.5)
		_expect(tutorial.step_completed, "A fresh press can complete the repeated lesson")
		tutorial.call("show_next_action")
		_expect(tutorial.current_action_index == 1 and not tutorial.step_completed, "Next opens exactly one new lesson")
		tutorial.call("receive_practice_input", &"move_right", true, 4.0)
		_expect(tutorial.practice_player.lane_index == 2, "Right lesson moves to the right lane")
		tutorial.call("show_next_action")
		tutorial.call("receive_practice_input", &"jump", true, 5.0)
		# Sample the real tween deterministically, independent of startup-frame load.
		var jump_tween: Tween = tutorial.practice_player.get("_action_tween")
		jump_tween.pause()
		jump_tween.custom_step(0.15)
		tutorial.practice_player.call("_process", 0.15)
		var visual: Node2D = tutorial.practice_player.get_node("Visual")
		_expect(visual.position.y < -4.0 and visual.scale == Vector2.ONE and tutorial.practice_player.character_sprite.animation == &"jump_low", "Jump lesson uses the higher readable arc without distortion")
		tutorial.call("toggle_tutorial_pause")
		var pose := visual.transform
		await create_timer(0.2).timeout
		_expect(visual.transform == pose, "Tutorial pause freezes practice animation")
		tutorial.call("show_next_action")
		_expect(tutorial.current_action_index == 2, "Paused tutorial cannot advance")
		tutorial.call("toggle_tutorial_pause")
		tutorial.call("show_next_action")
		tutorial.call("receive_practice_input", &"slide", true, 6.0)
		var slide_tween: Tween = tutorial.practice_player.get("_action_tween")
		slide_tween.pause()
		slide_tween.custom_step(0.15)
		tutorial.practice_player.call("_process", 0.15)
		_expect(tutorial.practice_player.character_sprite.animation == &"slide_duck" and tutorial.practice_player.get_node("Visual").position.y > 0.0 and tutorial.practice_player.get_node("Visual").scale == Vector2.ONE, "Slide lesson uses the deeper low pose without squash")
		_expect(tutorial.step_completed and next.text == "Continue", "Final action unlocks Ready")
		_expect(Store.get_session_config().get_target(&"jump") == 10, "Practice leaves session targets unchanged")
	tutorial.free()
	Store.configure(Config.AffectedSide.LEFT, 12)
	tutorial = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	await process_frame
	if tutorial.has_method("start_practice"):
		tutorial.call("start_practice")
	if tutorial.has_method("receive_practice_input"):
		var hint: Label = tutorial.get_node("Panel/Margin/Content/ActionCard/InstructionLabel")
		_expect(hint.text.contains("A"), "Left-affected setup keeps the literal left keyboard hint")
		tutorial.call("receive_practice_input", &"move_left", true, 10.0)
		_expect(tutorial.step_completed and tutorial.practice_player.lane_index == 0, "Practice keeps literal left input for a left-affected setup")
		# With no input there is no expiry or neutral miss in practice.
		tutorial.call("show_action_index", 3)
		await create_timer(0.6).timeout
		_expect(not tutorial.step_completed and tutorial.current_action_index == 3, "Practice waits without a countdown")
	tutorial.free()
	Store.reset()
	await _test_ready_routes()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN guided tutorial test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_ready_routes() -> void:
	var tutorial: Control = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	current_scene = tutorial
	await process_frame
	if not tutorial.has_method("receive_practice_input"):
		tutorial.free()
		return
	if tutorial.has_method("start_practice"):
		tutorial.call("start_practice")
	tutorial.call("show_action_index", 3)
	tutorial.call("receive_practice_input", &"slide", true, 20.0)
	tutorial.get_node("Panel/Margin/Content/NavigationRow/NextButton").pressed.emit()
	await process_frame
	await process_frame
	_expect(current_scene != null and current_scene.scene_file_path == "res://scenes/ready.tscn", "Completed practice continues to the real Ready screen")
	if current_scene != null:
		current_scene.free()
	tutorial = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	current_scene = tutorial
	await process_frame
	tutorial.call("toggle_tutorial_pause")
	tutorial.get_node("Panel/Margin/Content/UtilityRow/SkipButton").pressed.emit()
	await process_frame
	await process_frame
	_expect(current_scene != null and current_scene.scene_file_path == "res://scenes/ready.tscn", "Skip remains available even while practice is paused")
	if current_scene != null:
		current_scene.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
