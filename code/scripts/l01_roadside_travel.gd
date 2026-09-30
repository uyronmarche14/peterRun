class_name L01RoadsideTravel
extends Node2D

const GameSettings = preload("res://scripts/game_settings.gd")
const RoadProjectionModel = preload("res://scripts/road_projection.gd")

# Architectural sections pass along a single painted-curb ground path. The
# center of the road and the Hall never move with these decorative sections.
const CYCLE_DISTANCE := 20.0
const SPRITE_SIZE := 512.0
const CONTACT_Y := 480.0
const FAR_GROUND_Y := 120.0
const NEAR_GROUND_Y := 270.0
const FAR_LEFT_CURB_X := 195.0
const NEAR_LEFT_CURB_X := 0.0
const MODULE_DEFINITIONS: Array[Dictionary] = [
	{"path": "res://art/backgrounds/l01_barangay_v08/l01_v08_left_bungalow.png", "side": -1, "phase": 0.08},
	{"path": "res://art/backgrounds/l01_barangay_v08/l01_v08_left_mixed_home.png", "side": -1, "phase": 0.58},
	{"path": "res://art/backgrounds/l01_barangay_v08/l01_v08_right_sari_sari.png", "side": 1, "phase": 0.23},
	{"path": "res://art/backgrounds/l01_barangay_v08/l01_v08_right_waiting_shed.png", "side": 1, "phase": 0.68},
]

var motion_paused := false
var reduced_motion := GameSettings.reduced_motion
var motion_distance := 0.0
var _module_sprites: Array[Sprite2D] = []
var _module_sides: Array[int] = []
var _module_phases: Array[float] = []


func _ready() -> void:
	_build_module_pool()
	_project_all_modules()


func _build_module_pool() -> void:
	for definition in MODULE_DEFINITIONS:
		var side := int(definition["side"])
		var sprite := Sprite2D.new()
		sprite.name = String(String(definition["path"]).get_file().get_basename())
		sprite.texture = load(String(definition["path"])) as Texture2D
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# The inner edge stays outside the curb; all visible art extends outward.
		sprite.offset = Vector2(-SPRITE_SIZE if side < 0 else 0.0, -CONTACT_Y)
		add_child(sprite)
		_module_sprites.append(sprite)
		_module_sides.append(side)
		_module_phases.append(float(definition["phase"]))


func set_travel_distance(distance: float) -> void:
	if motion_paused or reduced_motion:
		return
	motion_distance = maxf(0.0, distance)
	_project_all_modules()


func set_motion_paused(should_pause: bool) -> void:
	motion_paused = should_pause


func set_reduced_motion(should_reduce: bool) -> void:
	reduced_motion = should_reduce


func get_module_sprites() -> Array[Sprite2D]:
	return _module_sprites


func get_module_sides() -> Array[int]:
	return _module_sides


func get_module_depth_fractions() -> Array[float]:
	var depths: Array[float] = []
	for phase in _module_phases:
		depths.append(fposmod(motion_distance / CYCLE_DISTANCE + phase, 1.0))
	return depths


func get_module_ground_points() -> Array[Vector2]:
	var grounds: Array[Vector2] = []
	for sprite in _module_sprites:
		grounds.append(sprite.position)
	return grounds


func get_module_visible_bounds() -> Array[Rect2]:
	var bounds: Array[Rect2] = []
	for sprite in _module_sprites:
		bounds.append(Rect2(sprite.position + sprite.offset * sprite.scale, sprite.texture.get_size() * sprite.scale))
	return bounds


func painted_curb_x(side: int, ground_y: float) -> float:
	var fraction := clampf((ground_y - FAR_GROUND_Y) / (NEAR_GROUND_Y - FAR_GROUND_Y), 0.0, 1.0)
	var left := lerpf(FAR_LEFT_CURB_X, NEAR_LEFT_CURB_X, fraction)
	return left if side < 0 else 480.0 - left


func _project_all_modules() -> void:
	for index in _module_sprites.size():
		_project_module(index)


func _project_module(index: int) -> void:
	var sprite := _module_sprites[index]
	var side := _module_sides[index]
	var depth := fposmod(motion_distance / CYCLE_DISTANCE + _module_phases[index], 1.0)
	var projection := RoadProjectionModel.depth_curve(depth)
	var ground_y := lerpf(FAR_GROUND_Y, NEAR_GROUND_Y, projection)
	var curb_x := painted_curb_x(side, ground_y)
	var verge_gap := lerpf(3.0, 6.0, projection)
	var scale_value := lerpf(0.075, 0.30, projection)
	var fade_in := smoothstep(0.20, 0.38, depth)
	var fade_out := 1.0 - smoothstep(0.86, 1.0, depth)
	var distance_haze := lerpf(0.75, 1.0, projection)
	sprite.position = Vector2(curb_x + float(side) * verge_gap, ground_y)
	sprite.scale = Vector2.ONE * scale_value
	sprite.modulate = Color(0.96, 0.98, 0.94, fade_in * fade_out * distance_haze)
	sprite.visible = sprite.modulate.a > 0.01
	sprite.z_index = 1 if depth > 0.55 else 0
