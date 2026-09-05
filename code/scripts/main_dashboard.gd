class_name MainDashboard
extends Control

const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"

@onready var session_status: Label = $Dashboard/Margin/Content/SessionStatus
@onready var start_session_button: Button = $Dashboard/Margin/Content/StartSessionButton
@onready var tutorial_button: Button = $Dashboard/Margin/Content/TutorialButton
@onready var settings_button: Button = $Dashboard/Margin/Content/SettingsButton
@onready var quit_button: Button = $Dashboard/Margin/Content/QuitButton


func _ready() -> void:
	start_session_button.pressed.connect(open_patient_setup)
	tutorial_button.pressed.connect(show_coming_soon.bind("Tutorial will be available in PR-10."))
	settings_button.pressed.connect(open_patient_setup)
	quit_button.pressed.connect(get_tree().quit)


func get_patient_setup_scene_path() -> String:
	return PATIENT_SETUP_SCENE_PATH


func open_patient_setup() -> void:
	var result := get_tree().change_scene_to_file(PATIENT_SETUP_SCENE_PATH)
	if result != OK:
		session_status.text = "Unable to open Patient Setup. Please restart the app."


func show_coming_soon(message: String) -> void:
	session_status.text = message
