extends SceneTree

const Geometry = preload("res://scripts/l01_visual_geometry.gd")
const MANIFEST := "res://../Peter_Run_Visual_Production/imagegen_sources/l01_home_passby_v02/layout.json"
const STAGE := "res://scenes/levels/runner_level.tscn"
const OUTPUT := "res://../test_evidence/experience_revamp_geometry/home_passby_v02"
const SIZE := Vector2i(960, 540)
const SAMPLE_COUNT := 8


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not parsed is Dictionary:
		printerr("Home pass-by source manifest is invalid")
		quit(1)
		return
	var modules: Array = parsed.get("modules", [])
	var scene := (load(STAGE) as PackedScene).instantiate()
	scene.set_script(null)
	root.add_child(scene)
	await process_frame
	scene.get_node(^"WorldMotion").set_process(false)
	var route := scene.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	var stage := route.get_node(^"JourneyStages/StageHome") as Sprite2D
	var folder := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(folder)
	for sample_index in SAMPLE_COUNT:
		var cycle_phase := float(sample_index) / float(SAMPLE_COUNT)
		var canvas := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0.03, 0.11, 0.16))
		for layer in [stage, stage.get_node(^"Far"), stage.get_node(^"Landmark"), stage.get_node(^"Road")]:
			_blend_layer(canvas, (layer as Sprite2D).texture)
		var placements: Array[Dictionary] = []
		for raw_entry in modules:
			var entry: Dictionary = raw_entry
			var local_phase := fposmod(cycle_phase + float(entry["phase"]), 1.0)
			var depth := pow(local_phase, 1.18)
			var ground_y := lerpf(128.0, 246.0, depth)
			placements.append({"entry": entry, "ground_y": ground_y, "depth": depth})
		placements.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["ground_y"] < b["ground_y"])
		for placement in placements:
			_blend_module(canvas, placement)
		_blend_layer(canvas, (stage.get_node(^"Foreground") as Sprite2D).texture)
		var target := folder.path_join("home_passby_v02_phase_%02d_960x540.png" % sample_index)
		canvas.save_png(target)
		var native := canvas.duplicate() as Image
		native.resize(480, 270, Image.INTERPOLATE_LANCZOS)
		native.save_png(folder.path_join("home_passby_v02_phase_%02d_480x270.png" % sample_index))
		print("Home pass-by preview phase %d/%d" % [sample_index, SAMPLE_COUNT])
	scene.free()
	print("PETER RUN Home pass-by v02 preview: PASS (%s)" % folder)
	quit(0)


func _blend_layer(destination: Image, texture: Texture2D) -> void:
	var image := texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	destination.blend_rect(image, Rect2i(Vector2i.ZERO, SIZE), Vector2i.ZERO)


func _blend_module(destination: Image, placement: Dictionary) -> void:
	var entry: Dictionary = placement["entry"]
	var image := Image.load_from_file(ProjectSettings.globalize_path(String(entry["source"])))
	if image == null:
		return
	image.convert(Image.FORMAT_RGBA8)
	var side := -1 if String(entry["side"]) == "left" else 1
	var ground_y := float(placement["ground_y"])
	var depth := float(placement["depth"])
	var art_scale := lerpf(0.035, 0.51, depth)
	var contact_array: Array = entry["contact"]
	var source_contact := Vector2(float(contact_array[0]), float(contact_array[1]))
	var contact := Vector2(Geometry.roadside_contact_x(side, ground_y, 2.0) * 2.0, ground_y * 2.0)
	var origin := (contact - source_contact * art_scale).round()
	image.resize(int(round(image.get_width() * art_scale)), int(round(image.get_height() * art_scale)), Image.INTERPOLATE_LANCZOS)
	_blend_outside_curb(destination, image, Vector2i(origin), side)


func _blend_outside_curb(destination: Image, image: Image, origin: Vector2i, side: int) -> void:
	var from_y := maxi(0, origin.y)
	var through_y := mini(SIZE.y, origin.y + image.get_height())
	for screen_y in range(from_y, through_y):
		var curb := Geometry.roadside_contact_x(side, float(screen_y) * 0.5, 2.0) * 2.0
		var from_x := maxi(0, origin.x)
		var through_x := mini(SIZE.x, origin.x + image.get_width())
		if side < 0:
			through_x = mini(through_x, int(floor(curb)))
		else:
			from_x = maxi(from_x, int(ceil(curb)))
		if through_x <= from_x:
			continue
		var source_pos := Vector2i(from_x - origin.x, screen_y - origin.y)
		destination.blend_rect(image, Rect2i(source_pos, Vector2i(through_x - from_x, 1)), Vector2i(from_x, screen_y))
