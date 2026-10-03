extends SceneTree

const Guide = preload("res://scripts/l01_visual_geometry.gd")
const CASES := [
	"res://scenes/props/crate.tscn",
	"res://scenes/props/puddle.tscn",
	"res://scenes/props/laundry_line.tscn",
]
const CURB_CLEARANCE := 18.0
const CRATE_MAX_VISIBLE_HEIGHT := 76.0

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	level.set_script(null)
	root.add_child(level)
	await process_frame
	var motion := level.get_node(^"WorldMotion")
	motion.set_process(false)
	# The level controller normally enables this only for L01. This isolated
	# scene test disables that controller, so enable the same visual contract.
	(level.get_node(^"LevelWorld/RoadAndLanes/RoadPresentation") as Node2D).visible = true
	var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	var anchor := level.get_node(^"LevelWorld/PromptWorldAnchor") as Node2D
	var container := anchor.get_node(^"PromptProps") as Node2D
	for scene_path in CASES:
		var prop := (load(scene_path) as PackedScene).instantiate() as Node2D
		container.add_child(prop)
		for lane in [0, 2]:
			motion.call("begin_prompt_approach", lane, 2.5, 2.0)
			for step in 21:
				var fraction := float(step) / 20.0
				motion.set("_prompt_elapsed", fraction * 4.5)
				motion.call("_apply_prompt_projection")
				_expect_curb_clearance(prop, lane, fraction, anchor.position.y)
				if scene_path == CASES[0]:
					_expect(_visible_bounds(prop).size.y <= CRATE_MAX_VISIBLE_HEIGHT,
						"Crate stack stays below adult height at %.2f" % fraction)
		prop.free()
	var formation: Array[Node2D] = []
	for scene_path in [CASES[0], CASES[1], CASES[0]]:
		var prop := (load(scene_path) as PackedScene).instantiate() as Node2D
		container.add_child(prop)
		formation.append(prop)
	var formation_lanes: Array[int] = [0, 1, 2]
	motion.call("set_prompt_formation", formation, formation_lanes)
	motion.call("begin_prompt_approach", 1, 2.5, 2.0)
	for step in 21:
		var fraction := float(step) / 20.0
		motion.set("_prompt_elapsed", fraction * 4.5)
		motion.call("_apply_prompt_projection")
		_expect_curb_clearance(formation[0], 0, fraction, anchor.position.y)
		_expect_curb_clearance(formation[2], 2, fraction, anchor.position.y)
		var left_bounds := _visible_bounds(formation[0])
		var middle_bounds := _visible_bounds(formation[1])
		var right_bounds := _visible_bounds(formation[2])
		_expect(left_bounds.end.x <= middle_bounds.position.x, "Mixed formation left prop stays distinct at %.2f" % fraction)
		_expect(middle_bounds.end.x <= right_bounds.position.x, "Mixed formation right prop stays distinct at %.2f" % fraction)
	for prop in formation:
		prop.free()
	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 prop visual clearance: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect_curb_clearance(prop: Node2D, lane: int, fraction: float, ground_y: float) -> void:
	var bounds := _visible_bounds(prop)
	var side := -1 if lane == 0 else 1
	var curb := Guide.painted_curb_x(side, ground_y)
	var gap := bounds.position.x - curb if lane == 0 else curb - bounds.end.x
	_expect(gap >= CURB_CLEARANCE - 0.5,
		"%s lane %d at %.2f has %.1f px curb clearance" % [prop.name, lane, fraction, gap])


func _visible_bounds(prop: Node2D) -> Rect2:
	var bounds := Rect2()
	var has_bounds := false
	for child in prop.get_children():
		var sprite := child as Sprite2D
		if sprite == null or not sprite.visible or sprite.texture == null:
			continue
		var used := sprite.texture.get_image().get_used_rect()
		if used.size == Vector2i.ZERO:
			continue
		var local := sprite.get_rect().position + Vector2(used.position)
		var a := sprite.to_global(local)
		var b := sprite.to_global(local + Vector2(used.size))
		var sprite_bounds := Rect2(a, b - a)
		bounds = bounds.merge(sprite_bounds) if has_bounds else sprite_bounds
		has_bounds = true
	return bounds


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
