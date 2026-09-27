extends SceneTree

var failures: PackedStringArray = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player: Node2D = load("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.set_process(false)
	var sprite: Sprite2D = player.get_node("Visual/CharacterSprite")
	_expect(sprite.has_method("play_clip"), "Player uses the classic frame animation presentation")
	if sprite.has_method("play_clip"):
		_expect(sprite.get("animation") == &"idle_ready", "Standalone player starts ready, not walking")
		_expect(sprite.scale == Vector2(0.3, 0.3), "Half-resolution atlas preserves original screen scale")
		_expect(sprite.position + sprite.offset * sprite.scale + Vector2(128, 216) * sprite.scale == Vector2(0, 15), "Authored feet pivot maps to existing ground")
		_expect(not sprite.centered, "Canvas pivot uses explicit top-left placement")
		sprite.call("advance", 1.0)
		_expect(sprite.call("get_clip_frame") == 24, "Idle samples at 24 fps across two seconds")
		sprite.call("advance", 1.0)
		_expect(sprite.call("get_clip_frame") == 0, "Idle cycle loops without duplicated endpoint")
		_expect(sprite.call("frame_path", &"move_left", 0) == "res://art/characters/peter_original_v01/move_left.png", "Frame lookup uses original atlas contract")
		sprite.call("play_clip", &"walk_forward")
		_expect(is_equal_approx(sprite.get("duration"), 1.2), "Walk respects production frame-duration multiplier")
		sprite.call("play_clip", &"rest")
		_expect(is_equal_approx(sprite.get("duration"), 2.0), "Rest respects production manifest duration")
	_expect(player.has_node("Shadow/GroundSprite"), "Player uses authored soft ground shadow")
	player.free()
	var menu: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	_expect(menu.get_node("CharacterMount/OpeningPlayer/Visual/CharacterSprite").get("animation") == &"rest", "Menu preview rests rather than walking in place")
	menu.free()
	# Let the real audio thread release menu playback; a startup delta can
	# consume a new SceneTreeTimer without giving the mixer any wall time.
	var release_at := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < release_at:
		await process_frame
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN classic sprite test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
