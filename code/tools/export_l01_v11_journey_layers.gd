extends SceneTree

## Reproducible, full-canvas L01 art extraction. The four stage plates remain
## the geometry authority; generated paintings only replace sky/empty depth.

const SIZE := Vector2i(960, 540)
const SOURCE_DIR := "res://../Peter_Run_Visual_Production/imagegen_sources/l01_journey_v11_layers/"
const OUTPUT_DIR := "res://art/backgrounds/l01_journey_v11_layers/"
const REVIEW_DIR := "res://../test_evidence/l01_v11_journey_layers/"
const V09_DIR := "res://art/backgrounds/l01_barangay_v09_journey/"
const HOME_DIR := "res://art/backgrounds/l01_home_v10_layers/"
const STAGES := ["waiting", "sari_sari", "palengke", "plaza"]
const ORIGINALS := [
	"l01_v09_waiting_early_morning.png",
	"l01_v09_sari_sari_late_morning.png",
	"l01_v09_palengke_early_afternoon.png",
	"l01_v09_plaza_golden_afternoon.png",
]
const LAYERS := ["sky", "far", "landmark", "left_street", "right_street", "road", "foreground"]
const LEFT_PROFILE := [Vector2(0, 163), Vector2(80, 292), Vector2(160, 352), Vector2(220, 383), Vector2(280, 338), Vector2(350, 276), Vector2(420, 180), Vector2(540, 0)]
const RIGHT_PROFILE := [Vector2(0, 777), Vector2(80, 774), Vector2(160, 720), Vector2(220, 676), Vector2(280, 646), Vector2(350, 718), Vector2(420, 790), Vector2(540, 960)]
const ROAD_LEFT_PROFILE := [Vector2(234, 383), Vector2(300, 258), Vector2(350, 150), Vector2(380, 92), Vector2(420, 39), Vector2(436, 14), Vector2(480, 0), Vector2(540, 0)]
const ROAD_RIGHT_PROFILE := [Vector2(234, 624), Vector2(300, 703), Vector2(350, 791), Vector2(380, 868), Vector2(420, 926), Vector2(436, 946), Vector2(480, 960), Vector2(540, 960)]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REVIEW_DIR))
	var manifest := {"canvas_px": [SIZE.x, SIZE.y], "coordinates": "top-left of full 960x540 source plate", "modules": []}
	var home_texture := load(V09_DIR + "l01_v09_home_dawn.png") as Texture2D
	if home_texture == null:
		printerr("Missing Home reference")
		quit(1)
		return
	_export_modules("home", home_texture.get_image(), manifest["modules"])
	for index in STAGES.size():
		var slug: String = STAGES[index]
		if not _export_stage(slug, ORIGINALS[index], manifest["modules"]):
			quit(2)
			return
	var file := FileAccess.open(OUTPUT_DIR + "l01_v11_roadside_modules.json", FileAccess.WRITE)
	if file == null:
		printerr("Could not write module manifest")
		quit(3)
		return
	file.store_string(JSON.stringify(manifest, "\t") + "\n")
	file.close()
	print("L01 v11: exported four aligned stages and twenty roadside modules")
	quit()


func _export_stage(slug: String, original_name: String, modules: Array) -> bool:
	var sky := Image.load_from_file(SOURCE_DIR + slug + "_sky_source.png")
	var underpaint := Image.load_from_file(SOURCE_DIR + slug + "_underpaint_source.png")
	var texture := load(V09_DIR + original_name) as Texture2D
	if sky == null or underpaint == null or texture == null:
		printerr("Missing artwork source for " + slug)
		return false
	var original := texture.get_image()
	if original.get_size() != SIZE:
		printerr("Unregistered V09 stage: " + slug)
		return false
	sky.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	sky.convert(Image.FORMAT_RGBA8)
	underpaint.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	underpaint.convert(Image.FORMAT_RGBA8)
	var images: Array[Image] = [sky]
	for layer_index in range(1, LAYERS.size()):
		images.append(_extract(underpaint if layer_index <= 2 else original, layer_index))
	for layer_index in LAYERS.size():
		var file_name: String = "l01_v11_%s_%s.png" % [slug, LAYERS[layer_index]]
		if images[layer_index].save_png(OUTPUT_DIR + file_name) != OK:
			printerr("Could not save " + file_name)
			return false
	var composite := images[0].duplicate()
	for layer_index in range(1, images.size()):
		composite.blend_rect(images[layer_index], Rect2i(Vector2i.ZERO, SIZE), Vector2i.ZERO)
	composite.save_png(REVIEW_DIR + slug + "_composite_960x540.png")
	_export_modules(slug, original, modules)
	return true


func _extract(source: Image, layer_index: int) -> Image:
	var output := _blank()
	for y in SIZE.y:
		var left := _profile_x(LEFT_PROFILE, y)
		var right := _profile_x(RIGHT_PROFILE, y)
		var road_left := _profile_x(ROAD_LEFT_PROFILE, y)
		var road_right := _profile_x(ROAD_RIGHT_PROFILE, y)
		for x in SIZE.x:
			var alpha := 0.0
			match layer_index:
				1:
					alpha = smoothstep(48.0, 150.0, float(y))
					var sun_region := (smoothstep(575.0, 630.0, float(x))
						* (1.0 - smoothstep(840.0, 890.0, float(x)))
						* smoothstep(35.0, 75.0, float(y)))
					alpha = maxf(alpha, sun_region)
				2:
					alpha = _landmark_mask(x, y)
				3:
					alpha = 1.0 - smoothstep(left - 8.0, left + 8.0, float(x))
				4:
					alpha = smoothstep(right - 8.0, right + 8.0, float(x))
				5:
					if y >= 234:
						alpha = (smoothstep(road_left - 5.0, road_left + 3.0, float(x))
							* (1.0 - smoothstep(road_right - 3.0, road_right + 5.0, float(x))))
				6:
					alpha = _foreground_mask(x, y)
			if alpha > 0.003:
				var pixel := source.get_pixel(x, y)
				pixel.a *= alpha
				output.set_pixel(x, y, pixel)
	return output


func _export_modules(slug: String, original: Image, modules: Array) -> void:
	# The cutouts retain their registered plate canvas and underpaint. They are
	# inputs for a later shallow-parallax pass, not yet moving scene objects.
	for side in [-1, 1]:
		for depth in ["far", "near"]:
			var module := _blank()
			for y in SIZE.y:
				var edge := _profile_x(LEFT_PROFILE if side < 0 else RIGHT_PROFILE, y)
				for x in SIZE.x:
					var side_alpha := (1.0 - smoothstep(edge - 8.0, edge + 8.0, float(x))) if side < 0 else smoothstep(edge - 8.0, edge + 8.0, float(x))
					var split := (1.0 - smoothstep(205.0, 255.0, float(x))) if side < 0 else smoothstep(705.0, 755.0, float(x))
					var depth_alpha := split if depth == "near" else 1.0 - split
					var alpha := side_alpha * depth_alpha
					if alpha > 0.003:
						var pixel := original.get_pixel(x, y)
						pixel.a *= alpha
						module.set_pixel(x, y, pixel)
			var side_name := "left" if side < 0 else "right"
			var file_name: String = "l01_v11_%s_%s_%s_module.png" % [slug, side_name, depth]
			module.save_png(OUTPUT_DIR + file_name)
			var contact := Vector2i(194, 385) if side < 0 else Vector2i(770, 385)
			if depth == "far":
				contact = Vector2i(335, 270) if side < 0 else Vector2i(625, 270)
			modules.append({"stage": slug, "side": side_name, "depth": depth, "contact_px": [contact.x, contact.y], "file": file_name})


func _blank() -> Image:
	var result := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	return result


func _profile_x(profile: Array, y: int) -> float:
	if y <= int(profile[0].x):
		return profile[0].y
	for index in range(1, profile.size()):
		var previous: Vector2 = profile[index - 1]
		var current: Vector2 = profile[index]
		if y <= int(current.x):
			return lerpf(previous.y, current.y, inverse_lerp(previous.x, current.x, float(y)))
	return profile[-1].y


func _landmark_mask(x: int, y: int) -> float:
	if y > 256:
		return 0.0
	if y >= 100:
		var left := _profile_x([Vector2(100, 398), Vector2(125, 382), Vector2(155, 365), Vector2(220, 354), Vector2(256, 345)], y)
		var right := _profile_x([Vector2(100, 586), Vector2(125, 701), Vector2(155, 718), Vector2(220, 726), Vector2(256, 736)], y)
		return smoothstep(left - 8.0, left + 8.0, float(x)) * (1.0 - smoothstep(right - 8.0, right + 8.0, float(x))) * (1.0 - smoothstep(246.0, 256.0, float(y)))
	var radius := lerpf(28.0, 112.0, clampf(float(y) / 150.0, 0.0, 1.0))
	return 1.0 - smoothstep(radius - 8.0, radius + 27.0, absf(float(x) - 490.0))


func _foreground_mask(x: int, y: int) -> float:
	var top_left := (1.0 - smoothstep(82.0, 106.0, float(x))) * (1.0 - smoothstep(34.0, 58.0, float(y)))
	var top_right := smoothstep(854.0, 878.0, float(x)) * (1.0 - smoothstep(34.0, 58.0, float(y)))
	var bottom_left := (1.0 - smoothstep(37.0, 62.0, float(x))) * smoothstep(450.0, 490.0, float(y))
	var bottom_right := smoothstep(898.0, 923.0, float(x)) * smoothstep(450.0, 490.0, float(y))
	return maxf(maxf(top_left, top_right), maxf(bottom_left, bottom_right))
