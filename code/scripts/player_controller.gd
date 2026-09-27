class_name PlayerController
extends Node2D

const PlayerLaneStateModel = preload("res://scripts/player_lane_state.gd")
const Settings = preload("res://scripts/game_settings.gd")

const LANE_X := [128.0, 240.0, 352.0]
const LANE_TWEEN_SECONDS := 0.22
const JUMP_RISE_SECONDS := 0.24
const JUMP_HOLD_SECONDS := 0.06
const JUMP_RETURN_SECONDS := 0.32
const LANDING_SECONDS := 0.22
const ACTION_RISE_SECONDS := 0.20
const ACTION_RETURN_SECONDS := 0.28
var _lane_state := PlayerLaneStateModel.new()
var _lane_tween: Tween
var _action_tween: Tween
var _shadow_tween: Tween
var is_gameplay_paused := false
var _walking := false
var _preview_pose: StringName = &"idle_ready"
var _pending_feedback: StringName = &""
var _landing_remaining := 0.0
var _lane_remaining := 0.0
var _lane_direction := 1.0

@onready var visual: Node2D = $Visual
@onready var shadow: Node2D = $Shadow
@onready var slide_streak: Line2D = $SlideStreak
@onready var slide_dust: Node2D = $SlideDust
@onready var character_sprite: Sprite2D = $Visual/CharacterSprite
@onready var landing_ring: Line2D = $LandingRing
@onready var landing_dust: Sprite2D = $LandingRing/LandingDust
@onready var lane_trail: Line2D = $LaneTrail
@onready var lane_trail_art: Sprite2D = $LaneTrail/TrailArt
@onready var slide_dust_art: Sprite2D = $SlideDust/DustArt

var lane_index: int:
	get:
		return _lane_state.lane_index

var action_state: int:
	get:
		return _lane_state.action_state


func _ready() -> void:
	position.x = LANE_X[lane_index]
	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE
	visual.rotation = 0.0
	shadow.scale = Vector2.ONE
	_reset_feedback_visuals()


func handle_action(action_name: StringName) -> bool:
	if is_gameplay_paused:
		return false

	var accepted := _lane_state.handle_action(action_name)
	if not accepted:
		return false
	# Cosmetic resolution from a previous input must not replay after this one.
	_pending_feedback = &""

	match action_name:
		&"move_left", &"move_right":
			_animate_lane_change()
		&"jump", &"slide":
			_play_neutral_action_animation(action_name)
	return true


func reset_for_practice() -> void:
	for tween in [_lane_tween, _action_tween, _shadow_tween]:
		if tween != null:
			tween.kill()
	_lane_state = PlayerLaneStateModel.new()
	is_gameplay_paused = false
	_walking = false
	_preview_pose = &"idle_ready"
	_pending_feedback = &""
	character_sprite.play_clip(&"idle_ready")
	_landing_remaining = 0.0
	_lane_remaining = 0.0
	position.x = LANE_X[lane_index]
	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE
	visual.rotation = 0.0
	shadow.scale = Vector2.ONE
	_reset_feedback_visuals()


func _animate_lane_change() -> void:
	if _lane_tween != null:
		_lane_tween.kill()
	_lane_tween = create_tween()
	_lane_remaining = LANE_TWEEN_SECONDS
	_lane_direction = signf(LANE_X[lane_index] - position.x)
	# Compress authored side-step frames to the unchanged lane travel time.
	if action_state == PlayerLaneStateModel.ActionState.IDLE:
		character_sprite.play_clip(&"move_left" if _lane_direction < 0.0 else &"move_right", LANE_TWEEN_SECONDS)
	_lane_tween.set_trans(Tween.TRANS_CUBIC)
	_lane_tween.set_ease(Tween.EASE_OUT)
	_lane_tween.tween_property(self, ^"position:x", LANE_X[lane_index], LANE_TWEEN_SECONDS)


func _process(delta: float) -> void:
	if is_gameplay_paused:
		return
	_update_ground_feedback(delta)
	if not (Settings.reduced_motion and character_sprite.animation in [&"idle_ready", &"walk_forward", &"rest"]):
		character_sprite.advance(delta)
	if character_sprite.finished and action_state == PlayerLaneStateModel.ActionState.IDLE:
		_play_base_animation()


func set_walking(walking: bool) -> void:
	_walking = walking
	_preview_pose = &"idle_ready"
	if action_state == PlayerLaneStateModel.ActionState.IDLE:
		_play_base_animation()


func _play_base_animation() -> void:
	if _pending_feedback != &"":
		character_sprite.play_clip(_pending_feedback)
		_pending_feedback = &""
		return
	character_sprite.play_clip(&"walk_forward" if _walking and not Settings.reduced_motion else _preview_pose)


func show_resolved_feedback(success: bool) -> void:
	if is_gameplay_paused:
		return
	_pending_feedback = &"success_settle" if success else &"neutral_clear"
	# Do not cut off authored airborne/duck/side-step motion at resolution.
	if action_state == PlayerLaneStateModel.ActionState.IDLE and _lane_remaining <= 0.0:
		_play_base_animation()


func set_resting_preview(paused_pose: bool = false) -> void:
	if is_gameplay_paused or action_state != PlayerLaneStateModel.ActionState.IDLE or _lane_remaining > 0.0:
		return
	_walking = false
	_pending_feedback = &""
	_preview_pose = &"paused" if paused_pose else &"rest"
	_play_base_animation()


func _update_ground_feedback(delta: float) -> void:
	_landing_remaining = maxf(0.0, _landing_remaining - delta)
	landing_ring.visible = _landing_remaining > 0.0 and not Settings.reduced_motion
	if landing_ring.visible:
		var fraction := 1.0 - _landing_remaining / LANDING_SECONDS
		landing_ring.scale = Vector2.ONE * lerpf(0.62, 1.38, fraction)
		landing_ring.modulate.a = (1.0 - fraction) * 0.72 * Settings.effects_intensity
		landing_dust.visible = true
		landing_dust.position = Vector2(0.0, -4.0 * sin(fraction * PI))
		landing_dust.scale = Vector2.ONE * lerpf(0.56, 0.72, fraction)
		landing_dust.modulate.a = (1.0 - fraction) * 0.78 * Settings.effects_intensity
	else:
		landing_dust.visible = false
	_lane_remaining = maxf(0.0, _lane_remaining - delta)
	lane_trail.visible = _lane_remaining > 0.0 and action_state != PlayerLaneStateModel.ActionState.JUMP and not Settings.reduced_motion
	if lane_trail.visible:
		var fraction := 1.0 - _lane_remaining / LANE_TWEEN_SECONDS
		lane_trail.scale.x = _lane_direction
		lane_trail.position.y = -2.0 * sin(fraction * PI)
		lane_trail.modulate.a = sin(fraction * PI) * 0.58 * Settings.effects_intensity
		lane_trail_art.modulate.a = 0.82
	if slide_dust.visible:
		var fraction := clampf(character_sprite.elapsed / maxf(character_sprite.duration, 0.001), 0.0, 1.0)
		var ease_alpha := sin(fraction * PI)
		slide_dust.position = Vector2(-5.0 - 8.0 * fraction, 14.0 - 2.0 * ease_alpha)
		slide_dust.modulate.a = ease_alpha * 0.72 * Settings.effects_intensity
		slide_dust_art.position.x = -14.0 - 4.0 * fraction
		slide_streak.modulate.a = ease_alpha * 0.62 * Settings.effects_intensity


func _play_neutral_action_animation(action_name: StringName) -> void:
	if _action_tween != null:
		_action_tween.kill()
	visual.transform = Transform2D.IDENTITY
	shadow.scale = Vector2.ONE
	_reset_feedback_visuals()
	_action_tween = create_tween()
	# The authored frames contain the lift/duck. Only this timer owns action
	# recovery, retaining the original collision/input semantics.
	if action_name == &"jump":
		var seconds := JUMP_RISE_SECONDS + JUMP_HOLD_SECONDS + JUMP_RETURN_SECONDS
		character_sprite.play_clip(&"jump_low", seconds)
		_action_tween.tween_interval(seconds)
		if not Settings.reduced_motion:
			_play_jump_shadow_animation()
	else:
		var seconds := ACTION_RISE_SECONDS + ACTION_RETURN_SECONDS
		character_sprite.play_clip(&"slide_duck", seconds)
		slide_streak.visible = not Settings.reduced_motion
		slide_dust.visible = not Settings.reduced_motion
		_action_tween.tween_interval(seconds)
	_action_tween.tween_callback(_finish_action_animation)


func _finish_action_animation() -> void:
	if action_state == PlayerLaneStateModel.ActionState.JUMP:
		_landing_remaining = LANDING_SECONDS
		landing_ring.visible = not Settings.reduced_motion
		landing_ring.scale = Vector2.ONE * 0.65
		landing_ring.modulate.a = 0.72 * Settings.effects_intensity
		landing_dust.visible = not Settings.reduced_motion
		landing_dust.modulate.a = 0.78 * Settings.effects_intensity
	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE
	visual.rotation = 0.0
	shadow.scale = Vector2.ONE
	slide_streak.visible = false
	slide_dust.visible = false
	_lane_state.finish_action()
	_play_base_animation()


func _play_jump_shadow_animation() -> void:
	if _shadow_tween != null:
		_shadow_tween.kill()
	_shadow_tween = create_tween()
	_shadow_tween.tween_property(shadow, ^"scale", Vector2(0.48, 0.48), JUMP_RISE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_shadow_tween.tween_interval(JUMP_HOLD_SECONDS)
	_shadow_tween.tween_property(shadow, ^"scale", Vector2.ONE, JUMP_RETURN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func set_gameplay_paused(should_pause: bool) -> void:
	is_gameplay_paused = should_pause
	var tween_speed := 0.0 if should_pause else 1.0
	if _lane_tween != null:
		_lane_tween.set_speed_scale(tween_speed)
	if _action_tween != null:
		_action_tween.set_speed_scale(tween_speed)
	if _shadow_tween != null:
		_shadow_tween.set_speed_scale(tween_speed)


func _reset_feedback_visuals() -> void:
	slide_streak.visible = false
	slide_streak.modulate = Color.WHITE
	slide_dust.visible = false
	slide_dust.position = Vector2(-5, 14)
	slide_dust.modulate = Color.WHITE
	slide_dust_art.position = Vector2(-14, 0)
	landing_ring.visible = false
	landing_ring.position = Vector2(0, 15)
	landing_ring.scale = Vector2.ONE
	landing_ring.modulate = Color.WHITE
	landing_dust.visible = false
	landing_dust.position = Vector2.ZERO
	landing_dust.scale = Vector2.ONE * 0.56
	landing_dust.modulate = Color.WHITE
	lane_trail.visible = false
	lane_trail.position = Vector2.ZERO
	lane_trail.scale = Vector2.ONE
	lane_trail.modulate = Color.WHITE
	lane_trail_art.modulate = Color.WHITE


func _exit_tree() -> void:
	finish_session_visuals()


func finish_session_visuals() -> void:
	# Terminal stop keeps the final pose but releases all pending callbacks.
	is_gameplay_paused = true
	_pending_feedback = &""
	if _lane_tween != null:
		_lane_tween.kill()
	if _action_tween != null:
		_action_tween.kill()
	if _shadow_tween != null:
		_shadow_tween.kill()
	_lane_tween = null
	_action_tween = null
	_shadow_tween = null
	_reset_feedback_visuals()
