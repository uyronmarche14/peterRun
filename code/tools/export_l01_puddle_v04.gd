extends SceneTree

const SOURCE := "res://../Peter_Run_Visual_Production/puddle_v04/prompt_l01_shallow_puddle_v04.svg"
const TARGET := "res://art/prompts/l01_barangay/prompt_l01_shallow_puddle_v04.png"


func _init() -> void:
	var source_path := ProjectSettings.globalize_path(SOURCE)
	var target_path := ProjectSettings.globalize_path(TARGET)
	var svg := FileAccess.get_file_as_string(source_path)
	if svg.is_empty():
		printerr("Missing puddle SVG source: " + source_path)
		quit(1)
		return
	var image := Image.new()
	var error := image.load_svg_from_string(svg, 1.0)
	if error != OK or image.get_size() != Vector2i(256, 128):
		printerr("Puddle SVG render failed: %d, size %s" % [error, image.get_size()])
		quit(1)
		return
	if image.get_pixel(0, 0).a >= 0.01:
		printerr("Puddle export corner must be transparent")
		quit(1)
		return
	error = image.save_png(target_path)
	if error != OK:
		printerr("Puddle PNG export failed: " + str(error))
		quit(1)
		return
	print("EXPORTED_PUDDLE_V04 ", target_path)
	quit(0)
