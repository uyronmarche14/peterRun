extends SceneTree

const LEVEL = preload("res://scenes/levels/runner_level.tscn")
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Isolate presentation so a runner parse regression cannot hide motion failures.
	var level := LEVEL.instantiate()
	level.set_script(null)
	root.add_child(level)
	var motion: Node = level.get_node("WorldMotion")
	motion.set_process(false)
	var anchor: Node2D = level.get_node("LevelWorld/PromptWorldAnchor")
	motion.call("begin_prompt_approach")
	motion.call("_process", 2.5)
	var warning_y := anchor.position.y
	motion.call("_process", 0.5)
	_expect(anchor.position.y > warning_y, "Item keeps approaching during the response window")
	var frozen := anchor.transform
	motion.call("set_motion_paused", true)
	motion.call("_process", 1.0)
	_expect(anchor.transform == frozen, "Pause freezes item position and scale")
	motion.call("set_motion_paused", false)
	_expect(motion.has_method("resolve_prompt_approach"), "Resolved items have a continuous exit")
	if motion.has_method("resolve_prompt_approach"):
		motion.call("begin_prompt_approach", 0, 2.5, 2.0)
		motion.call("_process", 4.5)
		_expect(absf(anchor.position.x - 128.0) < 0.1, "Left item reaches the left player lane")
		var before_exit := anchor.position
		motion.call("resolve_prompt_approach", false, 0.75)
		_expect(anchor.position == before_exit, "Resolution does not teleport the item")
		motion.call("_process", 0.4)
		_expect(anchor.position.y > before_exit.y and anchor.modulate.a < 1.0, "Neutral item passes and fades")
		var exit_transform := anchor.transform
		var exit_alpha := anchor.modulate.a
		motion.call("set_motion_paused", true)
		motion.call("_process", 0.2)
		_expect(anchor.transform == exit_transform and anchor.modulate.a == exit_alpha, "Pause also freezes the exit fade")
		motion.call("set_motion_paused", false)
		motion.call("_process", 0.4)
		_expect(is_zero_approx(anchor.modulate.a), "Item clears before the next prompt")
		motion.call("begin_prompt_approach", 2, 2.5, 2.0)
		motion.call("_process", 4.5)
		_expect(absf(anchor.position.x - 352.0) < 0.1 and anchor.modulate.a == 1.0, "Next item resets in the right lane")
		motion.call("begin_prompt_approach", 1, 2.5, 2.0)
		for frame in 90:
			motion.call("_process", 1.0 / 30.0)
		var at_30_fps := anchor.transform
		motion.call("begin_prompt_approach", 1, 2.5, 2.0)
		for frame in 360:
			motion.call("_process", 1.0 / 120.0)
		_expect(anchor.transform.is_equal_approx(at_30_fps), "Approach is identical at 30 and 120 simulation FPS")
		var node_count := get_node_count()
		var start_usec := Time.get_ticks_usec()
		for cycle in 1000:
			motion.call("begin_prompt_approach", cycle % 3, 2.5, 2.0)
			motion.call("_process", 4.5)
			motion.call("resolve_prompt_approach", cycle % 2 == 0, 0.75)
			motion.call("_process", 0.75)
		_expect(get_node_count() == node_count, "1000 prompt cycles reuse nodes without scene growth")
		print("1000 presentation cycles CPU time: %.2f ms (not a rendering FPS benchmark)" % ((Time.get_ticks_usec() - start_usec) / 1000.0))
	level.free()

	var runner_script: GDScript = load("res://scripts/runner_level_controller.gd")
	_expect(runner_script.can_instantiate(), "Runner script loads without parse errors")
	if runner_script.can_instantiate():
		await _test_progress_and_pause()
	if failures.is_empty():
		print("PETER RUN runner polish test: PASS")
	else:
		for failure in failures:
			printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)


func _test_progress_and_pause() -> void:
	var level := LEVEL.instantiate()
	root.add_child(level)
	await process_frame
	var bar := level.get_node_or_null("HUD/HUDRoot/ProgressBar") as ProgressBar
	_expect(bar != null, "HUD exposes repetition progress visually")
	var director: Node = level.get_node("PromptDirector")
	director.call("open_response_window")
	level.call("receive_input", &"move_left", true, 10.0)
	level.call("receive_input", &"move_left", true, 10.1)
	_expect(level.get("session_result").get_completed(&"move_left") == 1, "Held input earns one repetition")
	await create_timer(0.1).timeout
	level.call("pause_gameplay")
	var player: Node2D = level.get_node("Player")
	var visual: Node2D = player.get_node("Visual")
	var pose := visual.transform
	var progress := bar.value if bar != null else 0.0
	await create_timer(0.2).timeout
	_expect(visual.transform == pose, "Pause freezes running and action feedback")
	_expect(bar == null or bar.value == progress, "Pause freezes animated progress")
	level.call("resume_gameplay")
	await create_timer(0.4).timeout
	if bar != null:
		_expect(is_equal_approx(bar.value, 1.0), "Progress settles on the exact repetition count")
	# Completed targets cannot overfill aggregate progress while another action remains.
	for index in 20:
		level.get("session_result").record_success(&"move_left")
	level.call("_update_progress_hud")
	_expect(level.get_node("HUD/HUDRoot/ProgressLabel").text == "Reps: 10 / 40", "HUD caps each completed action at its planned target")
	level.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
