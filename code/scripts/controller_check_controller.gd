class_name ControllerCheckController
extends Control

const PATIENT_SETUP_SCENE_PATH := "res://scenes/patient_setup.tscn"
const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"
const READY_SCENE_PATH := "res://scenes/ready.tscn"
const InputAdapterModel = preload("res://scripts/input_adapter.gd")
const ControlHints = preload("res://scripts/control_hints.gd")

const ACTION_TILE_NAMES := {
	&"move_left": "MoveLeft",
	&"move_right": "MoveRight",
	&"jump": "Jump",
	&"slide": "Slide",
	&"pause_session": "Pause",
}
const DETECTED_COLOR := Color(0.083, 0.369, 0.388, 1)
const WAITING_COLOR := Color(0.36, 0.42, 0.42, 1)

@onready var keyboard_fallback_button: Button = %KeyboardFallbackButton
@onready var back_button: Button = %BackButton
@onready var reset_button: Button = %ResetButton
@onready var controller_status: Label = %ControllerStatus
@onready var status_detail: Label = %StatusDetail
@onready var action_tiles: HBoxContainer = %ActionTiles

var input_adapter: RefCounted
var detected_actions: Dictionary[StringName, bool] = {}
var _waiting_style: StyleBox
var _detected_style: StyleBoxFlat


func _ready() -> void:
	input_adapter = InputAdapterModel.new()
	_waiting_style = action_tiles.get_child(0).get_theme_stylebox("panel")
	_detected_style = _waiting_style.duplicate()
	_detected_style.bg_color = Color(0.85, 0.93, 0.87, 1)
	_detected_style.border_color = DETECTED_COLOR
	keyboard_fallback_button.pressed.connect(continue_to_ready)
	back_button.pressed.connect(return_to_patient_setup)
	reset_button.pressed.connect(reset_action_check)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_refresh_control_status()
	_refresh_action_tiles()


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh_control_status()
	_refresh_action_tiles()


# _input runs before GUI focus navigation, so D-pad tests never move focus.
# Every action is checked: one stick axis is a press of one lane and a
# release of the other.
func _input(event: InputEvent) -> void:
	var handled := false
	for action_name in InputAdapterModel.ACCEPTED_ACTIONS:
		if event.is_action_pressed(action_name):
			receive_test_action(action_name, true, Time.get_ticks_msec() / 1000.0)
			handled = true
		elif event.is_action_released(action_name):
			receive_test_action(action_name, false, Time.get_ticks_msec() / 1000.0)
			handled = true
	if handled:
		get_viewport().set_input_as_handled()


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
	var gamepad := ControlHints.uses_gamepad()
	controller_status.text = "%d of %d detected · %s" % [detected_actions.size(), ACTION_TILE_NAMES.size(), "Controller" if gamepad else "Keyboard"]
	status_detail.text = ControlHints.footer_text(gamepad) if gamepad else "Keyboard or MOVE controller: A D W S to move · P to pause"


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
	var gamepad := ControlHints.uses_gamepad()
	for action_name in ACTION_TILE_NAMES:
		var tile := action_tiles.get_node(ACTION_TILE_NAMES[action_name]) as PanelContainer
		var detected := detected_actions.has(action_name)
		var status := tile.get_node("Content/Status") as Label
		status.text = "✓ Detected" if detected else "Waiting"
		status.add_theme_color_override("font_color", DETECTED_COLOR if detected else WAITING_COLOR)
		(tile.get_node("Content/Keys") as Label).text = _keys_for(action_name, gamepad)
		tile.add_theme_stylebox_override("panel", _detected_style if detected else _waiting_style)


func _keys_for(action_name: StringName, gamepad: bool) -> String:
	var key := ControlHints.input_name(action_name, false)
	if not gamepad:
		return key
	var pad := ControlHints.input_name(action_name, true)
	if action_name == &"move_left" or action_name == &"move_right":
		pad = "D-pad"
	return "%s · %s" % [key, pad.trim_prefix("the ").trim_suffix(" button")]


func continue_to_tutorial() -> void:
	get_tree().change_scene_to_file(TUTORIAL_SCENE_PATH)


func continue_to_ready() -> void:
	get_tree().change_scene_to_file(READY_SCENE_PATH)


func return_to_patient_setup() -> void:
	get_tree().change_scene_to_file(PATIENT_SETUP_SCENE_PATH)
