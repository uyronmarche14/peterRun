class_name ReadyScreenController
extends Control

const RUNNER_LEVEL_SCENE_PATH := "res://scenes/levels/runner_level.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"
const SessionConfigModel = preload("res://scripts/session_config.gd")
const SessionSetupStoreModel = preload("res://scripts/session_setup_store.gd")

@onready var session_details: Label = $Panel/Margin/Content/SessionDetails
@onready var start_session_button: Button = $Panel/Margin/Content/StartSessionButton
@onready var back_button: Button = $Panel/Margin/Content/BackButton


func _ready() -> void:
	_refresh_session_details()
	start_session_button.pressed.connect(start_session)
	back_button.pressed.connect(return_to_tutorial)


func get_runner_scene_path() -> String:
	return RUNNER_LEVEL_SCENE_PATH


func start_session() -> void:
	get_tree().change_scene_to_file(RUNNER_LEVEL_SCENE_PATH)


func return_to_tutorial() -> void:
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)


func _refresh_session_details() -> void:
	var config: Variant = SessionSetupStoreModel.get_session_config()
	var target_repetitions: int = int(config.get_target(&"jump"))
	var side_name := "Left" if config.affected_side == SessionConfigModel.AffectedSide.LEFT else "Right"
	session_details.text = "L01 Barangay Morning • %d reps/action • %s affected side" % [target_repetitions, side_name]
