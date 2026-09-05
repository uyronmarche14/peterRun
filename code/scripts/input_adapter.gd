class_name InputAdapter
extends RefCounted

const SessionConfigModel = preload("res://scripts/session_config.gd")

const ACCEPTED_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"jump",
	&"slide",
	&"pause_session",
]

var affected_side: int
var cooldown_seconds: float
var _held_actions: Dictionary[StringName, bool] = {}
var _last_accepted_at: Dictionary[StringName, float] = {}


func _init(initial_affected_side: int = SessionConfigModel.AffectedSide.RIGHT, initial_cooldown_seconds: float = 0.35) -> void:
	affected_side = initial_affected_side
	cooldown_seconds = maxf(initial_cooldown_seconds, 0.0)


func accept_action(source_action: StringName, now_seconds: float) -> StringName:
	if not ACCEPTED_ACTIONS.has(source_action) or _held_actions.has(source_action):
		return &""

	_held_actions[source_action] = true
	var last_accepted_at := float(_last_accepted_at.get(source_action, -INF))
	if now_seconds < last_accepted_at + cooldown_seconds:
		return &""

	_last_accepted_at[source_action] = now_seconds
	return _map_affected_side(source_action)


func release_action(source_action: StringName) -> void:
	_held_actions.erase(source_action)


func _map_affected_side(source_action: StringName) -> StringName:
	if affected_side != SessionConfigModel.AffectedSide.LEFT:
		return source_action

	if source_action == &"move_left":
		return &"move_right"
	if source_action == &"move_right":
		return &"move_left"
	return source_action
