extends RefCounted

const Config = preload("res://scripts/session_config.gd")
const Result = preload("res://scripts/session_result.gd")

# Latest review only. No patient identifiers, disk storage, or automatic progression.
static var _config: Variant = null
static var _result: Variant = null
static var _end_reason: StringName = &""
static var _decision: StringName = &""


static func capture(config, result, end_reason: StringName) -> void:
	_config = Config.new()
	_config.affected_side = config.affected_side
	_config.selected_level_id = config.selected_level_id
	_config.level_definition = config.level_definition.duplicate(true) if config.level_definition != null else null
	_result = Result.new()
	for action in Config.ACTIONS:
		_config.set_target(action, config.get_target(action))
		_result.completed_repetitions[action] = result.get_completed(action)
	_result.neutral_misses = result.neutral_misses
	_result.rpe = result.rpe
	_end_reason = end_reason
	_decision = &""


static func get_config() -> Variant:
	return _config


static func get_result() -> Variant:
	return _result


static func get_end_reason() -> StringName:
	return _end_reason


static func get_decision() -> StringName:
	return _decision


static func set_decision(decision: StringName) -> void:
	if _result != null and decision in [&"rest", &"retry", &"finish"]:
		_decision = decision


static func reset() -> void:
	_config = null
	_result = null
	_end_reason = &""
	_decision = &""
