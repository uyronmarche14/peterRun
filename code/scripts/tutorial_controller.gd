class_name TutorialController
extends Control

const CONTROLLER_CHECK_SCENE_PATH := "res://scenes/controller_check.tscn"
const READY_SCENE_PATH := "res://scenes/ready.tscn"
const InputAdapterModel = preload("res://scripts/input_adapter.gd")
const Store = preload("res://scripts/session_setup_store.gd")
const Config = preload("res://scripts/session_config.gd")
const Hints = preload("res://scripts/control_hints.gd")
const MenuFocus = preload("res://scripts/menu_focus.gd")
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
var is_demonstrating := false
var tutorial_started := false

@onready var progress_label: Label = $Panel/Margin/Content/ProgressLabel
@onready var welcome: VBoxContainer = $Panel/Margin/Content/Welcome
@onready var start_practice_button: Button = $Panel/Margin/Content/Welcome/Actions/StartPracticeButton
@onready var show_first_demo_button: Button = $Panel/Margin/Content/Welcome/Actions/ShowFirstDemoButton
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
@onready var demo_button: Button = $Panel/Margin/Content/NavigationRow/DemoButton
@onready var demo_timer: Timer = $DemoTimer
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
	demo_button.pressed.connect(demonstrate_action)
	start_practice_button.pressed.connect(start_practice)
	show_first_demo_button.pressed.connect(show_first_demo)
	demo_timer.timeout.connect(_on_demo_finished)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	practice_area.resized.connect(_centre_practice)
	_centre_practice()
	_show_welcome()


func _centre_practice() -> void:
	practice_canvas.position.x = (practice_area.size.x - 480.0 * practice_canvas.scale.x) / 2.0


# _input runs before GUI focus navigation, so a focused button cannot turn the
# D-pad (also bound to ui_left/ui_right) into menu movement. Every action is
# checked because one stick axis is both a press of one lane and a release of the other.
func _input(event: InputEvent) -> void:
	# On the welcome card A/B are menu buttons, not practice input.
	if not tutorial_started:
		return
	# During practice A/B are being practised, so Y (Triangle) is the gamepad Next.
	if MenuFocus.is_continue_alt(event):
		get_viewport().set_input_as_handled()
		show_next_action()
		return
	var handled := false
	for action in InputAdapterModel.ACCEPTED_ACTIONS:
		if event.is_action_pressed(action):
			receive_practice_input(action, true, Time.get_ticks_msec() / 1000.0)
			handled = true
		elif event.is_action_released(action):
			receive_practice_input(action, false, Time.get_ticks_msec() / 1000.0)
			handled = true
	if handled:
		get_viewport().set_input_as_handled()


func receive_practice_input(source_action: StringName, pressed: bool, now_seconds: float) -> void:
	if not tutorial_started:
		return
	if not pressed:
		input_adapter.release_action(source_action)
		return
	var action: StringName = input_adapter.accept_action(source_action, now_seconds)
	if action == &"pause_session":
		toggle_tutorial_pause()
		return
	if action == &"" or is_tutorial_paused or is_demonstrating or step_completed:
		return
	if action != PRACTICE_ACTIONS[current_action_index]:
		tutorial_status.text = "Take your time. Try the highlighted movement."
		return
	if practice_player.handle_action(action):
		step_completed = true
		target_marker.modulate = Color(0.45, 0.9, 0.7)
		_refresh_status()


func repeat_action() -> void:
	if not tutorial_started:
		return
	show_action_index(current_action_index)


func demonstrate_action() -> void:
	if not tutorial_started or is_tutorial_paused or is_demonstrating:
		return
	show_action_index(current_action_index)
	is_demonstrating = true
	# Visual example only: bypass input acknowledgement and never count a rep.
	practice_player.handle_action(PRACTICE_ACTIONS[current_action_index])
	demo_timer.start()
	_refresh_status()


func start_practice() -> void:
	if tutorial_started:
		return
	tutorial_started = true
	welcome.hide()
	progress_label.show()
	$Panel/Margin/Content/ActionCard.show()
	tutorial_status.show()
	$Panel/Margin/Content/NavigationRow.show()
	pause_tutorial_button.show()
	show_action_index(0)


func show_first_demo() -> void:
	start_practice()
	demonstrate_action()


func _show_welcome() -> void:
	tutorial_started = false
	welcome.show()
	progress_label.hide()
	$Panel/Margin/Content/ActionCard.hide()
	tutorial_status.hide()
	$Panel/Margin/Content/NavigationRow.hide()
	pause_tutorial_button.hide()
	MenuFocus.focus(start_practice_button)


func _unhandled_input(event: InputEvent) -> void:
	if MenuFocus.is_back(event):
		get_viewport().set_input_as_handled()
		return_to_controller_check()


func _on_demo_finished() -> void:
	if not is_demonstrating or is_tutorial_paused:
		return
	is_demonstrating = false
	practice_player.reset_for_practice()
	_refresh_status()


func get_ready_scene_path() -> String:
	return READY_SCENE_PATH


func show_action_index(index: int) -> void:
	if not tutorial_started or is_tutorial_paused or is_demonstrating:
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


func _practice_instruction(gamepad: bool = Hints.uses_gamepad()) -> String:
	var action: StringName = PRACTICE_ACTIONS[current_action_index]
	var input_name := Hints.input_name(_source_for(action), gamepad)
	match action:
		&"move_left":
			return "Press %s to move to the left marker." % input_name
		&"move_right":
			return "Press %s to move to the right marker." % input_name
		&"jump":
			return "Press %s to jump over the puddle." % input_name
	return "Press %s to slide under the laundry line." % input_name


# Ask the adapter so the hint always names the input that produces this lesson.
func _source_for(action: StringName) -> StringName:
	for source in PRACTICE_ACTIONS:
		if input_adapter.call("_map_affected_side", source) == action:
			return source
	return action


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	instruction_label.text = _practice_instruction()
	if not connected and not is_tutorial_paused:
		toggle_tutorial_pause()


func _refresh_status() -> void:
	previous_button.disabled = is_tutorial_paused or is_demonstrating or current_action_index == 0
	repeat_button.disabled = is_tutorial_paused or is_demonstrating
	demo_button.disabled = is_tutorial_paused or is_demonstrating
	next_button.disabled = is_tutorial_paused or is_demonstrating or not step_completed
	if is_tutorial_paused:
		tutorial_status.text = "Practice paused. Resume when ready."
	elif is_demonstrating:
		tutorial_status.text = "Watch the example. Your turn comes next."
	elif step_completed:
		var next_hint: String = ("press " + Hints.continue_hint(true)) if Hints.uses_gamepad() else "choose %s" % next_button.text
		tutorial_status.text = "Nicely done! Repeat or %s." % next_hint
	else:
		tutorial_status.text = "Your turn. No timer and no penalties."


func show_previous_action() -> void:
	if not tutorial_started:
		return
	show_action_index(current_action_index - 1)


func show_next_action() -> void:
	if not tutorial_started or is_tutorial_paused or is_demonstrating or not step_completed:
		return
	if current_action_index == ACTIONS.size() - 1:
		skip_to_ready()
		return
	show_action_index(current_action_index + 1)


func skip_to_ready() -> void:
	get_tree().change_scene_to_file(READY_SCENE_PATH)


func toggle_tutorial_pause() -> void:
	if not tutorial_started:
		return
	is_tutorial_paused = not is_tutorial_paused
	practice_player.set_gameplay_paused(is_tutorial_paused)
	demo_timer.paused = is_tutorial_paused
	pause_tutorial_button.text = "Resume Tutorial" if is_tutorial_paused else "Pause Tutorial"
	_refresh_status()


func return_to_controller_check() -> void:
	get_tree().change_scene_to_file(CONTROLLER_CHECK_SCENE_PATH)
