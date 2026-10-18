extends SceneTree

const OUTPUT := "res://../test_evidence/character_inbetweens_v06"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Character visual review requires graphical Godot")
		quit(2)
		return
	root.mode = Window.MODE_WINDOWED
	await process_frame
	await process_frame
	root.size = Vector2i(960, 540)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var level: Node2D = (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	level.get_node("WorldMotion").set_process(false)
	level.get_node("LevelWorld/L01BarangayLayers").set_process(false)
	var player: Node2D = level.get_node("Player")
	player.set_process(false)
	player.call("reset_for_practice")
	player.call("set_walking", true)
	await _capture(player, "run")
	await _capture_action(player, &"jump", [0.12, 0.32, 0.52, 0.76])
	await _capture_action(player, &"slide", [0.08, 0.18, 0.30, 0.50])
	level.free()
	print("Character v06 in-between review captured at 960x540")
	quit(0)


func _capture_action(player: Node2D, action: StringName, times: Array) -> void:
	player.call("reset_for_practice")
	player.call("set_walking", true)
	assert(player.call("handle_action", action))
	var action_tween: Tween = player.get("_action_tween")
	action_tween.pause()
	var shadow_tween: Tween = player.get("_shadow_tween")
	if shadow_tween != null:
		shadow_tween.pause()
	var previous := 0.0
	for target in times:
		var delta: float = target - previous
		player.call("_process", delta)
		if shadow_tween != null:
			shadow_tween.custom_step(delta)
		action_tween.custom_step(delta)
		await _capture(player, "%s_%03d" % [action, int(target * 100)])
		previous = target


func _capture(player: Node2D, label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var sprite: Sprite2D = player.get_node("Visual/CharacterSprite")
	var frame := root.get_texture().get_image()
	assert(frame.get_size() == Vector2i(960, 540))
	var path := ProjectSettings.globalize_path("%s/%s.png" % [OUTPUT, label])
	assert(frame.save_png(path) == OK)
	print("ACTION_POSE ", label, " frame=", sprite.call("get_clip_frame"))
