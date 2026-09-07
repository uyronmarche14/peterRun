extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	menu.call("request_quit")
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
