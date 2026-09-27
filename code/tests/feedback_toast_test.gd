extends SceneTree

var failures: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level: Node = load("res://scenes/levels/runner_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var toast: Control = level.get_node_or_null("HUD/HUDRoot/FeedbackToast")
	_expect(toast != null, "Runner provides a nonblocking feedback toast")
	if toast != null:
		toast.set_process(false)
		var director: Node = level.get_node("PromptDirector")
		director.call("open_response_window")
		director.call("receive_action", director.get("current_action"))
		var first_message: String = toast.get_node("Message").text
		_expect(not first_message.is_empty() and toast.visible, "Successful movement shows encouragement")
		level.call("receive_input", &"move_left", true, 10.1)
		_expect(toast.get_node("Message").text == first_message, "Held input does not rotate or duplicate feedback")
		toast.call("_process", 0.2)
		var before_pause: float = toast.get("elapsed")
		level.call("pause_gameplay")
		toast.call("_process", 2.0)
		_expect(toast.get("elapsed") == before_pause and not toast.visible, "Pause hides and freezes toast feedback")
		level.call("resume_gameplay")
		_expect(toast.visible, "Resume restores remaining feedback")
		toast.call("_process", 2.0)
		_expect(not toast.visible, "Toast dismisses without user interaction")
		level.call("_on_resolve_timer_timeout")
		director.call("open_response_window")
		director.call("receive_action", director.get("current_action"))
		_expect(toast.get_node("Message").text != first_message, "Consecutive successes receive varied recognition")
		level.call("_on_resolve_timer_timeout")
		# This test exercises a non-contact neutral miss. Obstacle contact is a
		# distinct run-ending outcome and must not be treated as toast feedback.
		level.set("_active_formation", {})
		director.call("open_response_window")
		director.call("expire_active_prompt")
		_expect(toast.get_node("Message").text == "Take your time.", "Miss feedback stays neutral")
		_expect(toast.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Toast never intercepts mouse input")
		toast.call("show_result", true, 10)
		_expect(toast.get_node("Message").text == "10 movements completed!", "Completed movement milestones receive recognition")
		var child_count := toast.get_child_count()
		for count in 50:
			toast.call("show_result", true, 10)
		_expect(toast.get_child_count() == child_count, "Repeated feedback reuses one toast without a notification backlog")
		level.call("end_session_neutrally")
		_expect(not toast.visible, "End session clears feedback")
	level.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN feedback toast test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
