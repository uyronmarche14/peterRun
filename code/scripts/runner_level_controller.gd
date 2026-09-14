class_name RunnerLevelController
extends Node2D

const InputAdapterModel = preload("res://scripts/input_adapter.gd")
const LevelSelection = preload("res://scripts/level_selection.gd")
const PromptDirectorModel = preload("res://scripts/prompt_director.gd")
const PatternLibraryResolverModel = preload("res://scripts/pattern_library_resolver.gd")
const RouteJourney = preload("res://scripts/route_journey.gd")
const SessionConfigModel = preload("res://scripts/session_config.gd")
const SessionResultModel = preload("res://scripts/session_result.gd")
const SessionSetupStoreModel = preload("res://scripts/session_setup_store.gd")
const SessionReviewStore = preload("res://scripts/session_review_store.gd")

const SUMMARY_SCENE_PATH := "res://scenes/session_summary.tscn"

signal named_action_received(action_name: StringName)

var input_adapter := InputAdapterModel.new()
var level_definition: Resource
var _planned_sequence: Array[StringName] = []
var _pattern_sets: Array = []
var _formation_library: Array = []
var _formation_resolver := PatternLibraryResolverModel.new()
var _active_formation: Dictionary = {}
var active_formation_id: StringName = &""
var _formation_prop_pools: Dictionary = {}
var _active_formation_props: Array[Node2D] = []
var _pending_response_action: StringName = &""
var _pending_response_lane := -1
var _pending_response_movement_accepted := false
var _pattern_set_index := 0
var _pattern_step_index := 0
var _prop_nodes: Dictionary = {}
var _secondary_move_prop: Node2D
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
@onready var journey_label: Label = $HUD/HUDRoot/JourneyLabel
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
	_pattern_sets = level_definition.get_pattern_sets()
	_formation_library = level_definition.get_pattern_definitions()
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
	# A formation is one discrete clinical response. Once its first input has
	# been accepted, ignore later movement until the obstacle reaches Peter.
	if not _active_formation.is_empty() and prompt_director.state == PromptDirectorModel.State.ACTIVE and _pending_response_action != &"":
		return

	named_action_received.emit(logical_action)
	# Apply movement first so validation sees the resulting lane.
	var movement_accepted := player.handle_action(logical_action)
	if not _active_formation.is_empty() and prompt_director.state == PromptDirectorModel.State.ACTIVE:
		if _pending_response_action == &"":
			_pending_response_action = logical_action
			_pending_response_lane = player.lane_index
			_pending_response_movement_accepted = movement_accepted
		return
	prompt_director.call("receive_action", logical_action, player.lane_index, movement_accepted)


func _schedule_next_prompt() -> void:
	if is_session_ended:
		return
	_pending_response_action = &""
	_pending_response_lane = -1
	_pending_response_movement_accepted = false
	_active_formation = {}
	active_formation_id = &""
	if not _formation_library.is_empty():
		var formation := _formation_resolver.select_next(_formation_library, player.lane_index)
		if formation.is_empty():
			_show_neutral_end_overlay("Route needs review", "This route does not have a reachable next movement. End the session and review the route setup.", &"configuration_error")
			return
		_active_formation = formation
		active_formation_id = StringName(formation.get("pattern_id", &""))
		var formation_action := StringName(formation.get("required_action", &""))
		var prompt_lane := _get_formation_prompt_lane(formation)
		var safe_lane := int(formation.get("ending_lane", -1)) if formation.get("allow_idle_safe_clear", false) else -1
		var action_lanes: Array[int] = []
		for lane_value in formation.get("action_lanes", []):
			action_lanes.append(int(lane_value))
		if not action_lanes.is_empty() and (formation_action == &"jump" or formation_action == &"slide"):
			prompt_director.call("schedule_with_action_lanes", formation_action, action_lanes)
		else:
			prompt_director.call("schedule", formation_action, prompt_lane, safe_lane, safe_lane >= 0)
		return
	if not _pattern_sets.is_empty():
		var pattern: Dictionary = _pattern_sets[_pattern_set_index]
		var actions: Array = pattern.get("actions", [])
		var lanes: Array = pattern.get("lanes", [])
		if actions.is_empty() or actions.size() != lanes.size():
			return
		if _pattern_step_index >= actions.size():
			_pattern_set_index = (_pattern_set_index + 1) % _pattern_sets.size()
			_pattern_step_index = 0
			pattern = _pattern_sets[_pattern_set_index]
			actions = pattern.get("actions", [])
			lanes = pattern.get("lanes", [])
		var pattern_step := _pattern_step_index
		_pattern_step_index += 1
		var pattern_action := StringName(actions[pattern_step])
		var pattern_lane := int(lanes[pattern_step])
		var safe_lane := -1
		var idle_safe_clear := false
		if pattern_action == &"move_left":
			safe_lane = clampi(pattern_lane - 1, 0, 2)
			idle_safe_clear = true
		elif pattern_action == &"move_right":
			safe_lane = clampi(pattern_lane + 1, 0, 2)
			idle_safe_clear = true
		prompt_director.call("schedule", pattern_action, pattern_lane, safe_lane, idle_safe_clear)
		return
	if _planned_sequence.is_empty():
		return

	var action_name: StringName = _planned_sequence[_sequence_index]
	var planned_index := _sequence_index
	_sequence_index = (_sequence_index + 1) % _planned_sequence.size()
	prompt_director.call("schedule", action_name, level_definition.get_prompt_lane(planned_index, player.lane_index))


func _on_prompt_state_changed(state: int, action_name: StringName, resolution: int) -> void:
	if is_session_ended:
		return
	match state:
		PromptDirectorModel.State.WARNING:
			response_timer.stop()
			resolve_timer.stop()
			if not _active_formation.is_empty():
				_show_formation_prompt(action_name, "GET READY", Color(1.0, 0.855, 0.51, 1.0))
				world_motion.call("set_prompt_formation", _active_formation_props, _get_formation_lanes())
				world_motion.call("begin_prompt_approach", 1, level_definition.warning_seconds, level_definition.response_seconds)
			else:
				_show_prompt(action_name, "GET READY", Color(1.0, 0.855, 0.51, 1.0))
				var companion_lanes: Array[int] = []
				if action_name == &"move_left":
					var left_target := clampi(prompt_director.prompt_lane_index - 1, 0, 2)
					companion_lanes.append(2 if left_target == 0 else 0)
				elif action_name == &"move_right":
					var right_target := clampi(prompt_director.prompt_lane_index + 1, 0, 2)
					companion_lanes.append(0 if right_target == 2 else 2)
				var companion_nodes: Array[Node2D] = []
				if not companion_lanes.is_empty() and _secondary_move_prop != null:
					companion_nodes.append(_secondary_move_prop)
				world_motion.call("set_prompt_companions", companion_nodes, companion_lanes)
				world_motion.call("begin_prompt_approach", prompt_director.prompt_lane_index, level_definition.warning_seconds, level_definition.response_seconds)
			warning_timer.start(level_definition.warning_seconds)
		PromptDirectorModel.State.ACTIVE:
			warning_timer.stop()
			if not _active_formation.is_empty():
				_update_prompt_card(action_name, "MOVE NOW", Color(0.35, 0.78, 0.66, 1.0))
			else:
				_show_prompt(action_name, "MOVE NOW", Color(0.35, 0.78, 0.66, 1.0))
			response_timer.start(level_definition.response_seconds)
		PromptDirectorModel.State.RESOLVED:
			warning_timer.stop()
			response_timer.stop()
			_record_prompt_resolution(action_name, resolution)
			world_motion.call("resolve_prompt_approach", resolution != PromptDirectorModel.Resolution.NEUTRAL_MISS, level_definition.resolved_seconds)
			var resolved_text := "Nice step!" if resolution != PromptDirectorModel.Resolution.NEUTRAL_MISS else "Take your time."
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
	if not _formation_library.is_empty():
		var pool_sizes := {&"crate": 0, &"puddle": 0, &"laundry_line": 0}
		for formation_value in _formation_library:
			if not formation_value is Dictionary:
				continue
			var formation: Dictionary = formation_value
			var count_by_kind := {&"crate": 0, &"puddle": 0, &"laundry_line": 0}
			for obstacle_value in formation.get("obstacles", []):
				if obstacle_value is Dictionary:
					var kind := StringName(obstacle_value.get("kind", &""))
					if count_by_kind.has(kind):
						count_by_kind[kind] = int(count_by_kind[kind]) + 1
			for kind in pool_sizes:
				pool_sizes[kind] = maxi(int(pool_sizes[kind]), int(count_by_kind[kind]))
		for kind in pool_sizes:
			var pool: Array[Node2D] = []
			var packed_scene := _get_scene_for_obstacle(kind)
			for index in int(pool_sizes[kind]):
				var prop := packed_scene.instantiate() as Node2D
				prop.name = "Formation_%s_%d" % [kind, index]
				prop.visible = false
				$LevelWorld/PromptWorldAnchor/PromptProps.add_child(prop)
				pool.append(prop)
			_formation_prop_pools[kind] = pool
	_secondary_move_prop = level_definition.move_prop.instantiate()
	_secondary_move_prop.name = "SecondaryMoveProp"
	_secondary_move_prop.visible = false
	$LevelWorld/PromptWorldAnchor/PromptProps.add_child(_secondary_move_prop)


func get_visible_prompt() -> Node2D:
	return _visible_prompt


func get_active_formation_props() -> Array[Node2D]:
	return _active_formation_props.duplicate()


func _show_prompt(action_name: StringName, state_text: String, state_color: Color) -> void:
	_hide_props()
	prompt_action_label.text = level_definition.get_action_label(action_name)
	prompt_icon_label.text = level_definition.get_action_icon(action_name)
	prompt_state_label.text = state_text
	prompt_state_label.add_theme_color_override("font_color", state_color)
	_visible_prompt = _prop_nodes.get(action_name)
	if _visible_prompt != null:
		_visible_prompt.visible = true
	if _secondary_move_prop != null and (action_name == &"move_left" or action_name == &"move_right"):
		_secondary_move_prop.visible = true


func _show_formation_prompt(action_name: StringName, state_text: String, state_color: Color) -> void:
	_hide_props()
	_update_prompt_card(action_name, state_text, state_color)
	var used_by_kind := {}
	var action_kind := _get_kind_for_action(action_name)
	for obstacle_value in _active_formation.get("obstacles", []):
		if not obstacle_value is Dictionary:
			continue
		var obstacle: Dictionary = obstacle_value
		var kind := StringName(obstacle.get("kind", &""))
		var pool: Array = _formation_prop_pools.get(kind, [])
		var pool_index := int(used_by_kind.get(kind, 0))
		used_by_kind[kind] = pool_index + 1
		if pool_index >= pool.size() or not pool[pool_index] is Node2D:
			continue
		var prop := pool[pool_index] as Node2D
		prop.visible = true
		prop.position = Vector2.ZERO
		prop.scale = Vector2.ONE
		prop.modulate = Color.WHITE
		prop.set_meta("formation_lane", int(obstacle.get("lane", 1)))
		_active_formation_props.append(prop)
		if _visible_prompt == null or kind == action_kind:
			_visible_prompt = prop


func _update_prompt_card(action_name: StringName, state_text: String, state_color: Color) -> void:
	prompt_action_label.text = level_definition.get_action_label(action_name)
	prompt_icon_label.text = level_definition.get_action_icon(action_name)
	prompt_state_label.text = state_text
	prompt_state_label.add_theme_color_override("font_color", state_color)


func _hide_props() -> void:
	for prop in _prop_nodes.values():
		prop.visible = false
	if _secondary_move_prop != null:
		_secondary_move_prop.visible = false
	for pool_value in _formation_prop_pools.values():
		for prop_value in pool_value:
			if prop_value is Node2D:
				prop_value.visible = false
	_active_formation_props.clear()
	_visible_prompt = null
	prompt_backdrop.visible = false
	prompt_icon_label.text = "•"


func _record_prompt_resolution(action_name: StringName, resolution: int) -> void:
	if resolution == PromptDirectorModel.Resolution.SUCCESS:
		if session_result.get_completed(action_name) < session_config.get_target(action_name):
			session_result.record_success(action_name)
	elif resolution == PromptDirectorModel.Resolution.SAFE_CLEAR:
		session_result.record_route_clear()
	else:
		session_result.record_neutral_miss()
	_update_progress_hud(resolution == PromptDirectorModel.Resolution.SUCCESS)
	var completed := 0
	for action in SessionConfigModel.ACTIONS:
		completed += mini(session_result.get_completed(action), session_config.get_target(action))
	feedback_toast.show_result(resolution != PromptDirectorModel.Resolution.NEUTRAL_MISS, completed)


func _update_progress_hud(animate_success: bool = false) -> void:
	var completed_repetitions := 0
	var target_repetitions := 0
	for action_name in SessionConfigModel.ACTIONS:
		completed_repetitions += mini(session_result.get_completed(action_name), session_config.get_target(action_name))
		target_repetitions += session_config.get_target(action_name)
	progress_label.text = "Reps: %d / %d" % [completed_repetitions, target_repetitions]
	neutral_miss_label.text = "Misses: %d" % session_result.neutral_misses
	journey_label.text = RouteJourney.get_hud_text(session_result.route_clear_points)
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
	if not _active_formation.is_empty() and _pending_response_action != &"":
		prompt_director.call("receive_action", _pending_response_action, _pending_response_lane, _pending_response_movement_accepted)
	else:
		prompt_director.call("expire_active_prompt", player.lane_index)


func _get_formation_prompt_lane(formation: Dictionary) -> int:
	var action := StringName(formation.get("required_action", &""))
	if action == &"jump" or action == &"slide":
		return int(formation.get("action_lane", 1))
	var ending_lane := int(formation.get("ending_lane", 1))
	return clampi(ending_lane + 1 if action == &"move_left" else ending_lane - 1, 0, 2)


func _get_formation_lanes() -> Array[int]:
	var lanes: Array[int] = []
	for obstacle_value in _active_formation.get("obstacles", []):
		if obstacle_value is Dictionary:
			lanes.append(int(obstacle_value.get("lane", 1)))
	return lanes


func _get_kind_for_action(action_name: StringName) -> StringName:
	match action_name:
		&"move_left", &"move_right": return &"crate"
		&"jump": return &"puddle"
		&"slide": return &"laundry_line"
	return &""


func _get_scene_for_obstacle(kind: StringName) -> PackedScene:
	match kind:
		&"crate": return level_definition.get_prop_scene(&"move_left")
		&"puddle": return level_definition.get_prop_scene(&"jump")
		&"laundry_line": return level_definition.get_prop_scene(&"slide")
	return null


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
