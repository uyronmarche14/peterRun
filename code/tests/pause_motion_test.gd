extends SceneTree

const WORLD_MOTION_PATH := "res://scripts/world_motion_controller.gd"
const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(WORLD_MOTION_PATH):
		failures.append("World motion controller is missing")
		_finish()
		return

	var packed_scene: PackedScene = load(RUNNER_LEVEL_PATH)
	var level := packed_scene.instantiate()
	root.add_child(level)
	await process_frame

	_test_pause_controls_exist(level)
	await _test_pause_freezes_motion_timers_and_input(level)

	level.free()
	_finish()


func _test_pause_controls_exist(level: Node) -> void:
	_expect_button(level, ^"HUD/HUDRoot/PauseButton", "Pause")
	_expect_button(level, ^"PauseOverlay/Panel/Actions/ResumeButton", "Resume")
	_expect_button(level, ^"PauseOverlay/Panel/Actions/EndLevelButton", "End Level")
	_expect_button(level, ^"PauseOverlay/Panel/Actions/EndSessionButton", "End Session")
	_expect_button(level, ^"EndSessionOverlay/Panel/ReturnButton", "Review Summary")
	_expect(level.has_method("pause_gameplay"), "RunnerLevel can pause gameplay")
	_expect(level.has_method("resume_gameplay"), "RunnerLevel can resume gameplay")
	_expect(level.has_method("end_session_neutrally"), "RunnerLevel has a neutral end-session route")


func _test_pause_freezes_motion_timers_and_input(level: Node) -> void:
	var motion := level.get_node_or_null(^"WorldMotion")
	var warning_timer := level.get_node_or_null(^"PromptTimers/WarningTimer") as Timer
	var response_timer := level.get_node_or_null(^"PromptTimers/ResponseTimer") as Timer
	var resolve_timer := level.get_node_or_null(^"PromptTimers/ResolveTimer") as Timer
	var player := level.get_node_or_null(^"Player")
	var pause_overlay := level.get_node_or_null(^"PauseOverlay") as CanvasLayer

	_expect(motion != null and motion.has_method("set_motion_paused"), "RunnerLevel includes controllable world motion")
	_expect(warning_timer != null and not warning_timer.paused, "Prompt warning timer begins active")
	_expect(response_timer != null and not response_timer.paused, "Prompt response timer begins active")
	_expect(resolve_timer != null and not resolve_timer.paused, "Prompt resolve timer begins active")

	var has_motion_controller := motion != null and motion.has_method("set_motion_paused")
	var before_motion := float(motion.get("motion_distance")) if has_motion_controller else 0.0
	await create_timer(0.12).timeout
	if has_motion_controller:
		_expect(float(motion.get("motion_distance")) > before_motion, "World motion advances at a fixed calm pace")

	level.call("pause_gameplay")
	_expect_equal(level.get("is_gameplay_paused"), true, "Gameplay reports paused immediately")
	_expect(pause_overlay != null and pause_overlay.visible, "Pause overlay becomes visible")
	_expect(warning_timer != null and warning_timer.paused, "Warning timer freezes on pause")
	_expect(response_timer != null and response_timer.paused, "Response timer freezes on pause")
	_expect(resolve_timer != null and resolve_timer.paused, "Resolve timer freezes on pause")
	if has_motion_controller:
		_expect_equal(motion.get("is_motion_paused"), true, "World motion freezes on pause")

	var frozen_motion := float(motion.get("motion_distance")) if has_motion_controller else 0.0
	var lane_before_pause: Variant = player.get("lane_index") if player != null else -1
	level.call("receive_input", &"move_left", true, 10.0)
	_expect_equal(player.get("lane_index") if player != null else -1, lane_before_pause, "Movement input is ignored while paused")
	await create_timer(0.12).timeout
	if has_motion_controller:
		_expect_equal(float(motion.get("motion_distance")), frozen_motion, "World motion remains frozen while paused")

	level.call("resume_gameplay")
	_expect_equal(level.get("is_gameplay_paused"), false, "Gameplay resumes explicitly")
	_expect(pause_overlay != null and not pause_overlay.visible, "Pause overlay hides on resume")
	_expect(warning_timer != null and not warning_timer.paused, "Warning timer resumes")
	if has_motion_controller:
		_expect_equal(motion.get("is_motion_paused"), false, "World motion resumes")


func _expect_button(root_node: Node, path: NodePath, expected_text: String) -> void:
	var button := root_node.get_node_or_null(path) as Button
	_expect(button != null, "RunnerLevel includes %s button" % expected_text)
	if button != null:
		_expect_equal(button.text, expected_text, "%s button has its required label" % expected_text)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN pause and motion test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN pause and motion test: FAIL (%d failures)" % failures.size())
	quit(1)
