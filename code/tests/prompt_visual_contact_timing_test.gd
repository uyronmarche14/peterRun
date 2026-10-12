extends SceneTree

const PLAYER_SCENE := "res://scenes/player.tscn"
const RUNNER_SCENE := "res://scenes/levels/runner_level.tscn"

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for input_at in [0.0, 2.49, 2.5, 3.5, 4.49]:
		await _test_visual_start(input_at)
	await _test_warning_input_remains_one_rep()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN prompt visual contact timing test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _test_visual_start(input_at: float) -> void:
	var player: Node = (load(PLAYER_SCENE) as PackedScene).instantiate()
	root.add_child(player)
	await process_frame
	player.set_process(false)
	player.call("set_walking", true)
	var eta := 4.5 - input_at
	var accepted: Variant = player.call("handle_action", &"jump", eta)
	_expect(accepted == true, "Jump is accepted at t=%.2f" % input_at)
	if accepted != true:
		player.free()
		return
	var sprite: Sprite2D = player.get_node(^"Visual/CharacterSprite")
	_expect(player.get("action_state") == 1, "Input changes action state immediately at t=%.2f" % input_at)
	if eta > 0.92:
		_expect(sprite.get("animation") != &"jump_low", "Early input at t=%.2f waits visually for contact" % input_at)
		player.call("_process", eta - 0.93)
		_expect(sprite.get("animation") != &"jump_low", "Jump at t=%.2f does not finish too early" % input_at)
		player.call("_process", 0.02)
		_expect(sprite.get("animation") == &"jump_low", "Jump at t=%.2f starts near contact" % input_at)
	else:
		_expect(sprite.get("animation") == &"jump_low", "Late input at t=%.2f shows Jump immediately" % input_at)
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
	_expect(level.get_node(^"Player/Visual/CharacterSprite").get("animation") != &"jump_low", "Warning-phase Jump acknowledges input without finishing before contact")
	_expect(level.get("session_result").get_completed(&"jump") == 0, "Warning input cannot add an early repetition")
	level.call("_on_warning_timer_timeout")
	level.call("_on_response_timer_timeout")
	_expect(level.get("session_result").get_completed(&"jump") == 1, "Contact adds exactly one Jump repetition")
	level.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
