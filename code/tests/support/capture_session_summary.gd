extends SceneTree

const Setup = preload("res://scripts/session_setup_store.gd")
const Review = preload("res://scripts/session_review_store.gd")
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	Setup.reset()
	var runner: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(runner)
	current_scene = runner
	await process_frame
	runner.call("request_end_session")
	await _capture("pr11_end_confirmation")
	_check_controls(runner.get_node("EndConfirmation/Panel"), Rect2(0, 0, 480, 270))
	runner.call("confirm_end")
	runner.call("open_summary")
	await process_frame
	await process_frame
	var summary := current_scene
	await _capture("pr11_summary_unrated")
	_check_controls(summary.get_node("Panel"), summary.get_node("Panel").get_global_rect())
	summary.call("select_rating", 10)
	summary.call("rest_session")
	await _capture("pr11_summary_rest")
	_check_controls(summary.get_node("Panel"), summary.get_node("Panel").get_global_rect())
	# Check the same compact layout in a smaller and a non-16:9 window.
	for window_size in [Vector2i(960, 540), Vector2i(1024, 768)]:
		root.size = window_size
		await process_frame
		await process_frame
		_check_controls(summary.get_node("Panel"), summary.get_node("Panel").get_global_rect())
		await _capture("pr11_summary_%dx%d" % [window_size.x, window_size.y])
	summary.free()
	Review.reset()
	Setup.reset()
	print("PR-11 rendered layout: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)


func _check_controls(node: Node, bounds: Rect2) -> void:
	if node is Control and node.is_visible_in_tree():
		if not bounds.grow(1).encloses(node.get_global_rect()):
			failures += 1
			printerr("OVERFLOW: %s %s outside %s" % [node.get_path(), node.get_global_rect(), bounds])
	for child in node.get_children():
		_check_controls(child, bounds)


func _capture(filename: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var result := frame.save_png(ProjectSettings.globalize_path("res://../test_evidence/" + filename + ".png"))
	if result != OK:
		failures += 1
	print("CAPTURE %s: %s" % [filename, error_string(result)])
