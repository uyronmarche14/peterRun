class_name ControllerCheckController
extends Control

const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"

@onready var keyboard_fallback_button: Button = $Panel/Margin/Content/KeyboardFallbackButton
@onready var back_button: Button = $Panel/Margin/Content/BackButton


func _ready() -> void:
	keyboard_fallback_button.pressed.connect(continue_to_tutorial)
	back_button.pressed.connect(return_to_patient_setup)


func get_tutorial_scene_path() -> String:
	return TUTORIAL_SCENE_PATH


func continue_to_tutorial() -> void:
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)


func return_to_patient_setup() -> void:
	get_tree().change_scene_to_file(PATIENT_SETUP_SCENE_PATH)
