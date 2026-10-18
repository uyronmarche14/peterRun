extends SceneTree

const OUT := "res://../test_evidence/jump_review_2026_10_18"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Jump review needs graphical Godot")
		quit(2)
		return
	root.mode = Window.MODE_WINDOWED
	await process_frame
	await process_frame
	root.size = Vector2i(960, 540)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
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
	await _capture("run", player)
	player.call("handle_action", &"jump")
	var action_tween: Tween = player.get("_action_tween")
	var shadow_tween: Tween = player.get("_shadow_tween")
	action_tween.pause()
	shadow_tween.pause()
	for step in [Vector2(0.12, 0), Vector2(0.20, 1), Vector2(0.12, 2), Vector2(0.20, 3), Vector2(0.18, 4)]:
		var delta: float = step.x
		player.call("_process", delta)
		shadow_tween.custom_step(delta)
		action_tween.custom_step(delta)
		await _capture("jump_%d" % int(step.y), player)
	level.free()
	print("Jump review captured")
	quit(0)


func _capture(label: String, player: Node2D) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var visual: Node2D = player.get_node("Visual")
	var sprite: Sprite2D = player.get_node("Visual/CharacterSprite")
	print("JUMP_POSE ", label, " visual_y=", visual.position.y, " frame=", sprite.call("get_clip_frame"))
	var path := ProjectSettings.globalize_path("%s/%s.png" % [OUT, label])
	var frame := root.get_texture().get_image()
	assert(frame.get_size() == Vector2i(960, 540), "Unexpected capture dimensions: %s" % frame.get_size())
	assert(frame.save_png(path) == OK)
