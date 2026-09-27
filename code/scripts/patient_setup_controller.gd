class_name PatientSetupController
extends Control

const SessionConfigModel = preload("res://scripts/session_config.gd")
const SessionSetupStoreModel = preload("res://scripts/session_setup_store.gd")
const LevelCatalog = preload("res://data/levels/catalog.tres")

const CONTROLLER_CHECK_SCENE_PATH := "res://scenes/controller_check.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/main.tscn"
const MIN_TARGET_REPETITIONS := 10
const MAX_TARGET_REPETITIONS := 15

@onready var affected_side_option: OptionButton = $Panel/Margin/Content/AffectedSideOption
@onready var level_option: OptionButton = $Panel/Margin/Content/LevelOption
@onready var level_label: Label = $Panel/Margin/Content/LevelLabel
@onready var target_repetitions_spin_box: SpinBox = $Panel/Margin/Content/TargetRepetitionsSpinBox
@onready var session_summary: Label = $Panel/Margin/Content/SessionSummary
@onready var continue_button: Button = $Panel/Margin/Content/ContinueButton
@onready var back_button: Button = $Panel/Margin/Content/BackButton


func _ready() -> void:
	_configure_controls()
	continue_button.pressed.connect(continue_to_controller_check)
	back_button.pressed.connect(return_to_main_menu)


func get_controller_check_scene_path() -> String:
	return CONTROLLER_CHECK_SCENE_PATH


func set_affected_side(affected_side: int) -> void:
	var selected_index := 1 if affected_side == SessionConfigModel.AffectedSide.LEFT else 0
	affected_side_option.select(selected_index)
	_update_summary()


func set_target_repetitions(repetitions: int) -> void:
	target_repetitions_spin_box.value = clampi(repetitions, MIN_TARGET_REPETITIONS, MAX_TARGET_REPETITIONS)
	_update_summary()


func save_session_settings() -> void:
	SessionSetupStoreModel.configure(
		_get_selected_affected_side(),
		int(target_repetitions_spin_box.value),
		_get_selected_level_id()
	)
	_update_summary()


func continue_to_controller_check() -> void:
	save_session_settings()
	get_tree().change_scene_to_file(CONTROLLER_CHECK_SCENE_PATH)


func return_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _configure_controls() -> void:
	var current_config: Variant = SessionSetupStoreModel.get_session_config()
	affected_side_option.clear()
	affected_side_option.add_item("Right affected side", SessionConfigModel.AffectedSide.RIGHT)
	affected_side_option.add_item("Left affected side", SessionConfigModel.AffectedSide.LEFT)
	level_option.clear()
	var selected_level_index := 0
	for definition: Resource in LevelCatalog.levels:
		if definition == null or not definition.show_in_setup:
			continue
		level_option.add_item("%s · %s" % [definition.short_name, definition.title])
		level_option.set_item_metadata(level_option.item_count - 1, definition.level_id)
		if definition.level_id == current_config.selected_level_id:
			selected_level_index = level_option.item_count - 1
	level_option.select(selected_level_index)
	target_repetitions_spin_box.min_value = MIN_TARGET_REPETITIONS
	target_repetitions_spin_box.max_value = MAX_TARGET_REPETITIONS
	target_repetitions_spin_box.step = 1
	set_affected_side(current_config.affected_side)
	set_target_repetitions(current_config.get_target(&"jump"))
	_refresh_level_label()
	affected_side_option.item_selected.connect(_on_affected_side_selected)
	level_option.item_selected.connect(_on_level_selected)
	target_repetitions_spin_box.value_changed.connect(_on_target_repetitions_changed)


func _get_selected_affected_side() -> int:
	return affected_side_option.get_item_id(affected_side_option.selected)


func _refresh_level_label() -> void:
	var definition: Resource = LevelCatalog.find_level(_get_selected_level_id())
	level_label.text = "Route: " + (definition.title if definition != null else "Unavailable")


func _get_selected_level_id() -> StringName:
	return StringName(level_option.get_item_metadata(level_option.selected))


func _update_summary() -> void:
	if not is_instance_valid(session_summary):
		return
	var side_name := "left" if _get_selected_affected_side() == SessionConfigModel.AffectedSide.LEFT else "right"
	var per_action := int(target_repetitions_spin_box.value)
	session_summary.text = "%d per action · %d total · %s side" % [per_action, per_action * SessionConfigModel.ACTIONS.size(), side_name]


func _on_affected_side_selected(_index: int) -> void:
	_update_summary()


func _on_level_selected(_index: int) -> void:
	_refresh_level_label()
	_update_summary()


func _on_target_repetitions_changed(_value: float) -> void:
	_update_summary()
