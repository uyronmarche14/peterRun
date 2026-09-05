extends SceneTree

const L01_PROMPT_CATALOG_PATH := "res://scripts/l01_prompt_catalog.gd"
const PROMPT_DIRECTOR_PATH := "res://scripts/prompt_director.gd"
const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	_test_runner_scene_prompt_hooks()
	if not ResourceLoader.exists(L01_PROMPT_CATALOG_PATH):
		failures.append("L01 prompt catalog is missing")
		_finish()
		return

	_test_l01_action_mapping_and_sequence()
	_finish()


func _test_runner_scene_prompt_hooks() -> void:
	var packed_scene: PackedScene = load(RUNNER_LEVEL_PATH)
	var level := packed_scene.instantiate()
	_expect_node(level, ^"LevelWorld/PromptWorldAnchor/L01PromptProps/CratePrompt", "crate prompt silhouette")
	_expect_node(level, ^"LevelWorld/PromptWorldAnchor/L01PromptProps/PuddlePrompt", "puddle prompt silhouette")
	_expect_node(level, ^"LevelWorld/PromptWorldAnchor/L01PromptProps/LaundryLinePrompt", "laundry-line prompt silhouette")
	_expect_node(level, ^"HUD/HUDRoot/PromptActionLabel", "prompt action label")
	_expect_node(level, ^"HUD/HUDRoot/PromptStateLabel", "prompt state label")
	_expect_node(level, ^"PromptTimers/WarningTimer", "calm warning timer")
	_expect_node(level, ^"PromptTimers/ResponseTimer", "response timer")
	_expect_node(level, ^"PromptTimers/ResolveTimer", "resolved-state timer")
	level.free()


func _test_l01_action_mapping_and_sequence() -> void:
	var catalog: Variant = _new_catalog()
	_expect_equal(catalog.get_prop_id(&"move_left"), &"crate", "Move left maps to a crate")
	_expect_equal(catalog.get_prop_id(&"move_right"), &"crate", "Move right maps to a crate")
	_expect_equal(catalog.get_prop_id(&"jump"), &"puddle", "Jump maps to a puddle")
	_expect_equal(catalog.get_prop_id(&"slide"), &"laundry_line", "Slide maps to a laundry line")
	_expect_equal(catalog.get_prop_id(&"unknown"), &"", "Unknown action has no L01 prop")
	_expect_equal(catalog.get_action_label(&"jump"), "JUMP", "Jump has a readable prompt label")

	var planned_sequence: Array = catalog.get_planned_sequence()
	_expect_equal(planned_sequence, [&"move_left", &"jump", &"move_right", &"slide"], "L01 sequence is planned and balanced")

	var director_script: GDScript = load(PROMPT_DIRECTOR_PATH)
	var director: Node = director_script.new()
	for action_name in planned_sequence:
		_expect(director.schedule(action_name), "Planned action schedules: %s" % action_name)
		_expect(director.open_response_window(), "Planned action becomes active: %s" % action_name)
		_expect(director.receive_action(action_name), "Matching action resolves: %s" % action_name)
		_expect_equal(director.resolution, 1, "Matching action resolves successfully: %s" % action_name)
		_expect(director.clear_resolved_prompt(), "Resolved planned action clears: %s" % action_name)
	director.free()


func _new_catalog() -> Variant:
	var catalog_script: GDScript = load(L01_PROMPT_CATALOG_PATH)
	return catalog_script.new()


func _expect_node(root_node: Node, path: NodePath, description: String) -> void:
	_expect(root_node.get_node_or_null(path) != null, "RunnerLevel includes %s" % description)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN L01 prompt test: PASS")
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("PETER RUN L01 prompt test: FAIL (%d failures)" % failures.size())
	quit(1)
