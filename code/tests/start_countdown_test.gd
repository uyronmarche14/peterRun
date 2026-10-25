extends SceneTree

const RUNNER_LEVEL_PATH := "res://scenes/levels/runner_level.tscn"
const READY_PATH := "res://scenes/ready.tscn"
const GameSettingsModel = preload("res://scripts/game_settings.gd")
const PromptDirectorModel = preload("res://scripts/prompt_director.gd")

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_default_run_has_no_countdown()
	await _test_countdown_holds_then_starts_first_prompt()
	await _test_five_second_countdown()
	await _test_countdown_can_be_turned_off()
	await _test_ready_screen_requests_countdown()
	_finish()


func _make_level() -> Node:
	var level: Node = (load(RUNNER_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	return level


func _test_default_run_has_no_countdown() -> void:
	GameSettingsModel.start_countdown_pending = false
	var level := await _make_level()
	var director := level.get_node("PromptDirector")
	_expect(not level.is_countdown_active, "a direct scene load does not run the countdown")
	_expect(director.state == PromptDirectorModel.State.WARNING, "a direct scene load schedules the first prompt immediately")
	level.free()


func _test_countdown_holds_then_starts_first_prompt() -> void:
	GameSettingsModel.start_countdown_pending = true
	var level := await _make_level()
	var director := level.get_node("PromptDirector")
	var overlay := level.get_node_or_null(^"CountdownOverlay") as CanvasLayer
	var number := level.get_node_or_null(^"CountdownOverlay/Number") as Label
	var timer := level.get_node_or_null(^"PromptTimers/CountdownTimer") as Timer
	_expect(overlay != null and number != null and timer != null, "runner has CountdownOverlay, Number and CountdownTimer")
	if overlay == null or number == null or timer == null:
		level.free()
		return

	_expect(not GameSettingsModel.start_countdown_pending, "the one-shot countdown flag is consumed")
	_expect(level.is_countdown_active, "countdown is active after the scene loads")
	_expect(overlay.visible, "countdown overlay is visible")
	_expect(number.text == "3", "countdown starts at 3")
	_expect(director.state == PromptDirectorModel.State.IDLE, "no prompt is scheduled during the countdown")
	_expect(level.warning_timer.is_stopped(), "prompt timers do not run during the countdown")
	_expect(level.gameplay_ambience.playing, "the ambience starts at 3")
	_expect(level.player.character_sprite.animation == &"walk_forward", "Peter walks during the countdown")
	_expect(is_equal_approx(GameSettingsModel.motion_pace(), GameSettingsModel.visual_pace * GameSettingsModel.COUNTDOWN_PACE_FRACTION), "the road moves slowly during the countdown")
	var distance_before: float = level.world_motion.motion_distance
	level.world_motion._process(1.0)
	_expect(level.world_motion.motion_distance > distance_before, "the road and scenery keep moving during the countdown")

	level.receive_input(&"move_left", true, 10.0)
	level.receive_input(&"pause_session", true, 20.0)
	_expect(level.player.lane_index == 1, "movement input is ignored during the countdown")
	_expect(not level.is_gameplay_paused, "pause input is ignored during the countdown")

	timer.timeout.emit()
	_expect(number.text == "2", "countdown shows 2")
	timer.timeout.emit()
	_expect(number.text == "1", "countdown shows 1")
	timer.timeout.emit()
	_expect(number.text == "Go!", "countdown shows Go!")
	_expect(not level.is_countdown_active, "Go! ends the countdown")
	_expect(director.state == PromptDirectorModel.State.WARNING, "Go! begins the first prompt")
	_expect(overlay.visible, "Go! stays on screen briefly over the first prompt")
	_expect(GameSettingsModel.motion_pace() < GameSettingsModel.visual_pace, "the road is still easing up to speed right after Go!")
	level._process(0.25)
	var halfway := GameSettingsModel.motion_pace()
	_expect(halfway > GameSettingsModel.visual_pace * GameSettingsModel.COUNTDOWN_PACE_FRACTION and halfway < GameSettingsModel.visual_pace, "the road speeds up gradually (%.2f)" % halfway)
	level._process(0.3)
	_expect(is_equal_approx(GameSettingsModel.motion_pace(), GameSettingsModel.visual_pace), "the road reaches full speed about half a second after Go!")
	timer.timeout.emit()
	_expect(not overlay.visible, "the Go! text is removed after it has been shown")

	level.receive_input(&"move_left", true, 30.0)
	_expect(level.player.lane_index == 0, "movement works from Go!")
	level.free()
	_expect(is_equal_approx(GameSettingsModel.motion_pace(), GameSettingsModel.visual_pace), "leaving the run restores the normal pace")


func _test_five_second_countdown() -> void:
	GameSettingsModel.countdown_seconds = 5
	GameSettingsModel.start_countdown_pending = true
	var level := await _make_level()
	var number := level.get_node("CountdownOverlay/Number") as Label
	var timer := level.get_node("PromptTimers/CountdownTimer") as Timer
	var seen: Array[String] = [number.text]
	for i in 5:
		timer.timeout.emit()
		seen.append(number.text)
	_expect(seen == ["5", "4", "3", "2", "1", "Go!"], "a 5 second countdown shows 5 4 3 2 1 Go! (got %s)" % str(seen))
	_expect(not level.is_countdown_active, "the 5 second countdown ends at Go!")
	GameSettingsModel.countdown_seconds = 3
	level.free()


func _test_countdown_can_be_turned_off() -> void:
	GameSettingsModel.countdown_seconds = 0
	GameSettingsModel.start_countdown_pending = true
	var level := await _make_level()
	_expect(not level.is_countdown_active, "countdown set to Off does not run")
	_expect(level.get_node("PromptDirector").state == PromptDirectorModel.State.WARNING, "with the countdown Off the first prompt starts at once")
	_expect(not GameSettingsModel.start_countdown_pending, "the one-shot flag is still consumed when the countdown is Off")
	GameSettingsModel.countdown_seconds = 3
	level.free()


func _test_ready_screen_requests_countdown() -> void:
	GameSettingsModel.start_countdown_pending = false
	var ready_screen: Node = (load(READY_PATH) as PackedScene).instantiate()
	root.add_child(ready_screen)
	await process_frame
	ready_screen.start_session()
	_expect(GameSettingsModel.start_countdown_pending, "Start on the Ready screen requests the countdown")
	GameSettingsModel.start_countdown_pending = false
	ready_screen.free()


func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)


func _finish() -> void:
	if failures.is_empty():
		print("PETER RUN start countdown test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("FAIL: " + failure)
	quit(1)
