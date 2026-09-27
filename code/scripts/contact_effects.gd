class_name ContactEffects
extends Node2D

## One reusable canvas for small contact-line feedback. This is visual only:
## it never affects lane selection, prompt timing, or scoring.

const GameSettings = preload("res://scripts/game_settings.gd")

var active_effect: StringName = &""
var elapsed := 0.0
var duration := 0.42
var _paused := false
var _is_positive := false


func _ready() -> void:
	visible = false
	set_process(false)


func play_for_action(action_name: StringName, resolution: int, contact_position: Vector2) -> void:
	active_effect = action_name if action_name in [&"move_left", &"move_right", &"jump", &"slide"] else &"neutral"
	_is_positive = resolution != PromptDirector.Resolution.NEUTRAL_MISS
	position = contact_position
	elapsed = 0.0
	duration = 0.14 if GameSettings.reduced_motion else 0.42
	visible = not _paused
	set_process(not _paused)
	queue_redraw()


func set_effects_paused(should_pause: bool) -> void:
	_paused = should_pause
	visible = not should_pause and elapsed < duration
	set_process(not should_pause and elapsed < duration)


func _process(delta: float) -> void:
	if _paused:
		return
	elapsed = minf(duration, elapsed + delta)
	queue_redraw()
	if elapsed >= duration:
		visible = false
		set_process(false)


func _draw() -> void:
	if duration <= 0.0 or elapsed >= duration:
		return
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var intensity: float = GameSettings.effects_intensity
	var alpha := (1.0 - progress) * (0.82 if _is_positive else 0.48) * intensity
	var color := Color(0.48, 0.91, 0.73, alpha) if _is_positive else Color(0.93, 0.77, 0.43, alpha)
	match active_effect:
		&"jump":
			var radius := lerpf(8.0, 29.0, progress)
			draw_arc(Vector2(0.0, 13.0), radius, PI * 1.08, PI * 1.92, 16, color, 1.5 * intensity, true)
			draw_arc(Vector2(0.0, 13.0), radius * 0.67, PI * 1.12, PI * 1.88, 12, color.lightened(0.12), intensity, true)
		&"slide":
			var reach := lerpf(9.0, 37.0, progress)
			draw_line(Vector2(-reach, 12.0), Vector2(-4.0, 12.0), color, 2.0 * intensity, true)
			draw_line(Vector2(-reach * 0.72, 17.0), Vector2(-6.0, 17.0), color.darkened(0.12), intensity, true)
		&"move_left", &"move_right":
			var direction := -1.0 if active_effect == &"move_left" else 1.0
			var travel := lerpf(3.0, 31.0, progress) * direction
			draw_line(Vector2(0.0, 10.0), Vector2(travel, 10.0), color, 2.0 * intensity, true)
			draw_line(Vector2(travel, 10.0), Vector2(travel - direction * 5.0, 6.0), color, 1.25 * intensity, true)
			draw_line(Vector2(travel, 10.0), Vector2(travel - direction * 5.0, 14.0), color, 1.25 * intensity, true)
		_:
			draw_arc(Vector2(0.0, 13.0), lerpf(5.0, 16.0, progress), 0.0, TAU, 16, color, 1.25 * intensity, true)
