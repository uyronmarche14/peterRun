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
# Why the last press was not accepted: held, cooldown, unknown, or empty when accepted.
var last_rejection: StringName = &""
var _held_actions: Dictionary[StringName, bool] = {}
var _last_accepted_at: Dictionary[StringName, float] = {}


func _init(initial_affected_side: int = SessionConfigModel.AffectedSide.RIGHT, initial_cooldown_seconds: float = 0.35) -> void:
	affected_side = initial_affected_side
	cooldown_seconds = maxf(initial_cooldown_seconds, 0.0)


func accept_action(source_action: StringName, now_seconds: float) -> StringName:
	last_rejection = &""
	if not ACCEPTED_ACTIONS.has(source_action):
		last_rejection = &"unknown"
		return &""
	if _held_actions.has(source_action):
		last_rejection = &"held"
		return &""

	_held_actions[source_action] = true
	var last_accepted_at := float(_last_accepted_at.get(source_action, -INF))
	if now_seconds < last_accepted_at + cooldown_seconds:
		last_rejection = &"cooldown"
		return &""
	_last_accepted_at[source_action] = now_seconds
	return _map_affected_side(source_action)


func release_action(source_action: StringName) -> void:
	_held_actions.erase(source_action)


func _map_affected_side(source_action: StringName) -> StringName:
	# Physical directions remain literal for every session. Affected side is
	# recorded for setup/review, not used to reverse Left and Right in-game.
	return source_action
