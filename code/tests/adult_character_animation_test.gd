extends SceneTree

const ROOT := "res://art/characters/peter_adult_v02"
const MANIFEST_PATH := ROOT + "/animation_manifest.json"
const REQUIRED_CLIPS := {
	"idle_ready": [2.0, true],
	"walk_forward": [1.2, true],
	"move_left": [0.22, false],
	"move_right": [0.22, false],
	"jump_low": [0.62, false],
	"slide_duck": [0.48, false],
	"rest": [2.0, true],
	"success_settle": [0.5, false],
	"neutral_clear": [0.25, false],
	"paused": [1.0 / 24.0, false],
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
	_expect(manifest.get("source_file", "") == "Peter_Run_Visual_Production/Peter_Adult_Animated_v02.blend", "Manifest identifies the editable v02 Blender source")
	_expect(manifest.get("authoring_fps", 0) == 30 and manifest.get("sampling_fps", 0) == 24, "Authoring and export frame rates remain explicit")
	_expect(manifest.get("canvas", []) == [256, 256] and manifest.get("pivot", []) == [128, 216], "Every clip keeps the fixed runtime canvas and ground anchor")
	var animations: Dictionary = manifest.get("animations", {})
	_expect(animations.size() == REQUIRED_CLIPS.size(), "Manifest contains exactly the required adult clips")
	for clip in REQUIRED_CLIPS:
		_expect(animations.has(clip), "Manifest contains clip: " + clip)
		if not animations.has(clip):
			continue
		var spec: Dictionary = animations[clip]
		_expect(is_equal_approx(float(spec.get("duration_seconds", 0.0)), float(REQUIRED_CLIPS[clip][0])), "Clip duration matches gameplay contract: " + clip)
		_expect(bool(spec.get("loop", false)) == bool(REQUIRED_CLIPS[clip][1]), "Clip loop mode matches gameplay contract: " + clip)
		_expect(int(spec.get("frames", 0)) == maxi(1, ceili(float(REQUIRED_CLIPS[clip][0]) * 24.0 - 0.000001)), "Clip frame count matches 24 fps sampling: " + clip)
		var atlas_path := ROOT + "/" + String(spec.get("atlas", ""))
		_expect(ResourceLoader.exists(atlas_path), "Runtime atlas exists: " + clip)
		var atlas := load(atlas_path) as Texture2D
		_expect(atlas != null, "Runtime atlas loads: " + clip)
		if atlas != null:
			_expect(atlas.get_image().get_pixel(0, 0).a == 0.0, "Runtime atlas retains transparent padding: " + clip)

	var player_scene := load("res://scenes/player.tscn") as PackedScene
	_expect(player_scene != null, "Player scene loads with adult Peter v02")
	if player_scene != null:
		var player := player_scene.instantiate()
		root.add_child(player)
		var sprite: Sprite2D = player.get_node(^"Visual/CharacterSprite")
		_expect(sprite.call("frame_path", &"walk_forward", 0).begins_with(ROOT + "/"), "Player sprite resolves the adult-v02 atlas root")
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


func _finish() -> void:
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN adult character animation test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
