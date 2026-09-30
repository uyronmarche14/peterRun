extends SceneTree

const CASES := [
	{
		"scene": "res://scenes/props/crate.tscn",
		"asset": "res://art/prompts/l01_barangay/prompt_l01_delivery_crates_v03.png",
		"size": Vector2i(192, 192),
		"art_scale": Vector2(0.5, 0.5),
		"overlays": {
			"ActiveHighlight": "res://art/prompts/l01_barangay/prompt_l01_delivery_crates_highlight_v01.png",
			"ContactShadow": "res://art/prompts/l01_barangay/prompt_l01_delivery_crates_shadow_v01.png",
		},
	},
	{
		"scene": "res://scenes/props/puddle.tscn",
		"asset": "res://art/prompts/l01_barangay/prompt_l01_shallow_puddle_v03.png",
		"size": Vector2i(256, 128),
		"art_scale": Vector2(0.375, 0.375),
		"overlays": {
			"ActiveHighlight": "res://art/prompts/l01_barangay/prompt_l01_shallow_puddle_highlight_v01.png",
			"RippleOverlay": "res://art/prompts/l01_barangay/prompt_l01_shallow_puddle_ripple_v01.png",
		},
	},
	{
		"scene": "res://scenes/props/laundry_line.tscn",
		"asset": "res://art/prompts/l01_barangay/prompt_l01_laundry_line_v03.png",
		"size": Vector2i(256, 192),
		"art_scale": Vector2(0.4, 0.4),
		"overlays": {
			"ActiveHighlight": "res://art/prompts/l01_barangay/prompt_l01_laundry_line_highlight_v01.png",
			"ContactShadow": "res://art/prompts/l01_barangay/prompt_l01_laundry_line_shadow_v01.png",
			"ClothSwayOverlay": "res://art/prompts/l01_barangay/prompt_l01_laundry_cloth_sway_v01.png",
		},
	},
]

const DECOR_ASSETS := {
	"res://art/prompts/l01_barangay/decor_l01_delivery_crate_v01.png": Vector2i(128, 128),
	"res://art/prompts/l01_barangay/decor_l01_small_puddle_v01.png": Vector2i(128, 64),
	"res://art/prompts/l01_barangay/decor_l01_laundry_line_v01.png": Vector2i(192, 144),
}

var failures: PackedStringArray = []


func _init() -> void:
	for entry in CASES:
		_test_prop(entry)
	_test_decor_assets()
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
		var image := texture.get_image()
		_expect(image != null and image.get_pixel(0, 0).a == 0.0, "Prompt PNG has transparent canvas corners: " + asset_path)

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
	for node_name in entry.overlays:
		var overlay := prop.get_node_or_null(NodePath(node_name)) as Sprite2D
		var overlay_path: String = entry.overlays[node_name]
		_expect(overlay != null, "Prompt scene exposes image overlay %s: %s" % [node_name, entry.scene])
		if overlay != null:
			_expect(overlay.texture != null and overlay.texture.resource_path == overlay_path, "%s references its intended transparent PNG" % node_name)
			_expect(overlay.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "%s uses nearest-neighbour filtering" % node_name)
			if overlay.texture != null:
				_expect(overlay.texture.get_size() == Vector2(entry.size), "%s preserves the prop canvas for stable alignment" % node_name)
				var overlay_image := overlay.texture.get_image()
				_expect(overlay_image != null and overlay_image.get_pixel(0, 0).a == 0.0, "%s has transparent canvas corners" % node_name)
	prop.queue_free()


func _test_decor_assets() -> void:
	for asset_path in DECOR_ASSETS:
		_expect(ResourceLoader.exists(asset_path), "Roadside decor PNG exists: " + asset_path)
		var texture := load(asset_path) as Texture2D
		_expect(texture != null and texture.get_size() == Vector2(DECOR_ASSETS[asset_path]), "Roadside decor uses its approved canvas: " + asset_path)
		if texture != null:
			var image := texture.get_image()
			_expect(image != null and image.get_pixel(0, 0).a == 0.0, "Roadside decor has transparent canvas corners: " + asset_path)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
