extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const STATIC_BUILDINGS := [
	^"BuildingsFarLeft",
	^"BuildingsFarRight",
	^"BuildingsNearLeft",
	^"BuildingsNearRight",
]
const MISALIGNED_V06_SIDEWALK_OVERLAYS := [
	^"Laundry",
	^"ResidentWave",
	^"ResidentGardener",
	^"FloweringPlants",
	^"ResidentVendor",
	^"MarketAwning",
	^"HangingSign",
]
const ALIGNED_AMBIENT_OVERLAYS := [
	^"CloudsA",
	^"BananaLeavesLeft",
	^"BananaLeavesRight",
	^"ForegroundLeavesLeft",
	^"ForegroundLeavesRight",
]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.set_reduced_motion(false)
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "runner scene loads")
	if packed == null:
		_finish()
		return
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame
	var layers := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	var roadside := level.get_node(^"LevelWorld/RoadsideMotion") as Node2D
	var world_motion := level.get_node(^"WorldMotion") as Node
	_expect(layers.visible, "L01 illustrated layer is active")
	_expect(not roadside.visible, "v08 passing-house layer is hidden")
	var environment := layers.get_node(^"Environment") as Sprite2D
	var original_environment := load("res://art/backgrounds/l01_barangay_v05_layers/l01_v05_environment.png") as Texture2D
	_expect(environment != null and environment.texture == original_environment, "the original v05 static street is the L01 backdrop")
	var before: Array = []
	for path in STATIC_BUILDINGS:
		var building := layers.get_node_or_null(path) as Node2D
		_expect(building != null and not building.visible, "v06 replacement building is hidden: " + String(path))
		if building != null:
			before.append([building.position, building.scale, building.modulate])
	for path in MISALIGNED_V06_SIDEWALK_OVERLAYS:
		var overlay := layers.get_node_or_null(path) as Node2D
		_expect(overlay != null and not overlay.visible, "v06 sidewalk overlay does not float over the v05 street: " + String(path))
	for path in ALIGNED_AMBIENT_OVERLAYS:
		var overlay := layers.get_node_or_null(path) as Node2D
		_expect(overlay != null and overlay.visible, "aligned ambient layer remains visible: " + String(path))
	for stage_name in ["StageHome", "StageWaitingShed", "StageSariSari", "StagePalengke", "StagePlaza"]:
		var stage := layers.get_node("JourneyStages/" + stage_name) as Sprite2D
		_expect((stage.get_node(^"LeftStreet") as Sprite2D).visible and (stage.get_node(^"RightStreet") as Sprite2D).visible, "fixed stage buildings remain visible: " + stage_name)
		_expect(stage.get_node_or_null(^"StreetLife") != null, "small aligned street-life overlay replaces old floating sprite: " + stage_name)
	if before.size() == STATIC_BUILDINGS.size():
		layers.set_process(false)
		world_motion.set_process(false)
		var cloud := layers.get_node(^"CloudsA") as Sprite2D
		var cloud_before := cloud.position
		var distance_before := float(world_motion.get("motion_distance"))
		world_motion.call("_process", 2.0)
		layers.call("advance_layer_motion", 2.0)
		_expect(float(world_motion.get("motion_distance")) > distance_before, "road/world travel motion remains active")
		_expect(cloud.position != cloud_before, "cloud ambient motion remains active")
		for index in STATIC_BUILDINGS.size():
			var building := layers.get_node(STATIC_BUILDINGS[index]) as Node2D
			_expect([building.position, building.scale, building.modulate] == before[index], "hidden replacement building stays fixed: " + String(STATIC_BUILDINGS[index]))
	level.free()
	_finish()


func _finish() -> void:
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 static buildings restore test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
