class_name RunnerLevelController
extends Node2D

const InputAdapterModel = preload("res://scripts/input_adapter.gd")
const L01PromptCatalogModel = preload("res://scripts/l01_prompt_catalog.gd")
const PromptDirectorModel = preload("res://scripts/prompt_director.gd")
const SessionConfigModel = preload("res://scripts/session_config.gd")
const SessionResultModel = preload("res://scripts/session_result.gd")

const WARNING_SECONDS := 2.5
const RESPONSE_SECONDS := 2.0
const RESOLVED_SECONDS := 0.75
const MAIN_DASHBOARD_SCENE_PATH := "res://scenes/main.tscn"

signal named_action_received(action_name: StringName)

var input_adapter := InputAdapterModel.new()
var l01_prompt_catalog := L01PromptCatalogModel.new()
var session_config := SessionConfigModel.new()
var session_result := SessionResultModel.new()
var _sequence_index := 0
var is_gameplay_paused := false
var is_session_ended := false

@onready var player: PlayerController = $Player
@onready var prompt_director: Node = $PromptDirector
@onready var progress_label: Label = $HUD/HUDRoot/ProgressLabel
@onready var neutral_miss_label: Label = $HUD/HUDRoot/NeutralMissLabel
@onready var prompt_action_label: Label = $HUD/HUDRoot/PromptActionLabel
@onready var prompt_state_label: Label = $HUD/HUDRoot/PromptStateLabel
@onready var crate_prompt: Node2D = $LevelWorld/PromptWorldAnchor/L01PromptProps/CratePrompt
@onready var puddle_prompt: Node2D = $LevelWorld/PromptWorldAnchor/L01PromptProps/PuddlePrompt
@onready var laundry_line_prompt: Node2D = $LevelWorld/PromptWorldAnchor/L01PromptProps/LaundryLinePrompt
@onready var warning_timer: Timer = $PromptTimers/WarningTimer
@onready var response_timer: Timer = $PromptTimers/ResponseTimer
@onready var resolve_timer: Timer = $PromptTimers/ResolveTimer
@onready var pause_button: Button = $HUD/HUDRoot/PauseButton
@onready var pause_overlay: CanvasLayer = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/Panel/Actions/ResumeButton
@onready var end_level_button: Button = $PauseOverlay/Panel/Actions/EndLevelButton
@onready var end_session_button: Button = $PauseOverlay/Panel/Actions/EndSessionButton
@onready var end_session_overlay: CanvasLayer = $EndSessionOverlay
@onready var end_session_title: Label = $EndSessionOverlay/Panel/Title
@onready var end_session_message: Label = $EndSessionOverlay/Panel/Message
@onready var return_button: Button = $EndSessionOverlay/Panel/ReturnButton
@onready var world_motion: Node = $WorldMotion


func _ready() -> void:
	prompt_director.connect("prompt_state_changed", _on_prompt_state_changed)
	warning_timer.timeout.connect(_on_warning_timer_timeout)
	response_timer.timeout.connect(_on_response_timer_timeout)
	resolve_timer.timeout.connect(_on_resolve_timer_timeout)
	pause_button.pressed.connect(pause_gameplay)
	resume_button.pressed.connect(resume_gameplay)
	end_level_button.pressed.connect(end_level_neutrally)
	end_session_button.pressed.connect(end_session_neutrally)
	return_button.pressed.connect(return_to_dashboard)
	_update_progress_hud()
	_schedule_next_l01_prompt()


func _unhandled_input(event: InputEvent) -> void:
	for action_name in InputAdapterModel.ACCEPTED_ACTIONS:
		if event.is_action_pressed(action_name):
			receive_input(action_name, true, Time.get_ticks_msec() / 1000.0)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_released(action_name):
			receive_input(action_name, false, Time.get_ticks_msec() / 1000.0)
			get_viewport().set_input_as_handled()
			return


func receive_input(source_action: StringName, pressed: bool, now_seconds: float) -> void:
	if not pressed:
		input_adapter.release_action(source_action)
		return

	var logical_action := input_adapter.accept_action(source_action, now_seconds)
	if logical_action == &"":
		return
	if logical_action == &"pause_session":
		if not is_session_ended:
			if is_gameplay_paused:
				resume_gameplay()
			else:
				pause_gameplay()
		return
	if is_gameplay_paused or is_session_ended:
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
			world_motion.call("begin_prompt_approach")
			warning_timer.start(WARNING_SECONDS)
		PromptDirectorModel.State.ACTIVE:
			warning_timer.stop()
			_show_l01_prompt(action_name, "MOVE NOW", Color(0.35, 0.78, 0.66, 1.0))
			response_timer.start(RESPONSE_SECONDS)
		PromptDirectorModel.State.RESOLVED:
			warning_timer.stop()
			response_timer.stop()
			_record_prompt_resolution(action_name, resolution)
			var resolved_text := "Nice step!" if resolution == PromptDirectorModel.Resolution.SUCCESS else "Take your time."
			prompt_state_label.text = resolved_text
			prompt_state_label.add_theme_color_override("font_color", Color(0.84, 0.93, 0.88, 1.0))
			if session_result.has_met_targets(session_config):
				_show_neutral_end_overlay("L01 complete", "The planned repetitions are complete. Review the session with the therapist.")
				return
			resolve_timer.start(RESOLVED_SECONDS)
		PromptDirectorModel.State.IDLE:
			_hide_l01_props()
			world_motion.call("hide_prompt_approach")
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


func _record_prompt_resolution(action_name: StringName, resolution: int) -> void:
	if resolution == PromptDirectorModel.Resolution.SUCCESS:
		session_result.record_success(action_name)
	else:
		session_result.record_neutral_miss()
	_update_progress_hud()


func _update_progress_hud() -> void:
	var completed_repetitions := 0
	var target_repetitions := 0
	for action_name in SessionConfigModel.ACTIONS:
		completed_repetitions += session_result.get_completed(action_name)
		target_repetitions += session_config.get_target(action_name)
	progress_label.text = "Reps: %d / %d" % [completed_repetitions, target_repetitions]
	neutral_miss_label.text = "Misses: %d" % session_result.neutral_misses


func _on_warning_timer_timeout() -> void:
	prompt_director.call("open_response_window")


func _on_response_timer_timeout() -> void:
	prompt_director.call("expire_active_prompt")


func _on_resolve_timer_timeout() -> void:
	prompt_director.call("clear_resolved_prompt")
	_schedule_next_l01_prompt()


func pause_gameplay() -> void:
	if is_gameplay_paused or is_session_ended:
		return

	is_gameplay_paused = true
	_set_gameplay_updates_paused(true)
	pause_overlay.visible = true


func resume_gameplay() -> void:
	if not is_gameplay_paused or is_session_ended:
		return

	is_gameplay_paused = false
	_set_gameplay_updates_paused(false)
	pause_overlay.visible = false


func end_level_neutrally() -> void:
	_show_neutral_end_overlay("Level ended", "The level ended safely. No score or penalty was recorded.")


func end_session_neutrally() -> void:
	_show_neutral_end_overlay("Session ended", "The session ended safely. Return when the therapist is ready.")


func return_to_dashboard() -> void:
	get_tree().change_scene_to_file(MAIN_DASHBOARD_SCENE_PATH)


func _set_gameplay_updates_paused(should_pause: bool) -> void:
	warning_timer.paused = should_pause
	response_timer.paused = should_pause
	resolve_timer.paused = should_pause
	world_motion.call("set_motion_paused", should_pause)
	player.set_gameplay_paused(should_pause)


func _show_neutral_end_overlay(title: String, message: String) -> void:
	if is_session_ended:
		return

	is_gameplay_paused = true
	is_session_ended = true
	_set_gameplay_updates_paused(true)
	warning_timer.stop()
	response_timer.stop()
	resolve_timer.stop()
	pause_overlay.visible = false
	end_session_title.text = title
	end_session_message.text = message
	end_session_overlay.visible = true
