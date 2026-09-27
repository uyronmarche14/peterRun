extends SceneTree

const SpriteModel = preload("res://scripts/classic_runner_sprite.gd")
const EXPECTED_COUNTS := {&"idle_ready": 48, &"walk_forward": 29, &"move_left": 6, &"move_right": 6, &"jump_low": 15, &"slide_duck": 12, &"success_settle": 12, &"neutral_clear": 6, &"paused": 1, &"rest": 48}
var failures: PackedStringArray = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player: Node = load("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.set_process(false)
	var sprite: Sprite2D = player.get_node("Visual/CharacterSprite")
	var checked := 0
	var missing := 0
	for clip in EXPECTED_COUNTS:
		_expect(SpriteModel.CLIPS[clip][0] == EXPECTED_COUNTS[clip], "Exact frame contract: " + String(clip))
		var images: Array[Image] = []
		for index in EXPECTED_COUNTS[clip]:
			var path: String = SpriteModel.frame_path(clip, index)
			if not ResourceLoader.exists(path):
				missing += 1
				continue
			var spec: Dictionary = SpriteModel.manifest.animations[String(clip)]
			sprite.call("play_clip", clip)
			sprite.call("advance", float(spec.timestamps[index]) + 0.00001)
			var texture: Texture2D = sprite.texture
			_expect(texture is AtlasTexture and texture.get_size() == Vector2(256, 256), "Fixed 256px runtime tile: " + path)
			if texture == null:
				continue
			var image := texture.get_image()
			_expect(image.detect_alpha() != Image.ALPHA_NONE and image.get_pixel(0, 0).a == 0.0, "Transparent background: " + path)
			_expect(image.get_used_rect().has_area(), "Nonempty original artwork: " + path)
			images.append(image)
			_expect(sprite.call("get_clip_frame") == index, "Runtime selects exact manifest timestamp: " + path)
			checked += 1
		if images.size() > 1:
			var different := false
			for index in range(1, images.size()):
				if images[index].get_data() != images[0].get_data():
					different = true
			_expect(different, "Genuine distinct animation frames: " + String(clip))
	_expect(missing == 0, "%d production frames absent/unimported; run parent asset build then Godot --editor --import" % missing)
	_expect(checked == 183, "All 183 production frames must be exercised (checked %d)" % checked)
	player.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN classic sprite assets test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
