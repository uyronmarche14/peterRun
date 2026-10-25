extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const Summary = "res://scenes/session_summary.tscn"
const Runner = "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var original := Settings.visual_pace
	var fast := await _distance_after_rating(1)
	var slow := await _distance_after_rating(10)
	_expect(fast > slow * 2.5, "Rating 1 moves the road far further than rating 10 in the same time (%.2f vs %.2f)" % [fast, slow])
	_expect(is_equal_approx(fast / slow, Settings.MAX_PACE / Settings.MIN_PACE), "Distance ratio equals the pace ratio")
	Settings.set_visual_pace(original)
	if failures.is_empty():
		print("PETER RUN speed application test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("FAIL: " + failure)
	quit(1)


func _distance_after_rating(rating: int) -> float:
	Settings.start_countdown_pending = false
	var review := load("res://scripts/session_review_store.gd")
	review.capture(load("res://scripts/session_config.gd").new(), load("res://scripts/session_result.gd").new(), &"completed")
	var summary: Node = (load(Summary) as PackedScene).instantiate()
	root.add_child(summary)
	await process_frame
	summary.select_rating(rating)
	summary.free()
	var level: Node = (load(Runner) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var motion := level.get_node("WorldMotion")
	var before: float = motion.motion_distance
	motion._process(1.0)
	var moved: float = motion.motion_distance - before
	level.free()
	return moved


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
