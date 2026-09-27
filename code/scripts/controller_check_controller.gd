class_name ControllerCheckController
extends Control

const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"

@onready var keyboard_fallback_button: Button = $Panel/Margin/Content/KeyboardFallbackButton
@onready var back_button: Button = $Panel/Margin/Content/BackButton
@onready var controller_status: Label = $Panel/Margin/Content/ControllerSummary/ControllerStatus
@onready var status_detail: Label = $Panel/Margin/Content/ControllerSummary/StatusDetail


func _ready() -> void:
	keyboard_fallback_button.pressed.connect(continue_to_tutorial)
	back_button.pressed.connect(return_to_patient_setup)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh_control_status()


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh_control_status()


func get_tutorial_scene_path() -> String:
	return TUTORIAL_SCENE_PATH


func get_control_support_summary(connected_controller_count: int = -1) -> String:
	var count := connected_controller_count
	if count < 0:
		count = Input.get_connected_joypads().size()
	var availability := "A compatible controller is connected." if count > 0 else "Connect a compatible controller to test it."
	return "Keyboard: A / D / W / S, P pause.\nController: D-pad, A / B, Start. MOVE HID keys. " + availability


func _refresh_control_status() -> void:
	var connected_count := Input.get_connected_joypads().size()
	controller_status.text = "Controller ready" if connected_count > 0 else "Keyboard fallback ready"
	status_detail.text = get_control_support_summary(connected_count)


func continue_to_tutorial() -> void:
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)


func return_to_patient_setup() -> void:
	get_tree().change_scene_to_file(PATIENT_SETUP_SCENE_PATH)
