extends SceneTree

const RUNNER_PATH := "res://scenes/levels/runner_level.tscn"
const Settings = preload("res://scripts/game_settings.gd")

const ASSETS := {
	"stage_home": Vector2i(960, 540),
	"stage_waiting_shed": Vector2i(960, 540),
	"stage_sari_sari": Vector2i(960, 540),
	"stage_plaza": Vector2i(960, 540),
	"banana_left_strip": Vector2i(1024, 256),
	"banana_right_strip": Vector2i(1024, 256),
	"flowering_plants_strip": Vector2i(1024, 256),
	"market_awning_strip": Vector2i(1024, 192),
	"resident_gardener_strip": Vector2i(1536, 256),
	"resident_vendor_strip": Vector2i(1536, 256),
	"hall_window_glints": Vector2i(960, 540),
	"hanging_sign": Vector2i(256, 256),
	"route_stamp_atlas": Vector2i(512, 128),
}

const STAGE_NODES := [
	^"JourneyStages/StageHome",
	^"JourneyStages/StageWaitingShed",
	^"JourneyStages/StageSariSari",
	^"JourneyStages/StagePlaza",
]

const AMBIENT_NODES := [
	^"BananaLeavesLeft",
	^"BananaLeavesRight",
	^"FloweringPlants",
	^"MarketAwning",
	^"ResidentGardener",
	^"ResidentVendor",
	^"HallWindowGlints",
	^"HangingSign/Art",
]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_asset_contract()
	await _test_scene_and_motion_contract()
	await _test_runner_progress_wiring()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 v06 living-world test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_asset_contract() -> void:
	for asset_name in ASSETS:
		var path := "res://art/backgrounds/l01_barangay_v06_layers/l01_v06_%s.png" % asset_name
		_expect(ResourceLoader.exists(path), "v06 runtime asset exists: " + path)
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		_expect(texture != null and texture.get_size() == Vector2(ASSETS[asset_name]), "v06 asset has its stable authored canvas: " + path)


func _test_scene_and_motion_contract() -> void:
	var runner := (load(RUNNER_PATH) as PackedScene).instantiate()
	root.add_child(runner)
	await process_frame
	var motion := runner.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	motion.set_process(false)
	_expect(motion.has_method("configure_route"), "L01 motion accepts a deterministic route seed")
	_expect(motion.has_method("set_route_progress"), "L01 motion accepts visual journey progress")
	_expect(motion.has_method("get_route_progress"), "L01 motion exposes current visual journey progress")
	for path in STAGE_NODES:
		_expect(motion.get_node_or_null(path) is Sprite2D, "Journey overlay exists: " + String(path))
	for path in AMBIENT_NODES:
		_expect(motion.get_node_or_null(path) is Sprite2D, "Living-world overlay exists: " + String(path))
	if not motion.has_method("configure_route") or not motion.has_method("set_route_progress"):
		runner.free()
		return

	Settings.set_reduced_motion(false)
	motion.call("configure_route", 4242, 0)
	var first_focal := float(motion.get("_next_focal_at"))
	var first_breeze := float(motion.get("_next_breeze_at"))
	motion.call("configure_route", 4242, 0)
	_expect(is_equal_approx(first_focal, float(motion.get("_next_focal_at"))) and is_equal_approx(first_breeze, float(motion.get("_next_breeze_at"))), "Same route seed reproduces the ambient schedule")
	motion.call("configure_route", 4243, 0)
	_expect(not is_equal_approx(first_focal, float(motion.get("_next_focal_at"))) or not is_equal_approx(first_breeze, float(motion.get("_next_breeze_at"))), "Different route seeds vary calm ambient timing")

	motion.call("configure_route", 4242, 0)
	motion.call("set_route_progress", 1, true)
	motion.call("advance_layer_motion", 0.6)
	var home := motion.get_node(STAGE_NODES[0]) as Sprite2D
	var waiting := motion.get_node(STAGE_NODES[1]) as Sprite2D
	_expect(home.modulate.a > 0.0 and home.modulate.a < 1.0 and waiting.modulate.a > 0.0 and waiting.modulate.a < 1.0, "Intermediate landmark change crossfades over time")
	motion.call("advance_layer_motion", 0.7)
	_expect(is_equal_approx(home.modulate.a, 0.0) and is_equal_approx(waiting.modulate.a, 1.0), "Landmark crossfade settles on the selected stage")

	var frozen := _snapshot(motion)
	motion.call("set_motion_paused", true)
	motion.call("advance_layer_motion", 20.0)
	_expect(_snapshot(motion) == frozen, "Pause freezes ambient events and journey transitions immediately")
	motion.call("set_motion_paused", false)
	Settings.set_reduced_motion(true)
	motion.call("set_route_progress", 2, true)
	motion.call("advance_layer_motion", 5.0)
	_expect(int(motion.call("get_route_progress")) == 2, "Reduced motion still applies the selected landmark")
	for index in STAGE_NODES.size():
		var stage := motion.get_node(STAGE_NODES[index]) as Sprite2D
		_expect(is_equal_approx(stage.modulate.a, 1.0 if index == 2 else 0.0), "Reduced motion switches landmark without a crossfade")
	_expect(not (motion.get_node(^"Birds") as Sprite2D).visible, "Reduced motion hides distant birds")
	_expect(not (motion.get_node(^"HallWindowGlints") as Sprite2D).visible, "Reduced motion hides window glints")
	for path in [^"BananaLeavesLeft", ^"BananaLeavesRight", ^"FloweringPlants", ^"MarketAwning", ^"ResidentGardener", ^"ResidentVendor"]:
		_expect((motion.get_node(path) as Sprite2D).frame == 0, "Reduced motion keeps the neutral first frame: " + String(path))
	Settings.set_reduced_motion(false)
	runner.free()


func _test_runner_progress_wiring() -> void:
	var runner := (load(RUNNER_PATH) as PackedScene).instantiate()
	root.add_child(runner)
	await process_frame
	var motion := runner.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	if not motion.has_method("get_route_progress"):
		runner.free()
		return
	var config: Variant = runner.get("session_config")
	var result: Variant = runner.get("session_result")
	var total_target := 0
	for action in config.ACTIONS:
		total_target += config.get_target(action)
	var threshold := ceili(float(total_target) / 3.0)
	for index in threshold:
		result.record_success(config.ACTIONS[index % config.ACTIONS.size()])
	runner.call("_update_progress_hud")
	_expect(int(motion.call("get_route_progress")) == 1, "Completed repetitions send the first visual landmark to the route")
	result.record_neutral_miss()
	runner.call("_update_progress_hud")
	_expect(int(motion.call("get_route_progress")) == 1, "A neutral miss never advances the visual journey")
	runner.free()


func _snapshot(motion: Node) -> Dictionary:
	var result := {
		"phase": motion.get("motion_phase"),
		"route": motion.call("get_route_progress") if motion.has_method("get_route_progress") else -1,
		"focal": motion.get("_next_focal_at"),
		"breeze": motion.get("_next_breeze_at"),
	}
	for path in STAGE_NODES + AMBIENT_NODES + [^"Birds", ^"Laundry", ^"ResidentWave"]:
		var item := motion.get_node_or_null(path) as Node2D
		if item == null:
			continue
		result[String(path)] = [item.transform, item.modulate, item.visible, (item as Sprite2D).frame if item is Sprite2D else -1]
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
