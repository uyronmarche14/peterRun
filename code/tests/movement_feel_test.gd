extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var player: Node2D = load("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.set_process(false)
	player.call("handle_action", &"move_left")
	var lane_tween: Tween = player.get("_lane_tween")
	lane_tween.pause()
	lane_tween.custom_step(0.06)
	_expect(player.position.x < 200.0 and player.position.x > 128.0, "Lane input produces immediate visible travel without teleporting")
	player.call("reset_for_practice")
	player.call("handle_action", &"jump")
	var jump_tween: Tween = player.get("_action_tween")
	jump_tween.pause()
	jump_tween.custom_step(0.24)
	var visual: Node2D = player.get_node("Visual")
	_expect(visual.position.y <= -48.0, "Jump clears at least one full character height")
	jump_tween.custom_step(0.05)
	_expect(visual.position.y <= -48.0, "Jump has a readable apex before descending")
	jump_tween.custom_step(0.4)
	_expect(player.get("action_state") == 0, "Landing returns action state to running")
	var landing: Node2D = player.get_node_or_null("LandingRing")
	_expect(landing != null and landing.visible, "Landing produces a grounded visual cue")
	if landing != null:
		player.call("_process", 0.06)
		var landing_pose := landing.transform
		var landing_alpha := landing.modulate.a
		player.call("set_gameplay_paused", true)
		player.call("_process", 0.5)
		_expect(landing.transform == landing_pose and landing.modulate.a == landing_alpha, "Pause freezes landing feedback")
		player.call("set_gameplay_paused", false)
		player.call("_process", 0.3)
		_expect(not landing.visible, "Landing feedback clears without leaving particles")
	player.free()
	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	var scenery: Node = level.get_node_or_null("LevelWorld/RoadsideMotion")
	_expect(scenery != null, "Roadside scenery provides forward-motion depth cues")
	if scenery != null:
		var marker: Node2D = scenery.get_child(0)
		var motion: Node = level.get_node("WorldMotion")
		motion.set_process(false)
		var start := marker.transform
		motion.call("_process", 0.5)
		_expect(marker.transform != start, "Roadside markers travel with world motion")
		level.call("pause_gameplay")
		var frozen := marker.transform
		motion.call("_process", 0.5)
		_expect(marker.transform == frozen, "Pause freezes roadside motion")
	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN movement feel test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
