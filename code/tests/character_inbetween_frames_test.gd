extends SceneTree

const CHARACTER_SPRITE := preload("res://scripts/classic_runner_sprite.gd")
const ART_ROOT := "res://art/characters/peter_adult_image_v04/"
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var sprite: Sprite2D = CHARACTER_SPRITE.new()
	root.add_child(sprite)
	await process_frame
	_check_clip(sprite, &"jump_low", 15, 0.92, 0.065, "jump_smooth_v06.png")
	_check_clip(sprite, &"slide_duck", 11, 0.48, 0.04, "slide_smooth_v06.png")
	sprite.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN character in-between frames test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_clip(sprite: Sprite2D, clip: StringName, frame_count: int, seconds: float, first_midpoint: float, atlas_name: String) -> void:
	var spec: Dictionary = CHARACTER_SPRITE.manifest.animations[String(clip)]
	_expect(int(spec.frames) == frame_count, "%s has %d distinct authored poses" % [clip, frame_count])
	_expect(absf(float(spec.duration_seconds) - seconds) < 0.0001, "%s keeps its gameplay duration" % clip)
	_expect(String(spec.atlas) == atlas_name, "%s uses its separately versioned smooth atlas" % clip)
	if int(spec.frames) != frame_count:
		return
	_expect(spec.timestamps.size() == frame_count and spec.regions.size() == frame_count, "%s has one timestamp and region per pose" % clip)
	_expect(absf(float(spec.timestamps[1]) - first_midpoint) < 0.001, "%s places its first in-between at the intended motion beat" % clip)
	var atlas_path := ART_ROOT + atlas_name
	_expect(ResourceLoader.exists(atlas_path), "%s atlas imports" % clip)
	if not ResourceLoader.exists(atlas_path):
		return
	var atlas: Texture2D = load(atlas_path)
	var image := atlas.get_image()
	var previous_pixels := PackedByteArray()
	for index in frame_count:
		var region: Array = spec.regions[index]
		var x := int(region[0])
		var y := int(region[1])
		_expect(int(region[2]) == 256 and int(region[3]) == 256, "%s frame %d keeps the fixed canvas" % [clip, index])
		_expect(x >= 0 and y >= 0 and x + 256 <= image.get_width() and y + 256 <= image.get_height(), "%s frame %d stays inside the atlas" % [clip, index])
		var visible_samples := 0
		for sy in range(y + 16, y + 240, 16):
			for sx in range(x + 16, x + 240, 16):
				if image.get_pixel(sx, sy).a > 0.15:
					visible_samples += 1
		_expect(visible_samples >= 8, "%s frame %d contains a visible Peter pose" % [clip, index])
		var frame_pixels := image.get_region(Rect2i(x, y, 256, 256)).get_data()
		if index > 0:
			_expect(frame_pixels != previous_pixels, "%s frame %d is a new pose, not a duplicate" % [clip, index])
		previous_pixels = frame_pixels
	sprite.play_clip(clip, seconds)
	sprite.call("advance", first_midpoint + 0.001)
	_expect(sprite.call("get_clip_frame") == 1, "%s actually displays its new first in-between" % clip)
	sprite.call("advance", seconds)
	_expect(bool(sprite.get("finished")), "%s still finishes at its original duration" % clip)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
