class_name L01LayeredRouteMotion
extends Node2D

const GameSettings = preload("res://scripts/game_settings.gd")
const SCENERY_REVEAL_SHADER = preload("res://art/backgrounds/l01_barangay_v09_journey/l01_v09_scenery_reveal.gdshader")

## Calm, deterministic ambient motion for the L01 illustrated scene.
## Road, buildings, and horizon remain locked. Only small anchored sidewalk
## details, clouds, and foreground foliage use the ambient clock.

const CLOUD_DRIFT_AMPLITUDE := 5.0
const CLOUD_DRIFT_SPEED := 0.10
const STAGE_TRANSITION_SECONDS := 1.2
const BREEZE_INTERVAL := Vector2(10.0, 16.0)
const BREEZE_DURATION := Vector2(4.0, 6.0)
const FOCAL_INTERVAL := Vector2(9.0, 14.0)
const STAGE_PATHS: Array[NodePath] = [
	^"JourneyStages/StageHome",
	^"JourneyStages/StageWaitingShed",
	^"JourneyStages/StageSariSari",
	^"JourneyStages/StagePalengke",
	^"JourneyStages/StagePlaza",
]
const FOCAL_EVENTS: Array[StringName] = [
	&"resident_gardener", &"resident_vendor", &"birds", &"glint",
]
var is_motion_paused := false
var motion_phase := 0.0
var _base_positions: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _route_progress := 0
var _transition_from := -1
var _transition_to := -1
var _transition_elapsed := 0.0
var _next_focal_at := 0.0
var _focal_started_at := -1.0
var _focal_ends_at := -1.0
var _focal_event: StringName = &""
var _next_breeze_at := 0.0
var _breeze_started_at := -1.0
var _breeze_ends_at := -1.0


func _ready() -> void:
	_capture_base_positions()
	configure_route(1, 0)
	if GameSettings.reduced_motion:
		_apply_reduced_motion_pose()


func _capture_base_positions() -> void:
	for child in get_children():
		if child is Node2D and not _base_positions.has(child.name):
			_base_positions[child.name] = child.position


func _process(delta: float) -> void:
	advance_layer_motion(delta)


func set_active(active: bool) -> void:
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func set_motion_paused(should_pause: bool) -> void:
	is_motion_paused = should_pause


func configure_route(seed: int, initial_progress: int = 0) -> void:
	_rng.seed = maxi(1, seed)
	motion_phase = 0.0
	_route_progress = clampi(initial_progress, 0, STAGE_PATHS.size() - 1)
	_transition_from = -1
	_transition_to = -1
	_transition_elapsed = 0.0
	_focal_event = &""
	_focal_started_at = -1.0
	_focal_ends_at = -1.0
	_breeze_started_at = -1.0
	_breeze_ends_at = -1.0
	_next_focal_at = _rng.randf_range(FOCAL_INTERVAL.x, FOCAL_INTERVAL.y)
	_next_breeze_at = _rng.randf_range(BREEZE_INTERVAL.x, BREEZE_INTERVAL.y)
	_apply_stage_immediate(_route_progress)
	_reset_ambient_pose()


func set_route_progress(progress: int, animate: bool = true) -> void:
	var next_progress := clampi(progress, 0, STAGE_PATHS.size() - 1)
	if next_progress == _route_progress:
		return
	var previous_progress := _route_progress
	_route_progress = next_progress
	if GameSettings.reduced_motion or not animate:
		_apply_stage_immediate(_route_progress)
		return
	# The five stages are full opaque scenes. Start from one known opaque plate
	# before blending, so a new landmark never exposes the old background.
	_apply_stage_immediate(previous_progress)
	_transition_from = previous_progress
	_transition_to = _route_progress
	_transition_elapsed = 0.0
	if _transition_to > _transition_from:
		_apply_stage_alpha(_transition_to, 1.0)
		_set_stage_reveal(_transition_to, 0.0)
	else:
		_apply_stage_alpha(_transition_to, 1.0)
		_set_stage_reveal(_transition_from, 1.0)


func get_route_progress() -> int:
	return _route_progress


func advance_layer_motion(delta: float) -> void:
	if is_motion_paused:
		return
	if GameSettings.reduced_motion:
		_apply_reduced_motion_pose()
		return
	if _base_positions.is_empty():
		_capture_base_positions()
	motion_phase += maxf(0.0, delta)
	_update_stage_transition(delta)
	_update_cloud_drift()
	_update_plant_sway()
	_update_foreground_leaves()
	_update_stage_life()
	_update_event_schedule()
	_update_breeze_layers()
	_update_focal_event()
	_update_market_glow()


func _update_stage_transition(delta: float) -> void:
	if _transition_to < 0:
		return
	_transition_elapsed += maxf(0.0, delta)
	var weight := clampf(_transition_elapsed / STAGE_TRANSITION_SECONDS, 0.0, 1.0)
	if _transition_to > _transition_from:
		_set_stage_reveal(_transition_to, weight)
	else:
		_set_stage_reveal(_transition_from, 1.0 - weight)
	if weight >= 1.0:
		_apply_stage_immediate(_route_progress)


func _update_cloud_drift() -> void:
	var clouds := get_node_or_null(^"CloudsA") as Sprite2D
	if clouds == null:
		return
	var base: Vector2 = _base_positions.get(clouds.name, Vector2(-4.0, -35.0))
	clouds.position = base + Vector2(sin(motion_phase * CLOUD_DRIFT_SPEED) * CLOUD_DRIFT_AMPLITUDE, 0.0)
	clouds.modulate.a = 0.30 + sin(motion_phase * 0.22) * 0.025


func _update_plant_sway() -> void:
	var paths: Array[NodePath] = [^"BananaLeavesLeft", ^"BananaLeavesRight", ^"FloweringPlants"]
	for index in paths.size():
		var plant := get_node_or_null(paths[index]) as Sprite2D
		if plant == null:
			continue
		plant.frame = _ping_pong_frame(motion_phase + index * 0.7, 0.62)
		var base: Vector2 = _base_positions.get(plant.name, plant.position)
		var sway := sin(motion_phase * 0.42 + index * 1.3)
		plant.position = base + Vector2(sway * 0.38, 0.0)
		plant.rotation = sway * 0.006


func _update_foreground_leaves() -> void:
	var frame := _ping_pong_frame(motion_phase, 0.78)
	var sway := sin(motion_phase * 0.56)
	for path in [^"ForegroundLeavesLeft", ^"ForegroundLeavesRight"]:
		var leaves := get_node_or_null(path) as Sprite2D
		if leaves == null:
			continue
		leaves.frame = frame
		var base: Vector2 = _base_positions.get(leaves.name, leaves.position)
		leaves.position = base + Vector2(sway * 0.65, -absf(sway) * 0.18)
		leaves.rotation = sway * 0.008


func _update_stage_life() -> void:
	for path in STAGE_PATHS:
		var stage := get_node_or_null(path) as Sprite2D
		if stage == null:
			continue
		var life := stage.get_node_or_null(^"StreetLife") as Node2D
		if life != null:
			life.call("set_ambient_phase", motion_phase)


func _update_event_schedule() -> void:
	if _breeze_ends_at >= 0.0 and motion_phase >= _breeze_ends_at:
		_breeze_started_at = -1.0
		_breeze_ends_at = -1.0
		_next_breeze_at = motion_phase + _rng.randf_range(BREEZE_INTERVAL.x, BREEZE_INTERVAL.y)
	elif _breeze_started_at < 0.0 and motion_phase >= _next_breeze_at:
		_breeze_started_at = motion_phase
		_breeze_ends_at = motion_phase + _rng.randf_range(BREEZE_DURATION.x, BREEZE_DURATION.y)

	if _focal_ends_at >= 0.0 and motion_phase >= _focal_ends_at:
		_focal_event = &""
		_focal_started_at = -1.0
		_focal_ends_at = -1.0
		_next_focal_at = motion_phase + _rng.randf_range(FOCAL_INTERVAL.x, FOCAL_INTERVAL.y)
	elif _focal_started_at < 0.0 and motion_phase >= _next_focal_at:
		_focal_event = FOCAL_EVENTS[_rng.randi_range(0, FOCAL_EVENTS.size() - 1)]
		_focal_started_at = motion_phase
		_focal_ends_at = motion_phase + _get_focal_duration(_focal_event)


func _update_breeze_layers() -> void:
	var breeze_active := _breeze_started_at >= 0.0
	var local_time := motion_phase - _breeze_started_at if breeze_active else 0.0
	var frame := _ping_pong_frame(local_time, 1.1) if breeze_active else 0
	var laundry := get_node_or_null(^"Laundry") as Sprite2D
	if laundry != null:
		# The established line breathes continuously; only its internal cloth
		# frames change, so its two attachment points never slide.
		laundry.frame = int(floor(motion_phase * 1.15)) % 4
		laundry.position = _base_positions.get(laundry.name, laundry.position)
	var awning := get_node_or_null(^"MarketAwning") as Sprite2D
	if awning != null:
		awning.frame = frame
		awning.position = _base_positions.get(awning.name, awning.position)
	var hanging_sign := get_node_or_null(^"HangingSign") as Node2D
	if hanging_sign != null:
		hanging_sign.rotation = sin(local_time * 1.35) * 0.024 if breeze_active else 0.0


func _update_focal_event() -> void:
	var local_time := motion_phase - _focal_started_at if _focal_started_at >= 0.0 else 0.0
	var resident_wave := get_node_or_null(^"ResidentWave") as Sprite2D
	if resident_wave != null:
		var resident_cycle := fposmod(motion_phase, 10.0)
		resident_wave.frame = mini(5, int(floor((resident_cycle - 5.0) * 2.0))) if resident_cycle >= 5.0 and resident_cycle < 8.0 else 0
	_set_resident_frame(^"ResidentGardener", &"resident_gardener", local_time)
	_set_resident_frame(^"ResidentVendor", &"resident_vendor", local_time)

	var birds := get_node_or_null(^"Birds") as Sprite2D
	if birds != null:
		birds.visible = _focal_event == &"birds"
		if birds.visible:
			var base: Vector2 = _base_positions.get(birds.name, Vector2(145.0, 66.0))
			birds.position = base + Vector2(local_time * 7.0 - 24.0, sin(local_time * 1.4) * 0.45)
			birds.frame = int(floor(local_time * 1.8)) % 4

	var glints := get_node_or_null(^"HallWindowGlints") as Sprite2D
	if glints != null:
		glints.visible = _focal_event == &"glint"
		if glints.visible:
			glints.modulate.a = sin(clampf(local_time / _get_focal_duration(&"glint"), 0.0, 1.0) * PI)
	var old_glints := get_node_or_null(^"HallGlints") as Node2D
	if old_glints != null:
		old_glints.visible = false


func _set_resident_frame(path: NodePath, event_name: StringName, local_time: float) -> void:
	var resident := get_node_or_null(path) as Sprite2D
	if resident == null:
		return
	resident.frame = mini(5, int(floor(local_time * 2.0))) if _focal_event == event_name else 0


func _update_market_glow() -> void:
	var market_glow := get_node_or_null(^"MarketGlow") as Polygon2D
	if market_glow != null:
		market_glow.modulate.a = 0.68 + (sin(motion_phase * 0.32) + 1.0) * 0.08


func _apply_reduced_motion_pose() -> void:
	if _base_positions.is_empty():
		_capture_base_positions()
	_apply_stage_immediate(_route_progress)
	_reset_ambient_pose()
	var clouds := get_node_or_null(^"CloudsA") as Sprite2D
	if clouds != null:
		clouds.modulate.a = 0.30
	var market_glow := get_node_or_null(^"MarketGlow") as Polygon2D
	if market_glow != null:
		market_glow.modulate.a = 0.74


func _reset_ambient_pose() -> void:
	for path in STAGE_PATHS:
		var stage := get_node_or_null(path) as Sprite2D
		if stage != null:
			var life := stage.get_node_or_null(^"StreetLife") as Node2D
			if life != null:
				life.call("reset_pose")
	for path in [
		^"Birds", ^"Laundry", ^"ResidentWave", ^"BananaLeavesLeft", ^"BananaLeavesRight",
		^"FloweringPlants", ^"MarketAwning", ^"ResidentGardener", ^"ResidentVendor",
		^"ForegroundLeavesLeft", ^"ForegroundLeavesRight",
	]:
		var sprite := get_node_or_null(path) as Sprite2D
		if sprite == null:
			continue
		sprite.frame = 0
		sprite.rotation = 0.0
		if _base_positions.has(sprite.name):
			sprite.position = _base_positions[sprite.name]
	var birds := get_node_or_null(^"Birds") as Sprite2D
	if birds != null:
		birds.visible = false
	var glints := get_node_or_null(^"HallWindowGlints") as Sprite2D
	if glints != null:
		glints.visible = false
	var old_glints := get_node_or_null(^"HallGlints") as Node2D
	if old_glints != null:
		old_glints.visible = false
	var hanging_sign := get_node_or_null(^"HangingSign") as Node2D
	if hanging_sign != null:
		hanging_sign.rotation = 0.0


func _apply_stage_immediate(progress: int) -> void:
	_transition_from = -1
	_transition_to = -1
	_transition_elapsed = 0.0
	for index in STAGE_PATHS.size():
		_apply_stage_alpha(index, 1.0 if index == progress else 0.0)
		var stage := get_node_or_null(STAGE_PATHS[index]) as Sprite2D
		if stage != null:
			stage.material = null
			var life := stage.get_node_or_null(^"StreetLife") as Node2D
			if life != null:
				life.modulate.a = 1.0


func _apply_stage_alpha(index: int, alpha: float) -> void:
	if index < 0 or index >= STAGE_PATHS.size():
		return
	var stage := get_node_or_null(STAGE_PATHS[index]) as Sprite2D
	if stage != null:
		stage.modulate.a = clampf(alpha, 0.0, 1.0)


func _set_stage_reveal(index: int, progress: float) -> void:
	if index < 0 or index >= STAGE_PATHS.size():
		return
	var stage := get_node_or_null(STAGE_PATHS[index]) as Sprite2D
	if stage == null:
		return
	var reveal_material := stage.material as ShaderMaterial
	if reveal_material == null:
		reveal_material = ShaderMaterial.new()
		reveal_material.shader = SCENERY_REVEAL_SHADER
		stage.material = reveal_material
	reveal_material.set_shader_parameter("reveal_progress", clampf(progress, 0.0, 1.0))
	var life := stage.get_node_or_null(^"StreetLife") as Node2D
	if life != null:
		life.modulate.a = clampf(progress, 0.0, 1.0)


func _get_focal_duration(event_name: StringName) -> float:
	match event_name:
		&"birds": return 6.0
		&"glint": return 1.4
	return 3.0


func _ping_pong_frame(time_value: float, speed: float) -> int:
	var frames: Array[int] = [0, 1, 2, 1]
	return frames[int(floor(maxf(0.0, time_value) * speed)) % frames.size()]
