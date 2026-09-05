class_name MainDashboard
extends Control

const L01_PREVIEW_SCENE_PATH := "res://scenes/levels/runner_level.tscn"

@onready var session_status: Label = $Dashboard/Margin/Content/SessionStatus
@onready var play_l01_preview_button: Button = $Dashboard/Margin/Content/PlayL01PreviewButton
@onready var tutorial_button: Button = $Dashboard/Margin/Content/TutorialButton
@onready var settings_button: Button = $Dashboard/Margin/Content/SettingsButton
@onready var quit_button: Button = $Dashboard/Margin/Content/QuitButton


func _ready() -> void:
	play_l01_preview_button.pressed.connect(open_l01_preview)
	tutorial_button.pressed.connect(show_coming_soon.bind("Tutorial will be available in PR-10."))
	settings_button.pressed.connect(show_coming_soon.bind("Therapist setup will be available in PR-09."))
	quit_button.pressed.connect(get_tree().quit)


func get_l01_preview_scene_path() -> String:
	return L01_PREVIEW_SCENE_PATH


func open_l01_preview() -> void:
	var result := get_tree().change_scene_to_file(L01_PREVIEW_SCENE_PATH)
	if result != OK:
		session_status.text = "Unable to open the L01 preview. Please restart the app."


func show_coming_soon(message: String) -> void:
	session_status.text = message
