class_name RunnerLevelController
extends Node2D

const InputAdapterModel = preload("res://scripts/input_adapter.gd")
const L01PromptCatalogModel = preload("res://scripts/l01_prompt_catalog.gd")
const PromptDirectorModel = preload("res://scripts/prompt_director.gd")

const WARNING_SECONDS := 2.5
const RESPONSE_SECONDS := 2.0
const RESOLVED_SECONDS := 0.75

signal named_action_received(action_name: StringName)

var input_adapter := InputAdapterModel.new()
var l01_prompt_catalog := L01PromptCatalogModel.new()
var _sequence_index := 0

@onready var player: PlayerController = $Player
@onready var prompt_director: Node = $PromptDirector
@onready var prompt_action_label: Label = $HUD/HUDRoot/PromptActionLabel
@onready var prompt_state_label: Label = $HUD/HUDRoot/PromptStateLabel
@onready var crate_prompt: Node2D = $LevelWorld/PromptWorldAnchor/L01PromptProps/CratePrompt
@onready var puddle_prompt: Node2D = $LevelWorld/PromptWorldAnchor/L01PromptProps/PuddlePrompt
@onready var laundry_line_prompt: Node2D = $LevelWorld/PromptWorldAnchor/L01PromptProps/LaundryLinePrompt
@onready var warning_timer: Timer = $PromptTimers/WarningTimer
@onready var response_timer: Timer = $PromptTimers/ResponseTimer
@onready var resolve_timer: Timer = $PromptTimers/ResolveTimer


func _ready() -> void:
	prompt_director.connect("prompt_state_changed", _on_prompt_state_changed)
	warning_timer.timeout.connect(_on_warning_timer_timeout)
	response_timer.timeout.connect(_on_response_timer_timeout)
	resolve_timer.timeout.connect(_on_resolve_timer_timeout)
	_schedule_next_l01_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventAction:
		return
	if not InputAdapterModel.ACCEPTED_ACTIONS.has(event.action):
		return

	receive_input(event.action, event.pressed, Time.get_ticks_msec() / 1000.0)
	get_viewport().set_input_as_handled()


func receive_input(source_action: StringName, pressed: bool, now_seconds: float) -> void:
	if not pressed:
		input_adapter.release_action(source_action)
		return

	var logical_action := input_adapter.accept_action(source_action, now_seconds)
	if logical_action == &"":
		return

	named_action_received.emit(logical_action)
	prompt_director.call("receive_action", logical_action)
	player.handle_action(logical_action)


func _schedule_next_l01_prompt() -> void:
	var planned_sequence := l01_prompt_catalog.get_planned_sequence()
	if planned_sequence.is_empty():
		return

	var action_name: StringName = planned_sequence[_sequence_index]
	_sequence_index = (_sequence_index + 1) % planned_sequence.size()
	prompt_director.call("schedule", action_name)


func _on_prompt_state_changed(state: int, action_name: StringName, resolution: int) -> void:
	match state:
		PromptDirectorModel.State.WARNING:
			response_timer.stop()
			resolve_timer.stop()
			_show_l01_prompt(action_name, "GET READY", Color(1.0, 0.855, 0.51, 1.0))
			warning_timer.start(WARNING_SECONDS)
		PromptDirectorModel.State.ACTIVE:
			warning_timer.stop()
			_show_l01_prompt(action_name, "MOVE NOW", Color(0.35, 0.78, 0.66, 1.0))
			response_timer.start(RESPONSE_SECONDS)
		PromptDirectorModel.State.RESOLVED:
			warning_timer.stop()
			response_timer.stop()
			var resolved_text := "Nice step!" if resolution == PromptDirectorModel.Resolution.SUCCESS else "Take your time."
			prompt_state_label.text = resolved_text
			prompt_state_label.add_theme_color_override("font_color", Color(0.84, 0.93, 0.88, 1.0))
			resolve_timer.start(RESOLVED_SECONDS)
		PromptDirectorModel.State.IDLE:
			_hide_l01_props()
			prompt_action_label.text = "NEXT ACTION"
			prompt_state_label.text = ""


func _show_l01_prompt(action_name: StringName, state_text: String, state_color: Color) -> void:
	prompt_action_label.text = l01_prompt_catalog.get_action_label(action_name)
	prompt_state_label.text = state_text
	prompt_state_label.add_theme_color_override("font_color", state_color)

	var prop_id := l01_prompt_catalog.get_prop_id(action_name)
	crate_prompt.visible = prop_id == &"crate"
	puddle_prompt.visible = prop_id == &"puddle"
	laundry_line_prompt.visible = prop_id == &"laundry_line"


func _hide_l01_props() -> void:
	crate_prompt.visible = false
	puddle_prompt.visible = false
	laundry_line_prompt.visible = false


func _on_warning_timer_timeout() -> void:
	prompt_director.call("open_response_window")


func _on_response_timer_timeout() -> void:
	prompt_director.call("expire_active_prompt")


func _on_resolve_timer_timeout() -> void:
	prompt_director.call("clear_resolved_prompt")
	_schedule_next_l01_prompt()
