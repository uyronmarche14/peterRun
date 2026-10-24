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
	_expect(level.is_countdown_active, "countdown stays active while Go! is shown")
	timer.timeout.emit()
	_expect(not level.is_countdown_active, "countdown ends after Go!")
	_expect(not overlay.visible, "countdown overlay hides after Go!")
	_expect(director.state == PromptDirectorModel.State.WARNING, "the first prompt starts after the countdown")

	level.receive_input(&"move_left", true, 30.0)
	_expect(level.player.lane_index == 0, "movement works after the countdown")
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
