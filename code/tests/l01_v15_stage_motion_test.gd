extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const Guide = preload("res://scripts/l01_visual_geometry.gd")
const STAGES := ["StageHome", "StageWaitingShed", "StageSariSari", "StagePalengke", "StagePlaza"]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.set_reduced_motion(false)
	var packed := load("res://scenes/levels/runner_level.tscn") as PackedScene
	_expect(packed != null, "Runner scene loads")
	if packed == null:
		_finish()
		return
	var level := packed.instantiate()
	root.add_child(level)
	await process_frame
	var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	level.get_node(^"WorldMotion").set_process(false)
	for index in STAGES.size():
		route.call("configure_route", 17, index)
		var life := route.get_node("JourneyStages/%s/StreetLife" % STAGES[index]) as Node2D
		var parts: Array = life.call("get_animated_parts")
		_expect(parts.size() >= 3, "%s has at least three independent ambient assets" % STAGES[index])
		life.call("set_ambient_phase", 0.0)
		var rest := _snapshot(parts)
		var changed: Dictionary = {}
		for phase in [0.5, 1.25, 2.0, 3.0]:
			life.call("set_ambient_phase", phase)
			for part in parts:
				var sprite := part as Sprite2D
				if _part_pose(sprite) != rest[parts.find(part)]:
					changed[sprite.name] = true
		_expect(changed.size() >= 2, "%s has two readable actions during the first three seconds" % STAGES[index])
		life.call("set_ambient_phase", 1.25)
		for part in parts:
			var sprite := part as Sprite2D
			if sprite.name.contains("Wave") or sprite.name.contains("Neighbour"):
				_expect(sprite.frame > 0, "%s resident greets shortly after stage entry" % STAGES[index])
		life.call("set_ambient_phase", 2.0)
		for part in parts:
			var sprite := part as Sprite2D
			if sprite.name.contains("Sign"):
				_expect(absf(sprite.rotation) >= 0.03, "%s sign sway reads at normal game size" % STAGES[index])
		life.call("set_ambient_phase", 0.0)
		_expect(_snapshot(parts) == rest, "%s has a stable resting pose" % STAGES[index])
		for tick in 61:
			life.call("set_ambient_phase", float(tick) * 0.25)
			for part in parts:
				var sprite := part as Sprite2D
				var bounds := _alpha_bounds(sprite)
				var side := -1 if sprite.global_position.x < 240.0 else 1
				var curb := Guide.painted_curb_x(side, bounds.end.y)
				var clear := bounds.end.x < curb - 1.0 if side < 0 else bounds.position.x > curb + 1.0
				_expect(clear, "%s/%s stays off the road at t=%.2f" % [STAGES[index], sprite.name, float(tick) * 0.25])

	# Returning to a route stage must begin that stage's action schedule at entry,
	# not inherit a random part of the previous stage's global ambient clock.
	route.call("configure_route", 17, 0)
	route.call("advance_layer_motion", 7.0)
	route.call("set_route_progress", 1, false)
	route.call("advance_layer_motion", 1.0)
	var waiting := route.get_node(^"JourneyStages/StageWaitingShed/StreetLife") as Node2D
	var entered := _snapshot(waiting.call("get_animated_parts"))
	route.call("configure_route", 17, 1)
	route.call("advance_layer_motion", 1.0)
	_expect(_snapshot(waiting.call("get_animated_parts")) == entered, "Waiting Shed starts the same animation one second after any entry")
	# Shared sky and edge motion should be perceptible over a short look, while
	# the painted buildings and road stay registered to the curb.
	route.call("configure_route", 17, 0)
	var clouds := route.get_node(^"CloudsA") as Sprite2D
	var banana := route.get_node(^"BananaLeavesLeft") as Sprite2D
	var leaves := route.get_node(^"ForegroundLeavesLeft") as Sprite2D
	var street := route.get_node(^"JourneyStages/StageHome/LeftStreet") as Sprite2D
	var clouds_at := clouds.position
	var banana_at := banana.position
	var leaves_at := leaves.position
	var street_at := street.position
	route.call("advance_layer_motion", 3.0)
	_expect(clouds.position.distance_to(clouds_at) >= 2.0, "Clouds drift visibly but slowly over three seconds")
	_expect(banana.position.distance_to(banana_at) >= 1.0, "Banana leaves have readable edge sway")
	_expect(leaves.position.distance_to(leaves_at) >= 1.2, "Foreground leaves have readable edge sway")
	_expect(street.position == street_at, "The Home building plate never moves with ambience")
	var home := route.get_node(^"JourneyStages/StageHome/StreetLife") as Node2D
	var before_pause := _snapshot(home.call("get_animated_parts"))
	var clouds_before_pause := clouds.position
	var banana_before_pause := banana.position
	var leaves_before_pause := leaves.position
	var phase_before: float = route.get("motion_phase")
	route.call("set_motion_paused", true)
	route.call("advance_layer_motion", 4.0)
	_expect(_snapshot(home.call("get_animated_parts")) == before_pause and is_equal_approx(float(route.get("motion_phase")), phase_before), "Pause freezes active stage action and ambient clock")
	_expect(clouds.position == clouds_before_pause and banana.position == banana_before_pause and leaves.position == leaves_before_pause, "Pause freezes shared sky and edge layers")
	route.call("set_motion_paused", false)
	Settings.set_reduced_motion(true)
	route.call("advance_layer_motion", 0.5)
	_expect(is_equal_approx(float(route.get("motion_phase")), phase_before), "Reduced Motion does not advance ambient time")
	for part in home.call("get_animated_parts"):
		var sprite := part as Sprite2D
		_expect(sprite.frame == 0 and is_zero_approx(sprite.rotation), "Reduced Motion rests " + sprite.name)
	Settings.set_reduced_motion(false)
	level.free()
	_finish()


func _snapshot(parts: Array) -> Array:
	var result := []
	for part in parts:
		result.append(_part_pose(part as Sprite2D))
	return result


func _part_pose(part: Sprite2D) -> Array:
	return [part.frame, part.position, part.rotation, part.scale]


func _alpha_bounds(part: Sprite2D) -> Rect2:
	var texture_image := part.texture.get_image()
	var frame_size := Vector2i(texture_image.get_width() / part.hframes, texture_image.get_height() / part.vframes)
	var frame_image := texture_image.get_region(Rect2i(part.frame_coords * frame_size, frame_size))
	var used := frame_image.get_used_rect()
	var origin := part.get_rect().position + Vector2(used.position)
	var size := Vector2(used.size)
	var corners := [origin, origin + Vector2(size.x, 0.0), origin + size, origin + Vector2(0.0, size.y)]
	var first := part.to_global(corners[0])
	var minimum := first
	var maximum := first
	for corner in corners:
		var point := part.to_global(corner)
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 five-stage ambient motion: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
