class_name RunnerLevelController
extends Node2D

const InputAdapterModel = preload("res://scripts/input_adapter.gd")
const LevelSelection = preload("res://scripts/level_selection.gd")
const PromptDirectorModel = preload("res://scripts/prompt_director.gd")
const SessionConfigModel = preload("res://scripts/session_config.gd")
const SessionResultModel = preload("res://scripts/session_result.gd")
const SessionSetupStoreModel = preload("res://scripts/session_setup_store.gd")
const SessionReviewStore = preload("res://scripts/session_review_store.gd")

const SUMMARY_SCENE_PATH := "res://scenes/session_summary.tscn"

signal named_action_received(action_name: StringName)

var input_adapter := InputAdapterModel.new()
var level_definition: Resource
var _planned_sequence: Array[StringName] = []
var _prop_nodes: Dictionary = {}
var _visible_prompt: Node2D
var session_config := SessionConfigModel.new()
var session_result := SessionResultModel.new()
var _sequence_index := 0
var is_gameplay_paused := false
var is_session_ended := false
var _progress_tween: Tween
var _pending_end_reason: StringName = &""

@onready var player: PlayerController = $Player
@onready var prompt_director: Node = $PromptDirector
@onready var progress_label: Label = $HUD/HUDRoot/ProgressLabel
@onready var progress_bar: ProgressBar = $HUD/HUDRoot/ProgressBar
@onready var feedback_toast: PanelContainer = $HUD/HUDRoot/FeedbackToast
@onready var neutral_miss_label: Label = $HUD/HUDRoot/NeutralMissLabel
@onready var prompt_icon_label: Label = $HUD/HUDRoot/PromptCard/PromptIconLabel
@onready var prompt_action_label: Label = $HUD/HUDRoot/PromptActionLabel
@onready var prompt_state_label: Label = $HUD/HUDRoot/PromptStateLabel
@onready var prompt_backdrop: Node2D = $LevelWorld/PromptWorldAnchor/PromptProps/PromptBackdrop
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
@onready var end_confirmation: CanvasLayer = $EndConfirmation


func _ready() -> void:
	session_config = SessionSetupStoreModel.get_session_config()
	input_adapter = InputAdapterModel.new(session_config.affected_side)
	prompt_director.connect("prompt_state_changed", _on_prompt_state_changed)
	warning_timer.timeout.connect(_on_warning_timer_timeout)
	response_timer.timeout.connect(_on_response_timer_timeout)
	resolve_timer.timeout.connect(_on_resolve_timer_timeout)
	pause_button.pressed.connect(pause_gameplay)
	resume_button.pressed.connect(resume_gameplay)
	end_level_button.pressed.connect(request_end_level)
	end_session_button.pressed.connect(request_end_session)
	return_button.pressed.connect(open_summary)
	$EndConfirmation/Panel/Actions/CancelButton.pressed.connect(cancel_end)
	$EndConfirmation/Panel/Actions/ConfirmButton.pressed.connect(confirm_end)
	_update_progress_hud()
	level_definition = LevelSelection.resolve(session_config)
	if level_definition == null:
		_show_neutral_end_overlay("Level unavailable", "This level configuration cannot be loaded. Finish the review and return to setup.", &"configuration_error")
		return
	# Freeze the authored settings for this run; results/retry get their own copy.
	level_definition = level_definition.duplicate(true)
	session_config.level_definition = level_definition
	_planned_sequence = level_definition.get_planned_sequence()
	_apply_level_presentation()
	_schedule_next_prompt()


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


func _schedule_next_prompt() -> void:
	if is_session_ended:
		return
	if _planned_sequence.is_empty():
		return

	var action_name: StringName = _planned_sequence[_sequence_index]
	_sequence_index = (_sequence_index + 1) % _planned_sequence.size()
	prompt_director.call("schedule", action_name)


func _on_prompt_state_changed(state: int, action_name: StringName, resolution: int) -> void:
	if is_session_ended:
		return
	match state:
		PromptDirectorModel.State.WARNING:
			response_timer.stop()
			resolve_timer.stop()
			_show_prompt(action_name, "GET READY", Color(1.0, 0.855, 0.51, 1.0))
			world_motion.call("begin_prompt_approach", player.lane_index, level_definition.warning_seconds, level_definition.response_seconds)
			warning_timer.start(level_definition.warning_seconds)
		PromptDirectorModel.State.ACTIVE:
			warning_timer.stop()
			_show_prompt(action_name, "MOVE NOW", Color(0.35, 0.78, 0.66, 1.0))
			response_timer.start(level_definition.response_seconds)
		PromptDirectorModel.State.RESOLVED:
			warning_timer.stop()
			response_timer.stop()
			_record_prompt_resolution(action_name, resolution)
			world_motion.call("resolve_prompt_approach", resolution == PromptDirectorModel.Resolution.SUCCESS, level_definition.resolved_seconds)
			var resolved_text := "Nice step!" if resolution == PromptDirectorModel.Resolution.SUCCESS else "Take your time."
			prompt_state_label.text = resolved_text
			prompt_state_label.add_theme_color_override("font_color", Color(0.84, 0.93, 0.88, 1.0))
			if session_result.has_met_targets(session_config):
				_show_neutral_end_overlay(level_definition.short_name + " complete", "The planned repetitions are complete. Review the session with the therapist.")
				return
			resolve_timer.start(level_definition.resolved_seconds)
		PromptDirectorModel.State.IDLE:
			_hide_props()
			world_motion.call("hide_prompt_approach")
			prompt_action_label.text = "NEXT ACTION"
			prompt_state_label.text = ""


func _apply_level_presentation() -> void:
	$HUD/HUDRoot/LevelLabel.text = "%s · %s" % [level_definition.short_name, level_definition.title]
	$LevelWorld/Sky.color = level_definition.sky_color
	$LevelWorld/DistantHills.color = level_definition.distant_color
	$LevelWorld/Horizon.color = level_definition.horizon_color
	$LevelWorld/RoadAndLanes/RoadSurface.color = level_definition.road_color
	$LevelWorld/BackgroundArt.texture = level_definition.background_texture
	var instances: Dictionary = {}
	for action in SessionConfigModel.ACTIONS:
		var packed: PackedScene = level_definition.get_prop_scene(action)
		if not instances.has(packed):
			var prop: Node2D = packed.instantiate()
			prop.visible = false
			$LevelWorld/PromptWorldAnchor/PromptProps.add_child(prop)
			instances[packed] = prop
		_prop_nodes[action] = instances[packed]


func get_visible_prompt() -> Node2D:
	return _visible_prompt


func _show_prompt(action_name: StringName, state_text: String, state_color: Color) -> void:
	_hide_props()
	prompt_action_label.text = level_definition.get_action_label(action_name)
	prompt_icon_label.text = level_definition.get_action_icon(action_name)
	prompt_state_label.text = state_text
	prompt_state_label.add_theme_color_override("font_color", state_color)
	_visible_prompt = _prop_nodes.get(action_name)
	if _visible_prompt != null:
		_visible_prompt.visible = true


func _hide_props() -> void:
	for prop in _prop_nodes.values():
		prop.visible = false
	_visible_prompt = null
	prompt_backdrop.visible = false
	prompt_icon_label.text = "•"


func _record_prompt_resolution(action_name: StringName, resolution: int) -> void:
	if resolution == PromptDirectorModel.Resolution.SUCCESS:
		session_result.record_success(action_name)
	else:
		session_result.record_neutral_miss()
	_update_progress_hud(resolution == PromptDirectorModel.Resolution.SUCCESS)
	var completed := 0
	for action in SessionConfigModel.ACTIONS:
		completed += mini(session_result.get_completed(action), session_config.get_target(action))
	feedback_toast.show_result(resolution == PromptDirectorModel.Resolution.SUCCESS, completed)


func _update_progress_hud(animate_success: bool = false) -> void:
	var completed_repetitions := 0
	var target_repetitions := 0
	for action_name in SessionConfigModel.ACTIONS:
		completed_repetitions += mini(session_result.get_completed(action_name), session_config.get_target(action_name))
		target_repetitions += session_config.get_target(action_name)
	progress_label.text = "Reps: %d / %d" % [completed_repetitions, target_repetitions]
	neutral_miss_label.text = "Misses: %d" % session_result.neutral_misses
	progress_bar.max_value = maxf(1.0, target_repetitions)
	if _progress_tween != null:
		_progress_tween.kill()
	_progress_tween = create_tween().set_parallel(true)
	_progress_tween.tween_property(progress_bar, "value", float(completed_repetitions), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	progress_label.modulate = Color(1.15, 1.15, 1.1) if animate_success else Color.WHITE
	_progress_tween.tween_property(progress_label, "modulate", Color.WHITE, 0.45)


func _on_warning_timer_timeout() -> void:
	prompt_director.call("open_response_window")


func _on_response_timer_timeout() -> void:
	prompt_director.call("expire_active_prompt")


func _on_resolve_timer_timeout() -> void:
	prompt_director.call("clear_resolved_prompt")
	_schedule_next_prompt()


func pause_gameplay() -> void:
	if is_gameplay_paused or is_session_ended:
		return

	is_gameplay_paused = true
	_set_gameplay_updates_paused(true)
	pause_overlay.visible = true


func resume_gameplay() -> void:
	if not is_gameplay_paused or is_session_ended or end_confirmation.visible:
		return

	is_gameplay_paused = false
	_set_gameplay_updates_paused(false)
	pause_overlay.visible = false


func end_level_neutrally() -> void:
	_show_neutral_end_overlay("Level ended", "Your completed movements are kept for review. There is no penalty for ending early.", &"level_ended")


func end_session_neutrally() -> void:
	_show_neutral_end_overlay("Session ended", "Your completed movements are kept for review. There is no penalty for ending early.", &"session_ended")


func request_end_level() -> void:
	_request_end(&"level_ended", "End this level?")


func request_end_session() -> void:
	_request_end(&"session_ended", "End this session?")


func _request_end(reason: StringName, title: String) -> void:
	if is_session_ended:
		return
	pause_gameplay()
	_pending_end_reason = reason
	pause_overlay.visible = false
	$EndConfirmation/Panel/Title.text = title
	end_confirmation.visible = true


func cancel_end() -> void:
	if is_session_ended or _pending_end_reason == &"":
		return
	_pending_end_reason = &""
	end_confirmation.visible = false
	pause_overlay.visible = true


func confirm_end() -> void:
	var reason := _pending_end_reason
	_pending_end_reason = &""
	end_confirmation.visible = false
	if reason == &"level_ended":
		end_level_neutrally()
	elif reason == &"session_ended":
		end_session_neutrally()


func open_summary() -> void:
	if not is_session_ended or return_button.disabled:
		return
	return_button.disabled = true
	if get_tree().change_scene_to_file(SUMMARY_SCENE_PATH) != OK:
		return_button.disabled = false
		end_session_message.text = "Could not open the summary. Your results are still available; please try again."


func _set_gameplay_updates_paused(should_pause: bool) -> void:
	warning_timer.paused = should_pause
	response_timer.paused = should_pause
	resolve_timer.paused = should_pause
	world_motion.call("set_motion_paused", should_pause)
	player.set_gameplay_paused(should_pause)
	feedback_toast.set_feedback_paused(should_pause)
	if _progress_tween != null:
		_progress_tween.set_speed_scale(0.0 if should_pause else 1.0)


func _show_neutral_end_overlay(title: String, message: String, reason: StringName = &"completed") -> void:
	if is_session_ended:
		return

	is_gameplay_paused = true
	is_session_ended = true
	if session_result.has_met_targets(session_config):
		if _progress_tween != null:
			_progress_tween.kill()
		progress_bar.value = progress_bar.max_value
		progress_label.modulate = Color.WHITE
	_set_gameplay_updates_paused(true)
	warning_timer.stop()
	response_timer.stop()
	resolve_timer.stop()
	pause_overlay.visible = false
	end_confirmation.visible = false
	SessionReviewStore.capture(session_config, session_result, reason)
	end_session_title.text = title
	end_session_message.text = message
	end_session_overlay.visible = true
	feedback_toast.dismiss()
