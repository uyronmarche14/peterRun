extends SceneTree

const Pattern = preload("res://scripts/pattern_definition.gd")
const Resolver = preload("res://scripts/pattern_library_resolver.gd")
const LEVEL_PATH := "res://data/levels/l01_barangay.tres"

const NEW_LAYOUTS := {
	&"jump": ["PCO", "POC", "CPO", "OPC", "COP", "OCP", "PPO", "POP", "OPP", "PCP"],
	&"slide": ["LCO", "LOC", "CLO", "OLC", "COL", "OCL", "LLO", "LOL", "OLL"],
}

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var library: Array = (load(LEVEL_PATH) as Resource).get_pattern_definitions()
	_test_catalog(library)
	_test_validation(library)
	_test_complexity_ramp(library)
	_test_full_lane_action_selection(library)
	_test_repeated_only_action_stays_full(library)
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 formation expansion test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_catalog(library: Array) -> void:
	_expect(library.size() == 79, "L01 includes its 60 original and 19 approved new formations")
	var layouts := {&"jump": {}, &"slide": {}}
	for formation in library:
		var action := StringName(formation.get("required_action", &""))
		if not layouts.has(action):
			continue
		layouts[action][_layout(formation)] = true
	for action in NEW_LAYOUTS:
		for layout in NEW_LAYOUTS[action]:
			_expect(layouts[action].has(layout), "%s includes %s" % [action, layout])
		_expect(not layouts[action].has("PPP" if action == &"jump" else "LLL"), "%s does not activate an all-cue gate" % action)


func _test_validation(library: Array) -> void:
	var pattern_script: Script = load("res://scripts/pattern_definition.gd")
	_expect(pattern_script.has_method("validate_library"), "A library-wide validator exists")
	if not pattern_script.has_method("validate_library"):
		return
	_expect((pattern_script.call("validate_library", library) as PackedStringArray).is_empty(), "The authored L01 library has unique, valid formations")
	var duplicate := library.duplicate(true)
	duplicate.append(library[0].duplicate(true))
	_expect(not (pattern_script.call("validate_library", duplicate) as PackedStringArray).is_empty(), "Duplicate formation IDs are rejected")
	var conflicting: Dictionary = library[0].duplicate(true)
	for formation in library:
		if formation.get("required_action", &"") == &"jump":
			conflicting = formation.duplicate(true)
			break
	conflicting["obstacles"].append({"kind": &"laundry_line", "lane": 2})
	_expect(not Pattern.validate(conflicting).is_empty(), "A Jump formation rejects a Slide cue")


func _test_complexity_ramp(library: Array) -> void:
	var resolver := Resolver.new()
	resolver.set_seed(311)
	var remaining := {&"move_left": 30, &"move_right": 30, &"jump": 30, &"slide": 30}
	var sizes := {&"jump": [], &"slide": []}
	var current_lane := 1
	var previous_size := 0
	for index in 60:
		var formation: Dictionary = resolver.select_next_for_targets(library, current_lane, remaining)
		_expect(not formation.is_empty(), "Selection %d is reachable" % index)
		if formation.is_empty():
			return
		if index < 4:
			_expect(formation.get("category", &"") == &"beginner", "Opening %d remains beginner" % index)
		var size: int = formation.get("obstacles", []).size()
		var action := StringName(formation.get("required_action", &""))
		if sizes.has(action):
			sizes[action].append(size)
			_expect(_is_full_lane_action(formation), "%s occupies all three lanes with its action cue and two crates" % formation.pattern_id)
		if action in [&"jump", &"slide"]:
			current_lane = current_lane
		else:
			current_lane = int(formation.get("ending_lane", current_lane))
		_expect(not (size == 3 and previous_size == 3), "Three-prop gates are separated when all four actions are available")
		previous_size = size
	for action in sizes:
		_expect(sizes[action].size() >= 3, "%s appears often enough to assess its ramp" % action)
		if sizes[action].size() >= 3:
			_expect(sizes[action].all(func(size: int) -> bool: return size == 3), "%s never leaves two open lanes" % action)
	var only_jump := {&"move_left": 0, &"move_right": 0, &"jump": 2, &"slide": 0}
	var recovery := resolver.select_next_for_targets(library, current_lane, only_jump, true)
	_expect(_is_full_lane_action(recovery), "Recovery remains a single clear action cue with both side lanes occupied")


func _test_full_lane_action_selection(library: Array) -> void:
	for seed in [17, 83, 311]:
		for start_lane in [0, 1, 2]:
			var resolver := Resolver.new()
			resolver.set_seed(seed)
			var targets := {&"move_left": 0, &"move_right": 0, &"jump": 20, &"slide": 20}
			for index in 24:
				var formation: Dictionary = resolver.select_next_for_targets(library, start_lane, targets)
				_expect(not formation.is_empty(), "Seed %d lane %d selection %d is reachable" % [seed, start_lane, index])
				if formation.is_empty():
					break
				_expect(formation.get("required_action", &"") in [&"jump", &"slide"], "Only unfinished Jump/Slide targets are selected")
				_expect(_is_full_lane_action(formation), "%s has one puddle/laundry cue and two crates, with no open lane" % formation.pattern_id)
				_expect(formation.get("entry_lanes", []).has(start_lane), "%s is reachable from lane %d" % [formation.pattern_id, start_lane])


func _test_repeated_only_action_stays_full(library: Array) -> void:
	for action in [&"jump", &"slide"]:
		for lane in [0, 1, 2]:
			var resolver := Resolver.new()
			resolver.set_seed(57)
			var targets := {&"move_left": 0, &"move_right": 0, &"jump": 0, &"slide": 0}
			targets[action] = 2
			for index in 2:
				var formation: Dictionary = resolver.select_next_for_targets(library, lane, targets)
				_expect(formation.get("required_action", &"") == action, "Repeated %s remains the unfinished target in lane %d" % [action, lane])
				_expect(_is_full_lane_action(formation), "Repeated %s in lane %d never falls back to a sparse cue" % [action, lane])


func _is_full_lane_action(formation: Dictionary) -> bool:
	var action := StringName(formation.get("required_action", &""))
	if action not in [&"jump", &"slide"]:
		return false
	var cue_kind := &"puddle" if action == &"jump" else &"laundry_line"
	var obstacles: Array = formation.get("obstacles", [])
	if obstacles.size() != 3:
		return false
	var lanes := {}
	var cue_count := 0
	var crate_count := 0
	for obstacle in obstacles:
		lanes[int(obstacle.get("lane", -1))] = true
		cue_count += int(obstacle.get("kind", &"") == cue_kind)
		crate_count += int(obstacle.get("kind", &"") == &"crate")
	return lanes.size() == 3 and cue_count == 1 and crate_count == 2


func _layout(formation: Dictionary) -> String:
	var lanes := ["O", "O", "O"]
	for obstacle in formation.get("obstacles", []):
		var kind := StringName(obstacle.get("kind", &""))
		lanes[int(obstacle.get("lane", -1))] = "C" if kind == &"crate" else "P" if kind == &"puddle" else "L"
	return "".join(PackedStringArray(lanes))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
