class_name PatternLibraryResolver
extends RefCounted

const Pattern = preload("res://scripts/pattern_definition.gd")

var _next_index := 0
var _last_pattern_id: StringName = &""
var _last_layout_key := ""
var _last_action: StringName = &""
var _random := RandomNumberGenerator.new()


func _init() -> void:
	_random.randomize()


func reset() -> void:
	_next_index = 0
	_last_pattern_id = &""
	_last_layout_key = ""
	_last_action = &""


func set_seed(seed: int) -> void:
	_random.seed = seed
	reset()


func select_next(library: Array, current_lane: int) -> Dictionary:
	if current_lane < 0 or current_lane > 2 or library.is_empty():
		return {}
	var candidates := _get_reachable_candidates(library, current_lane)
	if candidates.is_empty():
		return {}
	var varied_candidates := candidates.filter(func(candidate: Dictionary) -> bool:
		return _get_layout_key(candidate) != _last_layout_key and StringName(candidate.get("required_action", &"")) != _last_action
	)
	if varied_candidates.is_empty():
		varied_candidates = candidates.filter(func(candidate: Dictionary) -> bool: return _get_layout_key(candidate) != _last_layout_key)
	var selected_pool: Array = varied_candidates if not varied_candidates.is_empty() else candidates
	var selected: Dictionary = selected_pool[_random.randi_range(0, selected_pool.size() - 1)]
	_next_index = (_next_index + 1) % library.size()
	_last_pattern_id = StringName(selected.get("pattern_id", &""))
	_last_layout_key = _get_layout_key(selected)
	_last_action = StringName(selected.get("required_action", &""))
	return selected.duplicate(true)


func _get_reachable_candidates(library: Array, current_lane: int) -> Array:
	var candidates: Array = []
	for candidate_value in library:
		if not candidate_value is Dictionary:
			continue
		var candidate: Dictionary = candidate_value
		if not Pattern.validate(candidate).is_empty():
			continue
		var pattern_id := StringName(candidate.get("pattern_id", &""))
		var entry_lanes: Array = candidate.get("entry_lanes", [])
		if pattern_id == _last_pattern_id or not entry_lanes.has(current_lane):
			continue
		candidates.append(candidate)
	return candidates


func _get_layout_key(pattern: Dictionary) -> String:
	var lanes := ["none", "none", "none"]
	for obstacle_value in pattern.get("obstacles", []):
		if obstacle_value is Dictionary:
			var obstacle: Dictionary = obstacle_value
			var lane := int(obstacle.get("lane", -1))
			if lane >= 0 and lane < lanes.size():
				lanes[lane] = String(obstacle.get("kind", &"unknown"))
	return "|".join(lanes)
