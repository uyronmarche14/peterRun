extends SceneTree

const Geometry = preload("res://scripts/l01_visual_geometry.gd")
const FRONTAGE_SOURCE := "res://../Peter_Run_Visual_Production/imagegen_sources/l01_home_passby_v01/home_left_frontage_source_v01.png"
const STAGE := "res://scenes/levels/runner_level.tscn"
const SIZE := Vector2i(960, 540)
const CONTACT_ON_SOURCE := Vector2(1475, 750)
const PREVIEW_DEPTHS := [
	{"label": "far", "ground_y": 150.0, "scale": 0.22},
	{"label": "middle", "ground_y": 185.0, "scale": 0.32},
	{"label": "near", "ground_y": 220.0, "scale": 0.45},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := (load(STAGE) as PackedScene).instantiate()
	scene.set_script(null)
	root.add_child(scene)
	await process_frame
	scene.get_node(^"WorldMotion").set_process(false)
	var route := scene.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	var stage := route.get_node(^"JourneyStages/StageHome") as Sprite2D
	var source := Image.load_from_file(ProjectSettings.globalize_path(FRONTAGE_SOURCE))
	if source == null or source.is_empty():
		printerr("Missing Home left-frontage source")
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var folder := ProjectSettings.globalize_path("res://../test_evidence/experience_revamp_geometry")
	DirAccess.make_dir_recursive_absolute(folder)
	for sample in PREVIEW_DEPTHS:
		var canvas := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0.03, 0.11, 0.16))
		_blend_layer(canvas, stage.texture)
		for name in ["Far", "Landmark", "Road"]:
			_blend_layer(canvas, (stage.get_node(name) as Sprite2D).texture)
		var ground_y := float(sample["ground_y"])
		var art_scale := float(sample["scale"])
		var source_contact_x := Geometry.roadside_contact_x(-1, ground_y, 2.0) * 2.0
		var contact := Vector2(source_contact_x, ground_y * 2.0)
		var position := contact - CONTACT_ON_SOURCE * art_scale
		var scaled := source.duplicate() as Image
		scaled.resize(int(round(source.get_width() * art_scale)), int(round(source.get_height() * art_scale)), Image.INTERPOLATE_LANCZOS)
		_blend_frontage_outside_curb(canvas, scaled, position.round())
		_blend_layer(canvas, (stage.get_node(^"Foreground") as Sprite2D).texture)
		var label: String = sample["label"]
		var target := folder.path_join("l01_home_left_passby_candidate_%s_960x540.png" % label)
		canvas.save_png(target)
		var native := canvas.duplicate() as Image
		native.resize(480, 270, Image.INTERPOLATE_LANCZOS)
		native.save_png(folder.path_join("l01_home_left_passby_candidate_%s_480x270.png" % label))
		print("PREVIEW %s contact=(%.1f,%.1f) art_origin=(%.1f,%.1f)" % [label, contact.x * 0.5, contact.y * 0.5, position.x * 0.5, position.y * 0.5])
	scene.free()
	print("PETER RUN Home left pass-by source-art preview: PASS (%s)" % folder)
	quit(0)


func _blend_layer(destination: Image, texture: Texture2D) -> void:
	var image := texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	destination.blend_rect(image, Rect2i(Vector2i.ZERO, SIZE), Vector2i.ZERO)


func _blend_frontage_outside_curb(destination: Image, image: Image, origin: Vector2i) -> void:
	for local_y in image.get_height():
		var screen_y := origin.y + local_y
		if screen_y < 0 or screen_y >= SIZE.y:
			continue
		var native_y := float(screen_y) * 0.5
		var curb_limit := Geometry.roadside_contact_x(-1, native_y, 2.0)
		if native_y < 128.0:
			curb_limit = minf(curb_limit, 170.0)
		for local_x in image.get_width():
			var screen_x := origin.x + local_x
			if screen_x < 0 or screen_x >= SIZE.x or float(screen_x) * 0.5 > curb_limit:
				continue
			var pixel := image.get_pixel(local_x, local_y)
			if pixel.a <= 0.001:
				continue
			var old := destination.get_pixel(screen_x, screen_y)
			destination.set_pixel(screen_x, screen_y, old.blend(pixel))
