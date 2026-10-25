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

	for pace in [Settings.MIN_PACE, Settings.STANDARD_PACE, Settings.MAX_PACE]:
		var start := _scale_at_time(motion, pace, 0.0)
		var early := _scale_at_time(motion, pace, 0.9) - start
		var late := _scale_at_time(motion, pace, 4.5) - _scale_at_time(motion, pace, 3.6)
		_expect(late / early < 3.5, "Pace %.2f: the last fifth of the approach grows at most 3.5x faster than the first fifth (%.1fx)" % [pace, late / early])
		_expect(early > 0.1, "Pace %.2f: the obstacle is already visibly moving early (growth %.3f)" % [pace, early])
		_expect(is_equal_approx(_scale_at_time(motion, pace, 4.5), _scale_at_time(motion, Settings.STANDARD_PACE, 4.5)), "Pace %.2f: contact scale is the same at every speed" % pace)
		_scale_at_time(motion, pace, 1.0)
		_expect(is_equal_approx(motion.get_prompt_remaining_seconds(), 3.5), "Pace %.2f: remaining prompt seconds ignore the speed" % pace)

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
