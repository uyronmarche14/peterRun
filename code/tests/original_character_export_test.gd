extends SceneTree

func _init() -> void:
	var config := ConfigFile.new()
	if config.load("res://export_presets.cfg") != OK:
		printerr("FAIL: Export presets unavailable")
		quit(1)
		return
	var filter: String = config.get_value("preset.0", "include_filter", "")
	if not filter.contains("art/characters/peter_adult_image_v04/animation_manifest.json"):
		printerr("FAIL: Runtime animation manifest must be explicitly included in exports")
		quit(1)
		return
	print("PETER adult image export resource contract: PASS")
	quit(0)
