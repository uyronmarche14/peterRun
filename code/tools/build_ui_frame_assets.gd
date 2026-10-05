extends SceneTree

## Deterministic source for the native-resolution nine-slice PNG card frames.
## Run from the Godot project root with --headless --script res://tools/build_ui_frame_assets.gd.

const OUTPUT_DIR := "res://art/ui"
const SOURCE_SIZE := 256
const TARGET_SIZE := 64
const SUPERSAMPLE := 4.0

const FRAMES := [
	{
		"file": "ui_panel_cream_v01.png",
		"fill": Color("#fff4d6"),
		"border": Color("#155e63"),
		"highlight": Color("#fff9e8"),
		"shadow": Color(0.015, 0.07, 0.08, 0.26),
	},
	{
		"file": "ui_panel_teal_v01.png",
		"fill": Color(0.035, 0.12, 0.15, 0.95),
		"border": Color("#4a8a83"),
		"highlight": Color(0.12, 0.27, 0.29, 0.97),
		"shadow": Color(0.008, 0.035, 0.045, 0.38),
	},
	{
		"file": "ui_prompt_sign_v01.png",
		"fill": Color(0.027, 0.11, 0.145, 0.97),
		"border": Color("#f7b733"),
		"highlight": Color(0.16, 0.28, 0.29, 0.98),
		"shadow": Color(0.008, 0.035, 0.045, 0.43),
	},
]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for definition in FRAMES:
		var image := _make_frame(definition)
		var path := OUTPUT_DIR + "/" + String(definition["file"])
		var result := image.save_png(path)
		if result != OK:
			printerr("Unable to save UI frame %s: %s" % [path, error_string(result)])
			quit(1)
			return
		print("Generated " + path)
	quit()


func _make_frame(definition: Dictionary) -> Image:
	var image := Image.create(SOURCE_SIZE, SOURCE_SIZE, false, Image.FORMAT_RGBA8)
	for y in SOURCE_SIZE:
		for x in SOURCE_SIZE:
			var point := Vector2((float(x) + 0.5) / SUPERSAMPLE, (float(y) + 0.5) / SUPERSAMPLE)
			var color := Color.TRANSPARENT
			if _inside_rounded_rect(point, Rect2(1.0, 1.5, 62.0, 61.0), 2.0):
				color = definition["shadow"]
			if _inside_rounded_rect(point, Rect2(0.0, 0.0, 62.0, 61.0), 2.0):
				color = definition["border"]
			if _inside_rounded_rect(point, Rect2(1.25, 1.25, 59.5, 58.5), 1.0):
				color = definition["fill"]
				if point.y < 2.0:
					color = definition["highlight"]
			image.set_pixel(x, y, color)
	image.resize(TARGET_SIZE, TARGET_SIZE, Image.INTERPOLATE_LANCZOS)
	return image


func _inside_rounded_rect(point: Vector2, rect: Rect2, radius: float) -> bool:
	if not rect.has_point(point):
		return false
	var nearest := Vector2(
		clampf(point.x, rect.position.x + radius, rect.end.x - radius),
		clampf(point.y, rect.position.y + radius, rect.end.y - radius)
	)
	return point.distance_squared_to(nearest) <= radius * radius
