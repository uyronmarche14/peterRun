extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Input.use_accumulated_input = true
	var level: Node = (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	_expect(not Input.use_accumulated_input, "gameplay reads every input event at once, not batched per frame")
	_expect(bool(ProjectSettings.get_setting("input_devices/buffering/agile_event_flushing", false)), "agile event flushing is on to cut input buffering")
	level.free()
	Input.use_accumulated_input = true
	if failures.is_empty():
		print("PETER RUN input latency settings test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("FAIL: " + failure)
	quit(1)


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
