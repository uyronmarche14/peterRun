extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const PACES := [0.85, 1.0, 1.15]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Route pace is a visual comfort setting, never a shorter response window.
	var original_pace: float = Settings.visual_pace
	var original_reduced: bool = Settings.reduced_motion
	Settings.set_reduced_motion(false)
	var cloud_x: Array[float] = []
	for pace in PACES:
		Settings.set_visual_pace(pace)
		var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
		root.add_child(level)
		await process_frame
		for timer in level.get_node(^"PromptTimers").get_children():
			timer.stop()
		var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
		var motion: Node = level.get_node(^"WorldMotion")
		route.set_process(false)
		motion.set_process(false)
		route.call("configure_route", 17, 0)
		var street := route.get_node(^"JourneyStages/StageHome/LeftStreet") as Sprite2D
		var street_at := street.position
		route.call("advance_layer_motion", 3.0)
		_expect(is_equal_approx(float(route.get("motion_phase")), 3.0 * pace), "L01 ambient motion honors visual pace %.2f" % pace)
		cloud_x.append((route.get_node(^"CloudsA") as Sprite2D).position.x)
		_expect(street.position == street_at, "Fixed buildings remain aligned at visual pace %.2f" % pace)
		motion.call("begin_prompt_approach", 1, 2.5, 2.0)
		motion.call("_process", 1.0)
		_expect(is_equal_approx(float(motion.call("get_prompt_remaining_seconds")), 3.5), "Prompt approach timing is unchanged at visual pace %.2f" % pace)
		route.call("set_motion_paused", true)
		var paused_phase: float = route.get("motion_phase")
		route.call("advance_layer_motion", 1.0)
		_expect(is_equal_approx(float(route.get("motion_phase")), paused_phase), "Pause freezes ambient pace %.2f" % pace)
		level.free()
	_expect(cloud_x.size() == 3 and cloud_x[0] < cloud_x[1] and cloud_x[1] < cloud_x[2], "Cloud drift visibly responds to Calm, Standard, and Lively")
	Settings.set_visual_pace(original_pace)
	Settings.set_reduced_motion(original_reduced)
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 visual pace integration: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
