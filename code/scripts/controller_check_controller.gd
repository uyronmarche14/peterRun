class_name ControllerCheckController
extends Control

const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"
const READY_SCENE_PATH := "res://scenes/ready.tscn"
const InputAdapterModel = preload("res://scripts/input_adapter.gd")

const ACTION_TILE_NAMES := {
	&"move_left": "MovementGrid/MoveLeft",
	&"move_right": "MovementGrid/MoveRight",
	&"jump": "MovementGrid/Jump",
	&"slide": "MovementGrid/Slide",
	&"pause_session": "Pause",
}

@onready var keyboard_fallback_button: Button = $Panel/Margin/Content/KeyboardFallbackButton
@onready var back_button: Button = $Panel/Margin/Content/BackButton
@onready var reset_button: Button = $Panel/Margin/Content/ResetButton
@onready var controller_status: Label = $Panel/Margin/Content/ControllerSummary/ControllerStatus
@onready var status_detail: Label = $Panel/Margin/Content/ControllerSummary/StatusDetail

var input_adapter: RefCounted
var detected_actions: Dictionary[StringName, bool] = {}


func _ready() -> void:
	input_adapter = InputAdapterModel.new()
	keyboard_fallback_button.pressed.connect(continue_to_ready)
	back_button.pressed.connect(return_to_patient_setup)
	reset_button.pressed.connect(reset_action_check)
	_refresh_control_status()
	_refresh_action_tiles()


func _unhandled_input(event: InputEvent) -> void:
	for action_name in InputAdapterModel.ACCEPTED_ACTIONS:
		if event.is_action_pressed(action_name):
			receive_test_action(action_name, true, Time.get_ticks_msec() / 1000.0)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_released(action_name):
			receive_test_action(action_name, false, Time.get_ticks_msec() / 1000.0)
			get_viewport().set_input_as_handled()
			return


func get_tutorial_scene_path() -> String:
	return TUTORIAL_SCENE_PATH


func get_ready_scene_path() -> String:
	return READY_SCENE_PATH


func get_control_support_summary(connected_controller_count: int = -1) -> String:
	var count := connected_controller_count
	if count < 0:
		count = Input.get_connected_joypads().size()
	var availability := "A compatible controller is connected." if count > 0 else "Connect a compatible controller to test it."
	return "Keyboard: A / D / W / S, P pause.\nController: D-pad, A / B, Start. MOVE HID keys. " + availability


func _refresh_control_status() -> void:
	var connected_count := Input.get_connected_joypads().size()
	var source_status := "Controller ready" if connected_count > 0 else "Keyboard fallback ready"
	controller_status.text = "%d of %d actions detected · %s" % [detected_actions.size(), ACTION_TILE_NAMES.size(), source_status]
	status_detail.text = get_control_support_summary(connected_count)


func receive_test_action(source_action: StringName, pressed: bool, now_seconds: float) -> void:
	if input_adapter == null:
		return
	if not pressed:
		input_adapter.release_action(source_action)
		return
	var logical_action: StringName = input_adapter.accept_action(source_action, now_seconds)
	if logical_action == &"" or not ACTION_TILE_NAMES.has(logical_action):
		return
	detected_actions[logical_action] = true
	_refresh_control_status()
	_refresh_action_tiles()


func reset_action_check() -> void:
	detected_actions.clear()
	input_adapter = InputAdapterModel.new()
	_refresh_control_status()
	_refresh_action_tiles()


func _refresh_action_tiles() -> void:
	for action_name in ACTION_TILE_NAMES:
		var tile := get_node("Panel/Margin/Content/ActionTiles/" + ACTION_TILE_NAMES[action_name]) as PanelContainer
		var status := tile.get_node("Content/Status") as Label
		var detected := detected_actions.has(action_name)
		status.text = "Detected" if detected else "Waiting"
		tile.modulate = Color(0.78, 1.0, 0.86, 1.0) if detected else Color.WHITE


func continue_to_tutorial() -> void:
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)


func continue_to_ready() -> void:
	get_tree().change_scene_to_file(READY_SCENE_PATH)


func return_to_patient_setup() -> void:
	get_tree().change_scene_to_file(PATIENT_SETUP_SCENE_PATH)
