class_name L01PassingStreet
extends Node2D

## Decorative 2.5D roadside subjects. This node lives below a 0.5-scaled
## stage plate, so its sprite coordinates are in the 960x540 art canvas.
## Neither the road nor the curb are included in a moving texture.
const Guide = preload("res://scripts/l01_visual_geometry.gd")
const MANIFEST := "res://art/backgrounds/l01_roadside_v12/l01_v12_passing_street.json"
const FAR_Y := 132.0
const NEAR_Y := 248.0
const CYCLE_DISTANCE := 34.0
const VERGE_GAP := 4.0
const TEXTURE_SIZE := 512.0

@export var stage_slug := "home"

var motion_distance := 0.0
var motion_paused := false
var _sprites: Array[Sprite2D] = []
var _sides: Array[int] = []
var _phases: Array[float] = []
var _ground_ys: Array[float] = []


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not parsed is Dictionary or not parsed.has("stages"):
		push_error("L01 passing-street manifest is unavailable")
		return
	var stages: Dictionary = parsed["stages"]
	var entries: Array = stages.get(stage_slug, [])
	for index in entries.size():
		var entry: Dictionary = entries[index]
		var texture := load(String(entry.get("texture", ""))) as Texture2D
		if texture == null:
			push_error("Missing passing-street texture in " + stage_slug)
			continue
		var side := -1 if entry.get("side", "left") == "left" else 1
		var sprite := Sprite2D.new()
		sprite.name = "Passer_%s_%02d" % ["Left" if side < 0 else "Right", index]
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.centered = false
		sprite.use_parent_material = true
		sprite.offset = Vector2(-TEXTURE_SIZE if side < 0 else 0.0, -485.0 if String(entry["texture"]).contains("l01_roadside_v12") else -480.0)
		add_child(sprite)
		_sprites.append(sprite)
		_sides.append(side)
		_phases.append(float(entry.get("phase", 0.0)))
		_ground_ys.append(FAR_Y)
	_project_all()


func set_travel_distance(distance: float) -> void:
	if motion_paused:
		return
	motion_distance = maxf(0.0, distance)
	_project_all()


func set_motion_paused(should_pause: bool) -> void:
	motion_paused = should_pause


func get_module_sprites() -> Array[Sprite2D]:
	return _sprites


func get_module_bounds() -> Array[Dictionary]:
	var bounds: Array[Dictionary] = []
	for index in _sprites.size():
		var sprite := _sprites[index]
		var native_scale := sprite.scale.x * 0.5
		var position := (sprite.position + sprite.offset * sprite.scale) * 0.5
		bounds.append({
			"rect": Rect2(position, Vector2.ONE * TEXTURE_SIZE * native_scale),
			"side": _sides[index],
			"ground_y": _ground_ys[index],
		})
	return bounds


func _project_all() -> void:
	for index in _sprites.size():
		var sprite := _sprites[index]
		var side := _sides[index]
		var phase := fposmod(motion_distance / CYCLE_DISTANCE + _phases[index], 1.0)
		var depth := pow(phase, 1.18)
		var ground_y := lerpf(FAR_Y, NEAR_Y, depth)
		var curb_x := Guide.painted_curb_x(side, ground_y)
		var scale_value := lerpf(0.20, 0.72, pow(depth, 1.18))
		var edge_x := curb_x + float(side) * VERGE_GAP
		sprite.position = Vector2(edge_x * 2.0, ground_y * 2.0)
		sprite.scale = Vector2.ONE * scale_value
		# Keep the structure solid once it emerges from the far vegetation.
		# A long translucent fade reads as a ghost building against the Hall.
		sprite.modulate = Color(0.95, 0.97, 0.95, smoothstep(0.06, 0.085, phase) * (1.0 - smoothstep(0.93, 0.97, phase)))
		sprite.visible = sprite.modulate.a > 0.01
		_ground_ys[index] = ground_y
