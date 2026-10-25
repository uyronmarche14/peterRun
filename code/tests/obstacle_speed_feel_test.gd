extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.start_countdown_pending = false
	var level: Node = (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var motion := level.get_node("WorldMotion")
	var original := Settings.visual_pace

	var mid_fast := _scale_at_time(motion, Settings.MAX_PACE, 2.25)
	var mid_std := _scale_at_time(motion, Settings.STANDARD_PACE, 2.25)
	var mid_slow := _scale_at_time(motion, Settings.MIN_PACE, 2.25)
	_expect(mid_fast < mid_std and mid_std < mid_slow, "Halfway to contact a faster speed keeps the obstacle smaller, it then closes harder (%.3f < %.3f < %.3f)" % [mid_fast, mid_std, mid_slow])

	var end_fast := _scale_at_time(motion, Settings.MAX_PACE, 4.5)
	var end_slow := _scale_at_time(motion, Settings.MIN_PACE, 4.5)
	_expect(is_equal_approx(end_fast, end_slow), "Contact scale and timing are the same at every speed (%.3f vs %.3f)" % [end_fast, end_slow])
	_expect(is_equal_approx(motion.get_prompt_remaining_seconds(), 0.0), "Response time left does not depend on speed")

	_scale_at_time(motion, Settings.MAX_PACE, 1.0)
	_expect(is_equal_approx(motion.get_prompt_remaining_seconds(), 3.5), "Remaining prompt seconds ignore the speed setting")

	Settings.set_visual_pace(original)
	level.free()
	if failures.is_empty():
		print("PETER RUN obstacle speed feel test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("FAIL: " + failure)
	quit(1)


func _scale_at_time(motion: Node, pace: float, seconds: float) -> float:
	Settings.set_visual_pace(pace)
	motion.begin_prompt_approach(1, 2.5, 2.0)
	motion._prompt_elapsed = seconds
	motion._apply_prompt_projection()
	return motion.prompt_anchor.scale.x


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
