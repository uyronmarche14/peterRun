class_name PatternLibraryResolver
extends RefCounted

const Pattern = preload("res://scripts/pattern_definition.gd")

var _next_index := 0
var _last_pattern_id: StringName = &""


func reset() -> void:
	_next_index = 0
	_last_pattern_id = &""


func select_next(library: Array, current_lane: int) -> Dictionary:
	if current_lane < 0 or current_lane > 2 or library.is_empty():
		return {}
	for offset in library.size():
		var index := posmod(_next_index + offset, library.size())
		var candidate_value: Variant = library[index]
		if not candidate_value is Dictionary:
			continue
		var candidate: Dictionary = candidate_value
		if not Pattern.validate(candidate).is_empty():
			continue
		var pattern_id := StringName(candidate.get("pattern_id", &""))
		var entry_lanes: Array = candidate.get("entry_lanes", [])
		if pattern_id == _last_pattern_id or not entry_lanes.has(current_lane):
			continue
		_next_index = (index + 1) % library.size()
		_last_pattern_id = pattern_id
		return candidate.duplicate(true)
	return {}
