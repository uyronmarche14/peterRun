extends SceneTree

const PLAYER_SCENE := "res://scenes/player.tscn"
const RUNNER_SCENE := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for input_at in [0.0, 2.49, 2.5, 3.5, 4.49]:
		await _test_visual_contact(&"jump", input_at)
	await _test_visual_contact(&"slide", 2.5)
	await _test_warning_input_remains_one_rep()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN prompt visual contact timing test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_visual_contact(action: StringName, input_at: float) -> void:
	var player: Node = (load(PLAYER_SCENE) as PackedScene).instantiate()
	root.add_child(player)
	await process_frame
	player.set_process(false)
	player.call("set_walking", true)
	var eta := 4.5 - input_at
	var accepted: Variant = player.call("handle_action", action, eta)
	_expect(accepted == true, "%s is accepted at t=%.2f" % [action, input_at])
	if accepted != true:
		player.free()
		return
	var sprite: Sprite2D = player.get_node(^"Visual/CharacterSprite")
	_expect(player.get("action_state") != 0, "Input changes action state immediately at t=%.2f" % input_at)
	var lead := 0.43 if action == &"jump" else 0.33
	var clip := &"jump_low" if action == &"jump" else &"slide_duck"
	if eta > lead + 0.24:
		_expect(sprite.get("animation") == clip, "Early %s input at t=%.2f immediately shows anticipation" % [action, input_at])
		_expect(not player.get("_contact_visual_active"), "Early %s anticipation is not the contact clearance" % action)
		player.call("_process", 0.14)
		_expect(sprite.call("get_clip_frame") > 0, "%s anticipation visibly advances without waiting for contact" % action)
		_expect(is_zero_approx(player.get_node(^"Visual").position.y), "Early %s does not lift or duck twice" % action)
		player.call("_process", 0.10)
		_expect(sprite.get("animation") == &"walk_forward", "%s returns to travel after the immediate anticipation" % action)
		player.call("_process", eta - lead - 0.25)
		_expect(sprite.get("animation") != clip, "%s contact clearance has not started too early" % action)
		player.call("_process", 0.02)
		_expect(sprite.get("animation") == clip, "%s clearance starts before contact" % action)
		player.call("_process", lead - 0.01)
	else:
		_expect(sprite.get("animation") == clip, "Near-contact %s input at t=%.2f starts immediately" % [action, input_at])
		player.call("_process", eta)
	_expect(sprite.get("animation") == clip, "%s remains visible at contact t=%.2f" % [action, input_at])
	var body_y: float = player.get_node(^"Visual").position.y
	_expect(body_y < -12.0 if action == &"jump" else body_y > 2.0, "%s clearance pose is readable at contact t=%.2f (y=%.1f)" % [action, input_at, body_y])
	player.call("set_gameplay_paused", true)
	var pose := [sprite.get("animation"), sprite.get("elapsed"), player.get_node(^"Visual").position]
	player.call("_process", 1.0)
	_expect([sprite.get("animation"), sprite.get("elapsed"), player.get_node(^"Visual").position] == pose, "Pause freezes contact visual at t=%.2f" % input_at)
	player.call("set_gameplay_paused", false)
	player.free()


func _test_warning_input_remains_one_rep() -> void:
	var level: Node = (load(RUNNER_SCENE) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	for timer in level.get_node(^"PromptTimers").get_children():
		timer.stop()
	var formation: Dictionary = {}
	for candidate in level.get("_formation_library"):
		if candidate.get("pattern_id", &"") == &"l01_p03_jump_center":
			formation = candidate.duplicate(true)
			break
	var director: Node = level.get_node(^"PromptDirector")
	director.call("_set_state", 0)
	level.set("_active_formation", formation)
	director.call("schedule_with_action_lanes", &"jump", [1])
	level.get_node(^"WorldMotion").call("begin_prompt_approach", 1, 2.5, 2.0)
	level.call("receive_input", &"jump", true, 10.0)
	_expect(level.get_node(^"Player/Visual/CharacterSprite").get("animation") == &"jump_low", "Warning-phase Jump shows immediate anticipation")
	_expect(level.get("session_result").get_completed(&"jump") == 0, "Warning input cannot add an early repetition")
	level.call("_on_warning_timer_timeout")
	level.call("_on_response_timer_timeout")
	_expect(level.get("session_result").get_completed(&"jump") == 1, "Contact adds exactly one Jump repetition")
	level.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
