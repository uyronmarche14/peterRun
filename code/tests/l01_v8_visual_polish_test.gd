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
	var prompt_card := level.get_node(^"HUD/HUDRoot/PromptCard") as Control
	_expect(prompt_card.offset_bottom <= 32.0, "Prompt card does not cover the Hall tower")
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
		level.set("_shown_prompt_action", &"")
		(level.get_node(^"HUD/HUDRoot/PromptActionLabel") as Label).text = "SAFE PATH"
		level.call("refresh_control_hint", true)
		_expect(hint.text == "KEEP YOUR PATH", "Device refresh retains neutral safe-path guidance")

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

	# A spatial stage wipe must not show freestanding sidewalk sprites ahead
	# of the new painted street plate.
	route.call("configure_route", 17, 0)
	route.call("set_route_progress", 1, true)
	route.call("advance_layer_motion", 0.6)
	var incoming_life := route.get_node(^"JourneyStages/StageWaitingShed/StreetLife") as Node2D
	_expect(incoming_life.modulate.a <= 0.1, "Stage details wait for their supporting street plate")
	route.call("advance_layer_motion", 0.6)
	_expect(incoming_life.modulate.a >= 0.9, "Stage details become visible after the reveal")

	var laundry := (load("res://scenes/props/laundry_line.tscn") as PackedScene).instantiate() as Node2D
	level.get_node(^"LevelWorld/PromptWorldAnchor/PromptProps").add_child(laundry)
	var motion := level.get_node(^"WorldMotion")
	motion.call("begin_prompt_approach", 0, 2.5, 2.0)
	motion.set("_prompt_elapsed", 4.5)
	motion.call("_apply_prompt_projection")
	var laundry_aspect := laundry.scale.x / laundry.scale.y
	print("V8 side-lane laundry scale: %s, footprint: %s, aspect: %.3f" % [laundry.scale, laundry.get_meta(&"projection_footprint"), laundry_aspect])
	_expect(laundry_aspect >= 0.85, "Side-lane laundry retains a natural post-to-crossbar proportion")
	laundry.free()

	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN L01 v8 visual polish: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
