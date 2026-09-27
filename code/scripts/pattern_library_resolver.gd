class_name PatternLibraryResolver
extends RefCounted

const Pattern = preload("res://scripts/pattern_definition.gd")

var _next_index := 0
var _last_pattern_id: StringName = &""
var _last_layout_key := ""
var _last_action: StringName = &""
var _selection_count := 0
var _recent_actions: Array[StringName] = []
var _random := RandomNumberGenerator.new()


func _init() -> void:
	_random.randomize()


func reset() -> void:
	_next_index = 0
	_last_pattern_id = &""
	_last_layout_key = ""
	_last_action = &""
	_selection_count = 0
	_recent_actions.clear()


func set_seed(seed: int) -> void:
	_random.seed = seed
	reset()


func select_next(library: Array, current_lane: int) -> Dictionary:
	return _select_from_candidates(_get_reachable_candidates(library, current_lane))


func select_next_for_targets(library: Array, current_lane: int, remaining_targets: Dictionary, prefer_recovery: bool = false) -> Dictionary:
	if current_lane < 0 or current_lane > 2 or library.is_empty():
		return {}
	var candidates := _get_reachable_candidates(library, current_lane)
	var unfinished_candidates := candidates.filter(func(candidate: Dictionary) -> bool:
		return int(remaining_targets.get(StringName(candidate.get("required_action", &"")), 0)) > 0
	)
	if not unfinished_candidates.is_empty():
		candidates = unfinished_candidates
	if prefer_recovery:
		var recovery_candidates := candidates.filter(func(candidate: Dictionary) -> bool: return candidate.get("category", &"") == &"recovery")
		if not recovery_candidates.is_empty():
			candidates = recovery_candidates
	return _select_from_candidates(candidates)


func _select_from_candidates(candidates: Array) -> Dictionary:
	if candidates.is_empty():
		return {}
	var fair_candidates := _apply_gentle_pacing(candidates)
	var varied_candidates := fair_candidates.filter(func(candidate: Dictionary) -> bool:
		return _get_layout_key(candidate) != _last_layout_key and StringName(candidate.get("required_action", &"")) != _last_action
	)
	if varied_candidates.is_empty():
		varied_candidates = fair_candidates.filter(func(candidate: Dictionary) -> bool: return _get_layout_key(candidate) != _last_layout_key)
	var selected_pool: Array = varied_candidates if not varied_candidates.is_empty() else fair_candidates
	var selected: Dictionary = selected_pool[_random.randi_range(0, selected_pool.size() - 1)]
	_next_index += 1
	_selection_count += 1
	_last_pattern_id = StringName(selected.get("pattern_id", &""))
	_last_layout_key = _get_layout_key(selected)
	_last_action = StringName(selected.get("required_action", &""))
	_recent_actions.append(_last_action)
	while _recent_actions.size() > 2:
		_recent_actions.pop_front()
	return selected.duplicate(true)


func _apply_gentle_pacing(candidates: Array) -> Array:
	var paced: Array = candidates
	if _selection_count < 4:
		var beginner_candidates := paced.filter(func(candidate: Dictionary) -> bool: return candidate.get("category", &"") == &"beginner")
		if not beginner_candidates.is_empty():
			paced = beginner_candidates
	if _recent_actions.size() >= 2 and _are_lateral(_recent_actions[0]) and _are_lateral(_recent_actions[1]):
		var non_lateral := paced.filter(func(candidate: Dictionary) -> bool: return not _are_lateral(StringName(candidate.get("required_action", &""))))
		if not non_lateral.is_empty():
			paced = non_lateral
	if _recent_actions.size() >= 2 and _are_lateral(_recent_actions[0]) and _are_lateral(_recent_actions[1]):
		var no_oscillation := paced.filter(func(candidate: Dictionary) -> bool: return StringName(candidate.get("required_action", &"")) != _recent_actions[0])
		if not no_oscillation.is_empty():
			paced = no_oscillation
	return paced


func _are_lateral(action_name: StringName) -> bool:
	return action_name == &"move_left" or action_name == &"move_right"


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
