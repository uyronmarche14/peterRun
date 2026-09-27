extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var manifest_path := "res://art/characters/peter_original_v01/animation_manifest.json"
	if not FileAccess.file_exists(manifest_path):
		printerr("FAIL: Original rigged Peter manifest is absent")
		quit(1)
		return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	check(manifest.asset_origin == "original procedural mesh and skeletal animation", "Original provenance")
	var player: Node2D = load("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.set_process(false)
	var sprite: Sprite2D = player.get_node("Visual/CharacterSprite")
	for clip in manifest.animations:
		var spec: Dictionary = manifest.animations[clip]
		sprite.play_clip(StringName(clip))
		check(is_equal_approx(sprite.duration, spec.duration_seconds), "Manifest owns duration: " + clip)
		for index in int(spec.frames):
			sprite.play_clip(StringName(clip))
			sprite.advance(float(spec.timestamps[index]) + 0.00001)
			check(sprite.get_clip_frame() == index, "Timestamp selects frame: %s/%s" % [clip,index])
			check(sprite.texture is AtlasTexture, "Runtime atlas resource: " + clip)
			check(sprite.texture.get_size() == Vector2(256,256), "Runtime canvas")
		check(sprite.texture.get_image().get_pixel(0,0).a == 0.0, "Transparent corner")
	for action in [&"move_left", &"move_right", &"jump", &"slide"]:
		player.reset_for_practice()
		player.set_walking(true)
		check(player.handle_action(action), "Action accepted")
		var timer: Tween = player.get("_lane_tween" if action in [&"move_left", &"move_right"] else "_action_tween")
		timer.pause()
		timer.custom_step(0.08)
		player._process(0.08)
		var frozen := [player.position, sprite.elapsed, sprite.get_clip_frame(), player.action_state]
		player.set_gameplay_paused(true)
		timer.custom_step(3.0)
		player._process(3.0)
		check(frozen == [player.position, sprite.elapsed, sprite.get_clip_frame(), player.action_state], "Exact pause: " + action)
		player.set_gameplay_paused(false)
		timer.custom_step(0.03)
		player._process(0.03)
		check(sprite.elapsed > float(frozen[1]), "Resume advances existing clip")
		player.reset_for_practice()
		player._process(2.0)
		check(player.action_state == 0 and player.lane_index == 1 and sprite.animation == &"idle_ready", "Reset clears callbacks")
	# A queued resolution must never reappear after a subsequent accepted action.
	player.reset_for_practice()
	player.handle_action(&"jump")
	player.show_resolved_feedback(true)
	player.handle_action(&"move_right")
	check(player.get("_pending_feedback") == &"", "Accepted action clears stale cosmetic feedback")
	check(sprite.animation == &"jump_low", "Lateral movement preserves airborne clip")
	check(player.get_node("Visual").transform == Transform2D.IDENTITY, "Lift only in artwork")
	player.reset_for_practice()
	player.handle_action(&"move_left")
	player.handle_action(&"move_right")
	var lane: Tween = player.get("_lane_tween")
	lane.pause()
	lane.custom_step(0.22)
	player._process(0.22)
	check(is_equal_approx(player.position.x,240.0), "Rapid reversal settles in intended lane")
	player.reset_for_practice()
	player.handle_action(&"slide")
	player.show_resolved_feedback(true)
	player.finish_session_visuals()
	check(player.get("_action_tween") == null and player.get("_shadow_tween") == null and player.get("_lane_tween") == null, "End releases callbacks")
	check(player.get("_pending_feedback") == &"" and player.is_gameplay_paused, "Terminal state clears cosmetic queue")
	player.free()
	for failure in failures: printerr("FAIL: " + failure)
	print("PETER ORIGINAL character integration: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
