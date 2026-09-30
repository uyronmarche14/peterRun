extends SceneTree

const Director = preload("res://scripts/prompt_director.gd")
var failures: PackedStringArray = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	var player: Node = level.get_node("Player")
	player.set_process(false)
	var sprite: Sprite2D = player.get_node("Visual/CharacterSprite")
	_expect(sprite.get("animation") == &"walk_forward", "Playable level selects walking presentation")
	level.call("_record_prompt_resolution", &"move_left", Director.Resolution.SUCCESS)
	_expect(sprite.get("animation") == &"success_settle", "Only actual success feedback selects success settle")
	_expect(level.get("session_result").get_completed(&"move_left") == 1, "Feedback preserves one actual repetition")
	player.call("_process", 1.0)
	_expect(sprite.get("animation") == &"walk_forward", "Feedback returns to walking")
	level.call("_record_prompt_resolution", &"move_left", Director.Resolution.SAFE_CLEAR)
	_expect(sprite.get("animation") == &"neutral_clear", "Safe passage selects non-celebratory neutral clear")
	_expect(level.get("session_result").get_completed(&"move_left") == 1 and level.get("session_result").neutral_misses == 0, "Safe feedback awards no repetition and no miss")
	level.call("_record_prompt_resolution", &"jump", Director.Resolution.NEUTRAL_MISS)
	_expect(sprite.get("animation") == &"neutral_clear" and level.get("session_result").neutral_misses == 1, "Neutral misses keep their own accounting")
	player.call("handle_action", &"jump")
	level.call("_record_prompt_resolution", &"jump", Director.Resolution.SUCCESS)
	_expect(sprite.get("animation") == &"jump_low", "Resolving feedback never snaps an active airborne pose to ground")
	var action: Tween = player.get("_action_tween")
	action.pause()
	action.custom_step(0.93)
	_expect(sprite.get("animation") == &"success_settle", "Queued feedback plays only after action recovery")
	_expect(player.has_method("set_resting_preview"), "Rest/paused poses are available only as explicit resting previews")
	if player.has_method("set_resting_preview"):
		player.call("set_resting_preview")
		_expect(sprite.get("animation") == &"rest", "Resting preview uses original rest cycle")
		player.call("set_resting_preview", true)
		_expect(sprite.get("animation") == &"paused", "Paused artwork is available for grounded preview, not gameplay pause")
		player.call("handle_action", &"jump")
		player.call("set_resting_preview", true)
		_expect(sprite.get("animation") == &"jump_low", "Preview cannot override an active action")
	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN classic feedback animation test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
