extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const RoadProjection = preload("res://scripts/road_projection.gd")

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
	var travel := {}

	for pace in [Settings.MIN_PACE, Settings.STANDARD_PACE, Settings.MAX_PACE]:
		var ys: Array[float] = []
		var scales: Array[float] = []
		for step in 6:
			var seconds := 4.5 * float(step) / 5.0
			Settings.set_visual_pace(pace)
			motion.begin_prompt_approach(1, 2.5, 2.0)
			motion._prompt_elapsed = seconds
			motion._apply_prompt_projection()
			ys.append(motion.prompt_anchor.position.y)
			scales.append(motion.prompt_anchor.scale.x)
		var y_steps: Array[float] = []
		var scale_steps: Array[float] = []
		for step in 5:
			y_steps.append(ys[step + 1] - ys[step])
			scale_steps.append(scales[step + 1] - scales[step])
		_expect(_spread(y_steps) < 1.6, "Pace %.2f: the obstacle's ground speed stays within 1.6x from start to end (%.2fx)" % [pace, _spread(y_steps)])
		_expect(_spread(scale_steps) < 1.6, "Pace %.2f: the obstacle's growth stays within 1.6x from start to end (%.2fx)" % [pace, _spread(scale_steps)])
		_expect(is_equal_approx(scales[5], RoadProjection.PLAYER_SCALE), "Pace %.2f: contact size is the same at every speed" % pace)
		travel[pace] = ys[5] - ys[0]
		motion._prompt_elapsed = 1.0
		_expect(is_equal_approx(motion.get_prompt_remaining_seconds(), 3.5), "Pace %.2f: remaining prompt seconds ignore the speed" % pace)



	_expect(is_equal_approx(travel[Settings.MAX_PACE], travel[Settings.MIN_PACE]) and is_equal_approx(travel[Settings.MIN_PACE], travel[Settings.STANDARD_PACE]), "Every speed starts the obstacle at the same far point and covers the same ground (%.1f / %.1f / %.1f)" % [travel[Settings.MIN_PACE], travel[Settings.STANDARD_PACE], travel[Settings.MAX_PACE]])
	_expect(travel[Settings.MIN_PACE] > 85.0, "The obstacle starts far up the road at every speed, never in front of Peter")
	Settings.set_visual_pace(original)
	level.free()
	if failures.is_empty():
		print("PETER RUN obstacle speed feel test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("FAIL: " + failure)
	quit(1)


func _spread(steps: Array[float]) -> float:
	return steps.max() / maxf(steps.min(), 0.0001)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
