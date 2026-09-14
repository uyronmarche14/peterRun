class_name PlayerController
extends Node2D

const PlayerLaneStateModel = preload("res://scripts/player_lane_state.gd")

const LANE_X := [128.0, 240.0, 352.0]
const LANE_TWEEN_SECONDS := 0.22
const JUMP_HEIGHT := -50.0
const JUMP_RISE_SECONDS := 0.24
const JUMP_HOLD_SECONDS := 0.06
const JUMP_RETURN_SECONDS := 0.32
const LANDING_SECONDS := 0.22
const ACTION_RISE_SECONDS := 0.20
const ACTION_RETURN_SECONDS := 0.28
const PETER_IDLE = preload("res://art/characters/peter/peter_idle.svg")
const PETER_RUN_A = preload("res://art/characters/peter/peter_run_a.svg")
const PETER_RUN_B = preload("res://art/characters/peter/peter_run_b.svg")
const PETER_JUMP = preload("res://art/characters/peter/peter_jump.svg")
const PETER_SLIDE = preload("res://art/characters/peter/peter_slide.svg")
const PETER_LAND = preload("res://art/characters/peter/peter_land.svg")

var _lane_state := PlayerLaneStateModel.new()
var _lane_tween: Tween
var _action_tween: Tween
var _shadow_tween: Tween
var _slide_scale_tween: Tween
var _slide_rotation_tween: Tween
var is_gameplay_paused := false
var _run_phase := 0.0
var _landing_remaining := 0.0
var _lane_remaining := 0.0
var _lane_direction := 1.0

@onready var left_leg: Line2D = $Visual/LeftLeg
@onready var right_leg: Line2D = $Visual/RightLeg
@onready var left_arm: Line2D = $Visual/LeftArm
@onready var right_arm: Line2D = $Visual/RightArm

@onready var visual: Node2D = $Visual
@onready var shadow: Node2D = $Shadow
@onready var slide_streak: Line2D = $SlideStreak
@onready var character_sprite: Sprite2D = $Visual/CharacterSprite
@onready var landing_ring: Line2D = $LandingRing
@onready var lane_trail: Line2D = $LaneTrail

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
	slide_streak.visible = false


func handle_action(action_name: StringName) -> bool:
	if is_gameplay_paused:
		return false

	var accepted := _lane_state.handle_action(action_name)
	if not accepted:
		return false

	match action_name:
		&"move_left", &"move_right":
			_animate_lane_change()
		&"jump", &"slide":
			_play_neutral_action_animation(action_name)
	return true


func reset_for_practice() -> void:
	for tween in [_lane_tween, _action_tween, _shadow_tween, _slide_scale_tween, _slide_rotation_tween]:
		if tween != null:
			tween.kill()
	_lane_state = PlayerLaneStateModel.new()
	is_gameplay_paused = false
	_run_phase = 0.0
	_landing_remaining = 0.0
	_lane_remaining = 0.0
	landing_ring.visible = false
	lane_trail.visible = false
	position.x = LANE_X[lane_index]
	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE
	visual.rotation = 0.0
	shadow.scale = Vector2.ONE
	slide_streak.visible = false


func _animate_lane_change() -> void:
	if _lane_tween != null:
		_lane_tween.kill()
	_lane_tween = create_tween()
	_lane_remaining = LANE_TWEEN_SECONDS
	_lane_direction = signf(LANE_X[lane_index] - position.x)
	_lane_tween.set_trans(Tween.TRANS_CUBIC)
	_lane_tween.set_ease(Tween.EASE_OUT)
	_lane_tween.tween_property(self, ^"position:x", LANE_X[lane_index], LANE_TWEEN_SECONDS)


func _process(delta: float) -> void:
	if is_gameplay_paused:
		return
	_run_phase = fposmod(_run_phase + delta * 10.0, TAU)
	var stride := sin(_run_phase)
	var is_running := action_state == PlayerLaneStateModel.ActionState.IDLE
	if is_running:
		character_sprite.texture = PETER_RUN_A if sin(_run_phase) >= 0.0 else PETER_RUN_B
	left_leg.rotation = stride * 0.28 if is_running else -0.18
	right_leg.rotation = -stride * 0.28 if is_running else 0.18
	left_leg.position.y = maxf(0.0, stride) * -2.5 if is_running else 0.0
	right_leg.position.y = maxf(0.0, -stride) * -2.5 if is_running else 0.0
	left_arm.rotation = -stride * 0.22 if is_running else -0.3
	right_arm.rotation = stride * 0.22 if is_running else 0.3
	if action_state == PlayerLaneStateModel.ActionState.JUMP:
		visual.scale = Vector2(0.96, 1.06)
		left_leg.position.y = -4.0
		right_leg.position.y = -4.0
		left_arm.rotation = 0.45
		right_arm.rotation = -0.45
	_update_ground_feedback(delta)
	if is_running:
		visual.position.y = -absf(stride) * 1.3
		visual.rotation = clampf((LANE_X[lane_index] - position.x) * 0.002, -0.14, 0.14)
		var squash := sin(_landing_remaining / LANDING_SECONDS * PI) * 0.12
		visual.scale = Vector2(1.0 + squash, 1.0 - squash)


func _update_ground_feedback(delta: float) -> void:
	_landing_remaining = maxf(0.0, _landing_remaining - delta)
	landing_ring.visible = _landing_remaining > 0.0
	if landing_ring.visible:
		var fraction := 1.0 - _landing_remaining / LANDING_SECONDS
		landing_ring.scale = Vector2.ONE * lerpf(0.65, 1.4, fraction)
		landing_ring.modulate.a = (1.0 - fraction) * 0.5
	_lane_remaining = maxf(0.0, _lane_remaining - delta)
	lane_trail.visible = _lane_remaining > 0.0 and action_state != PlayerLaneStateModel.ActionState.JUMP
	if lane_trail.visible:
		var fraction := 1.0 - _lane_remaining / LANE_TWEEN_SECONDS
		lane_trail.scale.x = _lane_direction
		lane_trail.modulate.a = sin(fraction * PI) * 0.45


func _play_neutral_action_animation(action_name: StringName) -> void:
	if _action_tween != null:
		_action_tween.kill()
	if _slide_scale_tween != null:
		_slide_scale_tween.kill()
	if _slide_rotation_tween != null:
		_slide_rotation_tween.kill()

	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE
	visual.rotation = 0.0
	shadow.scale = Vector2.ONE
	slide_streak.visible = false
	_action_tween = create_tween()

	if action_name == &"jump":
		character_sprite.texture = PETER_JUMP
		_action_tween.tween_property(visual, ^"position:y", JUMP_HEIGHT, JUMP_RISE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_action_tween.tween_interval(JUMP_HOLD_SECONDS)
		_action_tween.tween_property(visual, ^"position:y", 0.0, JUMP_RETURN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_play_jump_shadow_animation()
	else:
		character_sprite.texture = PETER_SLIDE
		slide_streak.visible = true
		_action_tween.tween_property(visual, ^"position", Vector2(5.0, 7.0), ACTION_RISE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_action_tween.tween_property(visual, ^"position", Vector2.ZERO, ACTION_RETURN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_play_slide_pose_animation()

	_action_tween.tween_callback(_finish_action_animation)


func _finish_action_animation() -> void:
	character_sprite.texture = PETER_LAND if action_state == PlayerLaneStateModel.ActionState.JUMP else PETER_IDLE
	if action_state == PlayerLaneStateModel.ActionState.JUMP:
		_landing_remaining = LANDING_SECONDS
		landing_ring.visible = true
		landing_ring.scale = Vector2.ONE * 0.65
		landing_ring.modulate.a = 0.5
	visual.position = Vector2.ZERO
	visual.scale = Vector2.ONE
	visual.rotation = 0.0
	shadow.scale = Vector2.ONE
	slide_streak.visible = false
	_lane_state.finish_action()


func _play_jump_shadow_animation() -> void:
	if _shadow_tween != null:
		_shadow_tween.kill()
	_shadow_tween = create_tween()
	_shadow_tween.tween_property(shadow, ^"scale", Vector2(0.48, 0.48), JUMP_RISE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_shadow_tween.tween_interval(JUMP_HOLD_SECONDS)
	_shadow_tween.tween_property(shadow, ^"scale", Vector2.ONE, JUMP_RETURN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _play_slide_pose_animation() -> void:
	_slide_scale_tween = create_tween()
	_slide_scale_tween.tween_property(visual, ^"scale", Vector2(1.18, 0.56), ACTION_RISE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_slide_scale_tween.tween_property(visual, ^"scale", Vector2.ONE, ACTION_RETURN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_slide_rotation_tween = create_tween()
	_slide_rotation_tween.tween_property(visual, ^"rotation", -0.10, ACTION_RISE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_slide_rotation_tween.tween_property(visual, ^"rotation", 0.0, ACTION_RETURN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func set_gameplay_paused(should_pause: bool) -> void:
	is_gameplay_paused = should_pause
	var tween_speed := 0.0 if should_pause else 1.0
	if _lane_tween != null:
		_lane_tween.set_speed_scale(tween_speed)
	if _action_tween != null:
		_action_tween.set_speed_scale(tween_speed)
	if _shadow_tween != null:
		_shadow_tween.set_speed_scale(tween_speed)
	if _slide_scale_tween != null:
		_slide_scale_tween.set_speed_scale(tween_speed)
	if _slide_rotation_tween != null:
		_slide_rotation_tween.set_speed_scale(tween_speed)


func _exit_tree() -> void:
	if _lane_tween != null:
		_lane_tween.kill()
	if _action_tween != null:
		_action_tween.kill()
	if _shadow_tween != null:
		_shadow_tween.kill()
	if _slide_scale_tween != null:
		_slide_scale_tween.kill()
	if _slide_rotation_tween != null:
		_slide_rotation_tween.kill()
