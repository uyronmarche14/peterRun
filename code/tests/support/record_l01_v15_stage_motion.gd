extends SceneTree

## Records the five live L01 scenery stages with Godot's --write-movie option.
## This is visual QA footage, not a gameplay or controller playthrough.

const RouteJourney = preload("res://scripts/route_journey.gd")
const STAGES := ["home", "waiting", "sari_sari", "palengke", "plaza"]
const FRAMES_PER_STAGE := 144

var level: Node
var route: Node2D


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Visual recording requires graphical Godot")
		quit(2)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 540)
	level = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	level.get_node(^"WorldMotion").set_process(false)
	route = level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	for index in STAGES.size():
		_set_completed_progress(index)
		route.configure_route(41, index)
		print("RECORD L01 stage: " + STAGES[index])
		for frame in FRAMES_PER_STAGE:
			await process_frame
	level.free()
	quit()


func _set_completed_progress(stage: int) -> void:
	var config: Variant = level.get("session_config")
	var result: Variant = level.get("session_result")
	var target := 0
	for action in config.ACTIONS:
		target += config.get_target(action)
	var desired := 0
	while desired < target and RouteJourney.get_progress(desired, target) < stage:
		desired += 1
	var completed := 0
	for action in config.ACTIONS:
		completed += result.get_completed(action)
	var index := 0
	while completed < desired:
		var action: StringName = config.ACTIONS[index % config.ACTIONS.size()]
		if result.get_completed(action) < config.get_target(action):
			result.record_success(action)
			completed += 1
		index += 1
	level.call("_update_progress_hud", false)
