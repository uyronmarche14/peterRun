class_name WorldMotionController
extends Node

const GameSettings = preload("res://scripts/game_settings.gd")
const RoadProjectionModel = preload("res://scripts/road_projection.gd")
const L01VisualGuide = preload("res://scripts/l01_visual_geometry.gd")

# Constant travel in depth projects to increasing screen speed near the player.
# Warning/response timing comes from the session.
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
var _companion_nodes: Array[Node2D] = []
var _companion_lanes: Array[int] = []
var _formation_nodes: Array[Node2D] = []
var _formation_lanes: Array[int] = []
var _road_dashes: Array[Line2D] = []

@onready var road_motion_dashes: Node2D = get_node("../LevelWorld/RoadAndLanes/RoadMotionDashes") as Node2D
@onready var road_presentation: Node2D = get_node("../LevelWorld/RoadAndLanes/RoadPresentation") as Node2D
@onready var roadside_travel: Node2D = get_node("../LevelWorld/RoadsideMotion") as Node2D
@onready var prompt_anchor: Marker2D = get_node("../LevelWorld/PromptWorldAnchor") as Marker2D


func _ready() -> void:
	for child in road_motion_dashes.get_children():
		if child is Line2D:
			_road_dashes.append(child)
	# Initialize the subtle projected seams before the first rendered frame so
	# their authored editor placeholders can never flash as opaque bars.
	_update_road()
	roadside_travel.call("set_travel_distance", motion_distance)


func _process(delta: float) -> void:
	if is_motion_paused:
		return
	motion_distance += delta * GameSettings.visual_pace
	_update_road()
	roadside_travel.call("set_reduced_motion", GameSettings.reduced_motion)
	if not GameSettings.reduced_motion:
		roadside_travel.call("set_travel_distance", motion_distance)
	if not _prompt_is_visible:
		return
	_prompt_elapsed += delta
	_apply_prompt_projection()
	if _is_resolving:
		_exit_elapsed += delta
		var exit_fraction := clampf(_exit_elapsed / _exit_duration, 0.0, 1.0)
		# Keep the neutral resolution continuous: the grounded prop drifts a
		# short distance past the contact line while it fades, never teleporting.
		prompt_anchor.position.y += lerpf(0.0, 14.0, smoothstep(0.0, 1.0, exit_fraction))
		prompt_anchor.modulate.a = 1.0 - smoothstep(0.0, 1.0, exit_fraction)
		if _exit_success:
			prompt_anchor.modulate.g = 1.0 + 0.12 * sin(exit_fraction * PI)
		if exit_fraction >= 1.0:
			_prompt_is_visible = false


func _perspective_scale(fraction: float) -> float:
	return RoadProjectionModel.scale_at(fraction)


func _screen_y(depth_scale: float) -> float:
	return RoadProjectionModel.screen_y_at(RoadProjectionModel.fraction_from_scale(depth_scale))


func _apply_prompt_projection() -> void:
	var fraction := clampf(_prompt_elapsed / _approach_duration, 0.0, 1.0)
	var depth_scale := RoadProjectionModel.scale_at(fraction)
	prompt_anchor.position = Vector2(RoadProjectionModel.lane_center_at(_prompt_lane, fraction), RoadProjectionModel.screen_y_at(fraction))
	prompt_anchor.scale = Vector2.ONE * depth_scale
	# Distance haze clears as the prop approaches, reinforcing depth without a
	# flash, screen shake, or change to the response window.
	prompt_anchor.modulate.a = lerpf(0.72, 1.0, smoothstep(0.0, 0.42, fraction))
	_update_prompt_depth_details(fraction)
	var local_lane_spacing := RoadProjectionModel.lane_span_at(fraction) / depth_scale
	for index in mini(_companion_nodes.size(), _companion_lanes.size()):
		var companion := _companion_nodes[index]
		if not is_instance_valid(companion):
			continue
		companion.position = Vector2((_companion_lanes[index] - _prompt_lane) * local_lane_spacing, 0.0)
		companion.scale = Vector2.ONE
	for index in mini(_formation_nodes.size(), _formation_lanes.size()):
		var formation_prop := _formation_nodes[index]
		if not is_instance_valid(formation_prop):
			continue
		formation_prop.position = Vector2((_formation_lanes[index] - _prompt_lane) * local_lane_spacing, 0.0)
	_apply_lane_safe_prop_scales(fraction)
	# Props draw behind the player until their ground contact passes the feet.
	prompt_anchor.z_index = 2 if prompt_anchor.position.y > RoadProjectionModel.PLAYER_CONTACT_Y else 0


func _update_road() -> void:
	road_motion_dashes.visible = not GameSettings.reduced_motion
	if GameSettings.reduced_motion:
		return
	for index in _road_dashes.size():
		var fraction := fposmod(motion_distance / ROAD_LOOP_SECONDS + float(index) / _road_dashes.size(), 1.0)
		var projection_fraction := clampf(fraction * 1.06, 0.0, 1.0)
		var depth_scale := RoadProjectionModel.scale_at(projection_fraction)
		var y := RoadProjectionModel.screen_y_at(projection_fraction)
		var road_half_width := (L01VisualGuide.painted_curb_x(1, y) - L01VisualGuide.painted_curb_x(-1, y)) * 0.5 if road_presentation.visible else RoadProjectionModel.road_half_width_at(projection_fraction)
		var half_width := road_half_width * 0.82
		var dash := _road_dashes[index]
		dash.set_point_position(0, Vector2(RoadProjectionModel.SCREEN_CENTRE_X - half_width, y))
		dash.set_point_position(1, Vector2(RoadProjectionModel.SCREEN_CENTRE_X + half_width, y))
		dash.width = maxf(0.5, depth_scale * 0.7)
		var seam_intensity := 0.30 if road_presentation.visible else 0.18
		dash.modulate.a = smoothstep(0.0, 0.12, fraction) * (1.0 - smoothstep(0.84, 1.0, fraction)) * seam_intensity


func set_motion_paused(should_pause: bool) -> void:
	is_motion_paused = should_pause
	roadside_travel.call("set_motion_paused", should_pause)


func _update_prompt_depth_details(fraction: float) -> void:
	var prop_container := prompt_anchor.get_node_or_null(^"PromptProps")
	if prop_container == null:
		return
	var arrival := smoothstep(0.28, 1.0, fraction)
	var calm_pulse := 0.96 + sin(fraction * TAU * 2.0) * 0.04
	for child in prop_container.get_children():
		if not child is Node2D or not child.visible:
			continue
		var highlight := child.get_node_or_null(^"ActiveHighlight") as CanvasItem
		if highlight != null:
			highlight.modulate.a = lerpf(0.16, 0.42, arrival) * calm_pulse
		var contact_shadow := child.get_node_or_null(^"ContactShadow") as CanvasItem
		if contact_shadow != null:
			contact_shadow.modulate.a = lerpf(0.16, 0.38, arrival)


func _apply_lane_safe_prop_scales(fraction: float) -> void:
	var prop_container := prompt_anchor.get_node_or_null(^"PromptProps")
	if prop_container == null:
		return
	for child_value in prop_container.get_children():
		var child := child_value as Node2D
		if child == null or not child.visible:
			continue
		var footprint_value: Variant = child.get_meta(&"projection_footprint", Vector2.ZERO)
		var footprint := footprint_value as Vector2
		child.scale = Vector2.ONE * RoadProjectionModel.prop_fit_scale(footprint, fraction)


func lane_center_for(lane: int, fraction: float) -> float:
	return RoadProjectionModel.lane_center_at(lane, fraction)


func road_edge_for(side: int, fraction: float) -> float:
	return RoadProjectionModel.road_edge_at(side, fraction)


func begin_prompt_approach(lane: int = 1, warning_seconds: float = 2.5, response_seconds: float = 2.0) -> void:
	_prompt_is_visible = true
	_prompt_elapsed = 0.0
	_prompt_lane = clampi(lane, 0, 2)
	_approach_duration = maxf(0.01, warning_seconds + response_seconds)
	_is_resolving = false
	_exit_elapsed = 0.0
	prompt_anchor.modulate = Color.WHITE
	_apply_prompt_projection()


func set_prompt_companions(nodes: Array[Node2D], lanes: Array[int]) -> void:
	_companion_nodes = nodes
	_companion_lanes = lanes


func set_prompt_formation(nodes: Array[Node2D], lanes: Array[int]) -> void:
	_formation_nodes = nodes
	_formation_lanes = lanes


func resolve_prompt_approach(success: bool, duration: float = 0.75) -> void:
	_is_resolving = true
	_exit_elapsed = 0.0
	_exit_duration = maxf(0.01, duration)
	_exit_success = success


func hide_prompt_approach() -> void:
	_prompt_is_visible = false
	_is_resolving = false
	prompt_anchor.modulate.a = 0.0
	_formation_nodes.clear()
	_formation_lanes.clear()
