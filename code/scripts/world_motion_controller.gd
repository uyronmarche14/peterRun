class_name WorldMotionController
extends Node

const ROAD_DASH_SPEED := 18.0
const ROAD_DASH_LOOP_DISTANCE := 28.0
const PROMPT_APPROACH_DURATION := 2.5
const PROMPT_APPROACH_DISTANCE := 54.0
const PROMPT_APPROACH_SCALE := 0.38

var is_motion_paused := false
var motion_distance := 0.0
var _prompt_is_visible := false
var _prompt_elapsed := 0.0

@onready var road_motion_dashes: Node2D = get_node("../LevelWorld/RoadAndLanes/RoadMotionDashes") as Node2D
@onready var prompt_anchor: Marker2D = get_node("../LevelWorld/PromptWorldAnchor") as Marker2D
@onready var distant_hills: Polygon2D = get_node("../LevelWorld/DistantHills") as Polygon2D
@onready var prompt_ground_shadow: Polygon2D = get_node("../LevelWorld/PromptWorldAnchor/L01PromptProps/PromptGroundShadow") as Polygon2D


func _process(delta: float) -> void:
	if is_motion_paused:
		return

	motion_distance += delta
	road_motion_dashes.position.y = fposmod(motion_distance * ROAD_DASH_SPEED, ROAD_DASH_LOOP_DISTANCE)
	distant_hills.position.x = sin(motion_distance * 0.25) * 2.0

	if _prompt_is_visible:
		_prompt_elapsed += delta
		var normalized_time := clampf(_prompt_elapsed / PROMPT_APPROACH_DURATION, 0.0, 1.0)
		var eased_time := normalized_time * normalized_time * (3.0 - 2.0 * normalized_time)
		prompt_anchor.position.y = 104.0 + PROMPT_APPROACH_DISTANCE * eased_time
		prompt_anchor.scale = Vector2.ONE * (1.0 + PROMPT_APPROACH_SCALE * eased_time)
		prompt_ground_shadow.scale = Vector2.ONE * (0.78 + 0.62 * eased_time)
		prompt_ground_shadow.modulate.a = 0.45 + 0.45 * eased_time


func set_motion_paused(should_pause: bool) -> void:
	is_motion_paused = should_pause


func begin_prompt_approach() -> void:
	_prompt_is_visible = true
	_prompt_elapsed = 0.0
	prompt_anchor.position = Vector2(240.0, 104.0)
	prompt_anchor.scale = Vector2.ONE
	prompt_ground_shadow.visible = true
	prompt_ground_shadow.scale = Vector2.ONE * 0.78
	prompt_ground_shadow.modulate.a = 0.45


func hide_prompt_approach() -> void:
	_prompt_is_visible = false
	prompt_anchor.position = Vector2(240.0, 104.0)
	prompt_anchor.scale = Vector2.ONE
	prompt_ground_shadow.visible = false
	prompt_ground_shadow.scale = Vector2.ONE
	prompt_ground_shadow.modulate.a = 1.0
