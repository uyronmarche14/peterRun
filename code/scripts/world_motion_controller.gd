class_name WorldMotionController
extends Node

# Constant travel in depth projects to increasing screen speed near the player.
# Warning/response timing comes from the session.
const FAR_SCALE := 0.55
const PLAYER_SCALE := 1.35
const HORIZON_Y := 92.0
const PLAYER_PROMPT_Y := 218.0
const LANE_SPACING := 112.0
const ROAD_LOOP_SECONDS := 5.25

var is_motion_paused := false
var motion_distance := 0.0
var _prompt_is_visible := false
var _prompt_elapsed := 0.0
var _approach_duration := 4.5
var _prompt_lane := 1
var _is_resolving := false
var _exit_elapsed := 0.0
var _exit_duration := 0.75
var _exit_success := false
var _road_dashes: Array[Line2D] = []
var _roadside_markers: Array[Node2D] = []

@onready var road_motion_dashes: Node2D = get_node("../LevelWorld/RoadAndLanes/RoadMotionDashes") as Node2D
@onready var prompt_anchor: Marker2D = get_node("../LevelWorld/PromptWorldAnchor") as Marker2D
@onready var prompt_ground_shadow: Polygon2D = get_node("../LevelWorld/PromptWorldAnchor/L01PromptProps/PromptGroundShadow") as Polygon2D


func _ready() -> void:
	for child in road_motion_dashes.get_children():
		if child is Line2D:
			_road_dashes.append(child)
	for child in get_node("../LevelWorld/RoadsideMotion").get_children():
		if child is Node2D:
			_roadside_markers.append(child)
	_update_roadside()


func _process(delta: float) -> void:
	if is_motion_paused:
		return
	motion_distance += delta
	_update_road()
	_update_roadside()
	if not _prompt_is_visible:
		return
	_prompt_elapsed += delta
	_apply_prompt_projection()
	if _is_resolving:
		_exit_elapsed += delta
		var exit_fraction := clampf(_exit_elapsed / _exit_duration, 0.0, 1.0)
		prompt_anchor.modulate.a = 1.0 - smoothstep(0.0, 1.0, exit_fraction)
		if _exit_success:
			prompt_anchor.modulate.g = 1.0 + 0.12 * sin(exit_fraction * PI)
		if exit_fraction >= 1.0:
			_prompt_is_visible = false
			prompt_ground_shadow.visible = false


func _perspective_scale(fraction: float) -> float:
	return 1.0 / maxf(0.48, lerpf(1.0 / FAR_SCALE, 1.0 / PLAYER_SCALE, fraction))


func _screen_y(depth_scale: float) -> float:
	return HORIZON_Y + (PLAYER_PROMPT_Y - HORIZON_Y) * (depth_scale - FAR_SCALE) / (PLAYER_SCALE - FAR_SCALE)


func _apply_prompt_projection() -> void:
	var depth_scale := _perspective_scale(_prompt_elapsed / _approach_duration)
	prompt_anchor.position = Vector2(240.0 + (_prompt_lane - 1) * LANE_SPACING * depth_scale / PLAYER_SCALE, _screen_y(depth_scale))
	prompt_anchor.scale = Vector2.ONE * depth_scale
	# Props draw behind the player until their ground contact passes the feet.
	prompt_anchor.z_index = 2 if prompt_anchor.position.y > PLAYER_PROMPT_Y else 0
	prompt_ground_shadow.modulate.a = clampf(depth_scale / PLAYER_SCALE, 0.4, 0.8)


func _update_road() -> void:
	for index in _road_dashes.size():
		var fraction := fposmod(motion_distance / ROAD_LOOP_SECONDS + float(index) / _road_dashes.size(), 1.0)
		var depth_scale := _perspective_scale(fraction * 1.16)
		var y := _screen_y(depth_scale)
		var half_width := 142.0 * depth_scale / PLAYER_SCALE
		var dash := _road_dashes[index]
		dash.set_point_position(0, Vector2(240.0 - half_width, y))
		dash.set_point_position(1, Vector2(240.0 + half_width, y))
		dash.width = maxf(0.6, depth_scale)
		dash.modulate.a = smoothstep(0.0, 0.12, fraction) * (1.0 - smoothstep(0.86, 1.0, fraction)) * 0.35


func set_motion_paused(should_pause: bool) -> void:
	is_motion_paused = should_pause


func _update_roadside() -> void:
	# Fixed pool: no spawning or allocation as scenery passes the camera.
	for index in _roadside_markers.size():
		var fraction := fposmod(motion_distance / ROAD_LOOP_SECONDS + float(index / 2) / 3.0, 1.0)
		var depth_scale := _perspective_scale(fraction * 1.16)
		var side := -1.0 if index % 2 == 0 else 1.0
		var marker := _roadside_markers[index]
		marker.position = Vector2(240.0 + side * 192.0 * depth_scale / PLAYER_SCALE, _screen_y(depth_scale) + 15.0)
		marker.scale = Vector2.ONE * depth_scale
		marker.modulate.a = smoothstep(0.0, 0.12, fraction) * (1.0 - smoothstep(0.88, 1.0, fraction)) * 0.8


func begin_prompt_approach(lane: int = 1, warning_seconds: float = 2.5, response_seconds: float = 2.0) -> void:
	_prompt_is_visible = true
	_prompt_elapsed = 0.0
	_prompt_lane = clampi(lane, 0, 2)
	_approach_duration = maxf(0.01, warning_seconds + response_seconds)
	_is_resolving = false
	_exit_elapsed = 0.0
	prompt_anchor.modulate = Color.WHITE
	prompt_ground_shadow.visible = true
	prompt_ground_shadow.scale = Vector2.ONE
	_apply_prompt_projection()


func resolve_prompt_approach(success: bool, duration: float = 0.75) -> void:
	_is_resolving = true
	_exit_elapsed = 0.0
	_exit_duration = maxf(0.01, duration)
	_exit_success = success


func hide_prompt_approach() -> void:
	_prompt_is_visible = false
	_is_resolving = false
	prompt_anchor.modulate.a = 0.0
	prompt_ground_shadow.visible = false
