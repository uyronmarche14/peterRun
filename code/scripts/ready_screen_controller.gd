class_name ReadyScreenController
extends Control

const RUNNER_LEVEL_SCENE_PATH := "res://scenes/levels/runner_level.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"
const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"
const CONTROLLER_CHECK_SCENE_PATH := "res://scenes/controller_check.tscn"
const SessionConfigModel = preload("res://scripts/session_config.gd")
const SessionSetupStoreModel = preload("res://scripts/session_setup_store.gd")
const LevelSelection = preload("res://scripts/level_selection.gd")

@onready var session_details: Label = $Panel/Margin/Content/SessionSummary/SessionDetails
@onready var start_session_button: Button = $Panel/Margin/Content/StartSessionButton
@onready var back_button: Button = $Panel/Margin/Content/BackButton
@onready var test_controls_button: Button = $Panel/Margin/Content/ControlsRow/TestControlsButton
@onready var practice_button: Button = $Panel/Margin/Content/ControlsRow/PracticeButton


func _ready() -> void:
	_refresh_session_details()
	start_session_button.pressed.connect(start_session)
	back_button.pressed.connect(return_to_setup)
	test_controls_button.pressed.connect(open_controller_check)
	practice_button.pressed.connect(return_to_tutorial)


func get_runner_scene_path() -> String:
	return RUNNER_LEVEL_SCENE_PATH


func start_session() -> void:
	if LevelSelection.resolve(SessionSetupStoreModel.get_session_config()) == null:
		_refresh_session_details()
		return
	get_tree().change_scene_to_file(RUNNER_LEVEL_SCENE_PATH)


func return_to_tutorial() -> void:
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)


func return_to_setup() -> void:
	get_tree().change_scene_to_file(PATIENT_SETUP_SCENE_PATH)


func open_controller_check() -> void:
	get_tree().change_scene_to_file(CONTROLLER_CHECK_SCENE_PATH)


func _refresh_session_details() -> void:
	var config: Variant = SessionSetupStoreModel.get_session_config()
	var definition: Resource = LevelSelection.resolve(config)
	start_session_button.disabled = definition == null
	if definition == null:
		session_details.text = "Level unavailable. Return to setup before starting."
		return
	start_session_button.text = "Start %s Session" % definition.short_name
	var target_repetitions: int = int(config.get_target(&"jump"))
	var side_name := "Left" if config.affected_side == SessionConfigModel.AffectedSide.LEFT else "Right"
	session_details.text = "%s %s • %d reps/action • %s affected side" % [definition.short_name, definition.title, target_repetitions, side_name]
