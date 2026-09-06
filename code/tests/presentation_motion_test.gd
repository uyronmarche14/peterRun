extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_full_hd_pixel_presentation_settings()
	await _test_clean_prompt_presentation_and_eased_motion()
	_finish()


func _test_full_hd_pixel_presentation_settings() -> void:
	_expect_equal(ProjectSettings.get_setting("display/window/size/viewport_width"), 480, "Native pixel canvas remains 480 pixels wide")
	_expect_equal(ProjectSettings.get_setting("display/window/size/viewport_height"), 270, "Native pixel canvas remains 270 pixels high")
	_expect_equal(ProjectSettings.get_setting("display/window/size/window_width_override"), 1920, "Desktop presentation width is 1920")
	_expect_equal(ProjectSettings.get_setting("display/window/size/window_height_override"), 1080, "Desktop presentation height is 1080")
	_expect_equal(ProjectSettings.get_setting("display/window/size/mode"), 3, "Desktop presentation opens fullscreen")
	_expect_equal(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep", "Pixel canvas keeps its intended aspect ratio")


func _test_clean_prompt_presentation_and_eased_motion() -> void:
	var level: Node = (load(RUNNER_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame

	_expect_node(level, ^"HUD/HUDRoot/PromptCard", "high-contrast prompt card")
	_expect_node(level, ^"HUD/HUDRoot/PromptCard/PromptIconLabel", "prompt action icon")
	_expect_node(level, ^"LevelWorld/PromptWorldAnchor/PromptProps/PromptBackdrop", "clean prompt backdrop")

	var player := level.get_node_or_null(^"Player") as Node2D
	if player != null:
		player.call("handle_action", &"move_left")
		await create_timer(0.12).timeout
		_expect(player.position.x > 128.0 and player.position.x < 165.0, "Lane input responds early and eases toward the target without overshoot")
		await create_timer(0.16).timeout
		player.call("handle_action", &"jump")
		await create_timer(0.20).timeout
		var visual := player.get_node_or_null(^"Visual") as Node2D
		_expect(visual != null and visual.position.y <= -26.0, "Jump has a readable, smooth peak")

	# Sample the new full lifecycle deterministically; props reach the player
	# at the end of the response window, not at the end of the warning.
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	var motion: Node = level.get_node("WorldMotion")
	motion.set_process(false)
	motion.call("begin_prompt_approach")
	var prompt_anchor: Node2D = level.get_node("LevelWorld/PromptWorldAnchor")
	var initial_scale := prompt_anchor.scale.x
	motion.call("_process", 2.5)
	var warning_y := prompt_anchor.position.y
	var warning_scale := prompt_anchor.scale.x
	_expect(warning_y > 92.0 and warning_y < 218.0, "Warning prop remains on the road ahead")
	_expect(warning_scale > initial_scale, "Depth increases during warning")
	motion.call("_process", 2.0)
	_expect(prompt_anchor.position.y > warning_y, "Approach continues throughout response")
	_expect(is_equal_approx(prompt_anchor.position.y, 218.0), "Item reaches player contact depth at response close")
	_expect(prompt_anchor.scale.x > warning_scale, "Perspective grows continuously toward player")
	var prompt_ground_shadow: Polygon2D = level.get_node("LevelWorld/PromptWorldAnchor/PromptProps/PromptGroundShadow")
	_expect(prompt_ground_shadow.visible, "Approaching prop stays grounded")
	_expect(is_equal_approx(prompt_ground_shadow.global_scale.x, prompt_anchor.scale.x), "Shadow shares the same depth scale as its prop")

	level.queue_free()
	await process_frame


func _expect_node(root_node: Node, path: NodePath, description: String) -> void:
	_expect(root_node.get_node_or_null(path) != null, "RunnerLevel includes %s" % description)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN presentation and motion test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN presentation and motion test: FAIL (%d failures)" % failures.size())
	quit(1)
