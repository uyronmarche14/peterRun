class_name PromptDirector
extends Node

const SessionConfigModel = preload("res://scripts/session_config.gd")

enum State {
	IDLE,
	WARNING,
	ACTIVE,
	RESOLVED,
}

enum Resolution {
	NONE,
	SUCCESS,
	NEUTRAL_MISS,
	SAFE_CLEAR,
}

signal prompt_state_changed(state: int, action_name: StringName, resolution: int)

var state: int = State.IDLE
var current_action: StringName = &""
var resolution: int = Resolution.NONE
var prompt_lane_index: int = -1
var safe_lane_index: int = -1
var allow_idle_safe_clear := false


func schedule(action_name: StringName, lane_index: int = -1, safe_lane: int = -1, idle_safe_clear: bool = false) -> bool:
	if state != State.IDLE or not SessionConfigModel.ACTIONS.has(action_name):
		return false

	current_action = action_name
	prompt_lane_index = lane_index if lane_index >= 0 and lane_index <= 2 else -1
	safe_lane_index = safe_lane if safe_lane >= 0 and safe_lane <= 2 else -1
	allow_idle_safe_clear = idle_safe_clear
	resolution = Resolution.NONE
	_set_state(State.WARNING)
	return true


func open_response_window() -> bool:
	if state != State.WARNING:
		return false

	_set_state(State.ACTIVE)
	return true


func receive_action(action_name: StringName, lane_index: int = -1, movement_accepted: bool = true) -> bool:
	if state != State.ACTIVE or not SessionConfigModel.ACTIONS.has(action_name):
		return false

	resolution = Resolution.SUCCESS if action_name == current_action and _is_spatially_correct(action_name, lane_index, movement_accepted) else Resolution.NEUTRAL_MISS
	_set_state(State.RESOLVED)
	return true


func expire_active_prompt(lane_index: int = -1) -> bool:
	if state != State.ACTIVE:
		return false

	if allow_idle_safe_clear and lane_index == safe_lane_index:
		resolution = Resolution.SAFE_CLEAR
	else:
		resolution = Resolution.NEUTRAL_MISS
	_set_state(State.RESOLVED)
	return true


func clear_resolved_prompt() -> bool:
	if state != State.RESOLVED:
		return false

	current_action = &""
	prompt_lane_index = -1
	safe_lane_index = -1
	allow_idle_safe_clear = false
	resolution = Resolution.NONE
	_set_state(State.IDLE)
	return true


func _set_state(next_state: int) -> void:
	state = next_state
	prompt_state_changed.emit(state, current_action, resolution)


func _is_spatially_correct(action_name: StringName, lane_index: int, movement_accepted: bool) -> bool:
	# Direct unit callers may omit lane context; gameplay always supplies it.
	if lane_index < 0 or prompt_lane_index < 0:
		return movement_accepted
	if not movement_accepted:
		return false
	match action_name:
		&"jump", &"slide":
			return lane_index == prompt_lane_index
		&"move_left":
			return lane_index == clampi(prompt_lane_index - 1, 0, 2)
		&"move_right":
			return lane_index == clampi(prompt_lane_index + 1, 0, 2)
	return false
