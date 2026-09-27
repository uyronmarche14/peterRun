extends SceneTree

const PATTERN_DEFINITION_PATH := "res://scripts/pattern_definition.gd"
const L01_PATH := "res://data/levels/l01_barangay.tres"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(ResourceLoader.exists(PATTERN_DEFINITION_PATH), "PatternDefinition exists")
	_expect(ResourceLoader.exists(L01_PATH), "L01 level resource exists")
	if ResourceLoader.exists(PATTERN_DEFINITION_PATH):
		var pattern_definition: Script = load(PATTERN_DEFINITION_PATH)
		_expect(pattern_definition != null and pattern_definition.has_method("validate"), "PatternDefinition exposes validation")
		if pattern_definition != null and pattern_definition.has_method("validate"):
			_test_valid_formations(pattern_definition)
			_test_invalid_formations(pattern_definition)
			_test_l01_migration(pattern_definition)
			_test_l01_balanced_action_library()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN pattern definition test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_valid_formations(pattern_definition: Script) -> void:
	var left_gate := {
		"pattern_id": &"l01_gate_left_01",
		"category": &"beginner",
		"obstacles": [{"kind": &"crate", "lane": 1}, {"kind": &"crate", "lane": 2}],
		"open_lanes": [0],
		"required_action": &"move_left",
		"entry_lanes": [0, 1],
		"ending_lane": 0,
		"allow_idle_safe_clear": true,
	}
	_expect(pattern_definition.validate(left_gate).is_empty(), "A reachable two-crate left gate is valid")

	var jump := {
		"pattern_id": &"l01_jump_center_01",
		"category": &"beginner",
		"obstacles": [{"kind": &"puddle", "lane": 1}],
		"open_lanes": [],
		"required_action": &"jump",
		"action_lane": 1,
		"entry_lanes": [1],
		"ending_lane": 1,
		"allow_idle_safe_clear": false,
	}
	_expect(pattern_definition.validate(jump).is_empty(), "A lane-specific jump formation is valid")

	var two_puddle_jump := {
		"pattern_id": &"l01_two_puddle_jump_01",
		"category": &"mixed",
		"obstacles": [{"kind": &"puddle", "lane": 0}, {"kind": &"puddle", "lane": 1}, {"kind": &"crate", "lane": 2}],
		"open_lanes": [],
		"required_action": &"jump",
		"action_lanes": [0, 1],
		"entry_lanes": [0, 1],
		"ending_lane": 0,
		"allow_idle_safe_clear": false,
	}
	_expect(pattern_definition.validate(two_puddle_jump).is_empty(), "A crate plus two puddles permits a jump in either puddle lane")


func _test_invalid_formations(pattern_definition: Script) -> void:
	var invalid_lane := _valid_gate()
	invalid_lane.obstacles[0].lane = 3
	_expect(not pattern_definition.validate(invalid_lane).is_empty(), "Out-of-range obstacle lanes are rejected")

	var duplicate_obstacle := _valid_gate()
	duplicate_obstacle.obstacles[1].lane = 1
	_expect(not pattern_definition.validate(duplicate_obstacle).is_empty(), "Duplicate obstacle lanes are rejected")

	var blocked_gate := _valid_gate()
	blocked_gate.open_lanes = []
	_expect(not pattern_definition.validate(blocked_gate).is_empty(), "Movement gates need an open lane")

	var missing_action_lane := _valid_jump()
	missing_action_lane.erase("action_lane")
	_expect(not pattern_definition.validate(missing_action_lane).is_empty(), "Jump formations need an action lane")

	var unsafe_jump_clear := _valid_jump()
	unsafe_jump_clear.allow_idle_safe_clear = true
	_expect(not pattern_definition.validate(unsafe_jump_clear).is_empty(), "Jump formations cannot grant idle safe clears")

	var unreachable_gate := _valid_gate()
	unreachable_gate.entry_lanes = [2]
	_expect(not pattern_definition.validate(unreachable_gate).is_empty(), "Every declared movement-gate entry lane must reach safety")

	var wrong_gate_prop := _valid_gate()
	wrong_gate_prop.obstacles[0].kind = &"puddle"
	_expect(not pattern_definition.validate(wrong_gate_prop).is_empty(), "Movement gates require crate silhouettes")


func _test_l01_migration(pattern_definition: Script) -> void:
	var level: Resource = load(L01_PATH)
	_expect(level.get_pattern_sets().size() == 8, "L01 retains its eight runner compatibility sets")
	var formations: Array = level.get_pattern_definitions()
	_expect(formations.size() >= 44, "L01 provides expanded varied formations")
	_expect(formations.any(func(formation: Dictionary) -> bool: return formation.get("obstacles", []).size() == 3), "L01 includes a readable three-obstacle formation")
	_expect(formations.any(func(formation: Dictionary) -> bool: return formation.get("action_lanes", []).size() == 2 and formation.get("required_action", &"") == &"jump"), "L01 includes a two-puddle choice where either jump lane works")
	for formation in formations:
		_expect(not StringName(formation.get("pattern_id", &"")).is_empty(), "Migrated formation has an identifier")
		_expect(formation.has("obstacles"), "Migrated formation declares obstacles")
		_expect(formation.has("open_lanes"), "Migrated formation declares open lanes")
		_expect(pattern_definition.validate(formation).is_empty(), "Migrated formation is valid: " + str(formation.get("pattern_id", "unknown")))


func _test_l01_balanced_action_library() -> void:
	var level: Resource = load(L01_PATH)
	var formations: Array = level.get_pattern_definitions()
	var action_counts := {&"move_left": 0, &"move_right": 0, &"jump": 0, &"slide": 0}
	var slide_gate_lanes: Array[int] = []
	for formation in formations:
		var action := StringName(formation.get("required_action", &""))
		if action_counts.has(action):
			action_counts[action] = int(action_counts[action]) + 1
		if action != &"slide" or formation.get("obstacles", []).size() != 3:
			continue
		for obstacle in formation.get("obstacles", []):
			if obstacle is Dictionary and obstacle.get("kind", &"") == &"laundry_line":
				slide_gate_lanes.append(int(obstacle.get("lane", -1)))
	_expect(formations.size() == 60, "L01 provides a 60-formation balanced library")
	for action_name in action_counts:
		_expect(action_counts[action_name] == 15, "L01 gives %s an equal 15 safe formation choices" % action_name)
	for lane in [0, 1, 2]:
		_expect(slide_gate_lanes.has(lane), "L01 includes a readable Slide gate in lane %d" % lane)


func _valid_gate() -> Dictionary:
	return {
		"pattern_id": &"l01_gate_left_01",
		"category": &"beginner",
		"obstacles": [{"kind": &"crate", "lane": 1}, {"kind": &"crate", "lane": 2}],
		"open_lanes": [0],
		"required_action": &"move_left",
		"entry_lanes": [0, 1],
		"ending_lane": 0,
		"allow_idle_safe_clear": true,
	}


func _valid_jump() -> Dictionary:
	return {
		"pattern_id": &"l01_jump_center_01",
		"category": &"beginner",
		"obstacles": [{"kind": &"puddle", "lane": 1}],
		"open_lanes": [],
		"required_action": &"jump",
		"action_lane": 1,
		"entry_lanes": [1],
		"ending_lane": 1,
		"allow_idle_safe_clear": false,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
