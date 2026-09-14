extends SceneTree

const GAME_SETTINGS_PATH := "res://scripts/game_settings.gd"
const LEVEL_SELECTION_PATH := "res://scripts/level_selection.gd"
const CATALOG_PATH := "res://data/levels/catalog.tres"
const L02_PATH := "res://data/levels/l02_market.tres"
const L03_PATH := "res://data/levels/l03_rainy_crossing.tres"

var failures: PackedStringArray = []


func _init() -> void:
	_test_visual_pace_settings()
	_test_expandable_route_catalog()
	_finish()


func _test_visual_pace_settings() -> void:
	_expect(ResourceLoader.exists(GAME_SETTINGS_PATH), "Game settings model exists")
	if not ResourceLoader.exists(GAME_SETTINGS_PATH):
		return
	var settings_script: GDScript = load(GAME_SETTINGS_PATH)
	settings_script.call("set_visual_pace", 1.15)
	_expect(is_equal_approx(settings_script.get("visual_pace"), 1.15), "Visual pace accepts the lively setting")
	settings_script.call("set_visual_pace", 99.0)
	_expect(is_equal_approx(settings_script.get("visual_pace"), 1.15), "Visual pace stays within the approved range")


func _test_expandable_route_catalog() -> void:
	_expect(ResourceLoader.exists(L02_PATH), "L02 route resource exists")
	_expect(ResourceLoader.exists(L03_PATH), "L03 route resource exists")
	if not ResourceLoader.exists(CATALOG_PATH) or not ResourceLoader.exists(LEVEL_SELECTION_PATH):
		return
	var catalog: Resource = load(CATALOG_PATH)
	for level_id in [&"l01_barangay", &"l02_market", &"l03_rainy_crossing"]:
		var definition: Resource = catalog.call("find_level", level_id)
		_expect(definition != null, "Catalog resolves " + str(level_id))
		if definition != null:
			_expect(definition.call("validate").is_empty(), str(level_id) + " validates")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN game route settings test: PASS")
		quit(0)
		return
	for failure in failures:
		printerr("FAIL: " + failure)
	printerr("PETER RUN game route settings test: FAIL (%d failures)" % failures.size())
	quit(1)
