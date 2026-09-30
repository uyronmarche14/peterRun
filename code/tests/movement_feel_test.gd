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
	_expect(player.position.x < 200.0 and player.position.x > 108.0, "Lane input produces immediate visible travel toward the aligned lane without teleporting")
	player.call("reset_for_practice")
	player.call("handle_action", &"jump")
	var jump_tween: Tween = player.get("_action_tween")
	jump_tween.pause()
	jump_tween.custom_step(0.32)
	player.call("_process", 0.32)
	var visual: Node2D = player.get_node("Visual")
	_expect(visual.position.y <= -7.5 and visual.scale == Vector2.ONE and player.character_sprite.animation == &"jump_low", "Jump reaches the higher apex without distorting Peter")
	jump_tween.custom_step(0.22)
	player.call("_process", 0.22)
	_expect(player.action_state == 1 and visual.position.y <= -7.5, "Jump holds its readable apex briefly")
	jump_tween.custom_step(0.39)
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
	player.call("reset_for_practice")
	player.call("handle_action", &"slide")
	var slide_tween: Tween = player.get("_action_tween")
	slide_tween.pause()
	slide_tween.custom_step(0.32)
	player.call("_process", 0.32)
	var slide_dust: Node2D = player.get_node_or_null("SlideDust")
	_expect(slide_dust != null and slide_dust.visible, "Slide has a grounded dust cue beneath the lowered pose")
	_expect(visual.position.y >= 3.0 and visual.scale == Vector2.ONE and player.character_sprite.animation == &"slide_duck", "Slide settles lower without runtime squash")
	slide_tween.custom_step(0.35)
	_expect(slide_dust != null and not slide_dust.visible, "Slide dust clears when Peter returns to running")
	player.free()
	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	var scenery: Node = level.get_node_or_null("LevelWorld/RoadsideMotion")
	_expect(scenery != null and not (scenery as CanvasItem).is_visible_in_tree(), "Unused roadside modules and old cone-like markers stay hidden")
	var road_dashes := level.get_node_or_null(^"LevelWorld/RoadAndLanes/RoadMotionDashes") as Node2D
	_expect(road_dashes != null and road_dashes.get_child_count() > 0, "Subtle road seams provide forward-motion depth cues")
	if road_dashes != null and road_dashes.get_child_count() > 0:
		var marker := road_dashes.get_child(0) as Line2D
		var motion: Node = level.get_node("WorldMotion")
		motion.set_process(false)
		var start := marker.points.duplicate()
		motion.call("_process", 0.5)
		_expect(marker.points != start, "Road seams travel with world motion")
		level.call("pause_gameplay")
		var frozen := marker.points.duplicate()
		motion.call("_process", 0.5)
		_expect(marker.points == frozen, "Pause freezes road-depth motion")
	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN movement feel test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
