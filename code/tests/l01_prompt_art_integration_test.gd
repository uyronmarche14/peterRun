extends SceneTree

const CASES := [
	{
		"scene": "res://scenes/props/crate.tscn",
		"asset": "res://art/prompts/l01_barangay/prompt_l01_delivery_crates_v01.png",
		"size": Vector2i(192, 192),
		"art_scale": Vector2(0.5, 0.5),
	},
	{
		"scene": "res://scenes/props/puddle.tscn",
		"asset": "res://art/prompts/l01_barangay/prompt_l01_shallow_puddle_v01.png",
		"size": Vector2i(256, 128),
		"art_scale": Vector2(0.375, 0.375),
	},
	{
		"scene": "res://scenes/props/laundry_line.tscn",
		"asset": "res://art/prompts/l01_barangay/prompt_l01_laundry_line_v01.png",
		"size": Vector2i(256, 192),
		"art_scale": Vector2(0.4, 0.4),
	},
]

var failures: PackedStringArray = []


func _init() -> void:
	for entry in CASES:
		_test_prop(entry)
	_test_puddle_world_detail()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 prompt-art integration test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_prop(entry: Dictionary) -> void:
	var asset_path: String = entry.asset
	_expect(ResourceLoader.exists(asset_path), "Prompt PNG exists: " + asset_path)
	var texture: Texture2D = load(asset_path)
	_expect(texture != null, "Prompt PNG loads: " + asset_path)
	if texture != null:
		_expect(texture.get_size() == Vector2(entry.size), "Prompt PNG preserves native dimensions: " + asset_path)

	var packed: PackedScene = load(entry.scene)
	_expect(packed != null, "Prompt scene loads: " + entry.scene)
	if packed == null:
		return
	var prop := packed.instantiate()
	var sprite := prop.get_node_or_null(^"ArtSprite") as Sprite2D
	_expect(sprite != null, "Prompt scene uses its exported ArtSprite: " + entry.scene)
	if sprite != null:
		_expect(sprite.texture != null and sprite.texture.resource_path == asset_path, "ArtSprite references the intended prompt PNG: " + entry.scene)
		_expect(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "ArtSprite uses nearest-neighbour filtering: " + entry.scene)
		_expect(sprite.scale == entry.art_scale, "ArtSprite uses its readable 2.5D presentation scale: " + entry.scene)
	prop.queue_free()


func _test_puddle_world_detail() -> void:
	var puddle: Node2D = (load("res://scenes/props/puddle.tscn") as PackedScene).instantiate()
	var rim := puddle.get_node_or_null("PuddleRim") as Line2D
	var reflection := puddle.get_node_or_null("PuddleReflection") as Line2D
	_expect(rim != null and rim.visible, "Jump puddle has a visible high-contrast edge")
	_expect(reflection != null and reflection.visible, "Jump puddle has a visible reflective water cue")
	puddle.queue_free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
