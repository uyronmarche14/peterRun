extends SceneTree

## Tutorial and gameplay hints must name the button for the device in use:
## gamepad "A" is Jump, so a keyboard "Press A" hint misleads controller users.

const Store = preload("res://scripts/session_setup_store.gd")
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Store.reset()
	var tutorial: Control = load("res://scenes/tutorial.tscn").instantiate()
	root.add_child(tutorial)
	await process_frame
	if tutorial.has_method("start_practice"):
		tutorial.call("start_practice")
	var expected_pad := ["D-pad Left", "D-pad Right", "A button", "B button"]
	var expected_key := ["Press A ", "Press D ", "Press W ", "Press S "]
	for index in 4:
		tutorial.current_action_index = index
		var pad_text: String = tutorial.call("_practice_instruction", true)
		var key_text: String = tutorial.call("_practice_instruction", false)
		_expect(pad_text.contains(expected_pad[index]), "Gamepad lesson %d names %s (got '%s')" % [index, expected_pad[index], pad_text])
		_expect(not pad_text.contains(expected_key[index]), "Gamepad lesson %d does not show a keyboard key" % index)
		_expect(key_text.contains(expected_key[index]), "Keyboard lesson %d keeps '%s' (got '%s')" % [index, expected_key[index], key_text])
	tutorial.free()

	var runner: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(runner)
	await process_frame
	var footer: Label = runner.get_node("HUD/HUDRoot/KeyboardHint")
	_expect(runner.has_method("refresh_control_hint"), "Runner can refresh its control hint")
	if runner.has_method("refresh_control_hint"):
		runner.call("refresh_control_hint", true)
		_expect(footer.text.contains("Start") and footer.text.contains("D-pad") and not footer.text.contains("Keyboard"), "Gamepad footer names controller buttons (got '%s')" % footer.text)
		_expect(footer.get_minimum_size().x <= footer.size.x + 0.5, "Gamepad footer fits its label (%.1f > %.1f)" % [footer.get_minimum_size().x, footer.size.x])
		runner.call("refresh_control_hint", false)
		_expect(footer.text.contains("A D W S") and footer.text.contains("P to pause"), "Keyboard footer keeps keyboard keys")
	runner.free()

	Store.reset()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN control hints test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
