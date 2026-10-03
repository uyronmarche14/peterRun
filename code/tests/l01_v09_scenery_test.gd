extends SceneTree

const ScenePath := "res://scenes/levels/runner_level.tscn"
const Settings = preload("res://scripts/game_settings.gd")
const StageFiles := [
	"l01_v09_home_dawn.png",
	"l01_v09_waiting_early_morning.png",
	"l01_v09_sari_sari_late_morning.png",
	"l01_v09_palengke_early_afternoon.png",
	"l01_v09_plaza_golden_afternoon.png",
]
const StageNodes := [
	^"JourneyStages/StageHome",
	^"JourneyStages/StageWaitingShed",
	^"JourneyStages/StageSariSari",
	^"JourneyStages/StagePalengke",
	^"JourneyStages/StagePlaza",
]

var failures: PackedStringArray = []


func _init() -> void:
	_test_runtime_art()
	_test_scenery_scene_and_pause()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 v09 five-stage scenery test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_runtime_art() -> void:
	_expect(ResourceLoader.exists("res://art/backgrounds/l01_barangay_v09_journey/l01_v09_scenery_reveal.gdshader"), "One scenery reveal shader exists")
	for file_name in StageFiles:
		var path: String = "res://art/backgrounds/l01_barangay_v09_journey/" + file_name
		_expect(ResourceLoader.exists(path), "Runtime scenery exists: " + path)
		if ResourceLoader.exists(path):
			var texture := load(path) as Texture2D
			_expect(texture != null and texture.get_size() == Vector2(960, 540), "Scenery uses aligned 960x540 canvas: " + path)


func _test_scenery_scene_and_pause() -> void:
	var packed := load(ScenePath) as PackedScene
	_expect(packed != null, "Runner scene loads")
	if packed == null:
		return
	var runner := packed.instantiate()
	var motion := runner.get_node_or_null(^"LevelWorld/L01BarangayLayers") as Node2D
	_expect(motion != null, "L01 scenery controller exists")
	if motion == null:
		runner.free()
		return
	var environment := motion.get_node_or_null(^"Environment") as Sprite2D
	_expect(environment != null and not environment.visible, "Old whole-scene background does not duplicate the five new scenes")
	for index in StageNodes.size():
		var stage := motion.get_node_or_null(StageNodes[index]) as Sprite2D
		_expect(stage != null, "Five-stage scenery node exists: " + String(StageNodes[index]))
		if stage != null:
			_expect(stage.scale == Vector2(0.5, 0.5) and not stage.centered, "Stage aligns to the 480x270 canvas: " + String(StageNodes[index]))
			if index == 0:
				_expect(stage.texture != null and stage.texture.resource_path.ends_with("l01_v10_home_sky.png"), "Home stage uses aligned v10 layers")
			else:
				var layer_slug: String = ["waiting", "sari_sari", "palengke", "plaza"][index - 1]
				_expect(stage.texture != null and stage.texture.resource_path.ends_with("l01_v11_%s_sky.png" % layer_slug), "Stage uses aligned independent daylight layers")
	for name in [^"Laundry", ^"ResidentWave"]:
		var legacy := motion.get_node_or_null(name) as Sprite2D
		_expect(legacy != null and not legacy.visible, "Old location-specific sprite is hidden: " + String(name))
	Settings.set_reduced_motion(false)
	motion.call("configure_route", 7, 0)
	motion.call("set_route_progress", 1, true)
	motion.call("advance_layer_motion", 0.6)
	var first := motion.get_node_or_null(StageNodes[0]) as Sprite2D
	var second := motion.get_node_or_null(StageNodes[1]) as Sprite2D
	if first != null and second != null:
		_expect(is_equal_approx(first.modulate.a, 1.0) and is_equal_approx(second.modulate.a, 1.0), "Both full-scene plates stay opaque during the landmark reveal")
		_expect(second.material is ShaderMaterial, "Incoming scenery uses a masked reveal instead of ghosted alpha blending")
		var reveal_before_pause := -1.0
		if second.material is ShaderMaterial:
			reveal_before_pause = float((second.material as ShaderMaterial).get_shader_parameter("reveal_progress"))
			_expect(reveal_before_pause > 0.0 and reveal_before_pause < 1.0, "Intermediate landmark is partly revealed without transparent buildings")
		var phase_before_pause: float = motion.get("motion_phase")
		motion.call("set_motion_paused", true)
		motion.call("advance_layer_motion", 5.0)
		if second.material is ShaderMaterial:
			_expect(is_equal_approx(float((second.material as ShaderMaterial).get_shader_parameter("reveal_progress")), reveal_before_pause), "Pause freezes the scenery reveal mask")
		_expect(is_equal_approx(float(motion.get("motion_phase")), phase_before_pause), "Pause freezes ambient motion")
		motion.call("set_motion_paused", false)
		motion.call("advance_layer_motion", 0.7)
		_expect(is_equal_approx(first.modulate.a, 0.0) and is_equal_approx(second.modulate.a, 1.0) and second.material == null, "Reveal settles on the new scene without a residual mask")
	motion.call("set_route_progress", 4, true)
	var final_stage := motion.get_node_or_null(StageNodes[4]) as Sprite2D
	if final_stage != null:
		_expect(is_equal_approx(final_stage.modulate.a, 1.0) and final_stage.material is ShaderMaterial, "Plaza arrival begins masked, not with a hard cut")
	Settings.set_reduced_motion(true)
	motion.call("set_route_progress", 3, true)
	if final_stage != null:
		_expect(is_equal_approx(final_stage.modulate.a, 0.0), "Reduced motion removes the previous scene immediately")
	var market := motion.get_node_or_null(StageNodes[3]) as Sprite2D
	if market != null:
		_expect(is_equal_approx(market.modulate.a, 1.0), "Reduced motion shows the selected scenery immediately")
	Settings.set_reduced_motion(false)
	runner.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
