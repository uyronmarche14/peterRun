extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const MAIN_SCENE := "res://scenes/main.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# As a therapist, I need to know that this setting changes scenery motion,
	# not the response time allowed for a prescribed movement.
	var original_pace: float = Settings.visual_pace
	var dashboard := (load(MAIN_SCENE) as PackedScene).instantiate()
	root.add_child(dashboard)
	await process_frame
	var option := dashboard.get_node(^"SettingsOverlay/Panel/Margin/Content/RoutePaceOption") as OptionButton
	var explanation := dashboard.get_node(^"SettingsOverlay/Panel/Margin/Content/RoutePaceLabel") as Label
	_expect(option.item_count == 3, "Three visual motion comfort choices remain")
	for index in mini(3, option.item_count):
		_expect(option.get_item_text(index).begins_with("Scenery motion: "),
			"Choice %d names scenery motion, not game speed" % index)
	_expect(explanation.visible and explanation.text == "Prompt timing stays the same",
		"Visible settings explanation says prompt timing is unchanged")
	dashboard.call("set_route_pace", 2)
	_expect(is_equal_approx(Settings.visual_pace, Settings.LIVELY_PACE),
		"Existing visual pace choice still changes its own setting")
	dashboard.free()
	Settings.set_visual_pace(original_pace)
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN settings motion label: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
