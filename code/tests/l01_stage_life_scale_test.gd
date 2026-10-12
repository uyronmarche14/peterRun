extends SceneTree

const Geometry = preload("res://scripts/l01_visual_geometry.gd")
const STAGES := ["StageHome", "StageWaitingShed", "StageSariSari", "StagePalengke", "StagePlaza"]
const MIN_HEIGHT := {"wave": 37.0, "vendor": 41.0, "flowers": 22.0, "banana": 28.0, "laundry": 19.0, "sign": 17.0}
const GROUND_KINDS := ["wave", "vendor", "flowers", "banana"]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	level.get_node(^"WorldMotion").set_process(false)
	for stage_index in STAGES.size():
		route.call("configure_route", 17, stage_index)
		var life := route.get_node("JourneyStages/%s/StreetLife" % STAGES[stage_index]) as Node2D
		var parts: Array = life.call("get_animated_parts")
		_expect(parts.size() == 3, "%s has three calibrated details" % STAGES[stage_index])
		for part in parts:
			var sprite := part as Sprite2D
			var kind := _kind_for(sprite.texture.resource_path)
			var minimum_height := INF
			var maximum_height := 0.0
			var feet_min := INF
			var feet_max := -INF
			var curb_clearance := INF
			for frame in sprite.hframes:
				sprite.frame = frame
				var bounds := _alpha_bounds(sprite)
				minimum_height = minf(minimum_height, bounds.size.y)
				maximum_height = maxf(maximum_height, bounds.size.y)
				feet_min = minf(feet_min, bounds.end.y)
				feet_max = maxf(feet_max, bounds.end.y)
				var side := -1 if sprite.global_position.x < 240.0 else 1
				var curb := Geometry.painted_curb_x(side, bounds.end.y)
				var clearance := curb - bounds.end.x if side < 0 else bounds.position.x - curb
				curb_clearance = minf(curb_clearance, clearance)
			_expect(minimum_height >= float(MIN_HEIGHT.get(kind, 0.0)), "%s/%s visible height %.1f..%.1f is too small" % [STAGES[stage_index], sprite.name, minimum_height, maximum_height])
			_expect(curb_clearance >= 2.0, "%s/%s curb clearance %.1f px" % [STAGES[stage_index], sprite.name, curb_clearance])
			if kind in GROUND_KINDS:
				_expect(feet_max - feet_min <= 1.0, "%s/%s ground drift %.1f px" % [STAGES[stage_index], sprite.name, feet_max - feet_min])
			print("SCALE %s/%s kind=%s height=%.1f..%.1f ground_drift=%.1f curb=%.1f" % [STAGES[stage_index], sprite.name, kind, minimum_height, maximum_height, feet_max - feet_min, curb_clearance])
			sprite.frame = 0
	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 stage-life scale: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _kind_for(path: String) -> String:
	for kind in L01StageStreetLife.TEXTURES:
		if L01StageStreetLife.TEXTURES[kind] == path:
			return kind
	return "unknown"


func _alpha_bounds(part: Sprite2D) -> Rect2:
	var image := part.texture.get_image()
	var frame_size := Vector2i(image.get_width() / part.hframes, image.get_height())
	var used := image.get_region(Rect2i(Vector2i(part.frame * frame_size.x, 0), frame_size)).get_used_rect()
	var origin := part.get_rect().position + Vector2(used.position)
	var corners := [origin, origin + Vector2(used.size.x, 0), origin + Vector2(used.size)]
	var minimum := part.to_global(corners[0])
	var maximum := minimum
	for corner in corners:
		var point := part.to_global(corner)
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
