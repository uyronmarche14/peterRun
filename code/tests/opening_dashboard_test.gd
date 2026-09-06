extends SceneTree

var failures: PackedStringArray = []
const MUSIC := "res://art/audio/hakbang_sa_umaga.wav"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(FileAccess.file_exists(MUSIC), "Original menu instrumental exists")
	var menu: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	_expect(menu.has_method("toggle_music"), "Opening offers music control")
	_expect(menu.has_node("BarangayBackdrop"), "Opening has an original barangay environment")
	_expect(menu.has_node("SettingsOverlay"), "Settings opens an actual settings panel")
	_expect(menu.has_node("QuitOverlay"), "Quit has confirmation")
	if menu.has_method("toggle_music") and FileAccess.file_exists(MUSIC):
		var music: AudioStreamPlayer = menu.get_node("MenuMusic")
		_expect(music.stream is AudioStreamWAV and music.stream.get_length() >= 15, "Menu has a complete reusable instrumental loop")
		_expect(music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Music loops rather than stopping abruptly")
		menu.call("set_music_volume", 35.0)
		menu.call("toggle_music")
		_expect(music.stream_paused, "Mute immediately pauses music")
		menu.call("toggle_music")
		_expect(not music.stream_paused, "Music resumes explicitly")
		menu.call("set_music_volume", -50.0)
		_expect(music.volume_db <= -60.0, "Zero volume is silent")
		menu.call("set_music_volume", 1000.0)
		_expect(music.volume_db <= -12.0, "Music volume stays within a gentle output cap")
		menu.get_node("Dashboard/Margin/Content/SecondaryActions/SettingsButton").pressed.emit()
		_expect(menu.get_node("SettingsOverlay").visible, "Settings stays on the opening screen")
		menu.call("open_patient_setup")
		_expect(current_scene == menu, "Modal prevents click-through start")
		menu.call("close_overlays")
		menu.get_node("Dashboard/Margin/Content/SecondaryActions/QuitButton").pressed.emit()
		_expect(menu.get_node("QuitOverlay").visible, "Quit asks before exiting")
		menu.call("close_overlays")
		menu.call("toggle_music")
		menu.call("open_tutorial")
		await process_frame
		await process_frame
		_expect(current_scene.scene_file_path == "res://scenes/tutorial.tscn", "Tutorial remains accessible")
		_expect(not is_instance_valid(music), "Opening music does not leak into practice/gameplay")
		current_scene.free()
		menu = load("res://scenes/main.tscn").instantiate()
		root.add_child(menu)
		current_scene = menu
		await process_frame
		_expect(menu.get_node("MenuMusic").stream_paused, "Mute choice survives a return to the opening")
		menu.call("toggle_music")
		menu.call("set_music_volume", 35.0)
	menu.free()
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN opening dashboard test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
