extends SceneTree

var failures: PackedStringArray = []
const MUSIC := "res://art/audio/hakbang_sa_umaga.wav"
const HERO_ART := "res://art/backgrounds/dashboard_barangay_morning_hero_v03.png"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(FileAccess.file_exists(MUSIC), "Original menu instrumental exists")
	_expect(FileAccess.file_exists(HERO_ART), "Opening uses the approved image-based Barangay Morning dashboard art")
	var menu: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	_expect(menu.has_method("toggle_music"), "Opening offers music control")
	_expect(menu.has_node("DashboardHero"), "Opening has the dedicated Barangay Morning hero illustration")
	var hero := menu.get_node_or_null(^"DashboardHero") as TextureRect
	_expect(hero != null and hero.texture != null, "Opening dashboard hero texture loads")
	if hero != null and hero.texture != null:
		_expect(hero.texture.get_width() == 960 and hero.texture.get_height() == 540, "Dashboard hero uses the approved 960 x 540 source canvas")
	_expect(not menu.has_node("OpeningLife"), "Opening dashboard no longer depends on procedural scenery drawing")
	_expect(menu.has_node("Dashboard/Margin/Content/RouteTicket"), "Dashboard contains a route-ticket treatment")
	_expect(not menu.has_node("Dashboard/Margin/Content/RouteStrip"), "Card drops the landmark strip that disagreed with the in-game journey")
	_expect_label(menu, ^"Dashboard/Margin/Content/Title", "PETER RUN", "Opening title remains explicit")
	_expect_font(menu, ^"Dashboard/Margin/Content/Title", "LilitaOne", "Title uses the sign-painter display font")
	_expect_label(menu, ^"Dashboard/Margin/Content/Subtitle", "One step at a time.", "Card keeps the calm English subtitle")
	_expect_font(menu, ^"Dashboard/Margin/Content/Subtitle", "Fredoka", "Subtitle uses the rounded display font")
	_expect_label(menu, ^"%Quote", "Bawat hakbang ng buhay.", "Inspiration line sits over the scenery")
	_expect_label(menu, ^"%Translation", "Every step of life.", "Inspiration line has a quiet English gloss")
	_expect_font(menu, ^"%Quote", "Fredoka", "Inspiration line uses the rounded display font")
	var quote := menu.get_node_or_null(^"%Quote") as Label
	if quote != null:
		_expect(quote.get_theme_font_size("font_size") >= 16, "Inspiration line is large (at least 16 px native)")
		_expect((menu.get_node("HeroQuote/Pill") as PanelContainer).get_theme_stylebox("panel").bg_color.a >= 0.5, "Inspiration line sits on a readable backing over bright art")
		await process_frame
		var quote_rect := (menu.get_node("HeroQuote") as Control).get_global_rect()
		_expect(not quote_rect.intersects((menu.get_node("Dashboard") as Control).get_global_rect()), "Inspiration line stays clear of the card")
		_expect(not quote_rect.intersects((menu.get_node("MusicCredit") as Control).get_global_rect()), "Inspiration line stays clear of the music controls")
		_expect(quote_rect.end.x <= 480.0 and quote_rect.position.y >= 0.0, "Inspiration line stays on screen")
	_expect(not menu.has_node("RouteTagline"), "The old hard-to-read sky label is replaced")
	_expect_label(menu, ^"Dashboard/Margin/Content/WelcomeBadge/Label", "MABUHAY! · WELCOME", "Greeting is a badge on the card")
	_expect(not menu.has_node("Welcome"), "Corner greeting label is replaced by the badge")
	var credit := menu.get_node_or_null(^"MusicCredit") as Label
	_expect(credit != null and credit.text == "♫  Hakbang sa Umaga", "Music credit is short and names the track")
	_expect(credit != null and credit.position.y < 40.0, "Music credit sits with the Music button, not over foliage")
	_expect(menu.has_node("ReadabilityShade"), "A soft shade keeps the card readable over the painted art")
	var safety := menu.get_node_or_null(^"Dashboard/Margin/Content/SafetyNote") as Label
	_expect(safety != null and safety.text.begins_with("Supervised session") and not safety.text.contains("Keyboard mode available"), "Safety note is input-aware")
	_expect_label(menu, ^"Dashboard/Margin/Content/RouteTicket/Margin/Content/RouteName", "BARANGAY MORNING", "Route ticket names Barangay Morning")
	_expect_label(menu, ^"Dashboard/Margin/Content/RouteTicket/Margin/Content/RouteDetail", "L01 · GUIDED MOVEMENT ROUTE", "Route ticket explains the guided route")
	_expect(menu.has_node("SettingsOverlay"), "Settings opens an actual settings panel")
	_expect(menu.has_node("QuitOverlay"), "Quit has confirmation")
	for overlay_name in ["SettingsOverlay", "QuitOverlay"]:
		if menu.has_node(overlay_name):
			_expect(menu.get_node(overlay_name).z_index > menu.get_node("CharacterMount/OpeningPlayer").z_index, "Modal dims the animated character too: " + overlay_name)
	if menu.has_method("toggle_music") and FileAccess.file_exists(MUSIC):
		var music: AudioStreamPlayer = menu.get_node("MenuMusic")
		_expect(music.stream is AudioStreamWAV and music.stream.get_length() >= 15, "Menu has a complete reusable instrumental loop")
		_expect(music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Music loops rather than stopping abruptly")
		_expect(music.stream.loop_end == int(round(music.stream.get_length() * music.stream.mix_rate)), "Loop boundary covers the full imported track, including compressed audio")
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
	# Let the audio mixer release the stopped playback before process shutdown.
	await create_timer(0.15).timeout
	for failure in failures:
		printerr("FAIL: " + failure)
	print("PETER RUN opening dashboard test: " + ("PASS" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_label(root_node: Node, path: NodePath, expected: String, message: String) -> void:
	var label := root_node.get_node_or_null(path) as Label
	_expect(label != null and label.text == expected, message)


func _expect_font(root_node: Node, path: NodePath, file_hint: String, message: String) -> void:
	var control := root_node.get_node_or_null(path) as Control
	var font: Font = control.get_theme_font("font") if control != null else null
	var base: Font = font.base_font if font is FontVariation else font
	_expect(base != null and base.resource_path.contains(file_hint), message)
