class_name L01HomePassingStreet
extends Node2D

const Guide = preload("res://scripts/l01_visual_geometry.gd")
const MANIFEST := "res://art/backgrounds/l01_home_v16_passby/l01_v16_home_passby.json"
const NEIGHBOUR_REST = preload("res://art/backgrounds/l01_stage_details_v08/home_neighbour_rest_v08.png")
const NEIGHBOUR_WAVE = preload("res://art/backgrounds/l01_stage_details_v08/home_neighbour_wave_v08.png")
const CYCLE_DISTANCE := 34.0

var motion_distance := 0.0
var motion_paused := false
var reduced_motion := true
var _sprites: Array[Sprite2D] = []
var _entries: Array[Dictionary] = []
var _contacts: Array[Dictionary] = []
var _neighbour: Sprite2D


func _ready() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not parsed is Dictionary:
		push_error("L01 Home passing-frontage manifest is unavailable")
		return
	for raw_entry in parsed.get("modules", []):
		var entry: Dictionary = raw_entry
		var texture := load(String(entry["texture"])) as Texture2D
		if texture == null:
			push_error("Missing L01 Home passing art: " + String(entry["texture"]))
			continue
		var sprite := Sprite2D.new()
		sprite.name = String(entry["id"])
		sprite.texture = texture
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.use_parent_material = true
		var contact: Array = entry["contact_px"]
		sprite.offset = -Vector2(float(contact[0]), float(contact[1]))
		add_child(sprite)
		if String(entry["id"]) == "right_sari_sari":
			_neighbour = Sprite2D.new()
			_neighbour.name = "NeighbourWave"
			_neighbour.texture = NEIGHBOUR_REST
			_neighbour.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_neighbour.use_parent_material = true
			_neighbour.scale = Vector2.ONE * 0.05
			# Feet sit at the shop's road-facing ground contact; the neighbour
			# inherits the same perspective scale and cannot detach on travel.
			_neighbour.position = Vector2(115.0, -35.0)
			sprite.add_child(_neighbour)
		_sprites.append(sprite)
		_entries.append(entry)
		_contacts.append({})
	set_reduced_motion(false)
	_project_all()


func set_travel_distance(distance: float) -> void:
	if motion_paused:
		return
	motion_distance = maxf(0.0, distance)
	if not reduced_motion:
		_project_all()


func set_motion_paused(should_pause: bool) -> void:
	motion_paused = should_pause


func set_reduced_motion(should_reduce: bool) -> void:
	if reduced_motion == should_reduce:
		return
	reduced_motion = should_reduce
	visible = not should_reduce
	var stage := get_parent()
	for name in [^"LeftStreet", ^"RightStreet", ^"StreetLife"]:
		var layer := stage.get_node_or_null(name) as CanvasItem
		if layer != null:
			layer.visible = should_reduce
	if not should_reduce:
		_project_all()


func get_module_sprites() -> Array[Sprite2D]:
	return _sprites


func get_contact_points() -> Array[Dictionary]:
	return _contacts.duplicate(true)


func _project_all() -> void:
	if reduced_motion:
		return
	for index in _sprites.size():
		var sprite := _sprites[index]
		var entry := _entries[index]
		var side := -1 if String(entry["side"]) == "left" else 1
		var phase := fposmod(motion_distance / CYCLE_DISTANCE + float(entry["phase"]), 1.0)
		var depth := pow(phase, 1.18)
		var ground_y := lerpf(128.0, 246.0, depth)
		var contact_x := Guide.roadside_contact_x(side, ground_y, 2.0)
		var source_factor := float(entry["source_to_runtime_factor"])
		var art_scale := lerpf(0.035, 0.51, depth) / source_factor
		sprite.position = Vector2(contact_x, ground_y) * 2.0
		sprite.scale = Vector2.ONE * art_scale
		sprite.modulate.a = 1.0
		_contacts[index] = {"side": side, "point": Vector2(contact_x, ground_y)}
		if sprite.name == "right_sari_sari" and _neighbour != null:
			_neighbour.visible = phase >= 0.27 and phase <= 0.87
			var gesture_time := fposmod(motion_distance, 9.0)
			_neighbour.texture = NEIGHBOUR_WAVE if gesture_time >= 3.5 and gesture_time < 5.5 else NEIGHBOUR_REST
	var order: Array[int] = []
	for index in _sprites.size():
		order.append(index)
	order.sort_custom(func(a: int, b: int) -> bool: return _contacts[a]["point"].y < _contacts[b]["point"].y)
	for slot in order.size():
		move_child(_sprites[order[slot]], slot)
