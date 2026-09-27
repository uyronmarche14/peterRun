extends Sprite2D
## Presentation only. Gameplay owns action/lane durations and pause.
## Each image contains its own lift/pose; never add runtime squash or lift.

const ROOT := "res://art/characters/peter_adult_image_v04"
static var manifest: Dictionary = _read_manifest()
# Compatibility inspection interface; values are derived from the production
# manifest, not a second hard-coded frame/timing table.
static var CLIPS: Dictionary = _clip_summary()

static func _read_manifest() -> Dictionary:
	var path := ROOT + "/animation_manifest.json"
	assert(FileAccess.file_exists(path), "Adult Peter image animation manifest missing")
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(value is Dictionary and value.has("animations"), "Invalid adult Peter image animation manifest")
	return value

static func _clip_summary() -> Dictionary:
	var result := {}
	for clip in manifest.animations:
		var spec: Dictionary = manifest.animations[clip]
		result[StringName(clip)] = [int(spec.frames), float(spec.fps), bool(spec.loop)]
	return result

var animation: StringName = &"idle_ready"
var elapsed := 0.0
var duration := 2.0
var finished := false
var _textures: Dictionary = {}

func _ready() -> void:
	play_clip(&"idle_ready")

static func frame_path(clip: StringName, _index: int) -> String:
	return ROOT + "/" + String(manifest.animations[String(clip)].atlas)

func play_clip(clip: StringName, fit_seconds: float = 0.0) -> void:
	assert(CLIPS.has(clip), "Unknown adult Peter clip")
	animation = clip
	elapsed = 0.0
	finished = false
	duration = fit_seconds if fit_seconds > 0.0 else float(manifest.animations[String(clip)].duration_seconds)
	_apply_frame(0)

func advance(delta: float) -> void:
	elapsed += maxf(0.0, delta)
	var looping: bool = CLIPS[animation][2]
	finished = not looping and elapsed >= duration
	var phase := fposmod(elapsed, duration) if looping else minf(elapsed, duration)
	var spec: Dictionary = manifest.animations[String(animation)]
	var source_time: float = phase / duration * float(spec.duration_seconds)
	var index := 0
	for candidate in range(1, int(spec.frames)):
		if source_time + 0.000001 < float(spec.timestamps[candidate]):
			break
		index = candidate
	_apply_frame(index)

func _apply_frame(index: int) -> void:
	set_meta("clip_frame", index)
	var key := "%s/%d" % [animation, index]
	if not _textures.has(key):
		var path := frame_path(animation, index)
		var region: Array = manifest.animations[String(animation)].regions[index]
		var atlas := AtlasTexture.new()
		atlas.atlas = load(path)
		atlas.region = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
		atlas.filter_clip = true
		_textures[key] = atlas
	texture = _textures[key]

func get_clip_frame() -> int:
	return int(get_meta("clip_frame", 0))
