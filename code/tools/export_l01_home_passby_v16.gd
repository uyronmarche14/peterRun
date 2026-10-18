extends SceneTree

const Guide = preload("res://scripts/l01_visual_geometry.gd")
const SOURCE := "res://../Peter_Run_Visual_Production/imagegen_sources/l01_home_passby_v02/layout.json"
const OUTPUT := "res://art/backgrounds/l01_home_v16_passby"
const MAX_SIZE := Vector2(768.0, 512.0)
const MASK_SAMPLES := 17


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	if not parsed is Dictionary:
		printerr("Home pass-by source manifest is invalid")
		quit(1)
		return
	var output_dir := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var exported: Array[Dictionary] = []
	for raw_entry in parsed["modules"]:
		var entry: Dictionary = raw_entry
		var image := Image.load_from_file(ProjectSettings.globalize_path(String(entry["source"])))
		if image == null:
			printerr("Missing Home frontage source: " + String(entry["source"]))
			quit(1)
			return
		image.convert(Image.FORMAT_RGBA8)
		var factor := minf(MAX_SIZE.x / image.get_width(), MAX_SIZE.y / image.get_height())
		image.resize(int(round(image.get_width() * factor)), int(round(image.get_height() * factor)), Image.INTERPOLATE_LANCZOS)
		var source_contact: Array = entry["contact"]
		var contact := Vector2(float(source_contact[0]), float(source_contact[1])) * factor
		var side := -1 if String(entry["side"]) == "left" else 1
		_mask_lanes_at_all_depths(image, side, contact, factor)
		var filename := "l01_v16_%s.png" % String(entry["id"])
		var destination := output_dir.path_join(filename)
		if image.save_png(destination) != OK:
			printerr("Could not save Home frontage: " + destination)
			quit(1)
			return
		exported.append({
			"id": entry["id"],
			"side": entry["side"],
			"phase": entry["phase"],
			"texture": OUTPUT + "/" + filename,
			"contact_px": [contact.x, contact.y],
			"source_to_runtime_factor": factor,
		})
	var runtime_manifest := {"canvas_px": [480, 270], "art_canvas_px": [960, 540], "modules": exported}
	var file := FileAccess.open(output_dir.path_join("l01_v16_home_passby.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(runtime_manifest, "\t") + "\n")
	file.close()
	print("PETER RUN Home pass-by v16 runtime sprites: PASS (%d)" % exported.size())
	quit(0)


func _mask_lanes_at_all_depths(image: Image, side: int, contact: Vector2, export_factor: float) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.005:
				continue
			var local := Vector2(x, y) - contact
			var unsafe := false
			for sample in MASK_SAMPLES:
				var depth := float(sample) / float(MASK_SAMPLES - 1)
				var ground_y := lerpf(128.0, 246.0, depth)
				var scale_value := lerpf(0.035, 0.51, depth) / export_factor
				var projected_y := ground_y + local.y * scale_value * 0.5
				if projected_y < 112.0 or projected_y >= 270.0:
					continue
				var projected_x := Guide.roadside_contact_x(side, ground_y, 2.0) + local.x * scale_value * 0.5
				var safe_x := Guide.roadside_contact_x(side, projected_y, 2.0)
				if (side < 0 and projected_x > safe_x) or (side > 0 and projected_x < safe_x):
					unsafe = true
					break
			if unsafe:
				pixel.a = 0.0
				image.set_pixel(x, y, pixel)
