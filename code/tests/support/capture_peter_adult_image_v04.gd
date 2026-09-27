extends SceneTree
## Captures the real player/controller with the approved adult image animations.

const OUTPUT := "res://../test_evidence/peter_adult_image_v04"
const SIZES := [Vector2i(960, 540), Vector2i(1024, 768), Vector2i(1920, 1080)]

var level: Node
var player: Node
var entries: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		printerr("Actual graphical viewport required")
		quit(2)
		return
	root.mode = Window.MODE_WINDOWED
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = SIZES[0]
	root.title = "PETER RUN - Adult image animation verification"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	level = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	for timer in level.get_node("PromptTimers").get_children():
		timer.stop()
	player = level.get_node("Player")
	player.set_process(false)
	for size in SIZES:
		root.size = size
		await process_frame
		await process_frame
		for state in [&"idle_ready", &"walk_forward", &"move_left", &"move_right", &"jump", &"slide", &"rest", &"success_settle", &"neutral_clear", &"paused"]:
			player.reset_for_practice()
			match state:
				&"walk_forward":
					player.set_walking(true)
				&"rest":
					player.set_resting_preview()
				&"paused":
					player.set_resting_preview(true)
				&"success_settle":
					player.show_resolved_feedback(true)
				&"neutral_clear":
					player.show_resolved_feedback(false)
				&"move_left", &"move_right", &"jump", &"slide":
					player.handle_action(state)
				_:
					pass
			step(0.11 if state in [&"move_left", &"move_right"] else (0.24 if state == &"slide" else 0.30))
			player.set_gameplay_paused(true)
			await capture(String(state), size)
			if state in [&"jump", &"slide", &"move_left"]:
				level.pause_gameplay()
				await process_frame
				await capture(String(state) + "_pause_freeze", size)
				level.resume_gameplay()
				step(0.035)
				player.set_gameplay_paused(true)
				await capture(String(state) + "_resumed", size)
	var report := FileAccess.open(OUTPUT + "/captures.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(entries, "\t"))
	level.free()
	print("PETER ADULT IMAGE GRAPHICAL CAPTURE PASS: ", entries.size())
	quit(0)


func step(seconds: float) -> void:
	for key in [&"_lane_tween", &"_action_tween", &"_shadow_tween"]:
		var tween: Tween = player.get(key)
		if tween != null and tween.is_valid():
			tween.pause()
			tween.custom_step(seconds)
	player._process(seconds)


func capture(label: String, size: Vector2i) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var filename := "%s_%dx%d.png" % [label, size.x, size.y]
	var method := "viewport_readback"
	if image.get_size() != size:
		var window_image := Image.create_empty(size.x, size.y, false, image.get_format())
		window_image.fill(Color.BLACK)
		var inset := Vector2i((size.x - image.get_width()) / 2, (size.y - image.get_height()) / 2)
		window_image.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), inset)
		image = window_image
		method = "viewport_readback_with_letterbox_canvas"
	assert(image.save_png(OUTPUT + "/" + filename) == OK)
	assert(image.get_size() == size)
	entries.append({
		"file": filename,
		"capture_method": method,
		"viewport": [image.get_width(), image.get_height()],
		"clip": String(player.character_sprite.animation),
		"frame": player.character_sprite.get_clip_frame(),
		"elapsed": player.character_sprite.elapsed,
		"position": [player.position.x, player.position.y],
	})
