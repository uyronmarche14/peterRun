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
}

signal prompt_state_changed(state: int, action_name: StringName, resolution: int)

var state: int = State.IDLE
var current_action: StringName = &""
var resolution: int = Resolution.NONE


func schedule(action_name: StringName) -> bool:
	if state != State.IDLE or not SessionConfigModel.ACTIONS.has(action_name):
		return false

	current_action = action_name
	resolution = Resolution.NONE
	_set_state(State.WARNING)
	return true


func open_response_window() -> bool:
	if state != State.WARNING:
		return false

	_set_state(State.ACTIVE)
	return true


func receive_action(action_name: StringName) -> bool:
	if state != State.ACTIVE or not SessionConfigModel.ACTIONS.has(action_name):
		return false

	resolution = Resolution.SUCCESS if action_name == current_action else Resolution.NEUTRAL_MISS
	_set_state(State.RESOLVED)
	return true


func expire_active_prompt() -> bool:
	if state != State.ACTIVE:
		return false

	resolution = Resolution.NEUTRAL_MISS
	_set_state(State.RESOLVED)
	return true


func clear_resolved_prompt() -> bool:
	if state != State.RESOLVED:
		return false

	current_action = &""
	resolution = Resolution.NONE
	_set_state(State.IDLE)
	return true


func _set_state(next_state: int) -> void:
	state = next_state
	prompt_state_changed.emit(state, current_action, resolution)
