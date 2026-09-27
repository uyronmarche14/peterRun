extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"
const PromptDirectorModel = preload("res://scripts/prompt_director.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level: Node = (load(RUNNER_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	await process_frame
	var effects: Node = level.get_node_or_null("ContactEffects")
	_expect(effects != null, "Runner level includes one reusable contact-effects node")
	if effects != null:
		_expect(effects.has_method("play_for_action"), "Contact effects expose action-specific feedback")
		_expect(effects.has_method("set_effects_paused"), "Contact effects can pause with gameplay")
		effects.call("play_for_action", &"jump", PromptDirectorModel.Resolution.SUCCESS, Vector2(240, 220))
		_expect(effects.visible, "A successful action makes its contact effect visible")
		_expect(effects.get("active_effect") == &"jump", "Jump receives its own contact effect")
		effects.call("set_effects_paused", true)
		var elapsed_before := float(effects.get("elapsed"))
		effects.call("_process", 0.5)
		_expect(is_equal_approx(float(effects.get("elapsed")), elapsed_before), "Paused gameplay freezes contact effects")
	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN contact effects test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
