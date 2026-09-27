extends SceneTree

const ROOT := "res://art/characters/peter_adult_image_v04"
const MANIFEST_PATH := ROOT + "/animation_manifest.json"
const EXPECTED_DISPLAY_SCALE := 0.32
const EXPECTED_JUMP_LIFT := [0, -4, -12, -18, -7, 0]
const EXPECTED_SLIDE_SCALE := [1.0, 0.96, 0.90, 0.88, 0.95, 1.0]
const REQUIRED_CLIPS := {
	"idle_ready": [2.0, true, 6],
	"walk_forward": [1.2, true, 6],
	"move_left": [0.22, false, 6],
	"move_right": [0.22, false, 6],
	"jump_low": [0.62, false, 6],
	"slide_duck": [0.48, false, 6],
	"rest": [2.0, true, 6],
	"success_settle": [0.5, false, 4],
	"neutral_clear": [0.25, false, 4],
	"paused": [1.0 / 24.0, false, 1],
}

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		failures.append("Adult Peter v02 animation manifest exists")
		_finish()
		return
	var manifest_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	_expect(manifest_value is Dictionary, "Adult Peter manifest parses")
	if not manifest_value is Dictionary:
		_finish()
		return
	var manifest: Dictionary = manifest_value
	_expect(manifest.get("design_reference", "") == "Peter_Run_Visual_Production/character_concepts/peter_character_v03/peter_character_turnaround_v03.png", "Manifest identifies the approved adult design")
	_expect(manifest.get("source_directory", "") == "Peter_Run_Visual_Production/generated/peter_adult_image_v04/source_strips", "Manifest identifies the preserved image source strips")
	_expect(manifest.get("generation_method", "").contains("identity-preserving reference prompts"), "Manifest records the approved image-generation method")
	var adjustments: Dictionary = manifest.get("visual_adjustments", {})
	_expect(is_equal_approx(float(adjustments.get("display_scale", 0.0)), EXPECTED_DISPLAY_SCALE), "Adult Peter is slightly larger without changing the ground anchor")
	_expect(_numeric_array_matches(adjustments.get("jump_lift_pixels", []), EXPECTED_JUMP_LIFT), "Jump artwork uses the higher approved visual arc")
	_expect(_numeric_array_matches(adjustments.get("slide_vertical_scale", []), EXPECTED_SLIDE_SCALE), "Slide artwork uses the deeper approved crouch")
	var canvas: Array = manifest.get("canvas", [])
	var pivot: Array = manifest.get("pivot", [])
	_expect(canvas.size() == 2 and int(canvas[0]) == 256 and int(canvas[1]) == 256 and pivot.size() == 2 and int(pivot[0]) == 128 and int(pivot[1]) == 216, "Every clip keeps the fixed runtime canvas and ground anchor")
	var animations: Dictionary = manifest.get("animations", {})
	_expect(animations.size() == REQUIRED_CLIPS.size(), "Manifest contains exactly the required adult clips")
	for clip in REQUIRED_CLIPS:
		_expect(animations.has(clip), "Manifest contains clip: " + clip)
		if not animations.has(clip):
			continue
		var spec: Dictionary = animations[clip]
		_expect(is_equal_approx(float(spec.get("duration_seconds", 0.0)), float(REQUIRED_CLIPS[clip][0])), "Clip duration matches gameplay contract: " + clip)
		_expect(bool(spec.get("loop", false)) == bool(REQUIRED_CLIPS[clip][1]), "Clip loop mode matches gameplay contract: " + clip)
		_expect(int(spec.get("frames", 0)) == int(REQUIRED_CLIPS[clip][2]), "Clip contains the approved key-pose count: " + clip)
		var atlas_path := ROOT + "/" + String(spec.get("atlas", ""))
		_expect(ResourceLoader.exists(atlas_path), "Runtime atlas exists: " + clip)
		var atlas := load(atlas_path) as Texture2D
		_expect(atlas != null, "Runtime atlas loads: " + clip)
		if atlas != null:
			_expect(atlas.get_image().get_pixel(0, 0).a == 0.0, "Runtime atlas retains transparent padding: " + clip)

	var player_scene := load("res://scenes/player.tscn") as PackedScene
	_expect(player_scene != null, "Player scene loads with adult Peter image animations")
	if player_scene != null:
		var player := player_scene.instantiate()
		root.add_child(player)
		var sprite: Sprite2D = player.get_node(^"Visual/CharacterSprite")
		_expect(sprite.scale == Vector2.ONE * EXPECTED_DISPLAY_SCALE, "Player scene displays the slightly larger adult Peter")
		_expect(sprite.call("frame_path", &"walk_forward", 0).begins_with(ROOT + "/"), "Player sprite resolves the approved adult-image atlas root")
		player.set_walking(true)
		player._process(0.18)
		var frozen := [sprite.animation, sprite.elapsed, sprite.get_clip_frame()]
		player.set_gameplay_paused(true)
		player._process(1.0)
		_expect([sprite.animation, sprite.elapsed, sprite.get_clip_frame()] == frozen, "Pause freezes the current adult animation exactly")
		player.set_gameplay_paused(false)
		player._process(0.05)
		_expect(sprite.elapsed > float(frozen[1]), "Resume continues the same adult animation")
		player.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _numeric_array_matches(actual: Array, expected: Array) -> bool:
	if actual.size() != expected.size():
		return false
	for index in actual.size():
		if not is_equal_approx(float(actual[index]), float(expected[index])):
			return false
	return true


func _finish() -> void:
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN adult character animation test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
