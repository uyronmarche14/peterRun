class_name SessionConfig
extends RefCounted

enum AffectedSide {
	RIGHT,
	LEFT,
}

const ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"jump",
	&"slide",
]
const DEFAULT_TARGET_REPETITIONS := 10

var affected_side: AffectedSide = AffectedSide.RIGHT
var selected_level_id: StringName = &"l01_barangay"
# Optional explicit definition for developer fixtures; normal play resolves the catalog ID.
var level_definition: Resource = null
var target_repetitions: Dictionary[StringName, int] = {}


func _init() -> void:
	for action_name in ACTIONS:
		target_repetitions[action_name] = DEFAULT_TARGET_REPETITIONS


func set_target(action_name: StringName, repetitions: int) -> bool:
	if not ACTIONS.has(action_name) or repetitions < 1:
		return false

	target_repetitions[action_name] = repetitions
	return true


func get_target(action_name: StringName) -> int:
	return target_repetitions.get(action_name, 0)
