class_name WorldMotionController
extends Node

const GameSettings = preload("res://scripts/game_settings.gd")
const RoadProjectionModel = preload("res://scripts/road_projection.gd")
const L01VisualGuide = preload("res://scripts/l01_visual_geometry.gd")

# Constant travel in depth projects to increasing screen speed near the player.
# Warning/response timing comes from the session.
const ROAD_LOOP_SECONDS := 5.25
const L01_PROP_CURB_CLEARANCE := 18.5
const L01_PROP_MAX_LANE_INSET := 8.0
const L01_PROP_SEPARATOR_CLEARANCE := 2.0

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
var _prop_visual_half_widths: Dictionary = {}

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
	var depth_scale := RoadProjectionModel.scale_at(fraction)
	var lane_span := RoadProjectionModel.lane_span_at(fraction)
	var prompt_y := RoadProjectionModel.screen_y_at(fraction)
	for child_value in prop_container.get_children():
		var child := child_value as Node2D
		if child == null or not child.visible:
			continue
		var footprint_value: Variant = child.get_meta(&"projection_footprint", Vector2.ZERO)
		var footprint := footprint_value as Vector2
		var fit := RoadProjectionModel.prop_fit_scale(footprint, fraction)
		var l01_height_cap := float(child.get_meta(&"l01_screen_height_cap", 0.0))
		if road_presentation.visible and l01_height_cap > 0.0 and footprint.y > 0.0:
			fit = minf(fit, l01_height_cap / (footprint.y * depth_scale))
		var lane := _lane_for_prop(child)
		var base_local_x := float(lane - _prompt_lane) * lane_span / depth_scale
		var inset := 0.0
		if road_presentation.visible and lane != 1:
			var side := -1 if lane == 0 else 1
			var centre_x := RoadProjectionModel.lane_center_at(lane, fraction)
			var curb_x := L01VisualGuide.painted_curb_x(side, prompt_y)
			var visual_half_width := _get_prop_visual_half_width(child, footprint)
			var projected_half_width := visual_half_width * depth_scale * fit
			var current_clearance := centre_x - projected_half_width - curb_x if side < 0 else curb_x - centre_x - projected_half_width
			var needed_inset := maxf(0.0, L01_PROP_CURB_CLEARANCE - current_clearance)
			inset = minf(needed_inset, minf(L01_PROP_MAX_LANE_INSET, lane_span * 0.1))
			var adjusted_centre := centre_x - float(side) * inset
			var curb_room := adjusted_centre - curb_x - L01_PROP_CURB_CLEARANCE if side < 0 else curb_x - adjusted_centre - L01_PROP_CURB_CLEARANCE
			var separator_x := RoadProjectionModel.lane_separator_at(0 if side < 0 else 1, fraction)
			var separator_room := separator_x - adjusted_centre - L01_PROP_SEPARATOR_CLEARANCE if side < 0 else adjusted_centre - separator_x - L01_PROP_SEPARATOR_CLEARANCE
			fit = minf(fit, maxf(0.0, minf(curb_room, separator_room)) / (visual_half_width * depth_scale))
		child.position.x = base_local_x + (inset if lane == 0 else -inset) / depth_scale
		child.scale = Vector2.ONE * fit


func _lane_for_prop(prop: Node2D) -> int:
	var formation_index := _formation_nodes.find(prop)
	if formation_index >= 0 and formation_index < _formation_lanes.size():
		return _formation_lanes[formation_index]
	var companion_index := _companion_nodes.find(prop)
	if companion_index >= 0 and companion_index < _companion_lanes.size():
		return _companion_lanes[companion_index]
	return _prompt_lane


func _get_prop_visual_half_width(prop: Node2D, fallback: Vector2) -> float:
	var key := prop.get_instance_id()
	if _prop_visual_half_widths.has(key):
		return _prop_visual_half_widths[key]
	var half_width := maxf(1.0, fallback.x * 0.5)
	for child in prop.get_children():
		var sprite := child as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var source_image := sprite.texture.get_image()
		if source_image == null:
			continue
		var used := source_image.get_used_rect()
		if used.size == Vector2i.ZERO:
			continue
		var left := sprite.position.x + (sprite.get_rect().position.x + float(used.position.x)) * sprite.scale.x
		var right := left + float(used.size.x) * sprite.scale.x
		half_width = maxf(half_width, maxf(absf(left), absf(right)))
	_prop_visual_half_widths[key] = half_width
	return half_width


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
