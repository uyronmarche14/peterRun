extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	Settings.start_countdown_pending = false
	var level: Node = (load("res://scenes/levels/runner_level.tscn") as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var original := Settings.visual_pace
	var player: Node = level.player
	var sprite: Node = player.character_sprite
	player.set_walking(true)

	var fast := _walk_elapsed(player, sprite, Settings.MAX_PACE)
	var std := _walk_elapsed(player, sprite, Settings.STANDARD_PACE)
	var slow := _walk_elapsed(player, sprite, Settings.MIN_PACE)
	_expect(is_equal_approx(std, 0.5), "Standard speed leaves the walk cycle unchanged (%.3f)" % std)
	_expect(is_equal_approx(fast / std, Settings.MAX_PACE), "The walk cycle runs at the speed ratio when fast (%.3f)" % (fast / std))
	_expect(is_equal_approx(slow / std, Settings.MIN_PACE), "The walk cycle runs at the speed ratio when slow (%.3f)" % (slow / std))

	Settings.set_visual_pace(Settings.MAX_PACE)
	level.sync_audio_settings()
	var fast_pitch: float = level.gameplay_ambience.pitch_scale
	Settings.set_visual_pace(Settings.MIN_PACE)
	level.sync_audio_settings()
	var slow_pitch: float = level.gameplay_ambience.pitch_scale
	_expect(fast_pitch > slow_pitch and fast_pitch <= 1.25 and slow_pitch >= 0.8, "Ambience pitch follows speed, only mildly (%.2f vs %.2f)" % [fast_pitch, slow_pitch])

	Settings.set_visual_pace(original)
	level.free()
	if failures.is_empty():
		print("PETER RUN speed cues follow speed test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("FAIL: " + failure)
	quit(1)


func _walk_elapsed(player: Node, sprite: Node, pace: float) -> float:
	Settings.set_visual_pace(pace)
	sprite.play_clip(&"walk_forward")
	player._process(0.5)
	return sprite.elapsed


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
