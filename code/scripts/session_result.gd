class_name SessionResult
extends RefCounted

const SessionConfigModel = preload("res://scripts/session_config.gd")

var completed_repetitions: Dictionary[StringName, int] = {}
var neutral_misses := 0
var rpe := 0


func _init() -> void:
	for action_name in SessionConfigModel.ACTIONS:
		completed_repetitions[action_name] = 0


func record_success(action_name: StringName) -> bool:
	if not SessionConfigModel.ACTIONS.has(action_name):
		return false

	completed_repetitions[action_name] = get_completed(action_name) + 1
	return true


func record_neutral_miss() -> void:
	neutral_misses += 1


func get_completed(action_name: StringName) -> int:
	return completed_repetitions.get(action_name, 0)


func has_met_targets(config) -> bool:
	for action_name in SessionConfigModel.ACTIONS:
		if get_completed(action_name) < config.get_target(action_name):
			return false
	return true


func set_rpe(value: Variant) -> bool:
	if typeof(value) != TYPE_INT:
		return false

	var rating := int(value)
	if rating < 1 or rating > 10:
		return false

	rpe = rating
	return true
