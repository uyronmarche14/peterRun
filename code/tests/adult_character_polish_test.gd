extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const EFFECT_ROOT := "res://art/characters/peter_adult_image_v04/effects"
const CONTACT_ROOT := "res://../Peter_Run_Visual_Production/generated/peter_adult_image_v04/contact_sheets"
const REQUIRED_EFFECTS := [
	"landing_ring.png",
	"landing_dust.png",
	"lane_shift_trail.png",
	"slide_dust.png",
]
const REQUIRED_CLIPS := [
	"idle_ready",
	"walk_forward",
	"move_left",
	"move_right",
	"jump_low",
	"slide_duck",
	"rest",
	"success_settle",
	"neutral_clear",
	"paused",
]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_exported_effect_art()
	_test_contact_sheet_package()
	_test_runtime_feedback()
	Settings.set_reduced_motion(false)
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN adult character polish test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_exported_effect_art() -> void:
	for filename in REQUIRED_EFFECTS:
		var path: String = EFFECT_ROOT + "/" + String(filename)
		_expect(ResourceLoader.exists(path), "Reusable transparent feedback texture exists: " + filename)
		if not ResourceLoader.exists(path):
			continue
		var texture := load(path) as Texture2D
		_expect(texture != null, "Feedback texture imports: " + filename)
		if texture == null:
			continue
		var image := texture.get_image()
		_expect(image.get_size() == Vector2i(128, 64), "Feedback texture uses the stable 128x64 canvas: " + filename)
		_expect(image.get_pixel(0, 0).a == 0.0, "Feedback texture keeps transparent outer padding: " + filename)


func _test_contact_sheet_package() -> void:
	var manifest_path := CONTACT_ROOT + "/contact_sheet_manifest.json"
	_expect(FileAccess.file_exists(manifest_path), "Contact-sheet manifest exists")
	if not FileAccess.file_exists(manifest_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	_expect(parsed is Dictionary, "Contact-sheet manifest parses")
	if not parsed is Dictionary:
		return
	var manifest: Dictionary = parsed
	_expect(manifest.get("character_id", "") == "peter_adult_image_v04", "Contact sheets identify the approved adult Peter set")
	_expect(manifest.get("clips", []).size() == REQUIRED_CLIPS.size(), "Contact-sheet manifest covers all ten adult clips")
	var overview_path := CONTACT_ROOT + "/peter_adult_image_v04_contact_sheet.png"
	_expect(FileAccess.file_exists(overview_path), "Complete adult animation overview contact sheet exists")
	for clip in REQUIRED_CLIPS:
		var sheet_path: String = CONTACT_ROOT + "/" + String(clip) + "_contact_sheet.png"
		_expect(FileAccess.file_exists(sheet_path), "Per-clip contact sheet exists: " + clip)
		if FileAccess.file_exists(sheet_path):
			var image := Image.load_from_file(sheet_path)
			_expect(not image.is_empty() and image.get_width() >= 256 and image.get_height() >= 256, "Per-clip contact sheet is reviewable: " + clip)


func _test_runtime_feedback() -> void:
	var packed := load("res://scenes/player.tscn") as PackedScene
	_expect(packed != null, "Player scene loads for feedback verification")
	if packed == null:
		return
	var player := packed.instantiate()
	root.add_child(player)
	player.set_process(false)
	var landing_ring := player.get_node_or_null(^"LandingRing") as CanvasItem
	var landing_dust := player.get_node_or_null(^"LandingRing/LandingDust") as Sprite2D
	var lane_trail_art := player.get_node_or_null(^"LaneTrail/TrailArt") as Sprite2D
	var slide_dust_art := player.get_node_or_null(^"SlideDust/DustArt") as Sprite2D
	_expect(landing_ring != null and landing_dust != null, "Landing feedback combines a ring with a soft dust layer")
	_expect(lane_trail_art != null, "Lane movement uses a layered transparent trail")
	_expect(slide_dust_art != null, "Slide feedback uses a layered transparent dust sprite")

	Settings.set_reduced_motion(false)
	player.handle_action(&"move_left")
	player._process(0.06)
	_expect(player.get_node(^"LaneTrail").visible, "Lane trail appears during lateral transfer")
	if lane_trail_art != null:
		_expect(lane_trail_art.modulate.a > 0.0, "Lane trail art fades in gently")
	var lane_transform: Transform2D = player.get_node(^"LaneTrail").transform
	var lane_alpha: float = player.get_node(^"LaneTrail").modulate.a
	player.set_gameplay_paused(true)
	player._process(0.2)
	_expect(player.get_node(^"LaneTrail").transform == lane_transform and is_equal_approx(player.get_node(^"LaneTrail").modulate.a, lane_alpha), "Pause freezes lane-trail motion and fade")
	player.set_gameplay_paused(false)

	player.reset_for_practice()
	player.handle_action(&"slide")
	player._process(0.10)
	_expect(player.get_node(^"SlideDust").visible, "Slide dust remains visible through the low action")
	if slide_dust_art != null:
		_expect(slide_dust_art.modulate.a > 0.0 and slide_dust_art.position.x < 0.0, "Slide dust drifts calmly behind Peter")

	player.reset_for_practice()
	player.handle_action(&"jump")
	var action_tween: Tween = player.get("_action_tween")
	action_tween.pause()
	action_tween.custom_step(0.93)
	player._process(0.06)
	_expect(landing_ring != null and landing_ring.visible, "Jump recovery emits the landing ring")
	_expect(landing_dust != null and landing_dust.visible and landing_dust.modulate.a > 0.0, "Jump recovery emits a restrained landing puff")

	player.reset_for_practice()
	Settings.set_reduced_motion(true)
	player.handle_action(&"slide")
	player._process(0.1)
	_expect(not player.get_node(^"SlideDust").visible and not player.get_node(^"LaneTrail").visible and not player.get_node(^"LandingRing").visible, "Reduced motion suppresses every optional feedback layer")
	player.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
