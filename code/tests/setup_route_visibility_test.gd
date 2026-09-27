extends SceneTree

## L02/L03 stay in the catalog for development but are hidden from Setup until
## they have complete, finishable routes.

const Store = preload("res://scripts/session_setup_store.gd")
const Config = preload("res://scripts/session_config.gd")
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Store.reset()
	var setup: Control = load("res://scenes/patient_setup.tscn").instantiate()
	root.add_child(setup)
	await process_frame
	var option: OptionButton = setup.get_node("Panel/Margin/Content/LevelOption")
	var ids: Array = []
	for index in option.item_count:
		ids.append(StringName(option.get_item_metadata(index)))
	_expect(ids == [&"l01_barangay"], "Setup offers only Barangay Morning (got %s)" % [ids])
	setup.free()

	# A previously stored hidden route falls back to a visible one.
	Store.configure(Config.AffectedSide.RIGHT, 10, &"l02_market")
	setup = load("res://scenes/patient_setup.tscn").instantiate()
	root.add_child(setup)
	await process_frame
	setup.call("save_session_settings")
	_expect(Store.get_session_config().selected_level_id == &"l01_barangay", "A stored hidden route is replaced by a visible one")
	setup.free()

	var catalog: Resource = load("res://data/levels/catalog.tres")
	_expect(catalog.call("find_level", &"l02_market") != null, "L02 remains in the catalog for development")
	_expect(catalog.call("find_level", &"l03_rainy_crossing") != null, "L03 remains in the catalog for development")

	Store.reset()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN setup route visibility test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
