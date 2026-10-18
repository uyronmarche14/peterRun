extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const STAGE := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.set_reduced_motion(false)
	var scene := (load(STAGE) as PackedScene).instantiate()
	scene.set_script(null)
	root.add_child(scene)
	await process_frame
	var world := scene.get_node(^"WorldMotion") as Node
	var route := scene.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	world.set_process(false)
	route.set_process(false)
	var home := route.get_node(^"JourneyStages/StageHome") as Sprite2D
	var left := home.get_node(^"LeftStreet") as Sprite2D
	var right := home.get_node(^"RightStreet") as Sprite2D
	var life := home.get_node(^"StreetLife") as Node2D
	_expect(home.get_node_or_null(^"PassingFrontages") == null, "Home has no active passing-building node")
	_expect(left.visible and right.visible, "Normal Motion shows the fixed Home buildings")
	_expect(life.visible, "Normal Motion keeps the small street-life details")
	var left_pose := [left.position, left.scale, left.modulate]
	var right_pose := [right.position, right.scale, right.modulate]
	world.call("_process", 2.0)
	route.call("advance_layer_motion", 2.0)
	_expect([left.position, left.scale, left.modulate] == left_pose, "Left Home buildings stay fixed during travel")
	_expect([right.position, right.scale, right.modulate] == right_pose, "Right Home buildings stay fixed during travel")
	Settings.set_reduced_motion(true)
	world.call("_process", 0.0)
	_expect(left.visible and right.visible, "Reduced Motion also shows the fixed Home buildings")
	scene.free()
	Settings.set_reduced_motion(false)
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 Home fixed-street runtime: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
