extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
const STAGES := ["StageHome", "StageWaitingShed", "StageSariSari", "StagePalengke", "StagePlaza"]
const SIGNATURES := ["HomeBananaDetail", "WaitingGreeting", "SariGreeting", "MarketCanopyEdge", "PlazaHallGlint"]

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.set_reduced_motion(false)
	var level := (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	var route := level.get_node(^"LevelWorld/L01BarangayLayers") as Node2D
	route.set_process(false)
	level.get_node(^"WorldMotion").set_process(false)

	var hint := level.get_node_or_null(^"HUD/HUDRoot/PromptControlHint") as Label
	_expect(hint != null, "Single prompt card includes an action-specific control hint")
	if hint != null:
		for action in [&"move_left", &"move_right", &"jump", &"slide"]:
			level.call("_update_prompt_card", action, "GET READY", Color.WHITE)
			level.call("refresh_control_hint", false)
			var key := ControlHints.input_name(action, false)
			_expect(hint.text.contains(key), "%s keyboard hint names %s" % [action, key])
		level.call("_update_prompt_card", &"move_left", "GET READY", Color.WHITE)
		level.call("refresh_control_hint", true)
		_expect(hint.text.contains("D-pad Left") and not hint.text.contains("Press A"), "Controller left prompt names D-pad Left")
		level.call("_update_prompt_card", &"jump", "GET READY", Color.WHITE)
		level.call("refresh_control_hint", true)
		_expect(hint.text.contains("A button"), "Controller jump prompt names face button")
		_expect(hint.get_minimum_size().x <= hint.size.x + 0.5, "Control hint fits the prompt card")

	for index in STAGES.size():
		route.call("configure_route", 17, index)
		var life := route.get_node("JourneyStages/%s/StreetLife" % STAGES[index]) as Node2D
		var parts: Array = life.call("get_animated_parts")
		_expect(parts.size() == 4, "%s has one new signature detail" % STAGES[index])
		var signature := life.get_node_or_null(SIGNATURES[index]) as Sprite2D
		_expect(signature != null, "%s owns %s" % [STAGES[index], SIGNATURES[index]])
		if signature == null:
			continue
		life.call("set_ambient_phase", 0.0)
		var rest := [signature.frame, signature.rotation, signature.position, signature.modulate]
		life.call("set_ambient_phase", 2.5)
		var moved: bool = signature.frame != rest[0] or not is_equal_approx(signature.rotation, rest[1]) or signature.position != rest[2] or signature.modulate != rest[3]
		_expect(moved, "%s signature moves gently" % STAGES[index])
		route.call("set_motion_paused", true)
		var paused := [signature.frame, signature.rotation, signature.position, signature.modulate]
		route.call("advance_layer_motion", 2.0)
		_expect([signature.frame, signature.rotation, signature.position, signature.modulate] == paused, "%s signature freezes on Pause" % STAGES[index])
		route.call("set_motion_paused", false)
		Settings.set_reduced_motion(true)
		route.call("advance_layer_motion", 0.1)
		_expect(signature.frame == 0 and is_zero_approx(signature.rotation), "%s signature rests in Reduced Motion" % STAGES[index])
		Settings.set_reduced_motion(false)

	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 v8 visual polish: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
