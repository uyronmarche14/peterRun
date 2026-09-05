class_name ControllerCheckController
extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main.tscn"
const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"
const RUNNER_LEVEL_SCENE_PATH := "res://scenes/levels/runner_level.tscn"

@onready var keyboard_fallback_button: Button = $Panel/Margin/Content/KeyboardFallbackButton
@onready var back_button: Button = $Panel/Margin/Content/BackButton


func _ready() -> void:
	keyboard_fallback_button.pressed.connect(start_with_keyboard_fallback)
	back_button.pressed.connect(return_to_patient_setup)


func get_runner_scene_path() -> String:
	return RUNNER_LEVEL_SCENE_PATH


func start_with_keyboard_fallback() -> void:
	get_tree().change_scene_to_file(RUNNER_LEVEL_SCENE_PATH)


func return_to_patient_setup() -> void:
	get_tree().change_scene_to_file(PATIENT_SETUP_SCENE_PATH)
