extends SceneTree

## Keeps the approved V09 asphalt and curb pixels but excludes sidewalk people,
## pots, and buildings from the road layer used behind moving street subjects.
const Guide = preload("res://scripts/l01_visual_geometry.gd")
const SIZE := Vector2i(960, 540)
const V09_DIR := "res://art/backgrounds/l01_barangay_v09_journey/"
const OUTPUT_DIR := "res://art/backgrounds/l01_roadside_v12/"
const STAGES := [
	["home", "l01_v09_home_dawn.png"],
	["waiting", "l01_v09_waiting_early_morning.png"],
	["sari_sari", "l01_v09_sari_sari_late_morning.png"],
	["palengke", "l01_v09_palengke_early_afternoon.png"],
	["plaza", "l01_v09_plaza_golden_afternoon.png"],
]
const ROAD_LEFT_PROFILE := [Vector2(234, 383), Vector2(300, 258), Vector2(350, 150), Vector2(380, 92), Vector2(420, 39), Vector2(436, 14), Vector2(480, 0), Vector2(540, 0)]
const ROAD_RIGHT_PROFILE := [Vector2(234, 624), Vector2(300, 703), Vector2(350, 791), Vector2(380, 868), Vector2(420, 926), Vector2(436, 946), Vector2(480, 960), Vector2(540, 960)]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for entry in STAGES:
		var texture := load(V09_DIR + String(entry[1])) as Texture2D
		if texture == null:
			printerr("Missing V09 plate: " + String(entry[1]))
			quit(1)
			return
		var original := texture.get_image()
		if original.get_size() != SIZE:
			printerr("Unregistered plate: " + String(entry[1]))
			quit(2)
			return
		var output := Image.create(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8)
		output.fill(Color.TRANSPARENT)
		for y in range(234, SIZE.y):
			# The upper sidewalk needs a tight mask to exclude stranded people;
			# the foreground needs the original broad sidewalk/curb pixels to
			# cover small perspective differences in the clean underpaint.
			var foreground_weight := smoothstep(355.0, 420.0, float(y))
			var left := lerpf(Guide.painted_curb_x(-1, float(y) * 0.5) * 2.0, _profile_x(ROAD_LEFT_PROFILE, y), foreground_weight)
			var right := lerpf(Guide.painted_curb_x(1, float(y) * 0.5) * 2.0, _profile_x(ROAD_RIGHT_PROFILE, y), foreground_weight)
			for x in SIZE.x:
				var coverage := (smoothstep(left - 7.0, left + 3.0, float(x))
					* (1.0 - smoothstep(right - 3.0, right + 7.0, float(x))))
				if coverage > 0.003:
					var pixel := original.get_pixel(x, y)
					pixel.a *= coverage
					output.set_pixel(x, y, pixel)
		var path := OUTPUT_DIR + "l01_v12_%s_clean_road.png" % String(entry[0])
		if output.save_png(path) != OK:
			printerr("Could not save " + path)
			quit(3)
			return
	print("L01 v12: exported five clean registered roads")
	quit()


func _profile_x(profile: Array, y: int) -> float:
	if y <= int(profile[0].x):
		return profile[0].y
	for index in range(1, profile.size()):
		var previous: Vector2 = profile[index - 1]
		var current: Vector2 = profile[index]
		if y <= int(current.x):
			return lerpf(previous.y, current.y, inverse_lerp(previous.x, current.x, float(y)))
	return profile[-1].y
