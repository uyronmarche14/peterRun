class_name PlayerLaneState
extends RefCounted

enum Lane {
	LEFT,
	CENTER,
	RIGHT,
}

enum ActionState {
	IDLE,
	JUMP,
	SLIDE,
}

var lane_index: int = Lane.CENTER
var action_state: int = ActionState.IDLE


func handle_action(action_name: StringName) -> bool:
	match action_name:
		&"move_left":
			return _move_lane(-1)
		&"move_right":
			return _move_lane(1)
		&"jump":
			return _begin_action(ActionState.JUMP)
		&"slide":
			return _begin_action(ActionState.SLIDE)
		_:
			return false


func finish_action() -> void:
	action_state = ActionState.IDLE


func _move_lane(direction: int) -> bool:
	var next_lane := clampi(lane_index + direction, Lane.LEFT, Lane.RIGHT)
	if next_lane == lane_index:
		return false
	lane_index = next_lane
	return true


func _begin_action(next_action_state: int) -> bool:
	if action_state != ActionState.IDLE:
		return false
	action_state = next_action_state
	return true
