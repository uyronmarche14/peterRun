extends SceneTree

const Guide = preload("res://scripts/l01_visual_geometry.gd")
const CASES := [
	"res://scenes/props/crate.tscn",
	"res://scenes/props/puddle.tscn",
	"res://scenes/props/laundry_line.tscn",
]
const CURB_CLEARANCE := 12.0

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
			for fraction in [0.0, 0.25, 0.5, 0.75, 0.9, 1.0]:
				motion.set("_prompt_elapsed", fraction * 4.5)
				motion.call("_apply_prompt_projection")
				var bounds := _visible_bounds(prop)
				var side := -1 if lane == 0 else 1
				var curb := Guide.painted_curb_x(side, anchor.position.y)
				var gap := bounds.position.x - curb if lane == 0 else curb - bounds.end.x
				_expect(gap >= CURB_CLEARANCE - 0.5,
					"%s lane %d at %.2f has %.1f px curb clearance" % [scene_path.get_file(), lane, fraction, gap])
		prop.free()
	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 prop visual clearance: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


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
