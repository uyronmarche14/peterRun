class_name PlayerController
extends Node2D

const PlayerLaneStateModel = preload("res://scripts/player_lane_state.gd")

const LANE_X := [128.0, 240.0, 352.0]
const LANE_TWEEN_SECONDS := 0.24
const JUMP_HEIGHT := -30.0
const ACTION_RISE_SECONDS := 0.20
const ACTION_RETURN_SECONDS := 0.28

var _lane_state := PlayerLaneStateModel.new()
var _lane_tween: Tween
var _action_tween: Tween
var _shadow_tween: Tween
var _slide_scale_tween: Tween
var _slide_rotation_tween: Tween
var is_gameplay_paused := false

@onready var visual: Node2D = $Visual
@onready var shadow: Node2D = $Shadow
@onready var slide_streak: Line2D = $SlideStreak

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


func _animate_lane_change() -> void:
	if _lane_tween != null:
		_lane_tween.kill()
	_lane_tween = create_tween()
	_lane_tween.set_trans(Tween.TRANS_SINE)
	_lane_tween.set_ease(Tween.EASE_IN_OUT)
	_lane_tween.tween_property(self, ^"position:x", LANE_X[lane_index], LANE_TWEEN_SECONDS)


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
		_action_tween.tween_property(visual, ^"position:y", JUMP_HEIGHT, ACTION_RISE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_action_tween.tween_property(visual, ^"position:y", 0.0, ACTION_RETURN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_play_jump_shadow_animation()
	else:
		slide_streak.visible = true
		_action_tween.tween_property(visual, ^"position", Vector2(5.0, 7.0), ACTION_RISE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_action_tween.tween_property(visual, ^"position", Vector2.ZERO, ACTION_RETURN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_play_slide_pose_animation()

	_action_tween.tween_callback(_finish_action_animation)


func _finish_action_animation() -> void:
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
	_shadow_tween.tween_property(shadow, ^"scale", Vector2(0.62, 0.62), ACTION_RISE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_shadow_tween.tween_property(shadow, ^"scale", Vector2.ONE, ACTION_RETURN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


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
