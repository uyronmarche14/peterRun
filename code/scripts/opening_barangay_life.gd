class_name OpeningBarangayLife
extends Node2D

const GameSettings = preload("res://scripts/game_settings.gd")

var _elapsed := 0.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if GameSettings.reduced_motion:
		return
	_elapsed = fmod(_elapsed + delta * 0.55, TAU)
	queue_redraw()


func is_reduced_motion_aware() -> bool:
	return true


func _draw() -> void:
	var drift := 0.0 if GameSettings.reduced_motion else sin(_elapsed) * 2.0
	var glow := 0.10 if GameSettings.reduced_motion else 0.10 + (sin(_elapsed * 0.8) + 1.0) * 0.018
	# Gentle sunlight, cloud drift, and small route-side life sit over the static Blender hero.
	draw_circle(Vector2(276, 72), 30.0, Color(1.0, 0.72, 0.26, glow))
	for cloud_part in [Vector2(0, 0), Vector2(8, -2), Vector2(16, 1)]:
		draw_circle(Vector2(374 + drift * 0.35, 99) + cloud_part, 8.0, Color(1.0, 0.94, 0.75, 0.10))
	for offset in ([-8.0, 0.0, 8.0]):
		var bird := Vector2(339.0 + offset + drift, 79.0 + abs(offset) * 0.12)
		draw_arc(bird, 2.1, PI * 1.08, PI * 1.92, 6, Color(0.05, 0.16, 0.17, 0.46), 0.65)
		draw_arc(bird + Vector2(4.0, 0.0), 2.1, PI * 1.08, PI * 1.92, 6, Color(0.05, 0.16, 0.17, 0.46), 0.65)
	var sway := 0.0 if GameSettings.reduced_motion else sin(_elapsed * 1.3) * 1.2
	for base in [Vector2(365, 228), Vector2(379, 230), Vector2(394, 232)]:
		draw_line(base, base + Vector2(sway, -7), Color(0.09, 0.36, 0.20, 0.55), 1.0)
		draw_circle(base + Vector2(sway, -6), 2.5, Color(0.27, 0.59, 0.27, 0.42))
	# A quiet laundry line and awning edge move only a few pixels; neither conveys gameplay state.
	var fabric_sway := 0.0 if GameSettings.reduced_motion else sin(_elapsed * 1.5) * 1.4
	draw_line(Vector2(362, 177), Vector2(388, 177), Color(0.33, 0.17, 0.08, 0.38), 0.7)
	draw_colored_polygon(PackedVector2Array([Vector2(369, 177), Vector2(375, 177), Vector2(372 + fabric_sway, 184)]), Color(0.74, 0.29, 0.20, 0.36))
	draw_colored_polygon(PackedVector2Array([Vector2(379, 177), Vector2(385, 177), Vector2(382 - fabric_sway, 184)]), Color(0.96, 0.61, 0.14, 0.34))
	draw_line(Vector2(320, 151), Vector2(350, 151 + fabric_sway * 0.18), Color(0.74, 0.29, 0.20, 0.38), 1.1)
	var glint := 0.34 if GameSettings.reduced_motion else 0.22 + (sin(_elapsed * 1.7) + 1.0) * 0.12
	draw_line(Vector2(349, 168), Vector2(353, 164), Color(1.0, 0.89, 0.55, glint), 0.8)
	draw_line(Vector2(349, 164), Vector2(353, 168), Color(1.0, 0.89, 0.55, glint), 0.8)
