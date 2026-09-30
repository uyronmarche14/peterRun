extends SceneTree

const Setup = preload("res://scripts/session_setup_store.gd")
const Config = preload("res://scripts/session_config.gd")
const ReviewPath := "res://scripts/session_review_store.gd"
const SummaryPath := "res://scenes/session_summary.tscn"
var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(ResourceLoader.exists(ReviewPath), "Finished sessions have a review data store")
	_expect(ResourceLoader.exists(SummaryPath), "Session summary scene exists")
	if failures.is_empty():
		var review: GDScript = load(ReviewPath)
		review.call("reset")
		Setup.reset()
		await _test_completion_and_rating(review)
		await _test_early_end_and_retry(review)
		await _test_collision_outcome(review)
		await _test_empty_summary(review)
		Setup.reset()
	# Allow the stopped menu playback to leave the audio mixer before shutdown.
	await create_timer(0.15).timeout
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN session summary flow test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _open(path: String) -> Node:
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	return scene


func _test_completion_and_rating(review: GDScript) -> void:
	var config: Variant = Setup.get_session_config()
	for action in Config.ACTIONS:
		config.set_target(action, 1)
	var runner := _open("res://scenes/levels/runner_level.tscn")
	await process_frame
	var director: Node = runner.get_node("PromptDirector")
	# Collision now ends a run, so this completion path uses only correct
	# contact responses. Collision coverage lives in formation_runner_test.
	for _index in 80:
		if runner.get("is_session_ended"):
			break
		var action: StringName = director.get("current_action")
		director.call("open_response_window")
		director.call("receive_action", action)
		if not runner.get("is_session_ended"):
			runner.call("_on_resolve_timer_timeout")
	_expect(runner.get("is_session_ended"), "Meeting targets ends gameplay immediately")
	var result: Variant = review.call("get_result")
	_expect(result != null and result.neutral_misses == 0, "A collision-free completion preserves no neutral misses")
	if result == null:
		runner.free()
		return
	for action in Config.ACTIONS:
		_expect(result.get_completed(action) == 1, "Summary preserves completed " + str(action))
	_expect(review.call("get_end_reason") == &"completed", "Completion has a distinct review reason")
	runner.call("_on_prompt_state_changed", 3, &"jump", 1)
	_expect(runner.get("session_result").get_completed(&"jump") == 1, "Late callbacks cannot count after ending")
	runner.get("session_result").record_success(&"jump")
	config.set_target(&"jump", 9)
	_expect(result.get_completed(&"jump") == 1 and review.call("get_config").get_target(&"jump") == 1, "Review snapshots are independent of live gameplay/config")
	runner.get_node("EndSessionOverlay/Panel/ReturnButton").pressed.emit()
	await process_frame
	await process_frame
	_expect(current_scene.scene_file_path == SummaryPath, "Review button opens the actual summary")
	var summary := current_scene
	_expect_controls_fit(summary.get_node("Panel"), summary.get_node("Panel").get_global_rect())
	_expect(summary.get_node("Panel/Margin/Content/Repetitions/Jump").text == "Jump: 1 / 1", "Summary displays completed and planned repetitions")
	_expect_outcome(summary, "Outcome: Planned repetitions complete", "Summary identifies planned completion")
	_expect(summary.get_node("Panel/Margin/Content/Misses").text == "Neutral misses: 0", "Summary labels collision-free completion neutrally")
	_expect(summary.has_node("Panel/Margin/Content/Journey"), "Summary includes calm journey context")
	if summary.has_node("Panel/Margin/Content/Journey"):
		_expect(summary.get_node("Panel/Margin/Content/Journey").text == "Journey landmark: Barangay Plaza", "Completed repetitions reach the final journey landmark without a score")
		_expect(summary.has_node("Panel/Margin/Content/Journey/JourneyStamp"), "Summary journey row includes a calm route stamp")
		if summary.has_node("Panel/Margin/Content/Journey/JourneyStamp"):
			var stamp := summary.get_node("Panel/Margin/Content/Journey/JourneyStamp") as TextureRect
			_expect(stamp.texture is AtlasTexture and int((stamp.texture as AtlasTexture).region.position.x) == 384, "Completed route displays the Barangay Plaza stamp frame")
	_expect(summary.get_node("Panel/Margin/Content/Actions/RetryButton").disabled, "Retry waits for a recorded rating")
	for invalid in [0, 11, 3.5, "5"]:
		_expect(not summary.call("select_rating", invalid), "Invalid rating is rejected")
	for rating in range(1, 11):
		summary.get_node("Panel/Margin/Content/Ratings/Rating%d" % rating).pressed.emit()
		_expect(result.rpe == rating, "Mouse rating button records %d" % rating)
	_expect(current_scene == summary, "Even a high rating never starts a new session automatically")
	summary.get_node("Panel/Margin/Content/Actions/RestButton").pressed.emit()
	await process_frame
	_expect(current_scene == summary and summary.get("is_resting"), "Rest stays on review without a timer or automatic restart")
	summary.get_node("Panel/Margin/Content/Actions/FinishButton").pressed.emit()
	await process_frame
	await process_frame
	_expect(current_scene.scene_file_path == "res://scenes/main.tscn", "Finish returns to Main Menu")
	_expect(result.rpe == 10 and review.call("get_decision") == &"finish", "Rating and decision remain available in memory")
	current_scene.free()


func _test_early_end_and_retry(review: GDScript) -> void:
	Setup.configure(Config.AffectedSide.LEFT, 12)
	Setup.get_session_config().set_target(&"slide", 15)
	var runner := _open("res://scenes/levels/runner_level.tscn")
	await process_frame
	var director: Node = runner.get_node("PromptDirector")
	director.call("open_response_window")
	var completed_action: StringName = director.get("current_action")
	director.call("receive_action", completed_action)
	runner.get_node("PauseOverlay/Panel/Actions/EndSessionButton").pressed.emit()
	_expect(runner.get_node("EndConfirmation").visible and runner.get("is_gameplay_paused"), "Early end asks for confirmation and freezes play")
	runner.call("resume_gameplay")
	_expect(runner.get("is_gameplay_paused"), "Pause shortcut cannot resume beneath confirmation")
	runner.call("cancel_end")
	_expect(not runner.get("is_session_ended") and runner.get("is_gameplay_paused"), "Cancel returns to paused gameplay without losing results")
	runner.get_node("PauseOverlay/Panel/Actions/EndLevelButton").pressed.emit()
	runner.call("confirm_end")
	_expect(review.call("get_end_reason") == &"level_ended", "Early level ending records its reason")
	_expect(review.call("get_result").get_completed(completed_action) == 1, "Early ending preserves partial progress")
	runner.call("open_summary")
	await process_frame
	await process_frame
	var summary := current_scene
	_expect_outcome(summary, "Outcome: Level ended by therapist", "Summary identifies a therapist-ended level")
	summary.call("retry_session")
	_expect(current_scene == summary, "An unrated retry cannot bypass the disabled button")
	summary.call("select_rating", 4)
	summary.call("retry_session")
	await process_frame
	await process_frame
	_expect(current_scene.scene_file_path == "res://scenes/ready.tscn", "Retry requires an explicit start from Ready")
	_expect(Setup.get_session_config().affected_side == Config.AffectedSide.LEFT and Setup.get_session_config().get_target(&"jump") == 12, "Retry restores the reviewed session settings")
	_expect(Setup.get_session_config().get_target(&"slide") == 15, "Retry preserves per-action targets")
	Setup.get_session_config().set_target(&"slide", 13)
	_expect(review.call("get_config").get_target(&"slide") == 15, "Retry config does not alias the reviewed config")
	current_scene.call("start_session")
	await process_frame
	await process_frame
	_expect(current_scene.get("session_result").get_completed(&"jump") == 0 and current_scene.get("session_result").rpe == 0, "Retry starts a new result without inherited reps or rating")
	current_scene.call("request_end_session")
	current_scene.call("confirm_end")
	_expect(review.call("get_end_reason") == &"session_ended", "Early session ending records its reason")
	current_scene.call("open_summary")
	await process_frame
	await process_frame
	_expect_outcome(current_scene, "Outcome: Session ended by therapist", "Summary identifies a therapist-ended session")
	_expect(current_scene.get_node("Panel/Margin/Content/Actions/FinishButton").text == "Finish without rating", "An explicit unrated exit remains available")
	current_scene.call("finish_session")
	await process_frame
	await process_frame
	_expect(review.call("get_result").rpe == 0, "Unrated exit does not invent a rating")
	current_scene.free()


func _test_collision_outcome(review: GDScript) -> void:
	var config := Config.new()
	var result: Variant = (load("res://scripts/session_result.gd") as GDScript).new()
	review.call("capture", config, result, &"collision")
	var summary := _open(SummaryPath)
	await process_frame
	_expect_outcome(summary, "Outcome: Run ended after obstacle contact", "Summary identifies obstacle contact separately from a neutral miss")
	summary.free()


func _test_empty_summary(review: GDScript) -> void:
	review.call("reset")
	var summary := _open(SummaryPath)
	await process_frame
	_expect(summary.get_node("Panel/Margin/Content/Actions/RetryButton").disabled, "Opening Summary directly cannot replay a nonexistent session")
	summary.call("finish_session")
	await process_frame
	await process_frame
	_expect(current_scene.scene_file_path == "res://scenes/main.tscn", "Empty summary has a working exit")
	current_scene.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_outcome(summary: Node, expected_text: String, message: String) -> void:
	var outcome := summary.get_node_or_null("Panel/Margin/Content/Outcome") as Label
	_expect(outcome != null, message + " has an outcome row")
	if outcome != null:
		_expect(outcome.text == expected_text, message)


func _expect_controls_fit(node: Node, bounds: Rect2) -> void:
	if node is Control and node.is_visible_in_tree():
		_expect(bounds.grow(1).encloses(node.get_global_rect()), "Summary card contains " + str(node.get_path()))
	for child in node.get_children():
		_expect_controls_fit(child, bounds)
