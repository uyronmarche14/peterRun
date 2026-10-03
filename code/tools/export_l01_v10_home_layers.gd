extends SceneTree

## Deterministic full-canvas export from the reviewed Home plate and two
## generated source paintings. The PNGs stay registered to the 960x540 plate;
## no layer is independently cropped or resized after export.

const SIZE := Vector2i(960, 540)
const SOURCE_DIR := "res://../Peter_Run_Visual_Production/imagegen_sources/l01_home_v10_layers/"
const OUTPUT_DIR := "res://art/backgrounds/l01_home_v10_layers/"
const REVIEW_DIR := "res://../test_evidence/l01_v10_home_layers/"

const LEFT_PROFILE := [
	Vector2(0, 163), Vector2(80, 292), Vector2(160, 352),
	Vector2(220, 383), Vector2(280, 338), Vector2(350, 276),
	Vector2(420, 180), Vector2(540, 0),
]
const RIGHT_PROFILE := [
	Vector2(0, 777), Vector2(80, 774), Vector2(160, 720),
	Vector2(220, 676), Vector2(280, 646), Vector2(350, 718),
	Vector2(420, 790), Vector2(540, 960),
]
const ROAD_LEFT_PROFILE := [
	Vector2(234, 383), Vector2(300, 258), Vector2(350, 150),
	Vector2(380, 92), Vector2(420, 39), Vector2(436, 14),
	Vector2(480, 0), Vector2(540, 0),
]
const ROAD_RIGHT_PROFILE := [
	Vector2(234, 624), Vector2(300, 703), Vector2(350, 791),
	Vector2(380, 868), Vector2(420, 926), Vector2(436, 946),
	Vector2(480, 960), Vector2(540, 960),
]


func _init() -> void:
	var sky := _load_source(SOURCE_DIR + "home_sky_source.png")
	var underpaint := _load_source(SOURCE_DIR + "home_underpaint_source.png")
	var reference_texture := load("res://art/backgrounds/l01_barangay_v09_journey/l01_v09_home_dawn.png") as Texture2D
	var original := reference_texture.get_image() if reference_texture != null else null
	if sky == null or underpaint == null or original == null:
		quit(1)
		return
	sky.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	sky.convert(Image.FORMAT_RGBA8)
	underpaint.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
	if original.get_size() != SIZE:
		printerr("Home reference is not 960x540")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REVIEW_DIR))
	var layers: Array[Image] = [sky]
	var names := ["sky", "far", "landmark", "left_street", "right_street", "road", "foreground"]
	for layer_index in range(1, names.size()):
		var source := underpaint if layer_index <= 2 else original
		layers.append(_extract(source, layer_index))
	for index in names.size():
		var path: String = OUTPUT_DIR + "l01_v10_home_" + names[index] + ".png"
		var result := layers[index].save_png(path)
		if result != OK:
			printerr("Could not save %s: %s" % [path, error_string(result)])
			quit(3)
			return
	var composite := sky.duplicate()
	for index in range(1, layers.size()):
		composite.blend_rect(layers[index], Rect2i(Vector2i.ZERO, SIZE), Vector2i.ZERO)
	composite.save_png(REVIEW_DIR + "home_layered_composite_960x540.png")
	print("L01 v10 Home: exported %d aligned layers and review composite" % layers.size())
	quit()


func _load_source(path: String) -> Image:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		printerr("Missing source: " + path)
		return null
	return image


func _extract(source: Image, layer_index: int) -> Image:
	var output := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for y in SIZE.y:
		var left: float = _profile_x(LEFT_PROFILE, y)
		var right: float = _profile_x(RIGHT_PROFILE, y)
		var road_left: float = _profile_x(ROAD_LEFT_PROFILE, y)
		var road_right: float = _profile_x(ROAD_RIGHT_PROFILE, y)
		for x in SIZE.x:
			var alpha := 0.0
			match layer_index:
				1: # Independent painted distance and quiet verge underlay.
					alpha = smoothstep(48.0, 150.0, float(y))
					# Use one sun painting at the horizon, not two ghosted discs.
					var sun_region := (smoothstep(575.0, 630.0, float(x))
						* (1.0 - smoothstep(840.0, 890.0, float(x)))
						* smoothstep(35.0, 75.0, float(y)))
					alpha = maxf(alpha, sun_region)
				2: # The stable civic destination has its own aligned highlight layer.
					alpha = _landmark_mask(x, y)
				3: # Original left street, registered to its painted sidewalk.
					alpha = 1.0 - smoothstep(left - 8.0, left + 8.0, float(x))
				4:
					alpha = smoothstep(right - 8.0, right + 8.0, float(x))
				5: # Original road and sidewalks lock the three active lanes.
					if y >= 234:
						alpha = (smoothstep(road_left - 5.0, road_left + 3.0, float(x))
							* (1.0 - smoothstep(road_right - 3.0, road_right + 5.0, float(x))))
				6: # Only edge foliage, never the player or active prompt region.
					alpha = _foreground_mask(x, y)
			if alpha > 0.003:
				var pixel := source.get_pixel(x, y)
				pixel.a *= alpha
				output.set_pixel(x, y, pixel)
	return output


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
		var left := _profile_x([
			Vector2(100, 398), Vector2(125, 382), Vector2(155, 365),
			Vector2(220, 354), Vector2(256, 345),
		], y)
		var right := _profile_x([
			Vector2(100, 586), Vector2(125, 701), Vector2(155, 718),
			Vector2(220, 726), Vector2(256, 736),
		], y)
		var horizontal := smoothstep(left - 8.0, left + 8.0, float(x)) * (1.0 - smoothstep(right - 8.0, right + 8.0, float(x)))
		return horizontal * (1.0 - smoothstep(246.0, 256.0, float(y)))
	var radius := lerpf(28.0, 112.0, clampf(float(y) / 150.0, 0.0, 1.0))
	var horizontal := 1.0 - smoothstep(radius - 8.0, radius + 27.0, absf(float(x) - 490.0))
	return horizontal


func _foreground_mask(x: int, y: int) -> float:
	var top_left := (1.0 - smoothstep(82.0, 106.0, float(x))) * (1.0 - smoothstep(34.0, 58.0, float(y)))
	var top_right := smoothstep(854.0, 878.0, float(x)) * (1.0 - smoothstep(34.0, 58.0, float(y)))
	var bottom_left := (1.0 - smoothstep(37.0, 62.0, float(x))) * smoothstep(450.0, 490.0, float(y))
	var bottom_right := smoothstep(898.0, 923.0, float(x)) * smoothstep(450.0, 490.0, float(y))
	return maxf(maxf(top_left, top_right), maxf(bottom_left, bottom_right))
