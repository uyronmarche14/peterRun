class_name TutorialController
extends Control

const CONTROLLER_CHECK_SCENE_PATH := "res://scenes/controller_check.tscn"
const READY_SCENE_PATH := "res://scenes/ready.tscn"

const ACTIONS: Array[Dictionary] = [
	{
		"icon": "‹",
		"label": "MOVE LEFT",
		"instruction": "Move one lane to the left when this prompt appears.",
	},
	{
		"icon": "›",
		"label": "MOVE RIGHT",
		"instruction": "Move one lane to the right when this prompt appears.",
	},
	{
		"icon": "▲",
		"label": "JUMP",
		"instruction": "Take the forward-step action to clear a low prompt.",
	},
	{
		"icon": "▼",
		"label": "SLIDE",
		"instruction": "Use the slide action to pass safely under a low prompt.",
	},
]

var current_action_index := 0
var is_tutorial_paused := false

@onready var progress_label: Label = $Panel/Margin/Content/ProgressLabel
@onready var action_icon_label: Label = $Panel/Margin/Content/ActionCard/ActionIconLabel
@onready var action_label: Label = $Panel/Margin/Content/ActionCard/ActionLabel
@onready var instruction_label: Label = $Panel/Margin/Content/ActionCard/InstructionLabel
@onready var tutorial_status: Label = $Panel/Margin/Content/TutorialStatus
@onready var previous_button: Button = $Panel/Margin/Content/PreviousButton
@onready var next_button: Button = $Panel/Margin/Content/NextButton
@onready var skip_button: Button = $Panel/Margin/Content/SkipButton
@onready var pause_tutorial_button: Button = $Panel/Margin/Content/PauseTutorialButton
@onready var back_button: Button = $Panel/Margin/Content/BackButton


func _ready() -> void:
	previous_button.pressed.connect(show_previous_action)
	next_button.pressed.connect(show_next_action)
	skip_button.pressed.connect(skip_to_ready)
	pause_tutorial_button.pressed.connect(toggle_tutorial_pause)
	back_button.pressed.connect(return_to_controller_check)
	show_action_index(0)


func get_ready_scene_path() -> String:
	return READY_SCENE_PATH


func show_action_index(index: int) -> void:
	if is_tutorial_paused:
		return
	current_action_index = clampi(index, 0, ACTIONS.size() - 1)
	var action: Dictionary = ACTIONS[current_action_index]
	action_icon_label.text = action["icon"]
	action_label.text = action["label"]
	instruction_label.text = action["instruction"]
	progress_label.text = "Action %d of %d" % [current_action_index + 1, ACTIONS.size()]
	tutorial_status.text = "No countdown. Review at a comfortable pace."
	previous_button.disabled = current_action_index == 0
	next_button.text = "Continue" if current_action_index == ACTIONS.size() - 1 else "Next"


func show_previous_action() -> void:
	show_action_index(current_action_index - 1)


func show_next_action() -> void:
	if is_tutorial_paused:
		return
	if current_action_index == ACTIONS.size() - 1:
		skip_to_ready()
		return
	show_action_index(current_action_index + 1)


func skip_to_ready() -> void:
	get_tree().change_scene_to_file(READY_SCENE_PATH)


func toggle_tutorial_pause() -> void:
	is_tutorial_paused = not is_tutorial_paused
	pause_tutorial_button.text = "Resume Tutorial" if is_tutorial_paused else "Pause Tutorial"
	tutorial_status.text = "Tutorial paused. Resume when ready." if is_tutorial_paused else "No countdown. Review at a comfortable pace."
	previous_button.disabled = is_tutorial_paused or current_action_index == 0
	next_button.disabled = is_tutorial_paused


func return_to_controller_check() -> void:
	get_tree().change_scene_to_file(CONTROLLER_CHECK_SCENE_PATH)
