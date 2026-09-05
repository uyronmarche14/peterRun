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
	_expect_node(level, ^"LevelWorld/PromptWorldAnchor/L01PromptProps/PromptBackdrop", "clean prompt backdrop")

	var player := level.get_node_or_null(^"Player") as Node2D
	if player != null:
		player.call("handle_action", &"move_left")
		await create_timer(0.12).timeout
		_expect(player.position.x > 155.0 and player.position.x < 240.0, "Lane movement eases through the middle of the transition")
		await create_timer(0.16).timeout
		player.call("handle_action", &"jump")
		await create_timer(0.20).timeout
		var visual := player.get_node_or_null(^"Visual") as Node2D
		_expect(visual != null and visual.position.y <= -26.0, "Jump has a readable, smooth peak")

	var prompt_anchor := level.get_node_or_null(^"LevelWorld/PromptWorldAnchor") as Marker2D
	await create_timer(0.92).timeout
	_expect(prompt_anchor != null and prompt_anchor.position.y >= 120.0, "Prompt prop approaches clearly before response")
	_expect(prompt_anchor != null and prompt_anchor.scale.x >= 1.1, "Prompt prop grows gently as it approaches")
	var prompt_ground_shadow := level.get_node_or_null(^"LevelWorld/PromptWorldAnchor/L01PromptProps/PromptGroundShadow") as Polygon2D
	_expect(prompt_ground_shadow != null, "Prompt includes a ground shadow for depth")
	await create_timer(1.0).timeout
	_expect(prompt_anchor != null and prompt_anchor.position.y >= 150.0, "Prompt travels deeply into the lower road space")
	_expect(prompt_anchor != null and prompt_anchor.scale.x >= 1.32, "Prompt gains clear perspective scale near the player")
	_expect(prompt_ground_shadow != null and prompt_ground_shadow.visible, "Ground shadow stays visible while the prompt approaches")
	_expect(prompt_ground_shadow != null and prompt_ground_shadow.scale.x >= 1.2, "Ground shadow expands with the approaching prompt")

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
