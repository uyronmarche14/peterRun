extends SceneTree

## Normalizes isolated image-generation sources to a common transparent
## 512x512 canvas with a stable bottom contact point. No road is in these art
## sources; position and perspective are supplied by Godot at runtime.
const SOURCE_DIR := "res://../Peter_Run_Visual_Production/imagegen_sources/l01_roadside_v12/"
const OUTPUT_DIR := "res://art/backgrounds/l01_roadside_v12/"
const NAMES := ["home_veranda", "waiting_shed", "sari_sari", "market_stall", "plaza_kiosk"]
const SIZE := Vector2i(512, 512)
const MAX_CONTENT := Vector2(450.0, 440.0)
const CONTACT_Y := 485


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for name in NAMES:
		if not _export(String(name)):
			quit(1)
			return
	print("L01 v12: exported five transparent grounded roadside sprites")
	quit()


func _export(name: String) -> bool:
	var source := Image.load_from_file(SOURCE_DIR + name + "_source.png")
	if source == null or source.is_empty():
		printerr("Missing source: " + name)
		return false
	source.convert(Image.FORMAT_RGBA8)
	var max_y := 1135 if name == "waiting_shed" else source.get_height()
	var bounds := _content_bounds(source, max_y)
	if not bounds.has_area():
		printerr("No visible pixels: " + name)
		return false
	var crop := source.get_region(bounds)
	var factor := minf(MAX_CONTENT.x / float(bounds.size.x), MAX_CONTENT.y / float(bounds.size.y))
	var target_size := Vector2i(maxi(1, roundi(bounds.size.x * factor)), maxi(1, roundi(bounds.size.y * factor)))
	crop.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color.TRANSPARENT)
	var location := Vector2i((SIZE.x - target_size.x) / 2, CONTACT_Y - target_size.y)
	canvas.blend_rect(crop, Rect2i(Vector2i.ZERO, target_size), location)
	for y in SIZE.y:
		for x in SIZE.x:
			var pixel := canvas.get_pixel(x, y)
			if pixel.a < 0.04:
				canvas.set_pixel(x, y, Color.TRANSPARENT)
	var path := OUTPUT_DIR + "l01_v12_" + name + ".png"
	var result := canvas.save_png(path)
	if result != OK:
		printerr("Could not save " + path + ": " + error_string(result))
	return result == OK


func _content_bounds(source: Image, max_y: int) -> Rect2i:
	var min_x := source.get_width()
	var min_y := source.get_height()
	var max_x := -1
	var bottom := -1
	for y in mini(max_y, source.get_height()):
		for x in source.get_width():
			if source.get_pixel(x, y).a < 0.06:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			bottom = maxi(bottom, y)
	if max_x < 0:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, bottom - min_y + 1)
