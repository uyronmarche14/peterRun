extends SceneTree

const PLAYER_SCENE := preload("res://scenes/player.tscn")
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_jump(false)
	await _check_jump(true)
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN jump readability test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _check_jump(approaching_prop: bool) -> void:
	# A player should see clear air between Peter and his anchored road shadow,
	# whether Jump starts freely or is fitted to an approaching puddle.
	var player: Node2D = PLAYER_SCENE.instantiate()
	root.add_child(player)
	await process_frame
	player.set_process(false)
	var eta := 0.43 if approaching_prop else -1.0
	_expect(player.call("handle_action", &"jump", eta), "Jump input is accepted")
	var shadow_tween: Tween = player.get("_shadow_tween")
	shadow_tween.pause()
	player.call("_process", 0.32)
	shadow_tween.custom_step(0.32)
	var visual: Node2D = player.get_node("Visual")
	var shadow: Node2D = player.get_node("Shadow")
	var sprite: Sprite2D = player.get_node("Visual/CharacterSprite")
	var context := "contact" if approaching_prop else "free"
	_expect(visual.position.y <= -27.0, "%s Jump reaches a clear native-canvas apex" % context)
	_expect(shadow.scale.x <= 0.44, "%s Jump shrinks its road-anchored shadow at apex" % context)
	_expect(sprite.get("animation") == &"jump_low" and sprite.call("get_clip_frame") >= 2,
		"%s Jump keeps the authored airborne pose" % context)
	player.call("set_gameplay_paused", true)
	var frozen := [visual.position, shadow.scale, sprite.call("get_clip_frame")]
	player.call("_process", 0.5)
	_expect([visual.position, shadow.scale, sprite.call("get_clip_frame")] == frozen,
		"%s Jump freezes exactly at its apex" % context)
	player.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
