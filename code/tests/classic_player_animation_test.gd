extends SceneTree

const Settings = preload("res://scripts/game_settings.gd")
var failures: PackedStringArray = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var player: Node2D = load("res://scenes/player.tscn").instantiate()
	root.add_child(player)
	player.set_process(false)
	var sprite: Sprite2D = player.get_node("Visual/CharacterSprite")
	var visual: Node2D = player.get_node("Visual")
	_expect(player.has_method("set_walking"), "Player exposes presentation-only walking context")
	if player.has_method("set_walking"):
		player.call("set_walking", true)
		_expect(sprite.get("animation") == &"walk_forward", "Runner context walks")
		player.call("_process", 0.25)
		_expect(sprite.call("get_clip_frame") == 1, "Walking samples the approved six-pose manifest timestamps")
		player.call("handle_action", &"move_left")
		_expect(sprite.get("animation") == &"move_left", "Left uses original left artwork")
		_expect(is_equal_approx(sprite.get("duration"), 0.22), "Side-step artwork compresses to unchanged lane duration")
		var lane: Tween = player.get("_lane_tween")
		lane.pause()
		lane.custom_step(0.11)
		player.call("_process", 0.11)
		_expect(player.position.x < 240 and player.position.x > 128 and sprite.call("get_clip_frame") == 3, "Lane movement and approved side-step poses progress together")
		lane.custom_step(0.11)
		player.call("_process", 0.11)
		_expect(player.get("lane_index") == 0 and sprite.get("animation") == &"walk_forward", "Side-step ends at existing lane without changing state")
		player.call("handle_action", &"move_right")
		_expect(sprite.get("animation") == &"move_right", "Right artwork is not a mirrored left surrogate")
		for action in [&"jump", &"slide"]:
			player.call("reset_for_practice")
			player.call("handle_action", action)
			var expected := &"jump_low" if action == &"jump" else &"slide_duck"
			var seconds := 0.62 if action == &"jump" else 0.48
			_expect(sprite.get("animation") == expected, "Named action selects " + String(expected))
			var tween: Tween = player.get("_action_tween")
			tween.pause()
			tween.custom_step(seconds * 0.5)
			player.call("_process", seconds * 0.5)
			_expect(sprite.call("get_clip_frame") == 3, "Action advances using exact authored timestamps")
			_expect(visual.transform == Transform2D.IDENTITY, "Authored jump/duck never receives duplicate lift, lean or squash")
			if action == &"jump":
				var shadow_tween: Tween = player.get("_shadow_tween")
				shadow_tween.pause()
				shadow_tween.custom_step(0.25)
				var ground: Sprite2D = player.get_node("Shadow/GroundSprite")
				_expect(ground.to_global(Vector2(128, 216) + ground.offset).is_equal_approx(player.to_global(Vector2(0, 15))), "Shrinking jump shadow stays anchored to the ground pivot")
			var frozen_frame: int = sprite.call("get_clip_frame")
			var frozen_elapsed: float = sprite.get("elapsed")
			player.call("set_gameplay_paused", true)
			player.call("_process", 2.0)
			tween.custom_step(2.0)
			_expect(sprite.get("animation") == expected and sprite.call("get_clip_frame") == frozen_frame and sprite.get("elapsed") == frozen_elapsed, "Pause freezes exact action frame without grounded paused pose")
			_expect(player.get("action_state") != 0, "Pause freezes gameplay action timer too")
			player.call("set_gameplay_paused", false)
			tween.custom_step(seconds * 0.5 - 0.001)
			_expect(player.get("action_state") != 0, "Action remains active until original deadline")
			tween.custom_step(0.002)
			_expect(player.get("action_state") == 0, "Action recovers at original deadline")
		player.call("reset_for_practice")
		Settings.set_reduced_motion(true)
		player.call("set_walking", true)
		player.call("_process", 0.8)
		_expect(sprite.get("animation") == &"idle_ready" and sprite.call("get_clip_frame") == 0, "Reduced motion suppresses ambient walking, not gameplay")
		player.call("handle_action", &"jump")
		player.call("_process", 0.3)
		_expect(sprite.get("animation") == &"jump_low" and player.get("action_state") == 1, "Reduced motion retains meaningful action and timing")
		_expect(not player.get_node("LaneTrail").visible and not player.get_node("LandingRing").visible, "Reduced motion removes extra ground effects")
		Settings.set_reduced_motion(false)
	player.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN classic player animation test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
