class_name MainDashboard
extends Control

const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"

@onready var session_status: Label = $Dashboard/Margin/Content/SessionStatus
@onready var start_session_button: Button = $Dashboard/Margin/Content/StartSessionButton
@onready var tutorial_button: Button = $Dashboard/Margin/Content/SecondaryActions/TutorialButton
@onready var settings_button: Button = $Dashboard/Margin/Content/SecondaryActions/SettingsButton
@onready var quit_button: Button = $Dashboard/Margin/Content/SecondaryActions/QuitButton


func _ready() -> void:
	start_session_button.pressed.connect(open_patient_setup)
	tutorial_button.pressed.connect(open_tutorial)
	settings_button.pressed.connect(open_patient_setup)
	quit_button.pressed.connect(get_tree().quit)


func get_patient_setup_scene_path() -> String:
	return PATIENT_SETUP_SCENE_PATH


func get_tutorial_scene_path() -> String:
	return TUTORIAL_SCENE_PATH


func open_patient_setup() -> void:
	var result := get_tree().change_scene_to_file(PATIENT_SETUP_SCENE_PATH)
	if result != OK:
		session_status.text = "Unable to open Patient Setup. Please restart the app."


func open_tutorial() -> void:
	var result := get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)
	if result != OK:
		session_status.text = "Unable to open Tutorial. Please restart the app."


func show_coming_soon(message: String) -> void:
	session_status.text = message
