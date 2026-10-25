extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const MAIN_SCENE := "res://scenes/main.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# As a therapist, I need to know that this setting changes scenery motion,
	# not the response time allowed for a prescribed movement.
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 540)
	var original_pace: float = Settings.visual_pace
	var dashboard := (load(MAIN_SCENE) as PackedScene).instantiate()
	root.add_child(dashboard)
	await process_frame
	dashboard.call("open_settings")
	await process_frame
	var option := dashboard.get_node(^"SettingsOverlay/Panel/Margin/Content/RoutePaceOption") as OptionButton
	var explanation := dashboard.get_node(^"SettingsOverlay/Panel/Margin/Content/RoutePaceLabel") as Label
	var settings_panel := dashboard.get_node(^"SettingsOverlay/Panel") as Control
	_expect(option.item_count == 3, "Three visual motion comfort choices remain")
	for index in mini(3, option.item_count):
		_expect(option.get_item_text(index).begins_with("Scenery motion: "),
			"Choice %d names scenery motion, not game speed" % index)
	_expect(explanation.visible and explanation.text == "Prompt timing stays the same",
		"Visible settings explanation says prompt timing is unchanged")
	_expect(settings_panel.size.y <= 210.0,
		"Explained settings panel stays within a reviewed native height (got %.1f)" % settings_panel.size.y)
	dashboard.call("set_route_pace", 2)
	_expect(is_equal_approx(Settings.visual_pace, Settings.LIVELY_PACE),
		"Existing visual pace choice still changes its own setting")
	dashboard.free()
	Settings.set_visual_pace(original_pace)
	# A speed chosen on the review screen is not one of the three presets; the menu must say so.
	Settings.set_visual_pace(1.3)
	var custom_dashboard := (load(MAIN_SCENE) as PackedScene).instantiate()
	root.add_child(custom_dashboard)
	await process_frame
	var custom_option := custom_dashboard.get_node(^"SettingsOverlay/Panel/Margin/Content/RoutePaceOption") as OptionButton
	_expect(custom_option.item_count == 4 and custom_option.selected == 3, "A review-chosen pace is shown as its own selected choice")
	_expect(custom_option.get_item_text(3).begins_with("Scenery motion: Speed "), "The review-chosen pace is shows the 1-10 speed number")
	custom_dashboard.free()
	Settings.set_visual_pace(original_pace)
	# Start countdown choice.
	var cd_dashboard := (load(MAIN_SCENE) as PackedScene).instantiate()
	root.add_child(cd_dashboard)
	await process_frame
	var cd_option := cd_dashboard.get_node_or_null(^"SettingsOverlay/Panel/Margin/Content/CountdownOption") as OptionButton
	_expect(cd_option != null and cd_option.item_count == 3, "Settings offer a start countdown choice (3 s, 5 s, Off)")
	if cd_option != null:
		_expect(cd_option.selected == 0 and Settings.countdown_seconds == 3, "Countdown defaults to 3 seconds")
		cd_dashboard.call("set_countdown_choice", 1)
		_expect(Settings.countdown_seconds == 5, "Choosing 5 seconds sets the countdown to 5")
		cd_dashboard.call("set_countdown_choice", 2)
		_expect(Settings.countdown_seconds == 0, "Choosing Off sets the countdown to 0")
	Settings.set_countdown_seconds(3)
	cd_dashboard.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN settings motion label: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
