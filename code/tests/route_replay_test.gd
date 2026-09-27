extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"
const Review = preload("res://scripts/session_review_store.gd")
const Result = preload("res://scripts/session_result.gd")
const Setup = preload("res://scripts/session_setup_store.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Setup.reset()
	var level: Node = (load(RUNNER_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	var session_result: Variant = level.get("session_result")
	var session_seed: Variant = session_result.get("route_seed")
	_expect(session_seed is int and session_seed > 0, "Every session records a non-zero route seed")
	var result := Result.new()
	result.route_seed = 24680
	Review.capture(level.get("session_config"), result, &"completed")
	var reviewed_seed: Variant = Review.get_result().get("route_seed")
	_expect(reviewed_seed is int and reviewed_seed == 24680, "Review retains the route seed for a repeatable audit")
	level.free()
	Review.reset()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN route replay test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
