extends SceneTree

const Geometry = preload("res://scripts/l01_visual_geometry.gd")
const RoadModel = preload("res://scripts/road_projection.gd")
const STAGES := ["StageHome", "StageWaitingShed", "StageSariSari", "StagePalengke", "StagePlaza"]
const SOURCE_SIZE := Vector2i(960, 540)
const NATIVE_SIZE := Vector2i(480, 270)
const LAYER_NAMES := ["Far", "Landmark", "LeftStreet", "RightStreet", "Road", "Foreground"]
const PROMPTS := {
	"crates": "res://scenes/props/crate.tscn",
	"puddle": "res://scenes/props/puddle.tscn",
	"laundry": "res://scenes/props/laundry_line.tscn",
}

var output_dir := "res://../test_evidence/experience_revamp_geometry"


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output-dir="):
			output_dir = arg.trim_prefix("--output-dir=")
	call_deferred("_run")


func _run() -> void:
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	level.set_script(null)
	root.add_child(level)
	await process_frame
	level.get_node(^"WorldMotion").set_process(false)
	# The isolated scene has no runner controller to select the L01 visual mode.
	(level.get_node(^"LevelWorld/RoadAndLanes/RoadPresentation") as Node2D).visible = true
	var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	var error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if error != OK:
		printerr("Cannot create composition guide directory: %s" % absolute_dir)
		quit(1)
		return
	for index in STAGES.size():
		var stage := route.get_node("JourneyStages/%s" % STAGES[index]) as Sprite2D
		var composite := Image.create_empty(SOURCE_SIZE.x, SOURCE_SIZE.y, false, Image.FORMAT_RGBA8)
		composite.fill(Color(0.04, 0.11, 0.15))
		_blend_layer(composite, stage.texture)
		if index == 0:
			var no_street := composite.duplicate() as Image
			for name in ["Far", "Landmark", "Road", "Foreground"]:
				_blend_layer(no_street, (stage.get_node(name) as Sprite2D).texture)
			no_street.save_png(absolute_dir.path_join("l01_home_without_streets_960x540.png"))
		for name in LAYER_NAMES:
			_blend_layer(composite, (stage.get_node(name) as Sprite2D).texture)
		if index == 0:
			composite.save_png(absolute_dir.path_join("l01_home_stage_composite_960x540.png"))
		var road_image := (stage.get_node(^"Road") as Sprite2D).texture.get_image()
		_draw_guide(composite, road_image)
		var slug: String = ["home", "waiting", "sari_sari", "palengke", "plaza"][index]
		_save_at_sizes(composite, absolute_dir, slug)
	_report_prompt_envelopes(level)
	level.free()
	print("PETER RUN L01 composition guides: PASS (%s)" % absolute_dir)
	quit(0)


func _blend_layer(destination: Image, texture: Texture2D) -> void:
	var source := texture.get_image()
	source.convert(Image.FORMAT_RGBA8)
	destination.blend_rect(source, Rect2i(Vector2i.ZERO, SOURCE_SIZE), Vector2i.ZERO)


func _draw_guide(canvas: Image, road_image: Image) -> void:
	# Exclusion bands are intentionally shown over the plate, not rendered in game.
	_fill_native_rect(canvas, Rect2i(0, 0, 480, 35), Color(0.04, 0.13, 0.18, 0.45))
	_fill_native_rect(canvas, Rect2i(0, 249, 480, 21), Color(0.04, 0.13, 0.18, 0.45))
	_draw_native_line(canvas, Vector2(0, RoadModel.HORIZON_Y), Vector2(480, RoadModel.HORIZON_Y), Color(0.84, 0.63, 0.97), 1)
	for y in range(118, 242, 3):
		var span := _opaque_span(road_image, y * 2)
		if span.x >= 0.0:
			_plot_native(canvas, Vector2(span.x, y), Color.WHITE, 1)
			_plot_native(canvas, Vector2(span.y, y), Color.WHITE, 1)
	for side in [-1, 1]:
		for y in range(112, 241):
			if y <= 218:
				var fraction := pow(float(y - 112) / 106.0, 1.0 / 1.85)
				_plot_native(canvas, Vector2(RoadModel.l01_road_edge_at(side, fraction), y), Color(0.28, 0.75, 0.97), 1)
				for lane in 3:
					_plot_native(canvas, Vector2(RoadModel.lane_center_at(lane, fraction), y), Color(0.36, 0.96, 0.83), 1)
			_plot_native(canvas, Vector2(Geometry.painted_curb_x(side, y), y), Color(1.0, 0.67, 0.23), 1)
			if y >= 150:
				_plot_native(canvas, Vector2(Geometry.roadside_contact_x(side, y, 2.0), y), Color(0.63, 0.95, 0.27), 1)
	_draw_native_line(canvas, Vector2(178, 218), Vector2(302, 218), Color(1.0, 0.79, 0.31), 1)
	_draw_native_line(canvas, Vector2(209, 241), Vector2(271, 241), Color(0.98, 0.43, 0.82), 1)
	_plot_native(canvas, Vector2(240, 218), Color(1.0, 0.79, 0.31), 3)
	_plot_native(canvas, Vector2(240, 241), Color(0.98, 0.43, 0.82), 3)
	# Top prompt/Pause and lower status bar are no-scenery zones.
	_draw_native_rect(canvas, Rect2i(170, 4, 140, 28), Color(1.0, 0.79, 0.31))
	_draw_native_rect(canvas, Rect2i(414, 7, 58, 20), Color(0.98, 0.43, 0.82))
	_draw_native_rect(canvas, Rect2i(8, 4, 158, 29), Color(0.36, 0.96, 0.83))
	_draw_native_rect(canvas, Rect2i(8, 249, 464, 17), Color(0.36, 0.96, 0.83))


func _opaque_span(image: Image, source_y: int) -> Vector2:
	var left := -1
	var right := -1
	for x in image.get_width():
		if image.get_pixel(x, source_y).a >= 0.94:
			if left < 0:
				left = x
			right = x
	return Vector2(float(left) * 0.5, float(right) * 0.5)


func _save_at_sizes(source: Image, directory: String, slug: String) -> void:
	for target_value in [NATIVE_SIZE, SOURCE_SIZE, Vector2i(1024, 768), Vector2i(1920, 1080)]:
		var target: Vector2i = target_value
		var content_size: Vector2i = target
		var top := 0
		if target == Vector2i(1024, 768):
			content_size = Vector2i(1024, 576)
			top = 96
		var resized := source.duplicate() as Image
		resized.resize(content_size.x, content_size.y, Image.INTERPOLATE_NEAREST)
		var output := Image.create_empty(target.x, target.y, false, Image.FORMAT_RGBA8)
		output.fill(Color(0.02, 0.07, 0.10))
		output.blend_rect(resized, Rect2i(Vector2i.ZERO, content_size), Vector2i(0, top))
		var path := directory.path_join("l01_%s_guide_%dx%d.png" % [slug, target.x, target.y])
		var error := output.save_png(path)
		if error != OK:
			printerr("Cannot write composition guide: %s" % path)


func _report_prompt_envelopes(level: Node2D) -> void:
	var motion := level.get_node(^"WorldMotion")
	var container := level.get_node(^"LevelWorld/PromptWorldAnchor/PromptProps") as Node2D
	for prompt_name in PROMPTS:
		var prop := (load(PROMPTS[prompt_name]) as PackedScene).instantiate() as Node2D
		container.add_child(prop)
		for lane in 3:
			for fraction in [0.0, 0.5, 1.0]:
				motion.call("begin_prompt_approach", lane, 2.5, 2.0)
				motion.set("_prompt_elapsed", fraction * 4.5)
				motion.call("_apply_prompt_projection")
				var bounds := _visible_bounds(prop)
				print("ENVELOPE %s lane=%d depth=%.1f x=%.1f..%.1f y=%.1f..%.1f" % [prompt_name, lane, fraction,
					bounds.position.x, bounds.end.x, bounds.position.y, bounds.end.y])
		prop.free()


func _visible_bounds(prop: Node2D) -> Rect2:
	var bounds := Rect2()
	var has_bounds := false
	for child_value in prop.get_children():
		var sprite := child_value as Sprite2D
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


func _fill_native_rect(canvas: Image, rect: Rect2i, colour: Color) -> void:
	for y in range(rect.position.y * 2, rect.end.y * 2):
		for x in range(rect.position.x * 2, rect.end.x * 2):
			_blend_pixel(canvas, x, y, colour)


func _draw_native_rect(canvas: Image, rect: Rect2i, colour: Color) -> void:
	_draw_native_line(canvas, rect.position, Vector2(rect.end.x, rect.position.y), colour, 1)
	_draw_native_line(canvas, Vector2(rect.end.x, rect.position.y), rect.end, colour, 1)
	_draw_native_line(canvas, rect.end, Vector2(rect.position.x, rect.end.y), colour, 1)
	_draw_native_line(canvas, Vector2(rect.position.x, rect.end.y), rect.position, colour, 1)


func _draw_native_line(canvas: Image, start: Vector2, finish: Vector2, colour: Color, radius: int) -> void:
	var steps := maxi(1, int(ceil(start.distance_to(finish) * 2.0)))
	for step in range(steps + 1):
		_plot_native(canvas, start.lerp(finish, float(step) / float(steps)), colour, radius)


func _plot_native(canvas: Image, point: Vector2, colour: Color, radius: int) -> void:
	var centre := Vector2i(int(round(point.x * 2.0)), int(round(point.y * 2.0)))
	for y in range(centre.y - radius, centre.y + radius + 1):
		for x in range(centre.x - radius, centre.x + radius + 1):
			_blend_pixel(canvas, x, y, colour)


func _blend_pixel(canvas: Image, x: int, y: int, colour: Color) -> void:
	if x < 0 or x >= SOURCE_SIZE.x or y < 0 or y >= SOURCE_SIZE.y:
		return
	var old := canvas.get_pixel(x, y)
	canvas.set_pixel(x, y, old.lerp(Color(colour.r, colour.g, colour.b, 1.0), colour.a))
