extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const PromptDirectorModel = preload("res://scripts/prompt_director.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var original := Settings.visual_pace
	Settings.start_countdown_pending = false
	_expect(is_equal_approx(Settings.warning_seconds_for_pace(Settings.STANDARD_PACE), 2.5), "Standard speed keeps the prescribed 2.5 s warning")
	for case in [[Settings.MAX_PACE, 1.5], [Settings.STANDARD_PACE, 2.5], [Settings.MIN_PACE, 4.0]]:
		Settings.set_visual_pace(case[0])
		var level: Node = (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
		root.add_child(level)
		await process_frame
		var warning: float = case[1]
		_expect(level.get_node("PromptDirector").state == PromptDirectorModel.State.WARNING, "A prompt is in its warning phase")
		_expect(is_equal_approx(level.warning_timer.wait_time, warning), "Pace %.2f: the warning lasts %.1f s (got %.2f)" % [case[0], warning, level.warning_timer.wait_time])
		_expect(is_equal_approx(level.world_motion._approach_duration, warning + 2.0), "Pace %.2f: the obstacle reaches Peter after warning + 2.0 s (got %.2f)" % [case[0], level.world_motion._approach_duration])
		level.warning_timer.timeout.emit()
		_expect(is_equal_approx(level.response_timer.wait_time, 2.0), "Pace %.2f: the response window stays 2.0 s" % case[0])
		level.free()
	Settings.set_visual_pace(original)
	if failures.is_empty():
		print("PETER RUN speed warning time test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("FAIL: " + failure)
	quit(1)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
