class_name SessionSetupStore
extends RefCounted

const SessionConfigModel = preload("res://scripts/session_config.gd")

static var _session_config: Variant = null


static func get_session_config() -> Variant:
	if _session_config == null:
		_session_config = SessionConfigModel.new()
	return _session_config


static func configure(affected_side: int, target_repetitions: int, selected_level_id: StringName = &"l01_barangay") -> Variant:
	var config := SessionConfigModel.new()
	config.affected_side = affected_side
	config.selected_level_id = selected_level_id
	for action_name in SessionConfigModel.ACTIONS:
		config.set_target(action_name, target_repetitions)
	_session_config = config
	return _session_config


static func reset() -> void:
	_session_config = SessionConfigModel.new()


static func restore_session_config(source) -> void:
	var config := SessionConfigModel.new()
	config.affected_side = source.affected_side
	config.selected_level_id = source.selected_level_id
	for action in SessionConfigModel.ACTIONS:
		config.set_target(action, source.get_target(action))
	_session_config = config
