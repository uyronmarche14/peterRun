extends SceneTree

const Setup = preload("res://scripts/session_setup_store.gd")
const Review = preload("res://scripts/session_review_store.gd")
var failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	for path in ["res://data/levels/l01_barangay.tres", "res://tests/fixtures/alternate_level.tres"]:
		Setup.reset()
		var definition: Resource = load(path)
		var config: Variant = Setup.get_session_config()
		config.level_definition = definition
		config.selected_level_id = definition.level_id
		var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
		root.add_child(level)
		current_scene = level
		await process_frame
		for action in [&"move_left", &"jump", &"slide"]:
			level.call("_show_prompt", action, "MOVE NOW", Color(0.35, 0.78, 0.66))
			var motion: Node = level.get_node("WorldMotion")
			motion.call("begin_prompt_approach")
			motion.set_process(false)
			motion.call("_process", 3.7)
			for timer in level.get_node("PromptTimers").get_children():
				timer.stop()
			await _capture("%s_%s" % [definition.level_id, action])
		level.call("request_end_session")
		await _capture("%s_pause_end" % definition.level_id)
		level.call("confirm_end")
		level.call("open_summary")
		await process_frame
		await process_frame
		await _capture("%s_summary" % definition.level_id)
		current_scene.free()
	Setup.reset()
	Review.reset()
	print("PR-12 rendered capture: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)


func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var result := frame.save_png(ProjectSettings.globalize_path("res://../test_evidence/pr12_" + name + ".png"))
	if result != OK:
		failures += 1
	print("CAPTURE %s: %s" % [name, error_string(result)])
