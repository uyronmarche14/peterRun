class_name TutorialController
extends Control

const CONTROLLER_CHECK_SCENE_PATH := "res://scenes/controller_check.tscn"
const READY_SCENE_PATH := "res://scenes/ready.tscn"
const InputAdapterModel = preload("res://scripts/input_adapter.gd")
const Store = preload("res://scripts/session_setup_store.gd")
const Config = preload("res://scripts/session_config.gd")
const PRACTICE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"jump", &"slide"]

const ACTIONS: Array[Dictionary] = [
	{
		"icon": "‹",
		"label": "MOVE LEFT",
	},
	{
		"icon": "›",
		"label": "MOVE RIGHT",
	},
	{
		"icon": "▲",
		"label": "JUMP",
	},
	{
		"icon": "▼",
		"label": "SLIDE",
	},
]

var current_action_index := 0
var is_tutorial_paused := false
var step_completed := false
var input_adapter: RefCounted

@onready var progress_label: Label = $Panel/Margin/Content/ProgressLabel
@onready var action_icon_label: Label = $Panel/Margin/Content/ActionCard/ActionIconLabel
@onready var action_label: Label = $Panel/Margin/Content/ActionCard/ActionLabel
@onready var instruction_label: Label = $Panel/Margin/Content/ActionCard/InstructionLabel
@onready var tutorial_status: Label = $Panel/Margin/Content/TutorialStatus
@onready var previous_button: Button = $Panel/Margin/Content/NavigationRow/PreviousButton
@onready var next_button: Button = $Panel/Margin/Content/NavigationRow/NextButton
@onready var skip_button: Button = $Panel/Margin/Content/UtilityRow/SkipButton
@onready var pause_tutorial_button: Button = $Panel/Margin/Content/UtilityRow/PauseTutorialButton
@onready var back_button: Button = $Panel/Margin/Content/UtilityRow/BackButton
@onready var repeat_button: Button = $Panel/Margin/Content/NavigationRow/RepeatButton
@onready var practice_area: Control = $Panel/Margin/Content/ActionCard/PracticeArea
@onready var practice_canvas: Node2D = $Panel/Margin/Content/ActionCard/PracticeArea/PracticeCanvas
@onready var practice_player: Node2D = $Panel/Margin/Content/ActionCard/PracticeArea/PracticeCanvas/Player
@onready var target_marker: Node2D = $Panel/Margin/Content/ActionCard/PracticeArea/PracticeCanvas/TargetMarker
@onready var puddle: Node2D = $Panel/Margin/Content/ActionCard/PracticeArea/PracticeCanvas/Puddle
@onready var overhead: Node2D = $Panel/Margin/Content/ActionCard/PracticeArea/PracticeCanvas/Overhead


func _ready() -> void:
	input_adapter = InputAdapterModel.new(Store.get_session_config().affected_side)
	previous_button.pressed.connect(show_previous_action)
	next_button.pressed.connect(show_next_action)
	skip_button.pressed.connect(skip_to_ready)
	pause_tutorial_button.pressed.connect(toggle_tutorial_pause)
	back_button.pressed.connect(return_to_controller_check)
	repeat_button.pressed.connect(repeat_action)
	practice_area.resized.connect(_centre_practice)
	_centre_practice()
	show_action_index(0)


func _centre_practice() -> void:
	practice_canvas.position.x = (practice_area.size.x - 480.0 * practice_canvas.scale.x) / 2.0


func _unhandled_input(event: InputEvent) -> void:
	for action in InputAdapterModel.ACCEPTED_ACTIONS:
		if event.is_action_pressed(action):
			receive_practice_input(action, true, Time.get_ticks_msec() / 1000.0)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_released(action):
			receive_practice_input(action, false, Time.get_ticks_msec() / 1000.0)
			get_viewport().set_input_as_handled()
			return


func receive_practice_input(source_action: StringName, pressed: bool, now_seconds: float) -> void:
	if not pressed:
		input_adapter.release_action(source_action)
		return
	var action: StringName = input_adapter.accept_action(source_action, now_seconds)
	if action == &"pause_session":
		toggle_tutorial_pause()
		return
	if action == &"" or is_tutorial_paused or step_completed:
		return
	if action != PRACTICE_ACTIONS[current_action_index]:
		tutorial_status.text = "Take your time. Try the highlighted movement."
		return
	if practice_player.handle_action(action):
		step_completed = true
		target_marker.modulate = Color(0.45, 0.9, 0.7)
		_refresh_status()


func repeat_action() -> void:
	show_action_index(current_action_index)


func get_ready_scene_path() -> String:
	return READY_SCENE_PATH


func show_action_index(index: int) -> void:
	if is_tutorial_paused:
		return
	current_action_index = clampi(index, 0, ACTIONS.size() - 1)
	step_completed = false
	practice_player.reset_for_practice()
	var action: Dictionary = ACTIONS[current_action_index]
	action_icon_label.text = action["icon"]
	action_label.text = action["label"]
	instruction_label.text = _practice_instruction()
	progress_label.text = "Action %d of %d" % [current_action_index + 1, ACTIONS.size()]
	target_marker.position = Vector2(128.0 if current_action_index == 0 else 352.0 if current_action_index == 1 else 240.0, 107.0)
	target_marker.modulate = Color(1.0, 0.8, 0.4)
	puddle.visible = current_action_index == 2
	overhead.visible = current_action_index == 3
	next_button.text = "Continue" if current_action_index == ACTIONS.size() - 1 else "Next"
	_refresh_status()


func _practice_instruction() -> String:
	var left_affected: bool = input_adapter.affected_side == Config.AffectedSide.LEFT
	match current_action_index:
		0:
			return "Press %s to move to the left marker." % ("D" if left_affected else "A")
		1:
			return "Press %s to move to the right marker." % ("A" if left_affected else "D")
		2:
			return "Press W to jump over the puddle."
	return "Press S to slide under the laundry line."


func _refresh_status() -> void:
	previous_button.disabled = is_tutorial_paused or current_action_index == 0
	repeat_button.disabled = is_tutorial_paused
	next_button.disabled = is_tutorial_paused or not step_completed
	if is_tutorial_paused:
		tutorial_status.text = "Practice paused. Resume when ready."
	elif step_completed:
		tutorial_status.text = "Nicely done! Repeat or choose %s." % next_button.text
	else:
		tutorial_status.text = "Your turn. No timer and no penalties."


func show_previous_action() -> void:
	show_action_index(current_action_index - 1)


func show_next_action() -> void:
	if is_tutorial_paused or not step_completed:
		return
	if current_action_index == ACTIONS.size() - 1:
		skip_to_ready()
		return
	show_action_index(current_action_index + 1)


func skip_to_ready() -> void:
	get_tree().change_scene_to_file(READY_SCENE_PATH)


func toggle_tutorial_pause() -> void:
	is_tutorial_paused = not is_tutorial_paused
	practice_player.set_gameplay_paused(is_tutorial_paused)
	pause_tutorial_button.text = "Resume Tutorial" if is_tutorial_paused else "Pause Tutorial"
	_refresh_status()


func return_to_controller_check() -> void:
	get_tree().change_scene_to_file(CONTROLLER_CHECK_SCENE_PATH)
