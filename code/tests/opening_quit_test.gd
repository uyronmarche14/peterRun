extends SceneTree

var quit_started_at := 0

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	# Reproduce a busy startup frame; its delta must not consume a new quit wait.
	OS.delay_msec(200)
	menu.call("request_quit")
	quit_started_at = Time.get_ticks_msec()
	menu.call("confirm_quit")
	if not menu.get("_leaving") or menu.get_node("MenuMusic").playing:
		printerr("FAIL: Confirmed quit must stop music and lock navigation before shutdown")
		quit(1)
		return
	# The confirmation must allow one audio release interval before engine exit.
	await create_timer(0.05).timeout
	print("PETER RUN opening quit test: PASS")
	# A broken exit must not hang this test indefinitely.
	await create_timer(2.0).timeout
	printerr("FAIL: Confirmed quit did not close the application")
	quit(1)


func _finalize() -> void:
	if quit_started_at > 0 and Time.get_ticks_msec() - quit_started_at < 150:
		printerr("FAIL: Quit must allow 150ms of actual wall time for audio release")
