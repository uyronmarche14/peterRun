extends SceneTree

const RESOLVER_PATH := "res://scripts/pattern_library_resolver.gd"
const L01_PATH := "res://data/levels/l01_barangay.tres"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(ResourceLoader.exists(RESOLVER_PATH), "Pattern library resolver exists")
	if ResourceLoader.exists(RESOLVER_PATH):
		var resolver_script: Script = load(RESOLVER_PATH)
		_expect(resolver_script != null, "Pattern library resolver loads")
		if resolver_script != null:
			_test_shuffled_reachable_selection(resolver_script)
			_test_unfinished_target_preference(resolver_script)
			_test_gentle_opening_and_lateral_variety(resolver_script)
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN pattern library resolver test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_shuffled_reachable_selection(resolver_script: Script) -> void:
	var library: Array = (load(L01_PATH) as Resource).get_pattern_definitions()
	var first_resolver: RefCounted = resolver_script.new()
	var second_resolver: RefCounted = resolver_script.new()
	var alternate_resolver: RefCounted = resolver_script.new()
	_expect(first_resolver.has_method("set_seed"), "Formation selection exposes a reproducible shuffle seed")
	if not first_resolver.has_method("set_seed"):
		return
	first_resolver.call("set_seed", 321)
	second_resolver.call("set_seed", 321)
	alternate_resolver.call("set_seed", 789)
	var first_run := _select_cycle(first_resolver, library, 1, 80)
	var second_run := _select_cycle(second_resolver, library, 1, 80)
	var alternate_run := _select_cycle(alternate_resolver, library, 1, 80)
	_expect(first_run == second_run, "The same shuffle seed produces a reproducible route")
	_expect(first_run != alternate_run, "A different shuffle seed produces a different safe route")
	_expect(first_run.size() == 80, "Every selection cycle finds a reachable formation")
	for index in first_run.size():
		var selection: Dictionary = first_run[index]
		_expect(selection.entry_lanes.has(selection.selected_from_lane), "Selected formation accepts its current player lane")
		if index > 0:
			_expect(selection.pattern_id != first_run[index - 1].pattern_id, "Selection never repeats a formation immediately")


func _select_cycle(resolver: RefCounted, library: Array, start_lane: int, count: int) -> Array:
	var selected: Array = []
	var current_lane := start_lane
	for _index in count:
		var formation: Dictionary = resolver.select_next(library, current_lane)
		if formation.is_empty():
			break
		formation["selected_from_lane"] = current_lane
		selected.append(formation)
		current_lane = int(formation.ending_lane)
	return selected


func _test_unfinished_target_preference(resolver_script: Script) -> void:
	var resolver: RefCounted = resolver_script.new()
	_expect(resolver.has_method("select_next_for_targets"), "Resolver supports remaining-target route selection")
	if not resolver.has_method("select_next_for_targets"):
		return
	resolver.call("set_seed", 5)
	var library: Array = (load(L01_PATH) as Resource).get_pattern_definitions()
	var remaining := {&"move_left": 0, &"move_right": 0, &"jump": 2, &"slide": 0}
	var formation: Dictionary = resolver.call("select_next_for_targets", library, 1, remaining, false)
	_expect(formation.get("required_action", &"") == &"jump", "Route selection prefers an unfinished prescribed action when reachable")


func _test_gentle_opening_and_lateral_variety(resolver_script: Script) -> void:
	var resolver: RefCounted = resolver_script.new()
	resolver.call("set_seed", 99)
	var library: Array = (load(L01_PATH) as Resource).get_pattern_definitions()
	var current_lane := 1
	var actions: Array[StringName] = []
	for index in 30:
		var formation: Dictionary = resolver.call("select_next", library, current_lane)
		_expect(not formation.is_empty(), "Fair route selection finds a reachable formation")
		if formation.is_empty():
			return
		if index < 4:
			_expect(formation.get("category", &"") == &"beginner", "Opening formation %d remains beginner-friendly" % (index + 1))
		actions.append(StringName(formation.get("required_action", &"")))
		current_lane = int(formation.get("ending_lane", current_lane))
	for index in range(2, actions.size()):
		var a := actions[index - 2]
		var b := actions[index - 1]
		var c := actions[index]
		var all_lateral := a in [&"move_left", &"move_right"] and b in [&"move_left", &"move_right"] and c in [&"move_left", &"move_right"]
		_expect(not all_lateral, "Route never asks for three lateral moves in succession")
		_expect(not (a == c and a in [&"move_left", &"move_right"] and b in [&"move_left", &"move_right"]), "Route avoids left-right-left or right-left-right oscillation")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
